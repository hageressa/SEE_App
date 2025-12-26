import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

enum TimeRange {
  day,
  week,
  month,
  year,
}

class TimeSeriesChart extends StatefulWidget {
  final List<EmotionData> emotionData;
  final TimeRange timeRange;
  final List<EmotionType>? filterEmotions;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;

  const TimeSeriesChart({
    super.key,
    required this.emotionData,
    this.timeRange = TimeRange.week,
    this.filterEmotions,
    this.title = 'Emotion Trends',
    this.startDate,
    this.endDate,
  });

  @override
  State<TimeSeriesChart> createState() => _TimeSeriesChartState();
}

class _TimeSeriesChartState extends State<TimeSeriesChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  TimeRange _currentTimeRange = TimeRange.week;
  
  // Tooltip state
  bool _showTooltip = false;
  double? _tooltipX;
  double? _tooltipY;
  List<EmotionData>? _tooltipData;
  
  // Track counts for calculating averages
  final Map<DateTime, Map<EmotionType, double>> _countMap = {};

  @override
  void initState() {
    super.initState();
    _currentTimeRange = widget.timeRange;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(TimeSeriesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotionData != oldWidget.emotionData ||
        widget.timeRange != oldWidget.timeRange) {
      _currentTimeRange = widget.timeRange;
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emotionData.isEmpty) {
      return _buildEmptyState();
    }

    final groupedData = _processData();

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
                const SizedBox(height: 8),
                _buildTimeRangeSelector(),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? 350 : 220,
                  child: _buildChart(groupedData),
                ),
                const SizedBox(height: 8),
                _buildLegend(),
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
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
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
            const SizedBox(width: 16),
            _buildDateRangeDisplay(),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeDisplay() {
    final endDate = widget.endDate ?? DateTime.now();
    final formatter = DateFormat('MMM d, yyyy');
    String rangeText;

    switch (_currentTimeRange) {
      case TimeRange.day:
        rangeText = formatter.format(endDate);
        break;
      case TimeRange.week:
        final startDate = endDate.subtract(const Duration(days: 7));
        rangeText = '${formatter.format(startDate)} - ${formatter.format(endDate)}';
        break;
      case TimeRange.month:
        final startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        rangeText = '${formatter.format(startDate)} - ${formatter.format(endDate)}';
        break;
      case TimeRange.year:
        final startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        rangeText = '${formatter.format(startDate)} - ${formatter.format(endDate)}';
        break;
    }

    return Text(
      rangeText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _buildRangeButton(TimeRange.day, 'Day'),
          _buildRangeButton(TimeRange.week, 'Week'),
          _buildRangeButton(TimeRange.month, 'Month'),
          _buildRangeButton(TimeRange.year, 'Year'),
        ],
      ),
    );
  }

  Widget _buildRangeButton(TimeRange range, String label) {
    final isSelected = _currentTimeRange == range;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentTimeRange = range;
            _tooltipData = null;
            _showTooltip = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? theme_utils.SeeAppTheme.primaryColor
              : Colors.grey.shade200,
          foregroundColor:
              isSelected ? Colors.white : theme_utils.SeeAppTheme.primaryColor,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildChart(Map<DateTime, Map<EmotionType, double>> groupedData) {
    if (groupedData.isEmpty) {
      return _buildEmptyState();
    }

    // Sort time points chronologically
    final timePoints = groupedData.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Create line data for each emotion type
    final lines = <EmotionType, List<FlSpot>>{};
    final emotionTypes = _getEmotionTypes();

    for (final type in emotionTypes) {
      final spots = <FlSpot>[];
      for (int i = 0; i < timePoints.length; i++) {
        final date = timePoints[i];
        final intensity = groupedData[date]?[type] ?? 0.0;
        spots.add(FlSpot(i.toDouble(), intensity));
      }
      if (spots.isNotEmpty) {
        lines[type] = spots;
      }
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final emotionType = emotionTypes[spot.x.toInt()];
                return LineTooltipItem(
                  '${EmotionData.getEmotionName(emotionType)}: ${spot.y.toInt()}%',
                  TextStyle(
                    color: _getEmotionColor(emotionType),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < timePoints.length) {
                  final date = timePoints[index];
                  return Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        minX: 0,
        maxX: (timePoints.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: lines.entries.map((entry) {
          final type = entry.key;
          final spots = entry.value;
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getEmotionColor(type),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _getEmotionColor(type).withOpacity(0.1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No emotion data available for this period.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final emotionTypes = _getEmotionTypes();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: emotionTypes.map((type) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _getEmotionColor(type),
            ),
            const SizedBox(width: 4),
            Text(
              EmotionData.getEmotionName(type),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
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

  List<EmotionType> _getEmotionTypes() {
    if (widget.filterEmotions != null && widget.filterEmotions!.isNotEmpty) {
      return widget.filterEmotions!;
    }
    return EmotionType.values
        .where((type) => type != EmotionType.neutral)
        .toList();
  }

  double _getVerticalInterval(int dataLength) {
    if (_isExpanded) {
      if (dataLength <= 10) return 2;
      return 5;
    }
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    return 5;
  }
  
  String _formatTimePoint(DateTime date) {
    switch (_currentTimeRange) {
      case TimeRange.day:
        return DateFormat('ha').format(date); // Hour, AM/PM
      case TimeRange.week:
        return DateFormat.E().format(date); // Day of week (e.g., 'Mon')
      case TimeRange.month:
        return date.day.toString(); // Day of month
      case TimeRange.year:
        return DateFormat.MMM().format(date); // Month abbreviation (e.g., 'Jan')
    }
  }

  List<EmotionData> _findEmotionDataForDate(DateTime date) {
    return widget.emotionData
        .where((e) => _isSameTimePoint(e.timestamp, date))
        .toList();
  }
  
  bool _isSameTimePoint(DateTime d1, DateTime d2) {
    switch (_currentTimeRange) {
      case TimeRange.day:
        return d1.year == d2.year &&
            d1.month == d2.month &&
            d1.day == d2.day &&
            d1.hour == d2.hour;
      case TimeRange.week:
      case TimeRange.month:
        return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
      case TimeRange.year:
        return d1.year == d2.year && d1.month == d2.month;
    }
  }

  Map<DateTime, Map<EmotionType, double>> _processData() {
    final Map<DateTime, Map<EmotionType, double>> sumMap = {};
    final Map<DateTime, Map<EmotionType, int>> countMap = {};

    for (final data in widget.emotionData) {
      final key = _normalizeDate(data.timestamp);
      
      // Initialize maps if needed
      sumMap.putIfAbsent(key, () => {});
      countMap.putIfAbsent(key, () => {});
      
      // Update sums and counts
      sumMap[key]!.update(
        data.type,
        (value) => value + (data.intensity * 100),
        ifAbsent: () => data.intensity * 100,
      );
      
      countMap[key]!.update(
        data.type,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Calculate averages
    final Map<DateTime, Map<EmotionType, double>> result = {};
    for (final entry in sumMap.entries) {
      final date = entry.key;
      final sums = entry.value;
      final counts = countMap[date]!;
      
      result[date] = {};
      for (final type in sums.keys) {
        result[date]![type] = sums[type]! / counts[type]!;
      }
    }

    return result;
  }

  DateTime _normalizeDate(DateTime date) {
    switch (_currentTimeRange) {
      case TimeRange.day:
        return DateTime(date.year, date.month, date.day);
      case TimeRange.week:
        return DateTime(date.year, date.month, date.day - date.weekday + 1);
      case TimeRange.month:
        return DateTime(date.year, date.month, 1);
      case TimeRange.year:
        return DateTime(date.year, 1, 1);
    }
  }

  String _formatDate(DateTime date) {
    switch (_currentTimeRange) {
      case TimeRange.day:
        return DateFormat('ha').format(date);
      case TimeRange.week:
        return DateFormat.E().format(date);
      case TimeRange.month:
        return DateFormat.MMM().format(date);
      case TimeRange.year:
        return DateFormat.y().format(date);
    }
  }
}