import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/card_tile.dart';
import '../services/game_service.dart';
import '../utils/constants.dart';
import '../models/level.dart';
import '../models/puzzle_piece.dart';
import '../providers/lang_provider.dart';
import '../widgets/top_status_bar.dart';

class LevelScreen extends StatefulWidget {
  final Level level;
  const LevelScreen({Key? key, required this.level}) : super(key: key);

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
  bool _gameWon = false;
  bool _isFrozen = false;
  int _freezeCountThisLevel = 0;
  bool _isChecking = false;

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
    // Lấy GameService từ Provider
    final gameService = Provider.of<GameService>(context, listen: false);
    final int pairCount = widget.level.pairCount;

    // Lấy danh sách ảnh cho biome của level này
    final List<String> availableAssets =
        gameService.getCardAssetsForCurrentTheme();

    // Xử lý trường hợp không có đủ ảnh
    if (availableAssets.length < pairCount) {
      // Có thể hiển thị lỗi, hoặc dùng ảnh mặc định, hoặc lặp lại ảnh
      print(
          "Lỗi: Không đủ ảnh trong biome cho level ${widget.level.id}. Cần $pairCount, có ${availableAssets.length}");
      // Tạm thời dùng lại logic cũ để tránh crash
      final List<String> pool = [];
      for (int i = 0; i < pairCount; i++) {
        pool.add("?"); // Ký tự thay thế khi thiếu ảnh
        pool.add("?");
      }
      pool.shuffle(Random());
      _cards = pool;
    } else {
      // Chọn ngẫu nhiên 'pairCount' ảnh từ danh sách
      availableAssets.shuffle(Random());
      final List<String> selectedImagePaths =
          availableAssets.sublist(0, pairCount);

      // Tạo danh sách thẻ bài với các cặp đường dẫn ảnh
      final List<String> pool = [];
      for (String imagePath in selectedImagePaths) {
        pool.add(imagePath);
        pool.add(imagePath);
      }
      pool.shuffle(Random());
      _cards = pool; // Gán danh sách đường dẫn ảnh đã xáo trộn
    }

    _completed = [];
    _selected = [];

    // Cần gọi setState để cập nhật UI sau khi _cards được tạo
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_isFrozen) return;
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

  void _activateFreezeTime(GameService gs, Map<String, String> t) {
    if (_freezeCountThisLevel >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t['max_freeze'] ?? "Max 5 freezes per level!")),
      );
      return;
    }
    final ok = gs.useItem("freeze");
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t['not_enough_coins'] ?? "No item")),
      );
      return;
    }
    _freezeCountThisLevel++;
    setState(() => _isFrozen = true);
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() => _isFrozen = false);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Text(t['freeze_used'] ?? "Freeze Time activated for 20s!"),
      ),
    );
  }

  void _activateDoubleCoins(GameService gs, Map<String, String> t) {
    final ok = gs.useItem("double");
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t['not_enough_coins'] ?? "No item")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text(t['double_used'] ?? "Double Coins for next 3 plays!"),
      ),
    );
  }

  void _onCardTap(int index) {
    if (_gameOver ||
        _isChecking ||
        _completed.contains(index) ||
        _selected.contains(index)) {
      return;
    }

    // Nếu mới chọn 1 thẻ
    if (_selected.length < 2) {
      setState(() {
        _selected.add(index);
      });
    }

    // Nếu đã chọn đủ 2 thẻ
    if (_selected.length == 2) {
      _isChecking = true;
      final int a = _selected[0];
      final int b = _selected[1];

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        setState(() {
          // Kiểm tra xem 2 thẻ có khớp không
          if (_cards[a] == _cards[b]) {
            // KHỚP: Thêm chúng vào danh sách _completed
            _completed.add(a);
            _completed.add(b);
          }

          // Dù khớp hay không, xóa 2 thẻ khỏi _selected
          _selected.clear();

          _isChecking = false;
        });

        // Kiểm tra thắng
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
    setState(() {
      _gameOver = true;
      _gameWon = won;
    });

    if (!won) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(lang['time_up'] ?? 'Time up!'),
          content:
              Text(lang['level_failed'] ?? 'You did not complete this level.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
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
                  "${lang['stars'] ?? 'Stars'}: $stars ⭐    ${lang['coins'] ?? 'Coins'}: $coins",
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
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  Map<String, int> _calculateGridDimensions(int totalCards) {
    if (totalCards % 4 == 0) {
      return {'rows': totalCards ~/ 4, 'cols': 4};
    }
    if (totalCards % 3 == 0) {
      return {'rows': totalCards ~/ 3, 'cols': 3};
    }
    if (totalCards % 2 == 0) {
      return {'rows': totalCards ~/ 2, 'cols': 2};
    }
    return {'rows': totalCards, 'cols': 1};
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final gridDims = _calculateGridDimensions(_cards.length);
    final int numColumns = gridDims['cols']!;

    final langProvider = Provider.of<LangProvider>(context);
    final lang =
        langProvider.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final gs = context.watch<GameService>();

    return Scaffold(
      appBar: TopStatusBar(
        title: "${lang['start'] ?? 'Start'} ${widget.level.id}",
        showBack: true,
        showShopButton: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildItemButton(
                icon: Icons.ac_unit,
                label: lang['freeze'] ?? "Freeze",
                color: Colors.blueAccent,
                count: gs.user.inventory["freeze"]?.owned ?? 0,
                onTap: () => _activateFreezeTime(gs, lang),
              ),
              const SizedBox(width: 24),
              _buildItemButton(
                icon: Icons.monetization_on,
                label: lang['double'] ?? "Double",
                color: Colors.orangeAccent,
                count: gs.user.inventory["double"]?.owned ?? 0,
                onTap: () => _activateDoubleCoins(gs, lang),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              "⏰ $_timeLeft s",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isFrozen ? Colors.blue : Colors.red,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numColumns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final bool isRevealed =
                    _selected.contains(index) || _completed.contains(index);

                return CardTile(
                  revealed: isRevealed,
                  content: _cards[index],
                  onTap: () => _onCardTap(index),
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
  }) {
    return Column(
      children: [
        Stack(
          children: [
            IconButton(
              icon: Icon(icon, color: color, size: 36),
              onPressed: onTap,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "x$count",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
