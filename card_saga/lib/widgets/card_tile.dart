import 'dart:math' as math;

import 'package:flutter/material.dart';

class CardTile extends StatefulWidget {
  final bool revealed;
  final String content;
  final VoidCallback onTap;

  const CardTile({
    Key? key,
    required this.revealed,
    required this.content,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
      value: widget.revealed ? 1.0 : 0.0,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(CardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed != oldWidget.revealed) {
      if (widget.revealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backSide = Container(
      key: const ValueKey(false),
      decoration: BoxDecoration(
        color: Colors.teal.shade400,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.question_mark_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );

    final frontSide = Container(
      key: const ValueKey(true),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            widget.content,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print("Lỗi tải ảnh: ${widget.content} - $error");
              return const Icon(Icons.broken_image,
                  size: 30, color: Colors.grey);
            },
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;

          final showFront = angle > (math.pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: showFront
                ? Transform(
                    transform: Matrix4.rotationY(math.pi),
                    alignment: Alignment.center,
                    child: frontSide,
                  )
                : backSide,
          );
        },
      ),
    );
  }
}
