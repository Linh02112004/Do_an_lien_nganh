import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/card_tile.dart';
import '../services/game_service.dart';
import '../utils/constants.dart';
import '../models/level.dart';
import '../providers/lang_provider.dart';
import '../widgets/top_status_bar.dart';

class LevelScreen extends StatefulWidget {
  final Level level;
  const LevelScreen({super.key, required this.level});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  List<String> _cards = [];

  List<int> _completed = [];
  List<int> _selected = [];
  Timer? _timer;
  int _timeLeft = 0;
  bool _gameOver = false;
  bool _isChecking = false;

  bool _isFrozen = false;
  Timer? _freezeTimer;
  int _freezeCountThisLevel = 0; // giới hạn 5 lần mỗi màn

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  void _initGame() {
    _timeLeft = widget.level.timeLimit;
    _generateCards();
    _startTimer();
  }

  void _generateCards() {
    final gameService = Provider.of<GameService>(context, listen: false);
    final int pairCount = widget.level.pairCount;

    final List<String> availableAssets =
        gameService.getCardAssetsForCurrentTheme();

    if (availableAssets.length < pairCount) {
      print(
          "Lỗi: Không đủ ảnh trong biome cho level ${widget.level.id}. Cần $pairCount, có ${availableAssets.length}");
      final List<String> pool = [];
      for (int i = 0; i < pairCount; i++) {
        pool.add("?");
        pool.add("?");
      }
      pool.shuffle(Random());
      _cards = pool;
    } else {
      availableAssets.shuffle(Random());
      final List<String> selectedImagePaths =
          availableAssets.sublist(0, pairCount);

      final List<String> pool = [];
      for (String imagePath in selectedImagePaths) {
        pool.add(imagePath);
        pool.add(imagePath);
      }
      pool.shuffle(Random());
      _cards = pool;
    }

    _completed = [];
    _selected = [];

    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_isFrozen) {
        return;
      }

