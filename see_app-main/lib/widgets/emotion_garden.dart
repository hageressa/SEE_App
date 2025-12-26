import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/utils/theme.dart';

/// A widget that displays a growing plant based on the user's mission streak
/// Implements the "Emotional Garden" metaphor where consistent practice helps emotions grow
class EmotionGarden extends StatefulWidget {
  final MissionStreak? streak;
  final double? height;
  final double? width;
  final double maxWidth;
  
  const EmotionGarden({
    Key? key, 
    this.streak,
    this.height,
    this.width,
    this.maxWidth = 140,
  }) : super(key: key);
  
  @override
  State<EmotionGarden> createState() => _EmotionGardenState();
}

class _EmotionGardenState extends State<EmotionGarden> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _breatheAnimation;
  bool _isHovering = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
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
    final streakDays = widget.streak?.currentStreak ?? 0;
    final growthStage = _getGrowthStage(streakDays);
    final stageColor = _getStageColor(growthStage);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: widget.height ?? 150,
        ),
        child: AspectRatio(
          aspectRatio: 0.8, // height:width ratio
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  stageColor.withOpacity(0.3),
                ],
                stops: const [0.3, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: stageColor.withOpacity(_isHovering ? 0.4 : 0.2),
                  blurRadius: _isHovering ? 15 : 8,
                  spreadRadius: _isHovering ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: stageColor.withOpacity(_isHovering ? 0.5 : 0.3),
                width: 2.0,
              ),
            ),
            child: Stack(
              children: [
                // Background decoration with enhanced visuals
                if (growthStage != GrowthStage.seed)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundDecorationPainter(
                        stageColor: stageColor.withOpacity(0.1),
                        growthStage: growthStage,
                        decorationDensity: _isHovering ? 1.2 : 1.0,
                      ),
                    ),
                  ),
                
                // Content with improved styling
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Garden title with enhanced style
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: stageColor.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: stageColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_florist,
                                color: stageColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Emotional Garden',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stageColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Plant visualization with enhanced animation
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _breatheAnimation.value,
                              child: child,
                            );
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return _buildPlant(growthStage, constraints)
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 800.ms,
                                  curve: Curves.elasticOut,
                                );
                            },
                          ),
                        ),
                      ),
                      
                      // Growth message with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: stageColor.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: stageColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Text(
                              _getGrowthMessage(growthStage),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: stageColor.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: SeeAppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 10,
                                    color: SeeAppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${streakDays} ${streakDays == 1 ? 'day' : 'days'} of growth',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: SeeAppTheme.primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get color based on growth stage
  Color _getStageColor(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed:
        return Colors.brown;
      case GrowthStage.sprout:
        return SeeAppTheme.calmColor;
      case GrowthStage.growing:
        return Colors.green;
      case GrowthStage.flowering:
        return SeeAppTheme.joyColor;
      case GrowthStage.mature:
        return SeeAppTheme.primaryColor;
    }
  }
  
  /// Returns the appropriate plant widget based on growth stage and available space
  Widget _buildPlant(GrowthStage stage, BoxConstraints constraints) {
    // Scale factor to adjust plant size based on available space
    final double availableHeight = constraints.maxHeight;
    final scaleFactor = availableHeight / 150; // 150 is the reference height
    
    switch (stage) {
      case GrowthStage.seed:
        return _buildSeed(scaleFactor);
      case GrowthStage.sprout:
        return _buildSprout(scaleFactor);
      case GrowthStage.growing:
        return _buildGrowing(scaleFactor);
      case GrowthStage.flowering:
        return _buildFlowering(scaleFactor);
      case GrowthStage.mature:
        return _buildMature(scaleFactor);
    }
  }
  
  /// Build a seed (0 days)
  Widget _buildSeed(double scaleFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        Container(
          width: 20 * scaleFactor,
          height: 20 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            shape: BoxShape.circle,
          ),
        ),
        Container(
          height: 10 * scaleFactor,
          width: 40 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a small sprout (1-2 days)
  Widget _buildSprout(double scaleFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        Container(
          width: 8 * scaleFactor,
          height: 30 * scaleFactor,
          color: const Color(0xFF7CFC00), // Light green
        ),
        Container(
          width: 20 * scaleFactor,
          height: 20 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            shape: BoxShape.circle,
          ),
        ),
        Container(
          height: 10 * scaleFactor,
          width: 40 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a growing plant (3-6 days)
  Widget _buildGrowing(double scaleFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomPaint(
          size: Size(60 * scaleFactor, 80 * scaleFactor),
          painter: _LeafPainter(
            stemHeight: 60 * scaleFactor,
            leafCount: 2,
            leafSize: 20 * scaleFactor,
          ),
        ),
        Container(
          height: 10 * scaleFactor,
          width: 40 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a flowering plant (7-13 days)
  Widget _buildFlowering(double scaleFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomPaint(
          size: Size(80 * scaleFactor, 100 * scaleFactor),
          painter: _LeafPainter(
            stemHeight: 80 * scaleFactor,
            leafCount: 3,
            leafSize: 25 * scaleFactor,
            hasBud: true,
          ),
        ),
        Container(
          height: 10 * scaleFactor,
          width: 40 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a mature flowering plant (14+ days)
  Widget _buildMature(double scaleFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomPaint(
          size: Size(90 * scaleFactor, 110 * scaleFactor),
          painter: _LeafPainter(
            stemHeight: 90 * scaleFactor,
            leafCount: 4,
            leafSize: 30 * scaleFactor,
            hasBud: true,
            hasFlower: true,
          ),
        ),
        Container(
          height: 10 * scaleFactor,
          width: 40 * scaleFactor,
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513), // Brown
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Determine the growth stage based on streak days
  GrowthStage _getGrowthStage(int days) {
    if (days == 0) return GrowthStage.seed;
    if (days <= 2) return GrowthStage.sprout;
    if (days <= 6) return GrowthStage.growing;
    if (days <= 13) return GrowthStage.flowering;
    return GrowthStage.mature;
  }
  
  /// Get motivational message based on growth stage
  String _getGrowthMessage(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed:
        return 'Begin your journey';
      case GrowthStage.sprout:
        return 'First signs of growth!';
      case GrowthStage.growing:
        return 'Growing stronger';
      case GrowthStage.flowering:
        return 'Blossoming emotions';
      case GrowthStage.mature:
        return 'Emotional intelligence blooming!';
    }
  }
}

/// Custom painter for drawing a plant with stems and leaves
class _LeafPainter extends CustomPainter {
  final double stemHeight;
  final int leafCount;
  final double leafSize;
  final bool hasBud;
  final bool hasFlower;
  
  _LeafPainter({
    required this.stemHeight,
    required this.leafCount,
    required this.leafSize,
    this.hasBud = false,
    this.hasFlower = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF228B22) // Forest green
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final leafPaint = Paint()
      ..color = const Color(0xFF32CD32); // Lime green
    
    final flowerPaint = Paint()
      ..color = const Color(0xFFFF69B4); // Pink
    
    final centerX = size.width / 2;
    
    // Draw stem
    canvas.drawLine(
      Offset(centerX, size.height),
      Offset(centerX, size.height - stemHeight),
      stemPaint,
    );
    
    // Draw leaves
    final leafSpacing = stemHeight / (leafCount + 1);
    for (int i = 1; i <= leafCount; i++) {
      final isRight = i % 2 == 0;
      final leafY = size.height - (leafSpacing * i);
      
      final path = Path();
      path.moveTo(centerX, leafY);
      
      if (isRight) {
        path.quadraticBezierTo(
          centerX + leafSize, leafY - leafSize / 2,
          centerX + leafSize * 1.5, leafY,
        );
        path.quadraticBezierTo(
          centerX + leafSize, leafY + leafSize / 2,
          centerX, leafY,
        );
      } else {
        path.quadraticBezierTo(
          centerX - leafSize, leafY - leafSize / 2,
          centerX - leafSize * 1.5, leafY,
        );
        path.quadraticBezierTo(
          centerX - leafSize, leafY + leafSize / 2,
          centerX, leafY,
        );
      }
      
      canvas.drawPath(path, leafPaint);
    }
    
    // Draw bud
    if (hasBud) {
      canvas.drawCircle(
        Offset(centerX, size.height - stemHeight - 5),
        10,
        stemPaint..color = const Color(0xFF7CFC00), // Light green
      );
    }
    
    // Draw flower
    if (hasFlower) {
      final flowerCenter = Offset(centerX, size.height - stemHeight - 15);
      final petalRadius = 15.0;
      
      // Draw petals
      for (int i = 0; i < 8; i++) {
        final angle = i * (pi / 4);
        final x = petalRadius * 1.2 * cos(angle);
        final y = petalRadius * 1.2 * sin(angle);
        
        canvas.drawCircle(
          Offset(flowerCenter.dx + x, flowerCenter.dy + y),
          petalRadius,
          flowerPaint,
        );
      }
      
      // Draw center
      canvas.drawCircle(
        flowerCenter,
        12,
        Paint()..color = const Color(0xFFFFD700), // Gold
      );
    }
  }
  
  @override
  bool shouldRepaint(_LeafPainter oldDelegate) =>
      oldDelegate.stemHeight != stemHeight ||
      oldDelegate.leafCount != leafCount ||
      oldDelegate.leafSize != leafSize ||
      oldDelegate.hasBud != hasBud ||
      oldDelegate.hasFlower != hasFlower;
}

/// Background decoration painter for garden
class _BackgroundDecorationPainter extends CustomPainter {
  final Color stageColor;
  final GrowthStage growthStage;
  final double decorationDensity;
  
  _BackgroundDecorationPainter({
    required this.stageColor,
    required this.growthStage,
    required this.decorationDensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stageColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw background elements
    if (growthStage == GrowthStage.mature || growthStage == GrowthStage.flowering) {
      // Draw some subtle flower patterns in background
      for (int i = 0; i < 8; i++) {
        final x = size.width * (i % 3) / 3 + 10;
        final y = size.height * (i ~/ 3) / 3 + 10;
        
        // Draw small decorative elements
        canvas.drawCircle(Offset(x, y), 5, paint);
        
        // Draw little stems
        final path = Path()
          ..moveTo(x, y + 5)
          ..lineTo(x, y + 15);
        canvas.drawPath(path, paint);
      }
    } else if (growthStage == GrowthStage.growing) {
      // Draw some subtle dots for the growing stage
      for (int i = 0; i < 6; i++) {
        final x = size.width * (i % 3) / 3 + 15;
        final y = size.height * (i ~/ 3) / 3 + 15;
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_BackgroundDecorationPainter oldDelegate) =>
      oldDelegate.stageColor != stageColor ||
      oldDelegate.growthStage != growthStage ||
      oldDelegate.decorationDensity != decorationDensity;
}

/// Represents the growth stages of the plant
enum GrowthStage {
  seed,
  sprout,
  growing,
  flowering,
  mature,
}