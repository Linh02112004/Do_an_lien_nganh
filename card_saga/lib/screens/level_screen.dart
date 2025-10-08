import 'dart:async';
import 'dart:math';

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
  List<bool> _revealed = [];
  List<int> _selected = [];
  Timer? _timer;
  int _timeLeft = 0;
  bool _gameOver = false;
  bool _gameWon = false;
  bool _isFrozen = false;
  int _freezeCountThisLevel = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _timeLeft = widget.level.timeLimit;
    _generateCards();
    _startTimer();
  }

  void _generateCards() {
    final int pairCount = widget.level.pairCount;
    final List<String> pool = [];
    for (int i = 0; i < pairCount; i++) {
      pool.add("🍭${i + 1}");
      pool.add("🍭${i + 1}");
    }
    pool.shuffle(Random());
    _cards = pool;
    _revealed = List<bool>.filled(_cards.length, false);
    _selected = [];
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
    if (_revealed[index] || _selected.length == 2 || _gameOver) return;
    setState(() {
      _revealed[index] = true;
      _selected.add(index);
    });
    if (_selected.length == 2) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          final a = _selected[0], b = _selected[1];
          if (_cards[a] != _cards[b]) {
            _revealed[a] = false;
            _revealed[b] = false;
          }
          _selected.clear();
        });
        if (_revealed.every((r) => r)) {
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

    int crossAxis = sqrt(_cards.length).ceil();
    if (crossAxis < 2) crossAxis = 2;

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
                crossAxisCount: crossAxis,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return CardTile(
                  revealed: _revealed[index],
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
