import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/level.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../models/theme.dart';
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
  // Quản lý Theme
  List<GameTheme> _availableThemes = [];
  List<GameTheme> get availableThemes => _availableThemes;

  String _currentThemeId = 'default';
  GameTheme get currentTheme =>
      _availableThemes.firstWhere((t) => t.id == _currentThemeId,
          orElse: () => _availableThemes.first);

  List<String> _unlockedThemeIds = ['default'];
  List<String> get unlockedThemeIds => _unlockedThemeIds;

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
    _initializeGameData();
  }

  Future<void> _initializeGameData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await puzzleService.loadPuzzles();
      await _loadDecorationAssets();
      await _loadThemes();
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo dữ liệu game: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadThemes() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestJson);
    final allAssetPaths = manifestMap.keys.toList();

    final emojiPaths =
        allAssetPaths.where((p) => p.startsWith('assets/imgs/emoji/')).toList();
    final fruitPaths = allAssetPaths
        .where((p) => p.startsWith('assets/imgs/fruit_vegetables/'))
        .toList();
    final defaultPaths = emojiPaths.isNotEmpty
        ? emojiPaths.sublist(0, (emojiPaths.length / 2).ceil())
        : <String>[];

    _availableThemes = [
      GameTheme(
        id: 'default',
        nameKey: 'theme_default',
        requiredStars: 0,
        isDefault: true,
        cardImagePaths: defaultPaths,
        puzzleImageIds: [1, 2],
      ),
      GameTheme(
        id: 'emoji',
        nameKey: 'theme_emoji',
        requiredStars: 15,
        cardImagePaths: emojiPaths,
        puzzleImageIds: [3, 4, 5],
      ),
      GameTheme(
        id: 'fruits',
        nameKey: 'theme_fruits',
        requiredStars: 40,
        cardImagePaths: fruitPaths,
        puzzleImageIds: [6, 7, 8, 9, 10],
      ),
      // Thêm các theme khác nếu có...
    ];

    _unlockedThemeIds =
        _availableThemes.where((t) => t.isDefault).map((t) => t.id).toList();

    _currentThemeId = _availableThemes
        .firstWhere((t) => t.isDefault, orElse: () => _availableThemes.first)
        .id;

    debugPrint('Themes đã được tải: ${_availableThemes.length} themes.');
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

  List<String> getDecorationAssetsForLevel(int levelId) {
    final int biomeIndex = (levelId - 1) ~/ biomeSize;
    if (biomeOrder.isEmpty) return [];
    final String biomeName = biomeOrder[biomeIndex % biomeOrder.length];
    return decorationAssetsByBiome[biomeName] ?? [];
  }

  List<String> getCardAssetsForCurrentTheme() {
    final theme = currentTheme;
    if (theme.cardImagePaths.isEmpty) {
      debugPrint("Cảnh báo: Theme '${theme.id}' không có ảnh thẻ nào.");
      return ['assets/imgs/placeholder.png'];
    }
    return List<String>.from(theme.cardImagePaths);
  }

  void setCurrentTheme(String themeId) {
    if (_unlockedThemeIds.contains(themeId) &&
        _availableThemes.any((t) => t.id == themeId)) {
      _currentThemeId = themeId;
      debugPrint("Đã chuyển sang theme: $_currentThemeId");
      notifyListeners();
    } else {
      debugPrint(
          "Không thể chuyển sang theme '$themeId': Chưa mở khóa hoặc không tồn tại.");
    }
  }

  bool isThemeUnlocked(String themeId) {
    return _unlockedThemeIds.contains(themeId);
  }

  bool unlockTheme(String themeId) {
    final theme = _availableThemes.firstWhereOrNull((t) => t.id == themeId);
    if (theme == null) {
      debugPrint("Theme '$themeId' không tồn tại.");
      return false;
    }
    if (isThemeUnlocked(themeId)) {
      debugPrint("Theme '$themeId' đã được mở khóa rồi.");
      return true;
    }
    if (user.stars >= theme.requiredStars) {
      _unlockedThemeIds.add(themeId);
      debugPrint("Đã mở khóa theme: '$themeId'");
      notifyListeners();
      return true;
    } else {
      debugPrint(
          "Không đủ sao để mở khóa theme '$themeId'. Cần ${theme.requiredStars}, đang có ${user.stars}");
      return false;
    }
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

    _availableThemes
        .where((t) => !isThemeUnlocked(t.id))
        .forEach((themeToUnlock) {
      if (user.stars >= themeToUnlock.requiredStars) {
        unlockTheme(themeToUnlock.id);
        // Có thể thêm thông báo cho người dùng tại đây
      }
    });

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