      if (_timeLeft <= 0) {
        final langProvider = Provider.of<LangProvider>(context, listen: false);
        final langMap =
            langProvider.locale.languageCode == 'en' ? Strings.en : Strings.vi;
        _endGame(false, langMap);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  // hàm kích hoạt đóng băng thời gian
  void _activateFreezeTime(GameService gs, Map<String, String> t) {
    if (_isFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(t['freeze_already_active'] ?? "Freeze is already active!"),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_freezeCountThisLevel >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['max_freeze'] ?? "Max 5 freezes per level!"),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    final bool itemUsed = gs.useItem("freeze");
    if (!itemUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['not_enough_items'] ?? "No freeze items left!"),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _freezeCountThisLevel++;
    setState(() => _isFrozen = true);

    _freezeTimer?.cancel();

    // Hẹn giờ 20s để tắt đóng băng
    _freezeTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() => _isFrozen = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Text(t['freeze_used'] ?? "Freeze Time activated for 20s!"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // hàm kích hoạt nhân đôi xu thưởng
  void _activateDoubleCoins(GameService gs, Map<String, String> t) {
    if (gs.doubleCoinsPlaysLeft > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text(
            "${t['double_already_active'] ?? "Double Coins already active!"} ${t['plays_left'] ?? 'Plays left'}: ${gs.doubleCoinsPlaysLeft}"),
        duration: const Duration(seconds: 1),
      ));
      return;
    }

    final bool itemUsed = gs.useItem("double");
    if (!itemUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['not_enough_items'] ?? "No double coin items left!"),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.orangeAccent,
      content: Text(
          "${t['double_used'] ?? "Double Coins activated!"} ${t['plays_left'] ?? 'Plays left'}: ${gs.doubleCoinsPlaysLeft}"),
      duration: const Duration(seconds: 1),
    ));
  }

  void _onCardTap(int index) {
    if (_gameOver ||
        _isChecking ||
        _completed.contains(index) ||
        _selected.contains(index)) {
      return;
    }

    if (_selected.length < 2) {
      setState(() {
        _selected.add(index);
      });
    }

    if (_selected.length == 2) {
      _isChecking = true;
      final int a = _selected[0];
      final int b = _selected[1];

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        setState(() {
          if (_cards[a] == _cards[b]) {
            _completed.add(a);
            _completed.add(b);
          }

          _selected.clear();

          _isChecking = false;
        });

        if (_completed.length == _cards.length) {
          final langProvider =
              Provider.of<LangProvider>(context, listen: false);
          final langMap = langProvider.locale.languageCode == 'en'
              ? Strings.en
              : Strings.vi;
          _endGame(true, langMap);
        }
      });
    }
  }

  Future<void> _endGame(bool won, Map<String, String> lang) async {
    _timer?.cancel();
    _freezeTimer?.cancel();
    setState(() {
      _gameOver = true;
    });

    final gs = Provider.of<GameService>(context, listen: false);

    // --- PHÁT NHẠC KẾT QUẢ ---
    gs.playResultMusic(won);

    if (!won) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.bg,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied,
                  color: Colors.redAccent, size: 30),
              const SizedBox(width: 8),
              Text(lang['time_up'] ?? 'Time up!',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
              lang['level_failed'] ?? 'You did not complete this level.',
              textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                gs.playTapSound(); // Sound tap
                gs.resumeBgmAfterResult(); // Quay lại BGM
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: Text(lang['ok'] ?? "OK",
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
      return;
    }

    int stars = 0;
    int coins = 0;
    if (_timeLeft > widget.level.timeLimit * 0.6) {
      stars = 3;
    } else if (_timeLeft > widget.level.timeLimit * 0.3) {
      stars = 2;
    } else {
      stars = 1;
    }
    coins = stars * 10;

    LevelCompletionResult result = LevelCompletionResult();
    final gameService = Provider.of<GameService>(context, listen: false);

    try {
      result = await gameService.completeLevel(
          context, widget.level.id, stars, coins);
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("An error occurred during level completion: $e");
    } finally {
      if (!mounted) return;
      final bool wasDoubled = gameService.doubleCoinsPlaysLeft > 0 &&
          gameService.user.inventory["double"]?.owned != null;
      final int finalCoins = wasDoubled ? (coins * 2) : coins;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.bg,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
              const SizedBox(width: 8),
              Text(
                lang['level_complete'] ?? 'Level complete',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${lang['stars'] ?? 'Stars'}: $stars ⭐    ${lang['coins'] ?? 'Coins'}: $finalCoins",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                if (result.droppedPieces.isNotEmpty)
                  Column(
                    children: [
                      Text(lang['dropped_pieces'] ?? 'Mảnh thu được:',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: result.droppedPieces
                            .map(
                                (p) => p.buildWidget(size: 50, borderRadius: 8))
                            .toList(),
                      )
                    ],
                  ),
                if (result.milestonePieces.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Text(
                            lang['milestone_reward'] ??
                                '⭐ PHẦN THƯỞNG ĐẶC BIỆT ⭐',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: result.milestonePieces
                              .map((p) =>
                                  p.buildWidget(size: 60, borderRadius: 8))
                              .toList(),
                        )
                      ],
                    ),
                  ),
                if (result.droppedPieces.isEmpty &&
                    result.milestonePieces.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                        lang['better_luck'] ?? "Chúc bạn may mắn lần sau!"),
                  ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: Text(lang['ok'] ?? "OK",
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _freezeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final langProvider = Provider.of<LangProvider>(context);
    final lang =
        langProvider.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final gs = context.watch<GameService>();

    return Scaffold(
      appBar: TopStatusBar(
        title: "${lang['start'] ?? 'Start'} ${widget.level.id}",
        showBack: true,
        showShopButton: false,
        showGalleryButton: false,
        showCoinsAndStars: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // thanh hiển thị vật phẩm và thời gian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildItemButton(
                        icon: Icons.ac_unit,
                        label: lang['item_freeze'] ?? "Freeze",
                        color: Colors.blueAccent,
                        count: gs.user.inventory["freeze"]?.owned ?? 0,
                        onTap: () => _activateFreezeTime(gs, lang),
                        isDisabled: _isFrozen,
                      ),
                      const SizedBox(width: 16),
                      _buildItemButton(
                        icon: Icons.monetization_on,
                        label: lang['item_double'] ?? "Double",
                        color: Colors.orangeAccent,
                        count: gs.user.inventory["double"]?.owned ?? 0,
                        onTap: () => _activateDoubleCoins(gs, lang),
                        isDisabled: gs.doubleCoinsPlaysLeft > 0,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _isFrozen
                            ? Colors.blue.shade700
                            : Colors.red.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$_timeLeft s",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isFrozen
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          //Phần hiển thị thẻ
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth - 40;
                final double availableHeight = constraints.maxHeight - 40;
                const double spacing = 12.0;
                const double cardAspectRatio = 0.8;
                final int totalCards = _cards.length;

                int finalNumColumns = 2;
                double finalCardWidth = 0.0;

                for (int numCols in [2, 3, 4]) {
                  final int numRows = (totalCards / numCols).ceil();

                  // Tính kích thước thẻ dựa trên chiều rộng
                  final double cardWidthBasedOnWidth =
                      (availableWidth - (spacing * (numCols - 1))) / numCols;
                  final double cardHeightBasedOnWidth =
                      cardWidthBasedOnWidth / cardAspectRatio;

                  // Tính tổng chiều cao cần thiết
                  final double totalHeightNeeded =
                      (numRows * cardHeightBasedOnWidth) +
                          (spacing * (numRows - 1));

                  if (totalHeightNeeded <= availableHeight) {
                    finalNumColumns = numCols;
                    finalCardWidth = cardWidthBasedOnWidth;
                    break;
                  }

                  if (numCols == 4) {
                    finalNumColumns = 4;
                    final int numRows = (totalCards / numCols).ceil();

                    final double cardHeightBasedOnHeight =
                        (availableHeight - (spacing * (numRows - 1))) / numRows;
                    final double cardWidthBasedOnHeight =
                        cardHeightBasedOnHeight * cardAspectRatio;

                    finalCardWidth =
                        min(cardWidthBasedOnWidth, cardWidthBasedOnHeight);
                  }
                }

                finalCardWidth = finalCardWidth.clamp(60.0, 150.0);
                final double finalCardHeight = finalCardWidth / cardAspectRatio;

                // Sử dụng ConstrainedBox để giới hạn chiều rộng của Wrap
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Chiều rộng tối đa của Wrap là (số cột * rộng thẻ) + (khoảng cách)
                      maxWidth: (finalNumColumns * finalCardWidth) +
                          (spacing * (finalNumColumns - 1)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(_cards.length, (index) {
                        final bool isRevealed = _selected.contains(index) ||
                            _completed.contains(index);

                        return SizedBox(
                          width: finalCardWidth,
                          height: finalCardHeight,
                          child: CardTile(
                            revealed: isRevealed,
                            content: _cards[index],
                            onTap: () => _onCardTap(index),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final bool canUse = count > 0 && !isDisabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: canUse
                    ? color.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(icon, color: canUse ? color : Colors.grey, size: 30),
                onPressed: canUse ? onTap : null,
                tooltip: label,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: canUse ? Colors.redAccent : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
