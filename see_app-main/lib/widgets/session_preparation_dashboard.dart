import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/difficulty_level.dart';
import 'package:see_app/models/community_post.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/emotion_trend_chart.dart';

class SessionPreparationDashboard extends StatefulWidget {
  final Child patient;
  final DatabaseService databaseService;
  final DateTime sessionDate;
  final VoidCallback? onClose;

  const SessionPreparationDashboard({
    Key? key,
    required this.patient,
    required this.databaseService,
    required this.sessionDate,
    this.onClose,
  }) : super(key: key);

  @override
  State<SessionPreparationDashboard> createState() => _SessionPreparationDashboardState();
}

class _SessionPreparationDashboardState extends State<SessionPreparationDashboard> {
  bool _isLoading = true;
  List<EmotionData> _recentEmotions = [];
  List<Mission> _recentMissions = [];
  List<CommunityPost> _recentPosts = [];
  Map<String, dynamic> _patientStats = {};
  String _aiInsight = '';

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() => _isLoading = true);
      
      // Define the date range for recent data (last 7 days)
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 7));
      
      // Load all data concurrently for efficiency
      final results = await Future.wait([
        widget.databaseService.getEmotionsForDateRange(widget.patient.id, startDate, endDate),
        widget.databaseService.getMissionsByChild(widget.patient.id, limit: 5),
        widget.databaseService.getCommunityPostsByUser(widget.patient.id, limit: 5),
        widget.databaseService.getPatientStats(widget.patient.id),
        _generateAIInsight(widget.patient.id),
      ]);
      
      if (mounted) {
        setState(() {
          _recentEmotions = results[0] as List<EmotionData>;
          _recentMissions = results[1] as List<Mission>;
          _recentPosts = results[2] as List<CommunityPost>;
          _patientStats = results[3] as Map<String, dynamic>;
          _aiInsight = results[4] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patient data: $e'))
        );
      }
    }
  }

  Future<String> _generateAIInsight(String patientId) async {
    try {
      // This would integrate with your AI service to generate insights
      // For now we'll return a placeholder
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate API call
      return 'Based on recent emotion patterns, ${widget.patient.name} shows improved emotional regulation after calming exercises. Consider exploring more mindfulness techniques.';
    } catch (e) {
      return 'Unable to generate AI insight at this time.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Prep: ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionHeader(),
                  const SizedBox(height: 24),
                  
                  _buildEmotionalOverview(),
                  const SizedBox(height: 24),
                  
                  _buildMissionsSection(),
                  const SizedBox(height: 24),
                  
                  _buildActivitySection(),
                  const SizedBox(height: 24),
                  
                  _buildAIInsightsCard(),
                  const SizedBox(height: 24),
                  
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionHeader() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.sessionDate);
    final formattedTime = DateFormat('h:mm a').format(widget.sessionDate);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.patient.avatar != null
                      ? NetworkImage(widget.patient.avatar!)
                      : null,
                  child: widget.patient.avatar == null
                      ? Text(widget.patient.name[0],
                          style: const TextStyle(fontSize: 24))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.patient.age} years old · ${widget.patient.gender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Session',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme_utils.SeeAppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emotional Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_recentEmotions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No recent emotion data available'),
              ),
            ),
          )
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Emotion Trends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: EmotionTrendChart(
                      emotionData: _recentEmotions,
                      
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildEmotionStats(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmotionStats() {
    // Get the most common emotion
    final Map<EmotionType, int> emotionCounts = {};
    for (final emotion in _recentEmotions) {
      emotionCounts[emotion.type] = (emotionCounts[emotion.type] ?? 0) + 1;
    }
    
    EmotionType? mostCommonEmotion;
    int maxCount = 0;
    emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonEmotion = emotion;
      }
    });
    
    // Calculate average intensity
    double avgIntensity = 0;
    if (_recentEmotions.isNotEmpty) {
      avgIntensity = _recentEmotions.map((e) => e.intensity).reduce((a, b) => a + b) / _recentEmotions.length;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          'Most Common',
          mostCommonEmotion?.name ?? 'N/A',
          icon: Icons.trending_up,
        ),
        _buildStatCard(
          'Avg. Intensity',
          avgIntensity.toStringAsFixed(1),
          icon: Icons.speed,
          iconColor: _getIntensityColor(avgIntensity),
        ),
        _buildStatCard(
          'Entries',
          _recentEmotions.length.toString(),
          icon: Icons.note_alt,
        ),
      ],
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity < 3) return Colors.green;
    if (intensity < 6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(String label, String value, {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon,
            color: iconColor ?? theme_utils.SeeAppTheme.primaryColor,
            size: 24,
          ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Missions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_recentMissions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No recent missions available'),
              ),
            ),
          )
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: _recentMissions.map((mission) {
                  final bool completed = mission.completedDate != null;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: completed
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        completed ? Icons.check_circle : Icons.access_time,
                        color: completed ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(
                      mission.title,
                      style: TextStyle(
                        decoration: completed ? TextDecoration.lineThrough : null,
                        fontWeight: completed ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      completed
                          ? 'Completed on ${DateFormat('MMM d').format(mission.completedDate!)}'
                          : 'Due ${DateFormat('MMM d').format(mission.dueDate)}',
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    onTap: () {
                      // Navigate to mission details
                    },
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_recentPosts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No recent community activity'),
              ),
            ),
          )
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: _recentPosts.map((post) {
                  return ListTile(
                    title: Text(
                      post.title ?? 'Community Post',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      post.content.length > 50
                          ? '${post.content.substring(0, 50)}...'
                          : post.content,
                    ),
                    trailing: Text(
                      DateFormat('MMM d').format(post.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAIInsightsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Suggested Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
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
                      'Session Focus Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiInsight,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate Insight'),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final newInsight = await _generateAIInsight(widget.patient.id);
                      setState(() {
                        _aiInsight = newInsight;
                        _isLoading = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.assignment,
          label: 'Create Mission',
          onTap: () {
            // Navigate to or show dialog for creating a mission
          },
        ),
        _buildActionButton(
          icon: Icons.bookmark,
          label: 'Add Session Note',
          onTap: () {
            // Navigate to or show dialog for adding notes
          },
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Send Message',
          onTap: () {
            // Navigate to or show dialog for sending message
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                icon,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
