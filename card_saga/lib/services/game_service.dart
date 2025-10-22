import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/level.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../models/puzzle_piece.dart';
import '../services/level_generator.dart';
import '../services/puzzle_service.dart';

class LevelCompletionResult {
  final List<PuzzlePiece> droppedPieces;
  final List<PuzzlePiece> milestonePieces;
  LevelCompletionResult(
      {this.droppedPieces = const [], this.milestonePieces = const []});
}

class GameService extends ChangeNotifier {
  UserData user = UserData(coins: 100, stars: 0);
  final LevelGenerator _gen = LevelGenerator();
  final List<Level> levels = [];
  final PuzzleService puzzleService = PuzzleService();
  int doubleCoinsPlaysLeft = 0;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isGeneratingMore = false;

  final List<String> biomeOrder = [
    'emoji',
    'fruit_vegetables',
  ];

  static const int biomeSize = 10;

  final Map<String, List<String>> decorationAssetsByBiome = {};

  static const Map<int, List<String>> starMilestoneRewards = {
    10: ['1_0_0'],
    25: ['2_0_0'],
    50: ['3_0_0', '4_0_0'],
    100: ['5_0_0'],
  };

  GameService() {
    levels.add(_gen.firstLevel());
    generateMoreLevels(4);
    _initPuzzles();
  }

  Future<void> _initPuzzles() async {
    try {
      await puzzleService.loadPuzzles();
      await _loadDecorationAssets();
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDecorationAssets() async {
    try {
      decorationAssetsByBiome.clear();
      for (final biomeName in biomeOrder) {
        decorationAssetsByBiome[biomeName] = [];
      }

      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);

      final allAssetPaths = manifestMap.keys;

      for (final path in allAssetPaths) {
        for (final biomeName in biomeOrder) {
          if (path.startsWith('assets/imgs/$biomeName/')) {
            decorationAssetsByBiome[biomeName]?.add(path);
            break;
          }
        }
      }

      debugPrint('Đã tải và phân loại assets: $decorationAssetsByBiome');
    } catch (e) {
      debugPrint('Lỗi khi tải ảnh trang trí: $e');
    }
  }

  List<String> getAssetsForLevel(int levelId) {
    final int biomeIndex = (levelId - 1) ~/ biomeSize;

    if (biomeOrder.isEmpty) return [];

    final String biomeName = biomeOrder[biomeIndex % biomeOrder.length];

    return decorationAssetsByBiome[biomeName] ?? [];
  }

  final List<Item> shopItems = [
    Item(
        id: "freeze",
        name: "Freeze Time",
        type: ItemType.freezeTime,
        price: 50),
    Item(
        id: "double",
        name: "Double Coins (3 levels)",
        type: ItemType.doubleCoins,
        price: 80),
    Item(
        id: "piece",
        name: "World Piece",
        type: ItemType.worldPiece,
        price: 120),
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
    if (_isGeneratingMore) return;
    _isGeneratingMore = true;

    for (int i = 0; i < count; i++) {
      levels.add(_gen.generateNext(levels.last));
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isGeneratingMore = false;
    });
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

  List<PuzzlePiece> _checkStarMilestones(int oldStars, int newStars) {
    final rewards = <PuzzlePiece>[];
    starMilestoneRewards.forEach((starGoal, pieceIds) {
      if (oldStars < starGoal && newStars >= starGoal) {
        for (final pieceId in pieceIds) {
          final piece = puzzleService.getSpecialPieceById(pieceId);
          if (piece != null &&
              !user.puzzlePieces.any((p) => p.id == piece.id)) {
            rewards.add(piece);
          }
        }
      }
    });
    return rewards;
  }

  Future<LevelCompletionResult> completeLevel(
    BuildContext context,
    int id,
    int stars,
    int coins,
  ) async {
    if (doubleCoinsPlaysLeft > 0) {
      coins *= 2;
      doubleCoinsPlaysLeft--;
    }
    addCoins(coins);

    final int oldTotalStars = user.stars;
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

    final List<PuzzlePiece> dropped = puzzleService.dropRandomPieces();
    final List<PuzzlePiece> milestones =
        _checkStarMilestones(oldTotalStars, user.stars);

    puzzleService.dropRandomPiecesWithEffect(context, dropped);

    final allNewPieces = [...dropped, ...milestones];
    for (final piece in allNewPieces) {
      if (!user.puzzlePieces.any((p) => p.id == piece.id)) {
        piece.collected = true;
        user.puzzlePieces.add(piece);
      }
    }

    notifyListeners();

    return LevelCompletionResult(
      droppedPieces: dropped,
      milestonePieces: milestones,
    );
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
            owned: 1);
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
        doubleCoinsPlaysLeft += 3;
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}
