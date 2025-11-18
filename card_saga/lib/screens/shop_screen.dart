import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/item.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../widgets/top_status_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final items = gs.shopItems;
    final themes = gs.availableThemes.toList();

    return Scaffold(
      appBar: TopStatusBar(
        title: t['shop_title'] ?? 'Shop',
        showBack: true,
        showCoinsAndStars: true,
        showGalleryButton: false,
        showShopButton: false,
      ),
      body: ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount: items.length + themes.length + 2,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            // --- Tiêu đề Mục Vật phẩm ---
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  t['shop_items_title'] ?? 'Items',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                  textAlign: TextAlign.center,
                ),
              );
            }
            // --- Hiển thị Vật phẩm ---
            else if (index <= items.length) {
              final itemIndex = index - 1;
              final item = items[itemIndex];
              final owned = gs.user.inventory[item.id]?.owned ?? 0;

              String itemName = '';
              switch (item.type) {
                case ItemType.freezeTime:
                  itemName = t['freeze_time'] ?? 'Freeze Time';
                  break;
                case ItemType.doubleCoins:
                  itemName = t['double_coins'] ?? 'Double Coins...';
                  break;
              }

              return ListTile(
                leading: Icon(
                  item.type == ItemType.freezeTime
                      ? Icons.ac_unit
                      : Icons.monetization_on,
                  color: Colors.blueAccent,
                  size: 30,
                ),
                title: Text(itemName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  "${t['coins'] ?? 'Coins'}: ${item.price} | ${t['owned'] ?? 'Owned'}: $owned",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                  onPressed: () {
                    final success = gs.buyItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? "${t['purchased']} $itemName"
                            : (t['not_enough_coins'] ?? 'Not enough coins')),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(t['buy'] ?? 'Buy'),
                ),
              );
            }
            // --- Tiêu đề Mục Chủ đề ---
            else if (index == items.length + 1) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  t['shop_themes_title'] ?? 'Themes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                  textAlign: TextAlign.center,
                ),
              );
            }
            // --- Hiển thị Chủ đề ---
            else {
              final themeIndex = index - items.length - 2;
              if (themeIndex < themes.length) {
                final theme = themes[themeIndex];
                final bool isUnlocked = gs.isThemeUnlocked(theme.id);
                final bool canUnlock = gs.user.stars >= theme.requiredStars;
                final bool isSelected = gs.currentTheme.id == theme.id;

                Widget trailingButton;

                if (isUnlocked) {
                  if (isSelected) {
                    trailingButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: null,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(t['selected'] ?? 'Selected'),
                    );
                  } else {
                    trailingButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent),
                      onPressed: () {
                        gs.setCurrentTheme(theme.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Switched to ${t[theme.nameKey] ?? theme.id} theme')),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(t['select'] ?? 'Select'),
                    );
                  }
                } else {
                  if (canUnlock) {
                    trailingButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent),
                      onPressed: () {
                        final success = gs.unlockTheme(theme.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(success
                                  ? '${t['unlocked']} ${t[theme.nameKey] ?? theme.id}!'
                                  : 'Failed to unlock')),
                        );
                      },
                      icon: const Icon(Icons.lock_open, size: 18),
                      label: Text(t['unlock'] ?? 'Unlock'),
                    );
                  } else {
                    trailingButton = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                      onPressed: null,
                      icon: const Icon(Icons.lock, size: 18),
                      label: Text(t['unlock'] ?? 'Unlock'),
                    );
                  }
                }

                return ListTile(
                  leading:
                      const Icon(Icons.palette, color: Colors.purple, size: 30),
                  title: Text(t[theme.nameKey] ?? theme.id,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    theme.id == 'emoji'
                        ? (t['theme_default'] ?? 'Default Theme')
                        : "${t['stars_required'] ?? 'Stars Required'}: ${theme.requiredStars}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: trailingButton,
                );
              } else {
                return const SizedBox.shrink();
              }
            }
          }),
    );
  }
}
