import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/item.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../models/theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final items = gs.shopItems;
    final themes = gs.availableThemes.where((t) => !t.isDefault).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: t['back'],
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['shop_title'] ?? 'Shop',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => lang.toggle(),
          ),
        ],
      ),
      body: ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount:
              items.length + themes.length + 2, // +2 cho tiêu đề sections
          separatorBuilder: (context, index) => const Divider(), // Ngăn cách
          itemBuilder: (context, index) {
            // --- Tiêu đề Mục Vật phẩm ---
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  t['shop_items_title'] ??
                      'Items', // Thêm key 'shop_items_title' vào Strings
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

              // Lấy tên item đã dịch
              String itemName = '';
              switch (item.type) {
                case ItemType.freezeTime:
                  itemName = t['freeze_time'] ?? 'Freeze Time';
                  break;
                case ItemType.doubleCoins:
                  itemName = t['double_coins'] ?? 'Double Coins...';
                  break;
                case ItemType
                    .worldPiece: // Nếu bạn vẫn giữ world piece trong shop
                  itemName = t['world_piece'] ?? 'World Piece';
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

                return ListTile(
                    leading: const Icon(Icons.palette,
                        color: Colors.purple, size: 30), // Icon cho theme
                    title: Text(t[theme.nameKey] ?? theme.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)), // Lấy tên từ Strings
                    subtitle: Text(
                      "${t['stars'] ?? 'Stars'} required: ${theme.requiredStars}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: isUnlocked
                        ? ElevatedButton.icon(
                            // Nút chọn theme nếu đã mở khóa
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen),
                            onPressed: gs.currentTheme.id == theme.id
                                ? null
                                : () {
                                    // Vô hiệu hóa nếu đang là theme hiện tại
                                    gs.setCurrentTheme(theme.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Switched to ${t[theme.nameKey] ?? theme.id} theme')),
                                    );
                                  },
                            icon: Icon(
                                gs.currentTheme.id == theme.id
                                    ? Icons.check_circle
                                    : Icons.swap_horiz,
                                size: 18),
                            label: Text(gs.currentTheme.id == theme.id
                                ? t['selected'] ?? 'Selected'
                                : t['select'] ??
                                    'Select') // Thêm key 'selected', 'select'
                            )
                        : ElevatedButton.icon(
                            // Nút mở khóa nếu chưa mở khóa
                            style: ElevatedButton.styleFrom(
                                backgroundColor: canUnlock
                                    ? Colors.pinkAccent
                                    : Colors.grey),
                            onPressed: canUnlock
                                ? () {
                                    final success = gs.unlockTheme(theme.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(success
                                              ? '${t['unlocked']} ${t[theme.nameKey] ?? theme.id}!'
                                              : 'Failed to unlock')),
                                    );
                                  }
                                : null, // Vô hiệu hóa nút nếu không đủ sao
                            icon: const Icon(Icons.lock_open, size: 18),
                            label: Text(t['unlock'] ?? 'Unlock'),
                          ));
              } else {
                return const SizedBox
                    .shrink(); // Trường hợp index ngoài phạm vi
              }
            }
          }),
    );
  }
}
