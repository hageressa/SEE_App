import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/mission_category.dart';
import 'package:see_app/models/mission_badge.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// Display card for a parent-child bonding mission
class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final bool showProgress;
  final bool showBadge;
  final bool isToday;

  final bool isLoading;
  final String? errorMessage;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onComplete,
    this.onStart,
    this.showProgress = true,
    this.showBadge = true,
    this.isToday = false,
    
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: InkWell(
        onTap: onTap ?? onStart ?? onComplete,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.category.toString().split('.').last,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCategoryColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showBadge && mission.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: mission.badge!.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: mission.badge!.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${mission.rewardPoints} pts',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: mission.badge!.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mission.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme_utils.SeeAppTheme.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (showProgress && mission.progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(
                    value: mission.progress!,
                    backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
                  ),
                ),
              if (onComplete != null || onStart != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onStart != null)
                        TextButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: TextButton.styleFrom(
                            foregroundColor: _getCategoryColor(),
                          ),
                        ),
                      if (onComplete != null)
                        TextButton.icon(
                          onPressed: onComplete,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Complete'),
                          style: TextButton.styleFrom(
                            foregroundColor: _getCategoryColor(),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  /// Format the due date in a user-friendly way
  String _formatDueDate() {
    final now = DateTime.now();
    final difference = mission.dueDate.difference(now);

    if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays < 0) {
      return 'Overdue';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due ${mission.dueDate.month}/${mission.dueDate.day}';
    }
  }

  /// Build the badge preview widget
  Widget _buildBadgePreview(BuildContext context, MissionBadge badge) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          badge.badgeIcon,
          color: badge.color,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          badge.levelName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: badge.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build the progress bar widget
  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              '${(mission.progress! * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: mission.progress,
          backgroundColor: _getCategoryColor().withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  /// Get the color for the mission category
  Color _getCategoryColor() {
    switch (mission.category) {
      case MissionCategory.mimicry:
        return theme_utils.SeeAppTheme.joyColor;
      case MissionCategory.storytelling:
        return theme_utils.SeeAppTheme.primaryColor;
      case MissionCategory.labeling:
        return theme_utils.SeeAppTheme.secondaryColor;
      case MissionCategory.bonding:
        return theme_utils.SeeAppTheme.accentColor;
      case MissionCategory.routines:
        return theme_utils.SeeAppTheme.primaryColor;
      case MissionCategory.mindfulness:
        return theme_utils.SeeAppTheme.calmColor;
      case MissionCategory.journaling:
        return theme_utils.SeeAppTheme.primaryColor;
      case MissionCategory.creativity:
        return theme_utils.SeeAppTheme.secondaryColor;
      case MissionCategory.physical:
        return theme_utils.SeeAppTheme.accentColor;
      case MissionCategory.social:
        return theme_utils.SeeAppTheme.secondaryColor;
    }
  }

  /// Get the icon for the mission category
  IconData _getCategoryIcon() {
    switch (mission.category) {
      case MissionCategory.mimicry:
        return Icons.face;
      case MissionCategory.storytelling:
        return Icons.book;
      case MissionCategory.labeling:
        return Icons.label;
      case MissionCategory.bonding:
        return Icons.favorite;
      case MissionCategory.routines:
        return Icons.calendar_today;
      case MissionCategory.mindfulness:
        return Icons.psychology;
      case MissionCategory.journaling:
        return Icons.edit;
      case MissionCategory.creativity:
        return Icons.palette;
      case MissionCategory.physical:
        return Icons.directions_run;
      case MissionCategory.social:
        return Icons.people;
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            ...List.generate(2, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
              ),
            ),
          ],
        ),
      ),
    ).animate().shimmer(duration: 1500.ms, colors: [
      Colors.transparent,
      Colors.white.withOpacity(0.2),
      Colors.transparent,
    ]);
  }
  
  Widget _buildErrorState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme_utils.SeeAppTheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              errorMessage ?? 'Failed to load mission',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            TextButton.icon(
              onPressed: onStart, // Use this as retry
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Widget for displaying mission streak information
class MissionStreakBadge extends StatelessWidget {
  final int streak;
  final int longestStreak;
  
  const MissionStreakBadge({
    super.key,
    required this.streak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: theme_utils.SeeAppTheme.spacing12,
        vertical: theme_utils.SeeAppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme_utils.SeeAppTheme.primaryColor,
            theme_utils.SeeAppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streak Day Streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Best: $longestStreak days',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms);
  }
}

/// Dialog for displaying mission details
class MissionDetailsDialog extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onComplete;
  final Function(String)? onAddReflection;
  
  const MissionDetailsDialog({
    super.key,
    required this.mission,
    this.onComplete,
    this.onAddReflection,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(theme_utils.SeeAppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getCategoryColor().withOpacity(0.2),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getCategoryColor(),
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.categoryName,
                        style: TextStyle(
                          color: _getCategoryColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Difficulty: ${mission.difficultyStars}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
                Text(
                  mission.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                Container(
                  padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Research Evidence:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.evidenceSource,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: theme_utils.SeeAppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These researchers found that ${_getEvidenceExplanation()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (mission.isCompleted && mission.reflection != null) ...[
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: theme_utils.SeeAppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Your Reflection:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.reflection!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
                if (!mission.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Completed'),
                      onPressed: () {
                        onComplete?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else if (mission.reflection == null && onAddReflection != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Add Reflection'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showReflectionDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme_utils.SeeAppTheme.joyColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completed${mission.completedAt != null ? ' on ${_formatDate(mission.completedAt!)}' : ''}',
                        style: TextStyle(
                          color: theme_utils.SeeAppTheme.joyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Shows a dialog to add a reflection
  void _showReflectionDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Your Reflection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How did this activity go? What did you notice about your child\'s response?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your thoughts here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAddReflection?.call(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
  
  /// Get color based on mission category
  Color _getCategoryColor() {
    switch (mission.category) {
      case MissionCategory.mimicry:
        return Colors.orange;
      case MissionCategory.storytelling:
        return Colors.blue;
      case MissionCategory.labeling:
        return Colors.green;
      case MissionCategory.bonding:
        return Colors.red;
      case MissionCategory.routines:
        return Colors.purple;
      case MissionCategory.mindfulness:
        return Colors.teal;
      case MissionCategory.journaling:
        return Colors.indigo;
      case MissionCategory.creativity:
        return Colors.amber;
      case MissionCategory.physical:
        return Colors.deepOrange;
      case MissionCategory.social:
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
  
  /// Get icon based on mission category
  IconData _getCategoryIcon() {
    switch (mission.category) {
      case MissionCategory.mimicry:
        return Icons.face;
      case MissionCategory.storytelling:
        return Icons.book;
      case MissionCategory.labeling:
        return Icons.label;
      case MissionCategory.bonding:
        return Icons.favorite;
      case MissionCategory.routines:
        return Icons.calendar_today;
      case MissionCategory.mindfulness:
        return Icons.access_time;
      case MissionCategory.journaling:
        return Icons.note;
      case MissionCategory.creativity:
        return Icons.brush;
      case MissionCategory.physical:
        return Icons.directions_run;
      case MissionCategory.social:
        return Icons.people;
      default:
        return Icons.question_mark;
    }
  }
  
  /// Get evidence explanation based on category
  String _getEvidenceExplanation() {
    switch (mission.category) {
      case MissionCategory.mimicry:
        return 'practicing emotion mimicry helps children with Down syndrome improve their ability to recognize and express emotions.';
      case MissionCategory.storytelling:
        return 'emotional storytelling builds empathy and helps children understand complex emotions through narrative.';
      case MissionCategory.labeling:
        return 'explicitly labeling emotions improves children\'s emotional vocabulary and regulation skills.';
      case MissionCategory.bonding:
        return 'physical bonding activities strengthen the parent-child relationship and create a secure foundation for emotional development.';
      case MissionCategory.routines:
        return 'consistent emotional routines help establish patterns that can lead to long-term behavior change and improved emotional intelligence.';
      case MissionCategory.mindfulness:
        return 'mindfulness practices help children develop self-awareness and self-regulation skills.';
      case MissionCategory.journaling:
        return 'journaling helps children process and reflect on their emotions and experiences.';
      case MissionCategory.creativity:
        return 'creative activities provide an outlet for children to express and manage their emotions.';
      case MissionCategory.physical:
        return 'physical activities help children develop self-awareness and self-regulation skills.';
      case MissionCategory.social:
        return 'social activities help children develop empathy and understanding of others\' emotions.';
      default:
        return '';
    }
  }
}