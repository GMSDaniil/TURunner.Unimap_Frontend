// Add this widget to your map stack
import 'dart:math';

import 'package:flutter/material.dart';

class RainOverlay extends StatefulWidget {
  final bool isRaining;
  
  const RainOverlay({Key? key, required this.isRaining}) : super(key: key);
  
  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<RainDrop> _rainDrops = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _generateRainDrops();
    
    if (widget.isRaining) {
      _animationController.repeat();
    }
  }
  
  @override
  void didUpdateWidget(RainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRaining != oldWidget.isRaining) {
      if (widget.isRaining) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }
  
  void _generateRainDrops() {
    _rainDrops.clear();
    for (int i = 0; i < 70; i++) {
      _rainDrops.add(RainDrop(
        x: Random().nextDouble(),
        y: Random().nextDouble(),
        speed: 0.4 + Random().nextDouble() * 0.5,
        size: 1 + Random().nextDouble() * 2,
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isRaining) return SizedBox.shrink();
    
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: RainPainter(_rainDrops, _animationController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class RainDrop {
  final double x;
  final double y;
  final double speed;
  final double size;
  
  RainDrop({required this.x, required this.y, required this.speed, required this.size});
}

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;
  final double animationValue;
  
  RainPainter(this.rainDrops, this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF919191).withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (final drop in rainDrops) {
      final x = drop.x * size.width;
      final y = ((drop.y + animationValue * drop.speed) % 1.0) * size.height;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y + drop.size * 15),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}