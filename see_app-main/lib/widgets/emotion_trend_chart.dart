import 'package:flutter/material.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart';
import 'package:intl/intl.dart';

class EmotionTrendChart extends StatefulWidget {
  final List<EmotionData> emotionData;
  final int daysToShow;
  final Function(EmotionData)? onEmotionSelected;
  
  const EmotionTrendChart({
    super.key,
    required this.emotionData,
    this.daysToShow = 7,
    this.onEmotionSelected,
  });

  @override
  State<EmotionTrendChart> createState() => _EmotionTrendChartState();
}

class _EmotionTrendChartState extends State<EmotionTrendChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _barHeightAnimation;
  int _hoveredDayIndex = -1;
  int _hoveredBarIndex = -1;
  bool _isChartExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _barHeightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(EmotionTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate again if data changed
    if (widget.emotionData != oldWidget.emotionData) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emotionData.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Group data by day for visualization
    final groupedData = _groupDataByDay();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emotion Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Toggle view button
                    IconButton(
                      icon: Icon(
                        _isChartExpanded ? Icons.compress : Icons.expand,
                        color: SeeAppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isChartExpanded = !_isChartExpanded;
                        });
                      },
                      tooltip: _isChartExpanded ? 'Compact View' : 'Expanded View',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Date range selector (simplified)
                    _buildDateRangeSelector(context),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chart container with adaptive height
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isChartExpanded 
                ? constraints.maxHeight - 90 // Expanded view
                : min(constraints.maxHeight - 90, 220), // Compact view
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: _buildChartContent(context, groupedData, constraints),
            ),
            const SizedBox(height: 16),
            // Legend with horizontal scrolling for small screens
            SizedBox(
              height: 32,
              child: _buildLegend(context),
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 270), // Reduced height to avoid overflow
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Smoother scrolling
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4), // Extra padding to avoid edge boundaries
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_outlined, 
                    size: 56, // Slightly smaller icon
                    color: Colors.grey.shade400
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emotion data available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking emotions to see trends over time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to record emotion screen
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Record Emotion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SeeAppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: 12
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateRangeSelector(BuildContext context) {
    return DropdownButton<int>(
      value: widget.daysToShow,
      underline: const SizedBox.shrink(),
      icon: Icon(Icons.arrow_drop_down, color: SeeAppTheme.primaryColor),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: SeeAppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
      onChanged: (value) {
        // This would be handled by a parent widget in a real implementation
        // setState(() {
        //   daysToShow = value ?? 7;
        // });
      },
      items: [
        DropdownMenuItem(
          value: 7,
          child: Text('Last Week'),
        ),
        DropdownMenuItem(
          value: 14,
          child: Text('Last 2 Weeks'),
        ),
        DropdownMenuItem(
          value: 30,
          child: Text('Last Month'),
        ),
      ],
    );
  }
  
  Widget _buildChartContent(BuildContext context, Map<DateTime, List<EmotionData>> groupedData, BoxConstraints constraints) {
    // Sort dates in ascending order
    final dates = groupedData.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Take only the latest days based on daysToShow
    final displayDates = dates.length <= widget.daysToShow
        ? dates
        : dates.sublist(dates.length - widget.daysToShow);
    
    if (displayDates.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('100%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            Text('75%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            Text('50%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            Text('25%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            Text('0%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(width: 8),
        // Chart bars with tooltip overlay
        Expanded(
          child: Column(
            children: [
              // Chart grid and bars
              Expanded(
                child: Stack(
                  children: [
                    // Grid lines
                    _buildGridLines(context),
                    // Bars (animated)
                    AnimatedBuilder(
                      animation: _barHeightAnimation,
                      builder: (context, child) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(displayDates.length, (dayIndex) {
                            final date = displayDates[dayIndex];
                            return _buildDayColumn(
                              context, 
                              date, 
                              groupedData[date] ?? [], 
                              dayIndex
                            );
                          }),
                        );
                      }
                    ),
                    // Tooltip overlay (if a bar is hovered)
                    if (_hoveredDayIndex >= 0 && _hoveredBarIndex >= 0)
                      _buildTooltip(context, displayDates, groupedData),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // X-axis labels
              SizedBox(
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: displayDates.map((date) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final isToday = date.isAtSameMomentAs(today);
                    
                    final formatter = DateFormat('E, MMM d');
                    final label = isToday ? 'Today' : formatter.format(date);
                    
                    return Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? SeeAppTheme.primaryColor : Colors.grey.shade700,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGridLines(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: index < 4 
                    ? BorderSide(color: Colors.grey.shade200, width: 1)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayColumn(BuildContext context, DateTime date, List<EmotionData> dayData, int dayIndex) {
    // Calculate average intensity for each emotion type
    final Map<EmotionType, double> averageIntensities = _calculateDayIntensities(dayData);
    
    // Sort emotion types to ensure consistent order
    final emotionTypes = averageIntensities.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(emotionTypes.length, (barIndex) {
            final type = emotionTypes[barIndex];
            final intensity = averageIntensities[type] ?? 0;
            return _buildEmotionBar(context, type, intensity, dayIndex, barIndex);
          }),
        ),
      ),
    );
  }
  
  Widget _buildEmotionBar(BuildContext context, EmotionType type, double intensity, int dayIndex, int barIndex) {
    // Get color based on emotion type
    final color = _getEmotionColor(type);
    
    // Scale height based on animation progress
    final animatedHeight = intensity * 100 * 2 * _barHeightAnimation.value;
    
    // Determine if this bar is hovered
    final isHovered = _hoveredDayIndex == dayIndex && _hoveredBarIndex == barIndex;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredDayIndex = dayIndex;
          _hoveredBarIndex = barIndex;
        });
      },
      onExit: (_) {
        setState(() {
          if (_hoveredDayIndex == dayIndex && _hoveredBarIndex == barIndex) {
            _hoveredDayIndex = -1;
            _hoveredBarIndex = -1;
          }
        });
      },
      child: GestureDetector(
        onTap: () {
          // Provide feedback or details when bar is tapped
          if (widget.onEmotionSelected != null && dayIndex < widget.emotionData.length) {
            widget.onEmotionSelected!(widget.emotionData[dayIndex]);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: max(animatedHeight, 2), // Ensure small values are visible
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(isHovered ? 6 : 4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isHovered ? 0.4 : 0.2),
                blurRadius: isHovered ? 4 : 2,
                spreadRadius: isHovered ? 1 : 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          margin: const EdgeInsets.only(top: 1),
          width: double.infinity,
        ),
      ),
    );
  }
  
  Widget _buildTooltip(BuildContext context, List<DateTime> dates, Map<DateTime, List<EmotionData>> groupedData) {
    if (_hoveredDayIndex < 0 || _hoveredDayIndex >= dates.length) {
      return const SizedBox.shrink();
    }
    
    final date = dates[_hoveredDayIndex];
    final dayData = groupedData[date] ?? [];
    
    if (dayData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Calculate averages for display
    final averages = _calculateDayIntensities(dayData);
    final emotionTypes = averages.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    
    // Get the hovered emotion type
    EmotionType? hoveredType;
    if (_hoveredBarIndex >= 0 && _hoveredBarIndex < emotionTypes.length) {
      hoveredType = emotionTypes[_hoveredBarIndex];
    }
    
    if (hoveredType == null) return const SizedBox.shrink();
    
    final color = _getEmotionColor(hoveredType);
    final intensity = (averages[hoveredType] ?? 0) * 100;
    final emotionName = EmotionData.getEmotionName(hoveredType);
    final dateFormatted = DateFormat('MMM d, yyyy').format(date);
    
    // Position tooltip near the hovered bar
    return Positioned(
      left: (_hoveredDayIndex / dates.length) * 100 * 2,
      bottom: 120, // Adjust as needed
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateFormatted,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  emotionName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Intensity: ${intensity.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Records: ${dayData.where((e) => e.type == hoveredType).length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegend(BuildContext context) {
    // Maps all emotion types to their display names and colors
    final emotions = [
      (type: EmotionType.joy, label: 'Joy', color: SeeAppTheme.joyColor),
      (type: EmotionType.sadness, label: 'Sadness', color: SeeAppTheme.sadnessColor),
      (type: EmotionType.anger, label: 'Anger', color: SeeAppTheme.angerColor),
      (type: EmotionType.fear, label: 'Fear', color: SeeAppTheme.fearColor),
      (type: EmotionType.calm, label: 'Calm', color: SeeAppTheme.calmColor),
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emotions.map((emotion) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Filter by this emotion type (future feature)
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: emotion.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: emotion.color.withOpacity(0.3),
                              blurRadius: 2,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emotion.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Map<DateTime, List<EmotionData>> _groupDataByDay() {
    final Map<DateTime, List<EmotionData>> grouped = {};
    
    for (final data in widget.emotionData) {
      final day = DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
      
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      
      grouped[day]!.add(data);
    }
    
    return grouped;
  }
  
  Map<EmotionType, double> _calculateDayIntensities(List<EmotionData> dayData) {
    // Group emotions by type
    final Map<EmotionType, List<double>> emotionIntensities = {};
    
    for (final emotion in dayData) {
      if (!emotionIntensities.containsKey(emotion.type)) {
        emotionIntensities[emotion.type] = [];
      }
      emotionIntensities[emotion.type]!.add(emotion.intensity);
    }
    
    // Calculate average intensity for each emotion type
    final Map<EmotionType, double> averageIntensities = {};
    
    emotionIntensities.forEach((type, intensities) {
      if (intensities.isNotEmpty) {
        final sum = intensities.reduce((a, b) => a + b);
        averageIntensities[type] = sum / intensities.length;
      }
    });
    
    return averageIntensities;
  }
  
  Color _getEmotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return SeeAppTheme.joyColor;
      case EmotionType.sadness:
        return SeeAppTheme.sadnessColor;
      case EmotionType.anger:
        return SeeAppTheme.angerColor;
      case EmotionType.fear:
        return SeeAppTheme.fearColor;
      case EmotionType.calm:
        return SeeAppTheme.calmColor;
      default:
        return Colors.grey;
    }
  }
}

// Helper function for min/max since dart:math isn't automatically imported
double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;