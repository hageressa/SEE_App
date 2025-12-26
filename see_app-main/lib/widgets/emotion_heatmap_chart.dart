import 'package:flutter/material.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:intl/intl.dart';

/// A heatmap visualization showing emotional intensity patterns by time of day
class EmotionHeatmapChart extends StatefulWidget {
  /// Emotion data to visualize
  final List<EmotionData> emotionData;
  
  /// Optional specific emotion type to filter for
  final EmotionType? emotionType;
  
  /// Title of the chart
  final String title;
  
  /// Date range to visualize
  final DateTimeRange? dateRange;
  
  /// Number of rows in the heatmap (hours)
  final int hourRows;
  
  /// Number of columns in the heatmap (days)
  final int dayColumns;

  const EmotionHeatmapChart({
    super.key,
    required this.emotionData,
    this.emotionType,
    this.title = 'Emotion Intensity by Time of Day',
    this.dateRange,
    this.hourRows = 24,
    this.dayColumns = 7,
  });

  @override
  State<EmotionHeatmapChart> createState() => _EmotionHeatmapChartState();
}

class _EmotionHeatmapChartState extends State<EmotionHeatmapChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  
  // Filter settings
  EmotionType? _selectedEmotionType;
  
  // Heatmap cell information
  List<HeatmapCell> _cells = [];
  int _maxCount = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    _selectedEmotionType = widget.emotionType;
    _processData();
  }
  
  @override
  void didUpdateWidget(EmotionHeatmapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotionData != oldWidget.emotionData ||
        widget.emotionType != oldWidget.emotionType ||
        widget.dateRange != oldWidget.dateRange) {
      _selectedEmotionType = widget.emotionType;
      _processData();
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _processData() {
    // Get date range or use default (last 7 days)
    final now = DateTime.now();
    final endDate = widget.dateRange?.end ?? now;
    final startDate = widget.dateRange?.start ?? 
                      now.subtract(Duration(days: widget.dayColumns - 1));
    
    // Initialize cells with zeros
    final cells = <HeatmapCell>[];
    int maxCount = 0;
    double maxIntensity = 0.0;
    
    // Create grid of day/hour cells
    for (int dayIndex = 0; dayIndex < widget.dayColumns; dayIndex++) {
      final date = startDate.add(Duration(days: dayIndex));
      
      for (int hour = 0; hour < widget.hourRows; hour++) {
        final cell = HeatmapCell(
          dayIndex: dayIndex,
          hour: hour,
          date: DateTime(date.year, date.month, date.day, hour),
          count: 0,
          totalIntensity: 0.0,
          averageIntensity: 0.0,
          emotions: {},
        );
        cells.add(cell);
      }
    }
    
    // Filter data by date range and emotion type
    final filteredData = widget.emotionData.where((data) {
      // Check date range
      if (data.timestamp.isBefore(startDate) || 
          data.timestamp.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      
      // Check emotion type if selected
      if (_selectedEmotionType != null && data.type != _selectedEmotionType) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Aggregate data into cells
    for (final data in filteredData) {
      final daysDiff = data.timestamp.difference(startDate).inDays;
      if (daysDiff < 0 || daysDiff >= widget.dayColumns) continue;
      
      final hour = data.timestamp.hour;
      final cellIndex = daysDiff * widget.hourRows + hour;
      
      if (cellIndex >= 0 && cellIndex < cells.length) {
        final cell = cells[cellIndex];
        cell.count++;
        cell.totalIntensity += data.intensity;
        
        // Update emotion-specific data
        if (!cell.emotions.containsKey(data.type)) {
          cell.emotions[data.type] = EmotionStat(
            count: 0,
            totalIntensity: 0.0,
          );
        }
        cell.emotions[data.type]!.count++;
        cell.emotions[data.type]!.totalIntensity += data.intensity;
        
        // Update max values
        maxCount = maxCount < cell.count ? cell.count : maxCount;
        maxIntensity = maxIntensity < data.intensity ? data.intensity : maxIntensity;
      }
    }
    
    // Calculate averages
    for (final cell in cells) {
      if (cell.count > 0) {
        cell.averageIntensity = cell.totalIntensity / cell.count;
      }
      
      // Calculate emotion-specific averages
      for (final entry in cell.emotions.entries) {
        if (entry.value.count > 0) {
          entry.value.averageIntensity = entry.value.totalIntensity / entry.value.count;
        }
      }
    }
    
    setState(() {
      _cells = cells;
      _maxCount = maxCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emotionData.isEmpty) {
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
                const SizedBox(height: 16),
                _buildEmotionFilter(),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? 450 : 300,
                  child: _buildHeatmap(),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildEmotionFilterChip(null, 'All Emotions'),
          ...EmotionType.values.map((type) => 
            _buildEmotionFilterChip(type, EmotionData.getEmotionName(type))
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmotionFilterChip(EmotionType? type, String label) {
    final isSelected = _selectedEmotionType == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: type == null 
          ? theme_utils.SeeAppTheme.primaryColor 
          : _getEmotionColor(type),
        backgroundColor: Colors.grey.shade200,
        onSelected: (selected) {
          setState(() {
            _selectedEmotionType = selected ? type : null;
            _processData();
          });
        },
      ),
    );
  }

  Widget _buildHeatmap() {
    // Get date range
    final now = DateTime.now();
    final endDate = widget.dateRange?.end ?? now;
    final startDate = widget.dateRange?.start ?? 
                      now.subtract(Duration(days: widget.dayColumns - 1));
    
    // Layout sizes
    final double cellHeight = 10;
    final double cellWidth = 10;
    const double rowLabelWidth = 40;
    const double columnLabelHeight = 40;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - rowLabelWidth;
        final availableHeight = constraints.maxHeight - columnLabelHeight;
        
        final effectiveCellWidth = availableWidth / widget.dayColumns;
        final effectiveCellHeight = availableHeight / widget.hourRows;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels (columns)
            SizedBox(
              height: columnLabelHeight,
              child: Row(
                children: [
                  SizedBox(width: rowLabelWidth),
                  ...List.generate(widget.dayColumns, (dayIndex) {
                    final date = startDate.add(Duration(days: dayIndex));
                    return SizedBox(
                      width: effectiveCellWidth,
                      child: Column(
                        children: [
                          Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            DateFormat('M/d').format(date),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // Heatmap with hour labels
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels (rows)
                  SizedBox(
                    width: rowLabelWidth,
                    child: Column(
                      children: List.generate(widget.hourRows, (hour) {
                        // Show labels every 3 hours
                        if (hour % 3 != 0 && hour != 0) {
                          return SizedBox(height: effectiveCellHeight);
                        }
                        
                        final hourLabel = _formatHour(hour);
                        return SizedBox(
                          height: effectiveCellHeight,
                          child: Center(
                            child: Text(
                              hourLabel,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade700,
                                fontWeight: hour == 0 || hour == 12 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // Heatmap cells
                  Expanded(
                    child: Stack(
                      children: [
                        // Grid lines
                        CustomPaint(
                          size: Size(availableWidth, availableHeight),
                          painter: GridPainter(
                            columns: widget.dayColumns,
                            rows: widget.hourRows,
                          ),
                        ),
                        
                        // Cells
                        ...List.generate(_cells.length, (index) {
                          final cell = _cells[index];
                          final x = cell.dayIndex * effectiveCellWidth;
                          final y = cell.hour * effectiveCellHeight;
                          
                          return Positioned(
                            left: x,
                            top: y,
                            width: effectiveCellWidth,
                            height: effectiveCellHeight,
                            child: _buildHeatmapCell(cell),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildHeatmapCell(HeatmapCell cell) {
    // Empty cell
    if (cell.count == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      );
    }
    
    // Determine cell color based on emotion filter
    Color cellColor;
    double intensity;
    
    if (_selectedEmotionType != null) {
      // Single emotion view
      if (cell.emotions.containsKey(_selectedEmotionType)) {
        final emotionStat = cell.emotions[_selectedEmotionType]!;
        intensity = emotionStat.averageIntensity;
        cellColor = _getEmotionColor(_selectedEmotionType!);
      } else {
        // No data for this emotion
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        );
      }
    } else {
      // Combined emotions view - use dominant emotion
      EmotionType dominantEmotion = cell.getDominantEmotion();
      intensity = cell.averageIntensity;
      cellColor = _getEmotionColor(dominantEmotion);
    }
    
    // Adjust opacity based on intensity
    final double opacity = 0.3 + (intensity * 0.7);
    
    return GestureDetector(
      onTap: () => _showCellDetails(cell),
      child: Container(
        decoration: BoxDecoration(
          color: cellColor.withOpacity(opacity),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Center(
          child: cell.count > 3
            ? Text(
                '${cell.count}',
                style: TextStyle(
                  color: _isColorDark(cellColor.withOpacity(opacity))
                    ? Colors.white
                    : Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        ),
      ),
    );
  }
  
  void _showCellDetails(HeatmapCell cell) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(cell.date);
    final formattedTime = DateFormat('h:00 a').format(cell.date);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$formattedDate at $formattedTime'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total records: ${cell.count}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Emotion Breakdown',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...cell.emotions.entries.map((entry) {
                final emotion = entry.key;
                final stat = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getEmotionColor(emotion),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${EmotionData.getEmotionName(emotion)} (${stat.count})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${(stat.averageIntensity * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getEmotionColor(emotion),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Low',
          style: TextStyle(fontSize: 10),
        ),
        const SizedBox(width: 4),
        Container(
          width: 120,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _selectedEmotionType != null
                ? [
                    _getEmotionColor(_selectedEmotionType!).withOpacity(0.3),
                    _getEmotionColor(_selectedEmotionType!),
                  ]
                : [
                    theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
                    theme_utils.SeeAppTheme.primaryColor,
                  ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'High',
          style: TextStyle(fontSize: 10),
        ),
        const SizedBox(width: 24),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'No data',
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_4x4,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No emotion data available for heatmap',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12am';
    if (hour == 12) return '12pm';
    return hour < 12 ? '${hour}am' : '${hour - 12}pm';
  }
  
  bool _isColorDark(Color color) {
    // Calculate luminance to determine if text should be white or black
    return color.computeLuminance() < 0.5;
  }

  Color _getEmotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return Colors.yellow.shade800;
      case EmotionType.sadness:
        return Colors.blue;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.calm:
        return Colors.teal;
      case EmotionType.disgust:
        return Colors.green;
      case EmotionType.surprise:
        return Colors.orange;
      case EmotionType.neutral:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Represents a cell in the heatmap
class HeatmapCell {
  /// Day index (column) in the heatmap
  final int dayIndex;
  
  /// Hour (row) in the heatmap
  final int hour;
  
  /// Date and time represented by this cell
  final DateTime date;
  
  /// Count of emotion entries for this time slot
  int count;
  
  /// Sum of intensities for this time slot
  double totalIntensity;
  
  /// Average intensity for this time slot
  double averageIntensity;
  
  /// Emotion-specific statistics
  Map<EmotionType, EmotionStat> emotions;
  
  HeatmapCell({
    required this.dayIndex,
    required this.hour,
    required this.date,
    required this.count,
    required this.totalIntensity,
    required this.averageIntensity,
    required this.emotions,
  });
  
  /// Returns the dominant emotion (with highest average intensity)
  EmotionType getDominantEmotion() {
    if (emotions.isEmpty) return EmotionType.calm;
    
    EmotionType dominant = emotions.keys.first;
    double maxIntensity = emotions[dominant]!.averageIntensity;
    
    for (final entry in emotions.entries) {
      if (entry.value.averageIntensity > maxIntensity) {
        maxIntensity = entry.value.averageIntensity;
        dominant = entry.key;
      }
    }
    
    return dominant;
  }
}

/// Statistics for a specific emotion in a cell
class EmotionStat {
  /// Count of entries for this emotion
  int count;
  
  /// Sum of intensities for this emotion
  double totalIntensity;
  
  /// Average intensity for this emotion
  double averageIntensity = 0.0;
  
  EmotionStat({
    required this.count,
    required this.totalIntensity,
  });
}

/// Painter for drawing the grid lines
class GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  
  GridPainter({
    required this.columns,
    required this.rows,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    
    final width = size.width;
    final height = size.height;
    
    // Draw vertical lines (columns)
    for (int i = 0; i <= columns; i++) {
      final x = i * (width / columns);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        paint,
      );
    }
    
    // Draw horizontal lines (rows)
    for (int i = 0; i <= rows; i++) {
      final y = i * (height / rows);
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        paint,
      );
    }
    
    // Highlight specific hours (6am, 12pm, 6pm)
    final highlightPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;
    
    final sixAmRow = 6;
    final noonRow = 12;
    final sixPmRow = 18;
    
    final sixAmY = sixAmRow * (height / rows);
    final noonY = noonRow * (height / rows);
    final sixPmY = sixPmRow * (height / rows);
    
    canvas.drawLine(
      Offset(0, sixAmY),
      Offset(width, sixAmY),
      highlightPaint,
    );
    
    canvas.drawLine(
      Offset(0, noonY),
      Offset(width, noonY),
      highlightPaint,
    );
    
    canvas.drawLine(
      Offset(0, sixPmY),
      Offset(width, sixPmY),
      highlightPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}