import 'package:flutter/material.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart';
import 'package:intl/intl.dart';

class DistressAlertCard extends StatefulWidget {
  final DistressAlert alert;
  final VoidCallback? onViewDetails;
  final VoidCallback? onResolve;
  
  const DistressAlertCard({
    super.key,
    required this.alert,
    this.onViewDetails,
    this.onResolve,
  });

  @override
  State<DistressAlertCard> createState() => _DistressAlertCardState();
}

class _DistressAlertCardState extends State<DistressAlertCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animController;
  AnimationController? _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Create pulsing effect for high severity alerts
    if (widget.alert.severity == AlertSeverity.high) {
      // Create a separate controller for pulsing that repeats
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
      
      _pulseAnimation = TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
      ]).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // No pulsing for medium/low alerts
      _pulseAnimation = ConstantTween(1.0).animate(_animController);
    }
  }
  
  @override
  void dispose() {
    _animController.dispose();
    // Dispose the pulse controller if we created one
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final severityText = _getSeverityText();
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _animController.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _animController.reverse();
        });
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: severityColor.withOpacity(_isHovering ? 0.25 : 0.15),
                blurRadius: _isHovering ? 12 : 8,
                offset: const Offset(0, 2),
                spreadRadius: _isHovering ? 1 : 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.08 : 0.05),
                blurRadius: _isHovering ? 6 : 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onViewDetails,
              splashColor: severityColor.withOpacity(0.1),
              highlightColor: severityColor.withOpacity(0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Alert header
                  AnimatedBuilder(
                    animation: widget.alert.severity == AlertSeverity.high ? 
                             _pulseAnimation : _animController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(
                            widget.alert.severity == AlertSeverity.high ? 
                            (0.12 + (_pulseAnimation.value - 1.0) * 0.2) : 
                            (_isHovering ? 0.18 : 0.12)
                          ),
                          border: Border(
                            left: BorderSide(
                              color: severityColor,
                              width: widget.alert.severity == AlertSeverity.high ? 
                                  4 * _pulseAnimation.value : 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSeverityIcon(),
                              color: severityColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              severityText,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _buildIntensityIndicator(context),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Alert content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emotion and timestamp row
                        Row(
                          children: [
                            // Emotion indicator
                            _buildEmotionIndicator(context),
                            const SizedBox(width: 12),
                            // Timestamp chip
                            _buildTimeLabel(context),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Description
                        Text(
                          widget.alert.description ?? 'No additional information',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        _buildActionButtons(context),
                      ],
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
  
  Widget _buildEmotionIndicator(BuildContext context) {
    final emotionColor = _getEmotionColor();
    final emotionName = EmotionData.getEmotionName(widget.alert.triggerEmotion);
    
    return Expanded(
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(_isHovering ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovering ? [
                BoxShadow(
                  color: emotionColor.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Icon(
              _getEmotionIcon(),
              color: emotionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$emotionName detected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _isHovering ? emotionColor : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIntensityIndicator(BuildContext context) {
    final intensity = (widget.alert.intensity * 100).toInt();
    final severityColor = _getSeverityColor();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(_isHovering ? 0.3 : 0.2),
            blurRadius: _isHovering ? 6 : 4,
            spreadRadius: 0,
          ),
        ],
        border: _isHovering ? Border.all(color: severityColor, width: 1) : null,
      ),
      child: Text(
        '$intensity%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: severityColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildTimeLabel(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(widget.alert.timestamp);
    
    String timeText;
    
    if (difference.inHours < 1) {
      timeText = '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} hr ago';
    } else {
      final formatter = DateFormat('h:mm a');
      timeText = formatter.format(widget.alert.timestamp);
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovering ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: _isHovering ? _getSeverityColor() : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: _isHovering ? _getSeverityColor() : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen is narrow, stack buttons vertically
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailsButton(context),
              const SizedBox(height: 8),
              _buildResolveButton(context),
            ],
          );
        }
        
        // Otherwise, put them side by side
        return Row(
          children: [
            Expanded(child: _buildDetailsButton(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildResolveButton(context)),
          ],
        );
      }
    );
  }
  
  Widget _buildDetailsButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: widget.onViewDetails,
      icon: const Icon(Icons.visibility, size: 18),
      label: const Text('Details'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        foregroundColor: _isHovering ? _getSeverityColor() : null,
        side: _isHovering ? BorderSide(color: _getSeverityColor()) : null,
      ),
    );
  }
  
  Widget _buildResolveButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.onResolve == null ? null : () {
        // Add confirmation dialog for resolving
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Resolve Alert'),
              content: const Text('Are you sure you want to mark this alert as resolved?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onResolve!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getSeverityColor(),
                  ),
                  child: const Text('Resolve'),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Resolved'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: _isHovering ? _getSeverityColor() : SeeAppTheme.primaryColor,
      ),
    );
  }

  IconData _getSeverityIcon() {
    switch (widget.alert.severity) {
      case AlertSeverity.high:
        return Icons.priority_high;
      case AlertSeverity.medium:
        return Icons.error_outline;
      case AlertSeverity.low:
        return Icons.info_outline;
    }
  }

  Color _getSeverityColor() {
    switch (widget.alert.severity) {
      case AlertSeverity.high:
        return SeeAppTheme.alertHigh;
      case AlertSeverity.medium:
        return SeeAppTheme.alertMedium;
      case AlertSeverity.low:
        return SeeAppTheme.alertLow;
    }
  }
  
  String _getSeverityText() {
    switch (widget.alert.severity) {
      case AlertSeverity.high:
        return 'High Priority';
      case AlertSeverity.medium:
        return 'Medium Priority';
      case AlertSeverity.low:
        return 'Low Priority';
    }
  }
  
  Color _getEmotionColor() {
    switch (widget.alert.triggerEmotion) {
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
  
  IconData _getEmotionIcon() {
    switch (widget.alert.triggerEmotion) {
      case EmotionType.joy:
        return Icons.sentiment_very_satisfied;
      case EmotionType.sadness:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.anger:
        return Icons.mood_bad;
      case EmotionType.fear:
        return Icons.warning_amber;
      case EmotionType.calm:
        return Icons.sentiment_satisfied;
      case EmotionType.disgust:
        return Icons.sentiment_dissatisfied;
      case EmotionType.surprise:
        return Icons.sentiment_neutral;
      case EmotionType.neutral:
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }
}