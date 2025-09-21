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
          content: Text(t['freeze_used'] ?? "Freeze Time activated for 20s!")),
    );
  }

  void _activateDoubleCoins(GameService gs, Map<String, String> t) {
    final ok = gs.useItem("double");
    if (!ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(t['double_used'] ?? "Double Coins for next 3 plays!")),
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
        backgroundColor: AppColors.bg,
        title: Text(won
            ? (lang['level_complete'] ?? 'Level complete')
            : (lang['time_up'] ?? 'Time up!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won)
              Text(
                  "${lang['stars'] ?? 'Stars'}: $stars ⭐    ${lang['coins'] ?? 'Coins'}: $coins"),
            if (!won) Text(lang['time_up'] ?? 'Time up!'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildItemButton(
                icon: Icons.ac_unit,
                count: gs.user.inventory["freeze"]?.owned ?? 0,
                onTap: () => _activateFreezeTime(gs, lang),
              ),
              const SizedBox(width: 16),
              _buildItemButton(
                icon: Icons.monetization_on,
                count: gs.user.inventory["double"]?.owned ?? 0,
                onTap: () => _activateDoubleCoins(gs, lang),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerRight,
            child: Text("⏰ $_timeLeft s",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxis,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
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
    required int count,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.pink, size: 32),
          onPressed: onTap,
        ),
        Text("x$count"),
      ],
    );
  }
}
