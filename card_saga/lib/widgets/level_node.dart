import 'package:flutter/material.dart';
import '../models/level.dart';

// --- WIDGET NGÔI SAO CÓ HIỆU ỨNG (Giữ nguyên) ---
class AnimatedStar extends StatefulWidget {
  final bool isFilled;
  final int delayMilliseconds;

  const AnimatedStar({
    super.key,
    required this.isFilled,
    this.delayMilliseconds = 0,
  });

  @override
  State<AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMilliseconds), () {
      if (mounted && widget.isFilled) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFilled && !oldWidget.isFilled) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.isFilled ? Icons.star_rounded : Icons.star_border_rounded,
        size: 18,
        color: widget.isFilled ? Colors.amber.shade600 : Colors.grey.shade400,
      ),
    );
  }
}

// --- WIDGET LEVEL NODE (ĐÃ THÊM didUpdateWidget) ---
class LevelNode extends StatefulWidget {
  final Level level;
  final VoidCallback onTap;
  final bool isNextPlayable;

  const LevelNode({
    super.key,
    required this.level,
    required this.onTap,
    this.isNextPlayable = false,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isNextPlayable) {
      _controller.repeat(reverse: true);
    }
  }

  // --- PHẦN SỬA LỖI QUAN TRỌNG NHẤT ĐƯỢC THÊM VÀO ĐÂY ---
  @override
  void didUpdateWidget(covariant LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kiểm tra xem trạng thái isNextPlayable có thay đổi không
    if (widget.isNextPlayable != oldWidget.isNextPlayable) {
      if (widget.isNextPlayable) {
        // Nếu BÂY GIỜ nó là màn tiếp theo -> Bắt đầu animation
        _controller.repeat(reverse: true);
      } else {
        // Nếu nó KHÔNG CÒN là màn tiếp theo -> Dừng animation và reset
        _controller.stop();
        _controller.reset(); // Đưa kích thước về 1.0
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
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: widget.level.unlocked ? widget.onTap : null,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.level.unlocked
                    ? const Color(0xFFFFC1E3)
                    : const Color(0xFFBDBDBD),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.level.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black26)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (starIndex) {
            return AnimatedStar(
              isFilled: widget.level.stars > starIndex,
              delayMilliseconds: starIndex * 200,
            );
          }),
        ),
      ],
    );
  }
}
