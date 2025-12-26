import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// A chart for comparing emotion data across different patients or time periods
class ComparativeAnalysisChart extends StatefulWidget {
  /// List of datasets to compare (e.g., different patients or time periods)
  final List<ComparativeDataset> datasets;
  
  /// Emotions to display in the chart
  final List<EmotionType>? emotions;
  
  /// Title of the chart
  final String title;
  
  /// Subtitle explaining the comparison
  final String? subtitle;

  const ComparativeAnalysisChart({
    super.key,
    required this.datasets,
    this.emotions,
    this.title = 'Comparative Analysis',
    this.subtitle,
  });

  @override
  State<ComparativeAnalysisChart> createState() => _ComparativeAnalysisChartState();
}

class _ComparativeAnalysisChartState extends State<ComparativeAnalysisChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  
  // Selected dataset for detailed view
  int _selectedDatasetIndex = -1;
  
  // Filter settings
  List<EmotionType> _visibleEmotions = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    
    // Initialize visible emotions
    _initializeVisibleEmotions();
  }
  
  void _initializeVisibleEmotions() {
    if (widget.emotions != null && widget.emotions!.isNotEmpty) {
      _visibleEmotions = List.from(widget.emotions!);
    } else {
      // Get all unique emotions from all datasets
      final allEmotions = <EmotionType>{};
      for (final dataset in widget.datasets) {
        for (final data in dataset.data) {
          allEmotions.add(data.type);
        }
      }
      
      if (allEmotions.isEmpty) {
        // Default emotions if no data
        _visibleEmotions = [
          EmotionType.joy,
          EmotionType.sadness,
          EmotionType.anger,
          EmotionType.fear,
          EmotionType.calm,
        ];
      } else {
        _visibleEmotions = allEmotions.toList();
      }
    }
  }

  @override
  void didUpdateWidget(ComparativeAnalysisChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.datasets != oldWidget.datasets) {
      _animationController.reset();
      _animationController.forward();
      _initializeVisibleEmotions();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datasets.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildEmotionFilter(),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? 400 : 250,
                  child: _buildChart(),
                ),
                if (_selectedDatasetIndex >= 0) ...[
                  const SizedBox(height: 16),
                  _buildDatasetDetails(_selectedDatasetIndex),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
            color: theme_utils.SeeAppTheme.primaryColor,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          tooltip: _isExpanded ? 'Compact View' : 'Expanded View',
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEmotionFilter() {
    return Wrap(
      spacing: 6,
      children: EmotionType.values.map((emotion) {
        final isSelected = _visibleEmotions.contains(emotion);
        return FilterChip(
          label: Text(
            EmotionData.getEmotionName(emotion),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _visibleEmotions.add(emotion);
              } else {
                // Always keep at least one emotion visible
                if (_visibleEmotions.length > 1) {
                  _visibleEmotions.remove(emotion);
                }
              }
            });
          },
          backgroundColor: Colors.grey.shade200,
          selectedColor: _getEmotionColor(emotion),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    // Process data for each dataset
    final processedData = <String, Map<EmotionType, double>>{};
    
    for (final dataset in widget.datasets) {
      final averages = <EmotionType, double>{};
      final counts = <EmotionType, int>{};
      
      // Calculate average intensity for each emotion type
      for (final data in dataset.data) {
        if (!_visibleEmotions.contains(data.type)) continue;
        
        if (!averages.containsKey(data.type)) {
          averages[data.type] = 0;
          counts[data.type] = 0;
        }
        
        averages[data.type] = averages[data.type]! + data.intensity;
        counts[data.type] = counts[data.type]! + 1;
      }
      
      // Calculate final averages
      for (final type in averages.keys) {
        if (counts[type]! > 0) {
          averages[type] = (averages[type]! / counts[type]!) * 100;
        }
      }
      
      processedData[dataset.label] = averages;
    }
    
    // If no visible emotions have data, show empty state
    if (processedData.values.every((emotionMap) => 
      emotionMap.keys.every((type) => !_visibleEmotions.contains(type)))) {
      return _buildEmptyState();
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response == null || response.spot == null) {
              setState(() => _selectedDatasetIndex = -1);
              return;
            }
            if (event is FlTapUpEvent) {
              setState(() => _selectedDatasetIndex = response.spot!.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dataset = widget.datasets[groupIndex];
              final emotion = _visibleEmotions[rodIndex];
              return BarTooltipItem(
                '${dataset.label}\n${EmotionData.getEmotionName(emotion)}: ${rod.toY.toInt()}%',
                TextStyle(
                  color: _getEmotionColor(emotion),
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.datasets.length) {
                  return Text(
                    widget.datasets[index].label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        barGroups: List.generate(widget.datasets.length, (datasetIndex) {
          final dataset = widget.datasets[datasetIndex];
          final averages = processedData[dataset.label] ?? {};
          
          return BarChartGroupData(
            x: datasetIndex,
            barRods: List.generate(_visibleEmotions.length, (emotionIndex) {
              final emotion = _visibleEmotions[emotionIndex];
              final value = averages[emotion] ?? 0.0;
              
              return BarChartRodData(
                toY: value,
                color: _getEmotionColor(emotion),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDatasetDetails(int index) {
    if (index < 0 || index >= widget.datasets.length) {
      return const SizedBox.shrink();
    }
    
    final dataset = widget.datasets[index];
    
    // Calculate statistics for visible emotions
    final stats = <EmotionType, Map<String, dynamic>>{};
    
    for (final emotion in _visibleEmotions) {
      final emotionData = dataset.data.where((d) => d.type == emotion).toList();
      
      if (emotionData.isEmpty) continue;
      
      // Calculate mean
      final sum = emotionData.fold<double>(
        0, (sum, data) => sum + data.intensity
      );
      final mean = sum / emotionData.length;
      
      // Calculate min and max
      final min = emotionData.map((d) => d.intensity).reduce(
        (a, b) => a < b ? a : b
      );
      final max = emotionData.map((d) => d.intensity).reduce(
        (a, b) => a > b ? a : b
      );
      
      // Store statistics
      stats[emotion] = {
        'mean': mean,
        'min': min,
        'max': max,
        'count': emotionData.length,
      };
    }
    
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 16,
                  color: theme_utils.SeeAppTheme.secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Details for ${dataset.label}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme_utils.SeeAppTheme.secondaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedDatasetIndex = -1;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.isEmpty) ...[
              const Text('No data available for selected emotions'),
            ] else ...[
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: stats.entries.map((entry) {
                  final emotion = entry.key;
                  final data = entry.value;
                  
                  return SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getEmotionColor(emotion),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              EmotionData.getEmotionName(emotion),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow('Mean', '${(data['mean'] * 100).toStringAsFixed(1)}%'),
                        _buildStatRow('Min', '${(data['min'] * 100).toStringAsFixed(1)}%'),
                        _buildStatRow('Max', '${(data['max'] * 100).toStringAsFixed(1)}%'),
                        _buildStatRow('Records', '${data['count']}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for comparison',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return Colors.yellow[700]!;
      case EmotionType.sadness:
        return Colors.blue;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.calm:
        return Colors.green;
      case EmotionType.disgust:
        return Colors.brown;
      case EmotionType.surprise:
        return Colors.orange;
      case EmotionType.neutral:
        return Colors.grey;
    }
  }
}

/// Represents a single dataset for comparative analysis
class ComparativeDataset {
  /// Label for the dataset (e.g., patient name or time period description)
  final String label;
  
  /// The emotion data for this dataset
  final List<EmotionData> data;
  
  /// Optional time range for the dataset
  final DateTimeRange? timeRange;
  
  /// Optional child/patient ID
  final String? childId;

  const ComparativeDataset({
    required this.label,
    required this.data,
    this.timeRange,
    this.childId,
  });
}