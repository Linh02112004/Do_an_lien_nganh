import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../screens/shop_screen.dart';

class TopStatusBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showShopButton;
  final bool showBack;

  const TopStatusBar({
    super.key,
    this.title,
    this.showShopButton = true,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    return AppBar(
      backgroundColor: Colors.pinkAccent,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: t['back'],
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const Spacer(),
          const Icon(Icons.monetization_on, color: Colors.yellow),
          const SizedBox(width: 4),
          Text("${gs.user.coins}"),
          const SizedBox(width: 16),
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 4),
          Text("${gs.user.stars}"),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: () => lang.toggle(),
        ),
        if (showShopButton)
          IconButton(
            icon: const Icon(Icons.store),
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
