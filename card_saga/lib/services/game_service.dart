import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/level.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../models/theme.dart';
import '../models/puzzle_piece.dart';
import '../services/level_generator.dart';
import '../services/puzzle_service.dart';
import '../models/puzzle_image.dart';

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

  final AudioPlayer _bgmPlayer = AudioPlayer(); // Nhạc nền (loop)
  final AudioPlayer _resultPlayer = AudioPlayer(); // Kết quả vượt ải
  final AudioPlayer _sfxPlayer = AudioPlayer(); // Hiệu ứng

  bool _isMusicOn = true;
  bool get isMusicOn => _isMusicOn;

  int doubleCoinsPlaysLeft = 0;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isGeneratingMore = false;

  // Quản lý Theme
  List<GameTheme> _availableThemes = [];
  List<GameTheme> get availableThemes => _availableThemes;

  String _currentThemeId = 'emoji';
  GameTheme get currentTheme =>
      _availableThemes.firstWhere((t) => t.id == _currentThemeId,
          orElse: () => _availableThemes.first);

  List<String> _unlockedThemeIds = ['emoji'];
  List<String> get unlockedThemeIds => _unlockedThemeIds;

  // Lấy danh sách các PuzzleImage đã được mở khóa dựa trên theme
  List<PuzzleImage> get unlockedPuzzles {
    final unlockedPuzzleIds = _availableThemes
        .where((theme) => _unlockedThemeIds.contains(theme.id))
        .expand((theme) => theme.puzzleImageIds)
        .toSet();

    return puzzleService.puzzles
        .where((puzzle) => unlockedPuzzleIds.contains(puzzle.id))
        .toList();
  }

  final List<String> biomeOrder = [
    'emoji',
    'fruit_vegetables',
    'food',
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
    _initializeGameData();
  }

  //============== AUDIO LOGIC ==============
  Future<void> _initAudio() async {
    // cấu hình chế độ phát
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _resultPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    if (_isMusicOn) {
      _playBgm();
    }
  }

  Future<void> _playBgm() async {
    if (!_isMusicOn) {
      debugPrint("BGM: Nhạc nền đang tắt");
      return;
    }

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/bgm.mp3'), volume: 0.8);
      debugPrint("BGM: Nhạc nền bật thành công!"); //
    } catch (e) {
      debugPrint("Lỗi phát BGM: $e");
    }
  }

  Future<void> playResultMusic(bool isWin) async {
    // 1. Dừng BGM ngay lập tức
    await _bgmPlayer.stop();

    if (!_isMusicOn) return;

    try {
      final String file = isWin ? 'audio/win.mp3' : 'audio/lose.mp3';
      // 2. Phát nhạc kết quả
      await _resultPlayer.stop();
      await _resultPlayer.play(AssetSource(file), volume: 0.8);
    } catch (e) {
      debugPrint("Lỗi phát nhạc kết quả: $e");
    }
  }

  Future<void> resumeBgmAfterResult() async {
    await _resultPlayer.stop();

    if (_isMusicOn) {
      await _playBgm();
    }
  }

