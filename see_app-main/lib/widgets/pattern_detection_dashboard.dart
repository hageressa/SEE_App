import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/emotion_heatmap_chart.dart';
import 'package:see_app/widgets/time_series_chart.dart';

class PatternDetectionDashboard extends StatefulWidget {
  final Child patient;
  final DatabaseService databaseService;
  
  const PatternDetectionDashboard({
    Key? key,
    required this.patient,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<PatternDetectionDashboard> createState() => _PatternDetectionDashboardState();
}

class _PatternDetectionDashboardState extends State<PatternDetectionDashboard> {
  bool _isLoading = true;
  List<EmotionData> _emotionData = [];
  Map<String, dynamic> _detectedPatterns = {};
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load emotion data for selected date range
      final emotions = await widget.databaseService.getEmotionsForDateRange(
        widget.patient.id,
        _dateRange.start,
        _dateRange.end,
      );
      
      // Generate pattern analysis
      final patterns = await _analyzePatterns(emotions);
      
      if (mounted) {
        setState(() {
          _emotionData = emotions;
          _detectedPatterns = patterns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pattern data: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _analyzePatterns(List<EmotionData> emotions) async {
    // This would integrate with a more sophisticated AI model in production
    // Here we're using a simplified algorithm for demonstration

    // Placeholder for detected patterns
    Map<String, dynamic> patterns = {
      'emotionFrequency': <String, int>{},
      'timeOfDayPatterns': <String, Map<String, int>>{},
      'weekdayPatterns': <String, Map<String, int>>{},
      'emotionTransitions': <String, List<String>>{},
      'potentialTriggers': <String>[],
    };
    
    if (emotions.isEmpty) {
      return patterns;
    }

    // Simple frequency analysis
    for (var emotion in emotions) {
      // Count emotion types
      final emotionName = emotion.type.name;
      patterns['emotionFrequency'][emotionName] = 
          (patterns['emotionFrequency'][emotionName] ?? 0) + 1;
      
      // Analyze time of day patterns
      final hour = emotion.timestamp.hour;
      String timeOfDay = 'morning';
      if (hour >= 12 && hour < 17) {
        timeOfDay = 'afternoon';
      } else if (hour >= 17) {
        timeOfDay = 'evening';
      }
      
      patterns['timeOfDayPatterns'][timeOfDay] = 
          patterns['timeOfDayPatterns'][timeOfDay] ?? <String, int>{};
      patterns['timeOfDayPatterns'][timeOfDay][emotionName] = 
          (patterns['timeOfDayPatterns'][timeOfDay][emotionName] ?? 0) + 1;
      
      // Analyze weekday patterns
      final weekday = DateFormat('EEEE').format(emotion.timestamp);
      patterns['weekdayPatterns'][weekday] = 
          patterns['weekdayPatterns'][weekday] ?? <String, int>{};
      patterns['weekdayPatterns'][weekday][emotionName] = 
          (patterns['weekdayPatterns'][weekday][emotionName] ?? 0) + 1;
    }
    
    // Analyze emotion transitions (which emotions tend to follow others)
    for (int i = 0; i < emotions.length - 1; i++) {
      final current = emotions[i].type.name;
      final next = emotions[i + 1].type.name;
      
      patterns['emotionTransitions'][current] = 
          patterns['emotionTransitions'][current] ?? <String>[];
      patterns['emotionTransitions'][current]!.add(next);
    }
    
    // Identify potential triggers based on notes and patterns
    List<String> triggers = [];
    Map<String, int> triggerWordCount = {};
    
    for (var emotion in emotions) {
      if (emotion.note != null && emotion.note!.isNotEmpty) {
        // Simple keyword extraction - in production this would use NLP
        final words = emotion.note!.toLowerCase().split(' ');
        for (var word in words) {
          if (word.length > 3) { // Skip short words
            triggerWordCount[word] = (triggerWordCount[word] ?? 0) + 1;
          }
        }
      }
    }
    
    // Find words that appear multiple times, especially with negative emotions
    triggerWordCount.forEach((word, count) {
      if (count > 2) {
        triggers.add(word);
      }
    });
    
    patterns['potentialTriggers'] = triggers;
    
    // Calculate correlations (simplified)
    // In production, this would use proper statistical correlation
    final correlations = <String, double>{};
    
    patterns['correlations'] = correlations;
    
    // Add basic insights based on analysis
    patterns['insights'] = _generateInsights(patterns);
    
    return patterns;
  }

  List<String> _generateInsights(Map<String, dynamic> patterns) {
    List<String> insights = [];
    
    // Most frequent emotion
    if (patterns['emotionFrequency'].isNotEmpty) {
      final entries = patterns['emotionFrequency'].entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      
      if (entries.isNotEmpty) {
        insights.add('${widget.patient.name} most frequently experiences ${entries[0].key} (${entries[0].value} times).');
      }
      
      if (entries.length > 1) {
        insights.add('The second most common emotion is ${entries[1].key} (${entries[1].value} times).');
      }
    }
    
    // Time of day patterns
    final timePatterns = patterns['timeOfDayPatterns'];
    if (timePatterns is Map && timePatterns.isNotEmpty) {
      timePatterns.forEach((time, emotions) {
        if (emotions is Map && emotions.isNotEmpty) {
          final entries = emotions.entries.toList();
          entries.sort((a, b) => b.value.compareTo(a.value));
          
          if (entries.isNotEmpty) {
            insights.add('${entries[0].key} is most common during the $time.');
          }
        }
      });
    }
    
    // Weekday patterns
    final weekdayPatterns = patterns['weekdayPatterns'];
    if (weekdayPatterns is Map && weekdayPatterns.isNotEmpty) {
      Map<String, int> dayTotals = {};
      Map<String, String> dominantEmotionByDay = {};
      
      weekdayPatterns.forEach((day, emotions) {
        if (emotions is Map && emotions.isNotEmpty) {
          int total = 0;
          String dominant = '';
          int maxCount = 0;
          
          emotions.forEach((emotion, count) {
            total = total + (count as num).toInt();
            if (count > maxCount) {
              maxCount = count.toInt();
              dominant = emotion;
            }
          });
          
          dayTotals[day] = total;
          dominantEmotionByDay[day] = dominant;
        }
      });
      
      // Find day with most emotions logged
      if (dayTotals.isNotEmpty) {
        final entries = dayTotals.entries.toList();
        entries.sort((a, b) => b.value.compareTo(a.value));
        
        if (entries.isNotEmpty) {
          final day = entries[0].key;
          insights.add('$day shows the most emotional activity, with ${dominantEmotionByDay[day]} being dominant.');
        }
      }
    }
    
    // Potential triggers
    final triggers = patterns['potentialTriggers'];
    if (triggers is List && triggers.isNotEmpty) {
      if (triggers.length == 1) {
        insights.add('Potential trigger word identified: "${triggers[0]}".');
      } else if (triggers.length > 1) {
        insights.add('Potential trigger words include: "${triggers.take(3).join('", "')}".');
      }
    }
    
    return insights;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patterns: ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emotionData.isEmpty
              ? const Center(child: Text('No emotion data available for analysis'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRangeChip(),
                      const SizedBox(height: 16),
                      _buildInsightsSection(),
                      const SizedBox(height: 24),
                      _buildVisualizationsSection(),
                      const SizedBox(height: 24),
                      _buildPatternsSection(),
                      const SizedBox(height: 24),
                      _buildRecommendationsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateRangeChip() {
    return Center(
      child: Chip(
        avatar: const Icon(Icons.calendar_today, size: 16),
        label: Text(
          '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat('MMM d').format(_dateRange.end)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
      ),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _detectedPatterns['insights'] as List<String>? ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: theme_utils.SeeAppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI-Generated Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              const Text('No insights available with current data')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(insight)),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emotional Patterns Visualization',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emotion Heatmap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: EmotionHeatmapChart(
                    title: 'Emotion Patterns by Time of Day',
                    dateRange: DateTimeRange(
                      start: _dateRange.start,
                      end: _dateRange.end,
                    ),
                    emotionData: _emotionData,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Emotion Intensity Over Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: TimeSeriesChart(
                    title: 'Emotion Trends Over Time',
                    emotionData: _emotionData,
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsSection() {
    final frequency = _detectedPatterns['emotionFrequency'] as Map<String, dynamic>? ?? {};
    final timePatterns = _detectedPatterns['timeOfDayPatterns'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected Patterns',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPatternCard(
                'Emotion Frequency',
                Icons.pie_chart,
                frequency.entries.map((e) => '${e.key}: ${e.value}x').toList(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPatternCard(
                'Time of Day Patterns',
                Icons.access_time,
                timePatterns.entries.map((e) {
                  final time = e.key;
                  final emotions = e.value as Map<String, dynamic>;
                  final dominant = emotions.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  
                  return dominant.isNotEmpty 
                      ? '$time: ${dominant.first.key}'
                      : '$time: None';
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTriggerPatternCard(),
      ],
    );
  }

  Widget _buildPatternCard(String title, IconData icon, List<String> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme_utils.SeeAppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No data available')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(item),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerPatternCard() {
    final triggers = _detectedPatterns['potentialTriggers'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Potential Emotional Triggers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Based on analysis of emotion entries and notes:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            if (triggers.isEmpty)
              const Text('No specific triggers identified yet')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: triggers.map((trigger) => Chip(
                  label: Text(trigger.toString()),
                  backgroundColor: Colors.grey.shade200,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    // Generate simple recommendations based on detected patterns
    List<Map<String, dynamic>> recommendations = [];
    
    final frequency = _detectedPatterns['emotionFrequency'] as Map<String, dynamic>? ?? {};
    if (frequency.isNotEmpty) {
      final entries = frequency.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      
      if (entries.isNotEmpty) {
        final dominantEmotion = entries[0].key;
        
        if (dominantEmotion == 'anger' || dominantEmotion == 'fear') {
          recommendations.add({
            'title': 'Consider Calming Techniques',
            'description': 'The frequency of ${dominantEmotion.toLowerCase()} suggests focusing on calming and grounding techniques.',
            'icon': Icons.self_improvement,
          });
        } else if (dominantEmotion == 'sadness') {
          recommendations.add({
            'title': 'Mood Elevation Focus',
            'description': 'Consider activities and missions that promote positive engagement and joy.',
            'icon': Icons.wb_sunny,
          });
        }
      }
    }
    
    // Add general recommendations
    recommendations.add({
      'title': 'Custom Mission Opportunity',
      'description': 'Create a personalized mission targeting the patterns observed in this analysis.',
      'icon': Icons.assignment,
    });
    
    recommendations.add({
      'title': 'Discuss Triggers',
      'description': 'Consider discussing identified potential triggers in your next session.',
      'icon': Icons.psychology,
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Therapist Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(rec['icon'], color: theme_utils.SeeAppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(rec['description']),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.assignment_add),
            label: const Text('Create Custom Mission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // Navigate to mission creator with context from this analysis
            },
          ),
        ),
      ],
    );
  }
}
