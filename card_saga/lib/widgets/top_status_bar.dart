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
  final bool showGalleryButton;
  final bool showCoinsAndStars;
  final bool showSettings;

  const TopStatusBar({
    super.key,
    this.title,
    this.showShopButton = true,
    this.showBack = false,
    this.showGalleryButton = true,
    this.showCoinsAndStars = true,
    this.showSettings = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Popup cài đặt (Music + Language)
  void _showSettingsDialog(BuildContext context) {
    final gs = Provider.of<GameService>(context, listen: false);
    final langProvider = Provider.of<LangProvider>(context, listen: false);
    gs.playTapSound();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer2<GameService, LangProvider>(
          builder: (context, gs, lang, child) {
            final t =
                lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFFFFF0F5),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings, color: Colors.pinkAccent),
                  const SizedBox(width: 8),
                  Text(
                    t['setting'] ?? "Settings",
                    style: TextStyle(
                        color: Colors.pink.shade800,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Music Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(t['music'] ?? "Music",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      secondary: Icon(
                        gs.isMusicOn ? Icons.music_note : Icons.music_off,
                        color: gs.isMusicOn ? Colors.pinkAccent : Colors.grey,
                      ),
                      value: gs.isMusicOn,
                      activeColor: Colors.pinkAccent,
                      onChanged: (bool value) {
                        gs.playTapSound();
                        gs.toggleMusic();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Language Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading:
                          const Icon(Icons.language, color: Colors.pinkAccent),
                      title: Text(t['change_language'] ?? "Language",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pinkAccent),
                        ),
                        child: Text(
                          lang.locale.languageCode.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      onTap: () {
                        gs.playTapSound();
                        lang.toggle();
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    gs.playTapSound();
                    Navigator.pop(context);
                  },
                  child: Text(t['close'] ?? "Close",
                      style: const TextStyle(
                          color: Colors.pinkAccent, fontSize: 16)),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    // Compact text style
    final compactStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      elevation: 4.0,
      automaticallyImplyLeading: false,
      titleSpacing: 4, // Giảm spacing để tránh tràn
      // ============ BÊN TRÁI ============
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              tooltip: t['back'],
              onPressed: () {
                gs.playTapSound();
                Navigator.pop(context);
              },
            )
          : (showSettings
              ? IconButton(
                  icon:
                      const Icon(Icons.settings, color: Colors.white, size: 22),
                  tooltip: t['setting'] ?? 'Settings',
                  onPressed: () => _showSettingsDialog(context),
                )
              : null),

      // ============ TITLE: "Map" ============
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            )
          : null,

      // ============ BÊN PHẢI ============
      actions: [
        // Coins
        if (showCoinsAndStars) ...[
          const Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
          const SizedBox(width: 3),
          AnimatedCount(count: gs.user.coins, style: compactStyle),
          const SizedBox(width: 10),

          // Stars
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 3),
          AnimatedCount(count: gs.user.stars, style: compactStyle),
          const SizedBox(width: 8),
        ],

        // Puzzle Gallery Button
        if (showGalleryButton)
          IconButton(
            icon: const Icon(Icons.extension, color: Colors.white, size: 22),
            tooltip: t['view_puzzles'] ?? 'Puzzles',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () {
              gs.playTapSound();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PuzzleGalleryScreen()));
            },
          ),

        // Shop Button
        if (showShopButton)
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white, size: 22),
            tooltip: t['view_shop'] ?? 'Shop',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () {
              gs.playTapSound();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()));
            },
          ),

        const SizedBox(width: 4), // Padding cuối
      ],
    );
  }
}