// Âm thanh tap
  Future<void> playTapSound() async {
    if (!_isMusicOn) return;
    try {
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop();
      }
      await _sfxPlayer.play(AssetSource('audio/tap.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint("Error playing tap: $e");
    }
  }

  // Âm thanh khi Mua thành công
  Future<void> playBoughtSound() async {
    if (!_isMusicOn) return;
    try {
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop();
      }
      await _sfxPlayer.play(AssetSource('audio/bought.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint("Error playing bought: $e");
    }
  }

  void toggleMusic() {
    _isMusicOn = !_isMusicOn;
    debugPrint("Toggle Music: $_isMusicOn");

    if (_isMusicOn) {
      _playBgm();
    } else {
      _bgmPlayer.stop();
      _resultPlayer.stop();
      _sfxPlayer.stop();
    }

    saveGame();
    notifyListeners();
  }

  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> data = {
        'user': user.toJson(),
        'levels': levels.map((l) => l.toJson()).toList(),
        'unlockedThemeIds': _unlockedThemeIds,
        'currentThemeId': _currentThemeId,
        'doubleCoinsPlaysLeft': doubleCoinsPlaysLeft,
        'isMusicOn': _isMusicOn,
      };

      await prefs.setString('game_save_data', json.encode(data));
      debugPrint(">>> [System] Game Saved Successfully!");
    } catch (e) {
      debugPrint(">>> [System] Error Saving Game: $e");
    }
  }

  Future<void> _initializeGameData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Load tài nguyên tĩnh
      await puzzleService.loadPuzzles();
      await _loadDecorationAssets();
      await _loadThemes();

      // 2. Khởi tạo Audio
      await _initAudio();

      // 3. Load dữ liệu Save
      final prefs = await SharedPreferences.getInstance();
      final String? saveString = prefs.getString('game_save_data');

      if (saveString != null) {
        debugPrint(">>> [System] Found Save File. Loading...");
        final Map<String, dynamic> data = json.decode(saveString);

        // Load User
        if (data['user'] != null) {
          final userJson = data['user'];
          user.coins = userJson['coins'] ?? 100;
          user.stars = userJson['stars'] ?? 0;

          if (userJson['inventory'] != null) {
            user.inventory.clear();
            for (var itemJson in userJson['inventory']) {
              final item = Item.fromJson(itemJson);
              user.inventory[item.id] = item;
            }
          }

          if (userJson['collectedPieceIds'] != null) {
            user.puzzlePieces.clear();
            final List<dynamic> savedIds = userJson['collectedPieceIds'];
            final allSystemPieces =
                puzzleService.puzzles.expand((p) => p.pieces);

            for (var savedId in savedIds) {
              final piece =
                  allSystemPieces.firstWhereOrNull((p) => p.id == savedId);
              if (piece != null) {
                piece.collected = true;
                user.puzzlePieces.add(piece);
              }
            }
          }
        }

        // Load Level
        if (data['levels'] != null) {
          levels.clear();
          for (var levelJson in data['levels']) {
            levels.add(Level.fromJson(levelJson));
          }
        }

        // Load Theme & Dữ liệu khác
        if (data['unlockedThemeIds'] != null) {
          _unlockedThemeIds = List<String>.from(data['unlockedThemeIds']);
        }
        if (data['currentThemeId'] != null) {
          _currentThemeId = data['currentThemeId'];
        }
        if (data['doubleCoinsPlaysLeft'] != null) {
          doubleCoinsPlaysLeft = data['doubleCoinsPlaysLeft'];
        }

        // Load BGM
        if (data['isMusicOn'] != null) {
          _isMusicOn = data['isMusicOn'];
        }
      } else {
        // New Game
        debugPrint(">>> [System] No Save File. Creating New Game.");
        levels.clear();
        levels.add(_gen.firstLevel());
        generateMoreLevels(4);
      }
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo dữ liệu game: $e');
      if (levels.isEmpty) {
        levels.add(_gen.firstLevel());
        generateMoreLevels(4);
      }
    } finally {
      _isLoading = false;
      notifyListeners();

      if (_isMusicOn) {
        await _playBgm(); // Đảm bảo BGM chạy nếu setting bật
      }
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
    final foodPaths =
        allAssetPaths.where((p) => p.startsWith('assets/imgs/food/')).toList();

    _availableThemes = [
      GameTheme(
        id: 'emoji',
        nameKey: 'theme_emoji',
        requiredStars: 0,
        isDefault: true,
        cardImagePaths: emojiPaths,
        puzzleImageIds: [1, 2],
      ),
      GameTheme(
        id: 'fruits',
        nameKey: 'theme_fruits',
        requiredStars: 15,
        cardImagePaths: fruitPaths,
        puzzleImageIds: [3, 4],
      ),
      GameTheme(
        id: 'food',
        nameKey: 'theme_food',
        requiredStars: 30,
        cardImagePaths: foodPaths,
        puzzleImageIds: [5, 6],
      ),
    ];

    if (_unlockedThemeIds.length == 1 && _unlockedThemeIds.first == 'emoji') {
      _unlockedThemeIds =
          _availableThemes.where((t) => t.isDefault).map((t) => t.id).toList();
    }

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
      saveGame();
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
    if (user.stars >= theme.requiredStars &&
        !_unlockedThemeIds.contains(themeId)) {
      _unlockedThemeIds.add(themeId);
      saveGame();
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
    saveGame();
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

    final unlockedPuzzleIds = _availableThemes
        .where((theme) => _unlockedThemeIds.contains(theme.id))
        .expand((theme) => theme.puzzleImageIds)
        .toSet();

    final List<PuzzlePiece> dropped =
        puzzleService.dropRandomPieces(allowedPuzzleIds: unlockedPuzzleIds);
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

    saveGame();
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
      playBoughtSound();
      saveGame();
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
      saveGame();
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _resultPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
