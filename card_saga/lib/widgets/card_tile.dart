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
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, child) {
          final angle = _flipAnim.value * 3.14159;
          final isFront = angle < 1.5708;

          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: isFront ? Colors.teal.shade400 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Transform(
                  transform: Matrix4.rotationY(isFront ? 0 : 3.14159),
                  alignment: Alignment.center,
                  child: isFront
                      ? const Icon(
                          Icons.help_outline,
                          size: 36,
                          color: Colors.white,
                        )
                      : Text(
                          widget.content,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
