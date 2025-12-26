import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart';

class SeeLogo extends StatefulWidget {
  final double size;
  final bool interactive;
  final bool animate;
  final bool showText;
  
  const SeeLogo({
    Key? key,
    this.size = 100,
    this.interactive = true,
    this.animate = true,
    this.showText = false,
  }) : super(key: key);

  @override
  State<SeeLogo> createState() => _SeeLogoState();
}

class _SeeLogoState extends State<SeeLogo> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _heartbeatController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartbeatAnimation;
  
  bool _isHovering = false;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation (subtle pulsing of the entire logo)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _pulseAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Setup heartbeat animation (pulsing of the heart)
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _heartbeatAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.13), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.13, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
    
    if (widget.animate) {
      // Start animations
      _pulseController.repeat(reverse: true);
      
      // Heartbeat on intervals
      _scheduleNextHeartbeat();
    }
  }
  
  void _scheduleNextHeartbeat() {
    if (!mounted) return;
    
    // Random interval between 4-8 seconds
    final interval = 4000 + math.Random().nextInt(4000);
    
    Future.delayed(Duration(milliseconds: interval), () {
      if (mounted && widget.animate) {
        _heartbeatController.forward(from: 0.0).then((_) {
          _scheduleNextHeartbeat();
        });
      }
    });
  }
  
  void _triggerInteraction() {
    if (!widget.interactive || !mounted) return;
    
    // Trigger a heartbeat
    _heartbeatController.forward(from: 0.0);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MouseRegion(
          onEnter: (_) {
            if (widget.interactive) {
              setState(() => _isHovering = true);
            }
          },
          onExit: (_) {
            if (widget.interactive) {
              setState(() {
                _isHovering = false;
                _isPressed = false;
              });
            }
          },
          child: GestureDetector(
            onTapDown: (_) {
              if (widget.interactive) {
                setState(() => _isPressed = true);
                _triggerInteraction();
              }
            },
            onTapUp: (_) {
              if (widget.interactive) {
                setState(() => _isPressed = false);
              }
            },
            onTapCancel: () {
              if (widget.interactive) {
                setState(() => _isPressed = false);
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController, 
                _heartbeatController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animate ? _pulseAnimation.value : 1.0,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: _SeeLogoPainter(
                        heartScale: widget.animate ? _heartbeatAnimation.value : 1.0,
                        isHovering: _isHovering,
                        isPressed: _isPressed,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showText) ...[
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              "SEE",
              style: TextStyle(
                color: SeeAppTheme.primaryColor,
                fontFamily: SeeAppTheme.primaryFont,
                fontWeight: FontWeight.bold,
                fontSize: (widget.size * 0.3).clamp(12.0, 24.0),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _SeeLogoPainter extends CustomPainter {
  final double heartScale;
  final bool isHovering;
  final bool isPressed;
  
  _SeeLogoPainter({
    required this.heartScale,
    required this.isHovering,
    required this.isPressed,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    
    // Draw the teal arc at top (updated from yellow)
    final arcPaint = Paint()
      ..color = SeeAppTheme.secondaryColor // Now teal instead of yellow
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;
    
    // Add gradient effect to the arc
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final Gradient arcGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        SeeAppTheme.secondaryColor,
        SeeAppTheme.secondaryColor.withOpacity(0.8),
      ],
    );
    
    final arcGradientPaint = Paint()
      ..shader = arcGradient.createShader(arcRect)
      ..style = PaintingStyle.fill;
    
    canvas.drawArc(
      arcRect,
      -math.pi, // Start from top-left
      -math.pi, // Semi-circle to top-right
      true,
      arcGradientPaint,
    );
    
    // Draw the blue eye shape
    final eyePaint = Paint()
      ..color = SeeAppTheme.primaryColor
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;
    
    // Create eye shape path
    final eyePath = Path();
    eyePath.addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Draw eye
    canvas.drawPath(eyePath, eyePaint);
    
    // Draw white inner oval
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.7,
        height: size.height * 0.5,
      ),
      innerPaint,
    );
    
    // Add a subtle shadow/depth to the heart
    if (isHovering || isPressed) {
      final shadowPaint = Paint()
        ..color = SeeAppTheme.accentColor.withOpacity(isPressed ? 0.4 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawPath(
        _createHeartPath(
          center: center,
          size: Size(size.width * 0.35 * heartScale, size.height * 0.35 * heartScale),
          offset: const Offset(0, 0),
        ),
        shadowPaint,
      );
    }
    
    // Draw the heart
    final heartPaint = Paint()
      ..color = SeeAppTheme.accentColor // Now a brighter red
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(
      _createHeartPath(
        center: center,
        size: Size(size.width * 0.3 * heartScale, size.height * 0.3 * heartScale),
        offset: const Offset(0, 0),
      ),
      heartPaint,
    );
  }
  
  Path _createHeartPath({
    required Offset center,
    required Size size,
    required Offset offset,
  }) {
    final width = size.width;
    final height = size.height;
    final x = center.dx + offset.dx;
    final y = center.dy + offset.dy;
    
    final path = Path();
    
    // Starting point at the bottom peak of the heart
    path.moveTo(x, y + height / 2);
    
    // Draw the right half of the heart
    path.cubicTo(
      x, y + height / 2, // Current point
      x + width / 2, y, // Control point 1
      x, y - height / 2, // Destination point
    );
    
    // Draw the left half of the heart
    path.cubicTo(
      x, y - height / 2, // Current point
      x - width / 2, y, // Control point 1
      x, y + height / 2, // Back to starting point
    );
    
    return path;
  }
  
  @override
  bool shouldRepaint(_SeeLogoPainter oldDelegate) {
    return oldDelegate.heartScale != heartScale ||
           oldDelegate.isHovering != isHovering ||
           oldDelegate.isPressed != isPressed;
  }
}