import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/mission_badge.dart';
import 'package:see_app/models/mission_category.dart';
import 'package:see_app/services/mission_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/badge_display.dart';
import 'package:see_app/widgets/emotion_garden.dart';
import 'package:see_app/widgets/mission_card.dart';

/// Connect & Reflect Missions section for the Home tab
class ConnectReflectSection extends StatefulWidget {
  final VoidCallback? onViewAllMissions;

  const ConnectReflectSection({
    super.key,
    this.onViewAllMissions,
  });

  @override
  State<ConnectReflectSection> createState() => _ConnectReflectSectionState();
}

class _ConnectReflectSectionState extends State<ConnectReflectSection> {
  @override
  void initState() {
    super.initState();
    
    // Ensure missions are loaded
    Future.microtask(() {
      if (!mounted) return;
      final missionService = Provider.of<MissionService>(context, listen: false);
      if (!missionService.isLoading && missionService.missions.isEmpty) {
        missionService.fetchMissions();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for newly earned badges
    final missionService = Provider.of<MissionService>(context, listen: false);
    Future.microtask(() {
      if (!mounted) return;
      if (missionService.lastEarnedBadge != null) {
        _showBadgeAchievement(context, missionService.lastEarnedBadge!);
        missionService.clearLastEarnedBadge();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionService>(
      builder: (context, missionService, child) {
        // Show loading state
        if (missionService.isLoading) {
          return _buildLoadingState(context);
        }
        
        // Show error state
        if (missionService.error != null) {
          return _buildErrorState(context, missionService);
        }
        
        // If no missions are available, show placeholder
        if (missionService.missions.isEmpty) {
          return _buildEmptyState(context);
        }
        
        // Show today's mission, streak, and achievement sections
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, missionService),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            if (missionService.todaysMission != null)
              MissionCard(
                mission: missionService.todaysMission!,
                isToday: true,
                onComplete: () => _completeMission(context, missionService.todaysMission!),
                onStart: () => _showMissionDetails(context, missionService.todaysMission!),
              ),
              
            // Growth Garden and Badges in a horizontal layout
            if (missionService.userStreak != null && missionService.userStreak!.currentStreak > 0)
              Padding(
                padding: const EdgeInsets.only(top: theme_utils.SeeAppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title with icon
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events,
                              color: theme_utils.SeeAppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Progress',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Two-column layout for garden and badges
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Growth Garden - left side
                          Expanded(
                            flex: 5,
                            child: _buildGrowthGarden(context, missionService),
                          ),
                          const SizedBox(width: 12),
                          // Badges - right side
                          Expanded(
                            flex: 6,
                            child: _buildBadgesSection(context, missionService),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
      },
    );
  }
  
  /// Build section header with title and streak badge
  Widget _buildSectionHeader(BuildContext context, MissionService missionService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connect & Reflect',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Build emotional bonds with your child',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (missionService.userStreak != null && missionService.userStreak!.currentStreak > 0)
          MissionStreakBadge(
            streak: missionService.userStreak!.currentStreak,
            longestStreak: missionService.userStreak!.longestStreak,
          ),
        if (widget.onViewAllMissions != null)
          TextButton(
            onPressed: widget.onViewAllMissions,
            child: const Text('View All'),
            style: TextButton.styleFrom(
              foregroundColor: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
      ],
    );
  }
  
  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connect & Reflect",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Loading missions...",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme_utils.SeeAppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
          ],
        ),
      ),
    );
  }
  
  /// Build error state
  Widget _buildErrorState(BuildContext context, MissionService missionService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connect & Reflect",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Unable to load missions",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme_utils.SeeAppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  missionService.fetchMissions();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          ],
        ),
      ),
    );
  }
  
  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 40,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              'Connect & Reflect Missions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
            Text(
              'Bond with your child through simple, evidence-based activities that develop emotional intelligence.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: () {
                final missionService = Provider.of<MissionService>(context, listen: false);
                missionService.fetchMissions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Load Missions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the Emotional Garden section
  Widget _buildGrowthGarden(BuildContext context, MissionService missionService) {
    return Card(
      elevation: 4,
      shadowColor: theme_utils.SeeAppTheme.calmColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme_utils.SeeAppTheme.calmColor.withOpacity(0.2),
              theme_utils.SeeAppTheme.calmColor.withOpacity(0.05),
            ],
            stops: const [0.0, 0.8],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: theme_utils.SeeAppTheme.calmColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: EmotionGarden(
            streak: missionService.userStreak,
            maxWidth: double.infinity,
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 300.ms, duration: 600.ms)
      .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 600.ms);
  }
  
  /// Build the Badges section
  Widget _buildBadgesSection(BuildContext context, MissionService missionService) {
    final earnedBadges = missionService.getEarnedBadges();
    
    if (earnedBadges.isEmpty) {
      // Empty badge state with more visual appeal
      return Card(
        elevation: 4,
        shadowColor: theme_utils.SeeAppTheme.joyColor.withOpacity(0.3),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme_utils.SeeAppTheme.joyColor.withOpacity(0.15),
                theme_utils.SeeAppTheme.joyColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.9],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge section title - enhanced with better design
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: theme_utils.SeeAppTheme.joyColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme_utils.SeeAppTheme.joyColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Placeholder badges with improved appearance
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  // Placeholder badges (locked)
                  _buildPlaceholderBadge(context, Icons.whatshot, 'First Step', Colors.blueAccent),
                  _buildPlaceholderBadge(context, Icons.diversity_3, 'Dedicated Parent', Colors.deepPurple),
                  _buildPlaceholderBadge(context, Icons.psychology, 'Emotion Explorer', Colors.teal),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Motivation text with better styling
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Complete more missions to earn achievements!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme_utils.SeeAppTheme.textPrimary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 600.ms);
    }
    
    // Earned badges with enhanced styling
    return Card(
        elevation: 4,
        shadowColor: theme_utils.SeeAppTheme.joyColor.withOpacity(0.3),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme_utils.SeeAppTheme.joyColor.withOpacity(0.15),
                theme_utils.SeeAppTheme.joyColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.8],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color: theme_utils.SeeAppTheme.joyColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Your Achievements',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme_utils.SeeAppTheme.joyColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          '${earnedBadges.length} Earned',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme_utils.SeeAppTheme.joyColor,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All Achievements',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your journey of emotional growth',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme_utils.SeeAppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (missionService.getBadgesByType(BadgeType.streak).isNotEmpty)
                                              BadgeCollection(
                                                title: 'Consistency Streaks',
                                                badges: missionService.getBadgesByType(BadgeType.streak).where((b) => b.isEarned).toList(),
                                                showUnearned: false,
                                              ),
                                            if (missionService.getBadgesByType(BadgeType.milestone).isNotEmpty)
                                              BadgeCollection(
                                                title: 'Mission Milestones',
                                                badges: missionService.getBadgesByType(BadgeType.milestone).where((b) => b.isEarned).toList(),
                                                showUnearned: false,
                                              ),
                                            if (missionService.getBadgesByType(BadgeType.category).isNotEmpty)
                                              BadgeCollection(
                                                title: 'Category Mastery',
                                                badges: missionService.getBadgesByType(BadgeType.category).where((b) => b.isEarned).toList(),
                                                showUnearned: false,
                                              ),
                                            if (missionService.getBadgesByType(BadgeType.reflection).isNotEmpty)
                                              BadgeCollection(
                                                title: 'Reflective Practice',
                                                badges: missionService.getBadgesByType(BadgeType.reflection).where((b) => b.isEarned).toList(),
                                                showUnearned: false,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        color: theme_utils.SeeAppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Responsive badge grid with Wrap layout
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: earnedBadges.map((badge) {
                  return SizedBox(
                    width: 65,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge icon with attractive styling
                        GestureDetector(
                          onTap: () => _showBadgeAchievement(context, badge),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background glow effect
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: badge.color.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Badge icon with enhanced styling
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      badge.color.withOpacity(0.9),
                                    ],
                                    radius: 0.7,
                                    focal: Alignment.topLeft,
                                    focalRadius: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: badge.color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    badge.badgeIcon,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Small sparkle effect in top-right
                              Positioned(
                                top: 0,
                                right: 5,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badge.color.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.star,
                                      size: 8,
                                      color: badge.color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate()
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          ),
                        const SizedBox(height: 4),
                        // Badge name with enhanced styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: badge.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            badge.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: badge.color.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 600.ms);
  }
  
  /// Show badge achievement dialog
  void _showBadgeAchievement(BuildContext context, MissionBadge badge) {
    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (context) => BadgeAchievement(
          badge: badge,
          onClose: () => Navigator.of(context).pop(),
        ),
      );
    });
  }
  
  /// Show mission details dialog
  void _showMissionDetails(BuildContext context, Mission mission) {
    showDialog(
      context: context,
      builder: (context) => MissionDetailsDialog(
        mission: mission,
        onComplete: () => _completeMission(context, mission),
        onAddReflection: (reflection) => _addReflection(context, mission, reflection),
      ),
    );
  }
  
  /// Complete a mission
  void _completeMission(BuildContext context, Mission mission) {
    HapticFeedback.mediumImpact();
    
    final missionService = Provider.of<MissionService>(context, listen: false);
    missionService.completeMission(mission.id).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" completed!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete mission. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
  
  /// Add a reflection to a completed mission
  void _addReflection(BuildContext context, Mission mission, String reflection) {
    final missionService = Provider.of<MissionService>(context, listen: false);
    missionService.completeMission(mission.id, reflection: reflection).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflection saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save reflection. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}

// Helper method to build placeholder badges when none are earned
Widget _buildPlaceholderBadge(BuildContext context, IconData icon, String label, Color color) {
  return SizedBox(
    width: 65,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Faded badge icon with lock overlay
        Stack(
          alignment: Alignment.center,
          children: [
            // Badge background
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: color.withOpacity(0.3),
                ),
              ),
            ),
            // Lock overlay
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Enhanced badge name
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 9, 
            color: color.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        // Hint text
        Text(
          'Coming soon',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 7,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}