import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/mission_badge.dart';
import 'package:see_app/utils/theme.dart';

/// A widget to display mission badges in a grid layout
class BadgeDisplay extends StatelessWidget {
  final List<MissionBadge> badges;
  final bool showUnearned;
  final void Function(MissionBadge)? onBadgeTap;
  
  const BadgeDisplay({
    Key? key,
    required this.badges,
    this.showUnearned = true,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter badges based on showUnearned setting
    final displayBadges = showUnearned 
        ? badges 
        : badges.where((badge) => badge.isEarned).toList();
    
    if (displayBadges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: SeeAppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No badges earned yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete missions and build streaks to earn badges',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8, 
        mainAxisSpacing: 8,
      ),
      itemCount: displayBadges.length,
      itemBuilder: (context, index) {
        return _BadgeItem(
          badge: displayBadges[index],
          onTap: onBadgeTap != null 
              ? () => onBadgeTap!(displayBadges[index]) 
              : null,
        ).animate()
          .fadeIn(
            duration: 400.ms, 
            delay: (index * 100).ms,
            curve: Curves.easeOut,
          )
          .slideY(
            begin: 0.2, 
            end: 0,
            duration: 400.ms, 
            delay: (index * 100).ms,
            curve: Curves.easeOut,
          );
      },
    );
  }
}

/// A widget to display a single badge item
class _BadgeItem extends StatelessWidget {
  final MissionBadge badge;
  final VoidCallback? onTap;
  
  const _BadgeItem({
    Key? key,
    required this.badge,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showBadgeDetails(context, badge);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: SeeAppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadgeIcon(context),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: badge.isEarned 
                      ? SeeAppTheme.textPrimary 
                      : SeeAppTheme.textSecondary.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the badge icon with appropriate styling based on earned status
  Widget _buildBadgeIcon(BuildContext context) {
    final iconSize = 42.0;
    final medalSize = 16.0;
    
    return Stack(
      children: [
        // Badge background
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: badge.isEarned 
                ? badge.color.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              badge.badgeIcon,
              size: iconSize / 2,
              color: badge.isEarned 
                  ? badge.color 
                  : Colors.grey.withOpacity(0.5),
            ),
          ),
        ),
        
        // Medal indicator
        if (badge.isEarned)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: medalSize,
              height: medalSize,
              decoration: BoxDecoration(
                color: _getMedalColor(badge.level),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  badge.medalIcon,
                  size: medalSize / 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
        // Lock icon for unearned badges
        if (!badge.isEarned)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: medalSize,
              height: medalSize,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Show badge details in a dialog
  void _showBadgeDetails(BuildContext context, MissionBadge badge) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: badge.isEarned 
                        ? badge.color.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      badge.badgeIcon,
                      size: 40,
                      color: badge.isEarned 
                          ? badge.color 
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Badge name
                Text(
                  badge.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badge.isEarned ? badge.color : SeeAppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Level indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMedalColor(badge.level).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badge.medalIcon,
                        size: 16,
                        color: _getMedalColor(badge.level),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badge.levelName,
                        style: TextStyle(
                          color: _getMedalColor(badge.level),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Badge description
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                // Earned date
                if (badge.isEarned && badge.earnedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Earned on ${_formatDate(badge.earnedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SeeAppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  /// Get medal color based on level
  Color _getMedalColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFCD7F32); // Bronze
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFFFD700); // Gold
      default:
        return Colors.grey;
    }
  }
  
  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// A widget to display a badge collection with a title
class BadgeCollection extends StatelessWidget {
  final String title;
  final List<MissionBadge> badges;
  final bool showUnearned;
  final void Function(MissionBadge)? onBadgeTap;
  
  const BadgeCollection({
    Key? key,
    required this.title,
    required this.badges,
    this.showUnearned = true,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter badges based on showUnearned setting
    final displayBadges = showUnearned 
        ? badges 
        : badges.where((badge) => badge.isEarned).toList();
    
    if (displayBadges.isEmpty && !showUnearned) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        BadgeDisplay(
          badges: displayBadges,
          showUnearned: showUnearned,
          onBadgeTap: onBadgeTap,
        ),
      ],
    );
  }
}

/// A widget to display a newly earned badge with animation
class BadgeAchievement extends StatelessWidget {
  final MissionBadge badge;
  final VoidCallback? onClose;
  
  const BadgeAchievement({
    Key? key,
    required this.badge,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: SeeAppTheme.cardBackground,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          
          // Confetti icon at the top
          Icon(
            Icons.celebration,
            color: SeeAppTheme.joyColor,
            size: 40,
          ).animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
            ),
          const SizedBox(height: 16),
          
          // Achievement title
          Text(
            'New Badge Earned!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: SeeAppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Badge icon with animation
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                badge.badgeIcon,
                size: 50,
                color: badge.color,
              ),
            ),
          ).animate()
            .scale(
              duration: 800.ms,
              curve: Curves.elasticOut,
              delay: 200.ms,
            )
            .shimmer(
              duration: 1800.ms,
              delay: 600.ms,
              color: Colors.white.withOpacity(0.9),
            ),
          const SizedBox(height: 16),
          
          // Badge name
          Text(
            badge.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: badge.color,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(
              duration: 600.ms,
              delay: 400.ms,
            ),
          const SizedBox(height: 8),
          
          // Badge description
          Text(
            badge.description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(
              duration: 600.ms,
              delay: 600.ms,
            ),
          const SizedBox(height: 24),
          
          // Close button
          ElevatedButton(
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: badge.color,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Awesome!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate()
            .fadeIn(
              duration: 600.ms,
              delay: 800.ms,
            ),
        ],
      ),
    ).animate()
      .scale(
        duration: 400.ms,
        curve: Curves.easeOutBack,
      );
  }
}