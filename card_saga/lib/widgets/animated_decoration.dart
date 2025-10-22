import 'dart:math';
import 'package:flutter/material.dart';

enum AnimationType { float, rotate }

class AnimatedDecoration extends StatefulWidget {
  final String imagePath;
  final double size;
  final AnimationType animationType;

  const AnimatedDecoration({
    super.key,
    required this.imagePath,
    required this.size,
    this.animationType = AnimationType.float,
  });

  @override
  State<AnimatedDecoration> createState() => _AnimatedDecorationState();
}

class _AnimatedDecorationState extends State<AnimatedDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final random = Random();

    _controller = AnimationController(
      // Thời gian animation ngẫu nhiên để trông tự nhiên hơn
      duration: Duration(milliseconds: 2000 + random.nextInt(1500)),
      vsync: this,
    );

    if (widget.animationType == AnimationType.float) {
      // Animation di chuyển lên xuống
      _animation = Tween<double>(begin: -5.0, end: 5.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    } else {
      // Animation xoay
      _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }

    // Bắt đầu chạy lặp lại
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.animationType == AnimationType.float) {
          // Áp dụng hiệu ứng trôi nổi
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        } else {
          // Áp dụng hiệu ứng xoay
          return Transform.rotate(
            angle: _animation.value,
            child: child,
          );
        }
      },
      child: Image.asset(
        widget.imagePath,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
