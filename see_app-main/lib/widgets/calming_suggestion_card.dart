import 'package:flutter/material.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/models/suggestion_feedback.dart';
import 'package:see_app/utils/theme.dart';

class CalmingSuggestionCard extends StatefulWidget {
  final CalmingSuggestion suggestion;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteToggled;
  final double? width;
  final Function(CalmingSuggestion, EffectivenessRating, EmotionType, double, EmotionType?, double?, String?)? onRateSuggestion;
  
  const CalmingSuggestionCard({
    super.key,
    required this.suggestion,
    this.onTap,
    this.onFavoriteToggled,
    this.width,
    this.onRateSuggestion,
  });
  
  @override
  State<CalmingSuggestionCard> createState() => _CalmingSuggestionCardState();
}

class _CalmingSuggestionCardState extends State<CalmingSuggestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
          _animationController.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _animationController.reverse();
        });
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width ?? 280,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(_isHovering ? 0.15 : 0.08),
                blurRadius: _isHovering ? 16 : 12,
                offset: const Offset(0, 4),
                spreadRadius: _isHovering ? 1 : 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.05 : 0.03),
                blurRadius: _isHovering ? 8 : 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashColor: categoryColor.withOpacity(0.1),
              highlightColor: categoryColor.withOpacity(0.05),
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image or placeholder header
                  Stack(
                    children: [
                      // Main image
                      Hero(
                        tag: 'suggestion_${widget.suggestion.id}',
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: widget.suggestion.imageUrl != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      widget.suggestion.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholderImage(categoryColor);
                                      },
                                    ),
                                    // Gradient overlay for better text visibility
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height: 60,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Hover effect overlay
                                    AnimatedOpacity(
                                      opacity: _isHovering ? 0.1 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildPlaceholderImage(categoryColor),
                        ),
                      ),
                      
                      // Category badge - positioned at top-right
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(0, _isHovering ? -2 : 0, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(_isHovering ? 0.15 : 0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(),
                                color: categoryColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCategoryName(),
                                style: TextStyle(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and duration row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Expanded(
                              child: Text(
                                widget.suggestion.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isHovering ? categoryColor : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Duration chip
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isHovering ? categoryColor.withOpacity(0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: _isHovering ? categoryColor : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: _isHovering ? categoryColor : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Description
                        Text(
                          widget.suggestion.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  
                  // Target emotions and actions row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        // For label
                        Text(
                          'For:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: SeeAppTheme.textSecondary,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Scrollable emotions list
                        Expanded(
                          child: SizedBox(
                            height: 26,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.suggestion.targetEmotions.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return _buildEmotionChip(
                                  context,
                                  widget.suggestion.targetEmotions[index],
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Favorite button
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: IconButton(
                            key: ValueKey<bool>(widget.suggestion.isFavorite),
                            onPressed: () {
                              widget.onFavoriteToggled?.call(!widget.suggestion.isFavorite);
                            },
                            icon: Icon(
                              widget.suggestion.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.suggestion.isFavorite
                                  ? Colors.red
                                  : Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        
                        // Rate button - only shown if onRateSuggestion is provided
                        if (widget.onRateSuggestion != null)
                          const SizedBox(width: 12),
                          
                        if (widget.onRateSuggestion != null)
                          InkWell(
                            onTap: () => _showRatingDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 16,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // View details button - appears on hover
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isHovering ? 40 : 0,
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHovering ? 1.0 : 0.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.9),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: categoryColor,
                            ),
                          ],
                        ),
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
  
  Widget _buildPlaceholderImage(Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.1),
            categoryColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 48,
              color: categoryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              _getActivityTypeLabel(),
              style: TextStyle(
                color: categoryColor.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmotionChip(BuildContext context, EmotionType emotion) {
    Color color;
    
    switch (emotion) {
      case EmotionType.joy:
        color = Colors.amber;
        break;
      case EmotionType.sadness:
        color = Colors.blue;
        break;
      case EmotionType.anger:
        color = Colors.red;
        break;
      case EmotionType.fear:
        color = Colors.purple;
        break;
      case EmotionType.calm:
        color = Colors.teal;
        break;
      case EmotionType.disgust:
        color = Colors.green;
        break;
      case EmotionType.surprise:
        color = Colors.orange;
        break;
      case EmotionType.neutral:
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, _isHovering ? -2 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovering ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Text(
        EmotionData.getEmotionName(emotion),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
  
  Color _getCategoryColor() {
    switch (widget.suggestion.category) {
      case SuggestionCategory.physical:
        return Colors.green;
      case SuggestionCategory.creative:
        return Colors.purple;
      case SuggestionCategory.cognitive:
        return Colors.blue;
      case SuggestionCategory.sensory:
        return Colors.orange;
      case SuggestionCategory.social:
        return Colors.pink;
    }
  }
  
  String _getCategoryName() {
    switch (widget.suggestion.category) {
      case SuggestionCategory.physical:
        return 'Physical';
      case SuggestionCategory.creative:
        return 'Creative';
      case SuggestionCategory.cognitive:
        return 'Thinking';
      case SuggestionCategory.sensory:
        return 'Sensory';
      case SuggestionCategory.social:
        return 'Social';
    }
  }
  
  IconData _getCategoryIcon() {
    switch (widget.suggestion.category) {
      case SuggestionCategory.physical:
        return Icons.directions_run;
      case SuggestionCategory.creative:
        return Icons.color_lens;
      case SuggestionCategory.cognitive:
        return Icons.psychology;
      case SuggestionCategory.sensory:
        return Icons.touch_app;
      case SuggestionCategory.social:
        return Icons.people;
    }
  }
  
  String _getActivityTypeLabel() {
    switch (widget.suggestion.category) {
      case SuggestionCategory.physical:
        return 'Physical Activity';
      case SuggestionCategory.creative:
        return 'Creative Expression';
      case SuggestionCategory.cognitive:
        return 'Mind Exercise';
      case SuggestionCategory.sensory:
        return 'Sensory Activity';
      case SuggestionCategory.social:
        return 'Social Interaction';
    }
  }
  
  String _formatDuration() {
    if (widget.suggestion.estimatedTime == null) {
      return 'Varies';
    }
    
    final minutes = widget.suggestion.estimatedTime!.inMinutes;
    
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      
      if (remainingMinutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $remainingMinutes min';
      }
    }
  }
  
  void _showRatingDialog(BuildContext context) {
    // Default selected values
    EffectivenessRating selectedRating = EffectivenessRating.moderatelyEffective;
    EmotionType beforeEmotion = EmotionType.anger; 
    double beforeIntensity = 0.7;
    EmotionType? afterEmotion = EmotionType.calm;
    double? afterIntensity = 0.3;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('How effective was this suggestion?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating selection
                  const Text('Effectiveness Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildRatingSelector(
                    selectedRating: selectedRating,
                    onRatingChanged: (rating) {
                      setState(() {
                        selectedRating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Before emotion state
                  const Text('Before using this suggestion:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildEmotionSelector(
                    label: 'Emotion:',
                    selectedEmotion: beforeEmotion,
                    onEmotionChanged: (emotion) {
                      setState(() {
                        beforeEmotion = emotion;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildIntensitySlider(
                    label: 'Intensity:',
                    intensity: beforeIntensity,
                    onIntensityChanged: (value) {
                      setState(() {
                        beforeIntensity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // After emotion state
                  const Text('After using this suggestion:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildEmotionSelector(
                    label: 'Emotion:',
                    selectedEmotion: afterEmotion ?? EmotionType.calm,
                    onEmotionChanged: (emotion) {
                      setState(() {
                        afterEmotion = emotion;
                      });
                    },
                    allowNull: true,
                    onClearEmotion: () {
                      setState(() {
                        afterEmotion = null;
                        afterIntensity = null;
                      });
                    },
                  ),
                  if (afterEmotion != null)
                    const SizedBox(height: 8),
                  if (afterEmotion != null)
                    _buildIntensitySlider(
                      label: 'Intensity:',
                      intensity: afterIntensity ?? 0.0,
                      onIntensityChanged: (value) {
                        setState(() {
                          afterIntensity = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  
                  // Additional comments
                  const Text('Additional Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this suggestion...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onRateSuggestion?.call(
                    widget.suggestion,
                    selectedRating,
                    beforeEmotion,
                    beforeIntensity,
                    afterEmotion,
                    afterIntensity,
                    commentController.text.isNotEmpty ? commentController.text : null,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(),
                ),
                child: const Text('Submit Feedback'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Widget _buildRatingSelector({
    required EffectivenessRating selectedRating,
    required ValueChanged<EffectivenessRating> onRatingChanged,
  }) {
    return Wrap(
      spacing: 8,
      children: EffectivenessRating.values.map((rating) {
        final isSelected = rating == selectedRating;
        
        Color getColorForRating() {
          switch (rating) {
            case EffectivenessRating.extremelyEffective:
              return Colors.green.shade700;
            case EffectivenessRating.veryEffective:
              return Colors.green;
            case EffectivenessRating.moderatelyEffective:
              return Colors.amber;
            case EffectivenessRating.slightlyEffective:
              return Colors.orange;
            case EffectivenessRating.notEffective:
              return Colors.red;
            default:
              return Colors.amber; // Default color for any other case
          }
        }
        
        String getRatingName() {
          switch (rating) {
            case EffectivenessRating.extremelyEffective:
              return 'Extremely Effective';
            case EffectivenessRating.veryEffective:
              return 'Very Effective';
            case EffectivenessRating.moderatelyEffective:
              return 'Moderately Effective';
            case EffectivenessRating.slightlyEffective:
              return 'Slightly Effective';
            case EffectivenessRating.notEffective:
              return 'Not Effective';
            default:
              return 'Moderately Effective'; // Default name for any other case
          }
        }
        
        return ChoiceChip(
          label: Text(getRatingName()),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onRatingChanged(rating);
            }
          },
          backgroundColor: getColorForRating().withOpacity(0.1),
          selectedColor: getColorForRating().withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? getColorForRating() : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildEmotionSelector({
    required String label,
    required EmotionType selectedEmotion,
    required ValueChanged<EmotionType> onEmotionChanged,
    bool allowNull = false,
    VoidCallback? onClearEmotion,
  }) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<EmotionType>(
            value: selectedEmotion,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: EmotionType.values.map((emotion) {
              return DropdownMenuItem<EmotionType>(
                value: emotion,
                child: Text(EmotionData.getEmotionName(emotion)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onEmotionChanged(value);
              }
            },
          ),
        ),
        if (allowNull && onClearEmotion != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClearEmotion,
            tooltip: 'Clear emotion',
          ),
      ],
    );
  }
  
  Widget _buildIntensitySlider({
    required String label,
    required double intensity,
    required ValueChanged<double> onIntensityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(intensity * 100).toInt()}%'),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getCategoryColor(),
            inactiveTrackColor: _getCategoryColor().withOpacity(0.2),
            thumbColor: _getCategoryColor(),
            trackHeight: 6,
          ),
          child: Slider(
            value: intensity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: onIntensityChanged,
          ),
        ),
      ],
    );
  }
}