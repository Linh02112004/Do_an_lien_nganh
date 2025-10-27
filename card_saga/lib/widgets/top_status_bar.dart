import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../screens/shop_screen.dart';
import '../screens/puzzle_gallery_screen.dart';

class AnimatedCount extends StatefulWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(begin: _previousCount, end: widget.count)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _previousCount = oldWidget.count;
      _animation = IntTween(begin: _previousCount, end: widget.count)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(_animation.value.toString(), style: widget.style);
      },
    );
  }
}

class TopStatusBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showShopButton;
  final bool showBack;

  const TopStatusBar({
    super.key,
    this.title,
    this.showShopButton = true,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        );

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      elevation: 4.0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              tooltip: t['back'],
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          const Spacer(),
          const Icon(Icons.monetization_on, color: Colors.yellow, size: 24),
          const SizedBox(width: 4),
          AnimatedCount(
            count: gs.user.coins,
            style: textStyle,
          ),
          const SizedBox(width: 16),
          const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
          const SizedBox(width: 4),
          AnimatedCount(
            count: gs.user.stars,
            style: textStyle,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language, color: Colors.white),
          onPressed: () => lang.toggle(),
        ),
        IconButton(
          icon: const Icon(Icons.extension, color: Colors.white),
          tooltip: t['view_puzzles'] ?? 'View Puzzles',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PuzzleGalleryScreen()),
            );
          },
        ),
        if (showShopButton)
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
          ),
      ],
    );
  }
}
