import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/item.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t['back'],
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['shop_title'] ?? 'Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => lang.toggle(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: gs.shopItems.length,
        itemBuilder: (context, i) {
          final item = gs.shopItems[i];
          final owned = gs.user.inventory[item.id]?.owned ?? 0;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(
                item.type == ItemType.freezeTime
                    ? Icons.ac_unit
                    : item.type == ItemType.doubleCoins
                        ? Icons.monetization_on
                        : Icons.public,
                color: Colors.pink,
              ),
              title: Text(
                item.type == ItemType.freezeTime
                    ? (t['freeze_time'] ?? 'Freeze Time')
                    : item.type == ItemType.doubleCoins
                        ? (t['double_coins'] ?? 'Double Coins (3 levels)')
                        : (t['world_piece'] ?? 'World Piece'),
              ),
              subtitle: Text(
                "${t['coins'] ?? 'Coins'}: ${item.price} | ${t['owned'] ?? 'Owned'}: $owned",
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  final success = gs.buyItem(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "${t['purchased']} "
                                "${item.type == ItemType.freezeTime ? t['freeze_time'] : item.type == ItemType.doubleCoins ? t['double_coins'] : t['world_piece']}"
                            : (t['not_enough_coins'] ?? 'Not enough coins'),
                      ),
                    ),
                  );
                },
                child: Text(t['buy'] ?? 'Buy'),
              ),
            ),
          );
        },
      ),
    );
  }
}
