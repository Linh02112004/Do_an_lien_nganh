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

  // Freeze state
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
      if (_isFrozen) return; // khi freeze thì không giảm thời gian
      if (_timeLeft <= 0) {
        _endGame(false);
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
    if (!ok) return;

    _freezeCountThisLevel++;
    setState(() => _isFrozen = true);

    Future.delayed(const Duration(seconds: 20), () {
      setState(() => _isFrozen = false);
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
    if (!ok) return;

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
        setState(() {
          final a = _selected[0], b = _selected[1];
          if (_cards[a] != _cards[b]) {
            _revealed[a] = false;
            _revealed[b] = false;
          }
          _selected.clear();
        });

        if (_revealed.every((r) => r)) {
          _endGame(true);
        }
      });
    }
  }

  void _endGame(bool won) {
    _timer?.cancel();
    setState(() {
      _gameOver = true;
      _gameWon = won;
    });

    int stars = 0;
    int coins = 0;
    if (won) {
      if (_timeLeft > widget.level.timeLimit * 0.6) {
        stars = 3;
      } else if (_timeLeft > widget.level.timeLimit * 0.3) {
        stars = 2;
      } else {
        stars = 1;
      }
      coins = stars * 10;
    }

    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.completeLevel(widget.level.id, stars, coins);

    final langProvider = Provider.of<LangProvider>(context, listen: false);
    final lang =
        langProvider.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bg,
        title: Row(
          children: [
            Icon(won ? Icons.emoji_events : Icons.timer_off,
                color: won ? Colors.amber : Colors.red, size: 30),
            const SizedBox(width: 8),
            Text(
              won
                  ? (lang['level_complete'] ?? 'Level complete')
                  : (lang['time_up'] ?? 'Time up!'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won)
              Text(
                "${lang['stars'] ?? 'Stars'}: $stars ⭐    ${lang['coins'] ?? 'Coins'}: $coins",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            if (!won)
              Text(
                lang['time_up'] ?? 'Time up!',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // quay về map
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 20), // cách lề
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxis,
                mainAxisSpacing: 12, // khoảng cách dọc giữa các card
                crossAxisSpacing: 12, // khoảng cách ngang
                childAspectRatio: 0.8, // tỷ lệ card (rộng/hẹp)
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
