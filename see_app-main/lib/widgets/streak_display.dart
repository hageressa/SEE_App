import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:confetti/confetti.dart';
import 'dart:math';

/// A widget to display user's connect & reflect streak information
/// with a design similar to Duolingo to increase engagement
class StreakDisplay extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final bool showTrophyAnimation;

  const StreakDisplay({
    Key? key, 
    required this.currentStreak,
    required this.longestStreak,
    this.showTrophyAnimation = false,
  }) : super(key: key);

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay> {
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    if (widget.showTrophyAnimation) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _confettiController.play();
      });
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildStreakCard(context),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
              Colors.orange,
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStreakCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme_utils.SeeAppTheme.primaryColor.withOpacity(0.9),
            theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with streak information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Current streak with fire icon
                  _buildStreakCounter(
                    context,
                    widget.currentStreak,
                    'Current Streak',
                    Icons.local_fire_department,
                    Colors.orange,
                    widget.showTrophyAnimation,
                  ),
                  
                  const Spacer(),
                  
                  // Longest streak with trophy icon
                  _buildStreakCounter(
                    context,
                    widget.longestStreak,
                    'Longest Streak',
                    Icons.emoji_events,
                    Colors.amber,
                    false,
                  ),
                ],
              ),
            ),
            
            // Progress bar at the bottom
            _buildStreakProgressBar(context),
          ],
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 3.seconds,
      delay: 2.seconds,
      color: Colors.white.withOpacity(0.2),
      angle: -0.45,
      size: 1.2,
    );
  }
  
  Widget _buildStreakCounter(
    BuildContext context,
    int count,
    String label,
    IconData icon,
    Color iconColor,
    bool animate,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
        ).animate(
          target: animate ? 1 : 0,
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scale(
          duration: 600.ms,
          curve: Curves.easeInOut,
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate(
              target: animate ? 1 : 0,
            ).shimmer(
              duration: 1.5.seconds,
              color: Colors.white,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStreakProgressBar(BuildContext context) {
    // Calculate week progress (0-6 with 6 being a full week)
    final weekProgress = widget.currentStreak % 7;
    final percentComplete = weekProgress / 7;
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Weekly Goal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${weekProgress}/7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Background (empty) progress bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Filled progress bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 8,
                width: (MediaQuery.of(context).size.width - 32) * percentComplete,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber,
                      Colors.orange.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A smaller version of the streak display for use in other contexts
class MiniStreakDisplay extends StatelessWidget {
  final int currentStreak;
  
  const MiniStreakDisplay({
    Key? key,
    required this.currentStreak,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme_utils.SeeAppTheme.primaryColor,
            theme_utils.SeeAppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange.shade400,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            currentStreak == 1 ? 'day' : 'days',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
