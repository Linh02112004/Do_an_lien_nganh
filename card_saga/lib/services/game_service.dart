import 'package:flutter/material.dart';
import '../models/level.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../services/level_generator.dart';

class GameService extends ChangeNotifier {
  UserData user = UserData(coins: 100, stars: 0);

  final LevelGenerator _gen = LevelGenerator();
  final List<Level> levels = [];

  int doubleCoinsPlaysLeft = 0; // số lượt còn lại được x2 xu

  GameService() {
    levels.add(_gen.firstLevel());
    generateMoreLevels(4);
  }

  final List<Item> shopItems = [
    Item(
      id: "freeze",
      name: "Freeze Time",
      type: ItemType.freezeTime,
      price: 50,
    ),
    Item(
      id: "double",
      name: "Double Coins (3 levels)",
      type: ItemType.doubleCoins,
      price: 80,
    ),
    Item(
      id: "piece",
      name: "World Piece",
      type: ItemType.worldPiece,
      price: 120,
    ),
  ];

  void addCoins(int c) {
    user.coins += c;
    notifyListeners();
  }

  void spendCoins(int c) {
    user.coins = (user.coins - c).clamp(0, 999999);
    notifyListeners();
  }

  void addStars(int s) {
    user.stars += s;
    notifyListeners();
  }

  void generateMoreLevels([int count = 5]) {
    for (int i = 0; i < count; i++) {
      levels.add(_gen.generateNext(levels.last));
    }
    notifyListeners();
  }

  void unlockNext(int currentLevelId) {
    final idx = levels.indexWhere((l) => l.id == currentLevelId);
    if (idx >= 0) {
      if (idx + 1 >= levels.length) {
        generateMoreLevels(1);
      }
      levels[idx + 1].unlocked = true;
      notifyListeners();
    }
  }

  void completeLevel(int id, int stars, int coins) {
    if (doubleCoinsPlaysLeft > 0) {
      coins *= 2;
      doubleCoinsPlaysLeft--;
    }

    addCoins(coins);

    final idx = levels.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      final level = levels[idx];

      if (stars > level.stars) {
        final diff = stars - level.stars;
        addStars(diff);
        level.stars = stars;
      }

      unlockNext(id);
    }

    notifyListeners();
  }

  bool buyItem(Item item) {
    if (user.coins >= item.price) {
      spendCoins(item.price);

      if (user.inventory.containsKey(item.id)) {
        user.inventory[item.id]!.owned++;
      } else {
        user.inventory[item.id] = Item(
          id: item.id,
          name: item.name,
          type: item.type,
          price: item.price,
          owned: 1,
        );
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  bool useItem(String id) {
    final item = user.inventory[id];
    if (item != null && item.owned > 0) {
      item.owned--;

      if (item.type == ItemType.doubleCoins) {
        doubleCoinsPlaysLeft += 3; // cộng dồn thêm 3 lượt x2 xu
      }

      notifyListeners();
      return true;
    }
    return false;
  }
}
