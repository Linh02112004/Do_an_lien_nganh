import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:animate_do/animate_do.dart';

import '../services/game_service.dart';
import '../widgets/level_node.dart';
import 'level_screen.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../widgets/top_status_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNextPlayableLevel();
      _scrollController.addListener(_onScroll);
    });
  }

  void _scrollToNextPlayableLevel() {
    if (!mounted) return;
    final gs = context.read<GameService>();
    final nextPlayable = gs.levels
        .firstWhereOrNull((level) => level.unlocked && level.stars == 0);

    if (nextPlayable != null) {
      final index = gs.levels.indexOf(nextPlayable);
      final offset = (index * 120.0 - 40.0).clamp(0.0, double.infinity);

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onScroll() {
    if (!mounted) return;
    final gs = context.read<GameService>();
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      gs.generateMoreLevels(5);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Phần code trên không đổi)
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    if (gs.isLoading) {
      return Scaffold(/* ... Màn hình loading ... */);
    }

    final nextPlayableLevel =
        gs.levels.firstWhereOrNull((l) => l.unlocked && l.stars == 0);
    final nextPlayableLevelId = nextPlayableLevel?.id;

    final screenWidth = MediaQuery.of(context).size.width;
    const nodeSize = 64.0;
    const verticalGap = 120.0;
    final totalLevels = gs.levels.length;
    final contentHeight = math.max(
        MediaQuery.of(context).size.height, totalLevels * verticalGap + 200.0);

    final leftA = 24.0;
    final leftB = screenWidth - nodeSize - 24.0;

    return Scaffold(
      appBar: TopStatusBar(title: t['map_title']!, showShopButton: true),
      body: Stack(
        children: [
          // ... (Phần background không đổi)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFEAF4), Color(0xFFFFD6EC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: contentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: Size(screenWidth, contentHeight),
                    painter: _PathPainter(
                        totalLevels: totalLevels, verticalGap: verticalGap),
                  ),
                  ...List.generate(totalLevels, (i) {
                    final level = gs.levels[i];
                    final left = (i % 2 == 0) ? leftA : leftB;
                    final top = i * verticalGap + 40.0;

                    return Positioned(
                      left: left,
                      top: top,
                      width: nodeSize,
                      height: nodeSize + 30,
                      // --- 2. THAY ĐỔI Ở ĐÂY ---
                      child: FadeInUp(
                        delay: Duration(milliseconds: 80 * (i % 10)),
                        duration: const Duration(milliseconds: 400),
                        child: LevelNode(
                          level: level,
                          isNextPlayable: level.id == nextPlayableLevelId,
                          onTap: () {
                            if (level.unlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LevelScreen(level: level),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Level ${level.id} đã bị khóa'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Class _PathPainter không đổi)
class _PathPainter extends CustomPainter {
  final int totalLevels;
  final double verticalGap;
  _PathPainter({required this.totalLevels, required this.verticalGap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startY = 40.0 + (64.0 / 2);

    if (totalLevels == 0) return;

    final firstNodeIsLeft = 0 % 2 == 0;
    final firstNodeX =
        firstNodeIsLeft ? (24.0 + 32.0) : (size.width - 24.0 - 32.0);
    path.moveTo(firstNodeX, startY);

    for (int i = 0; i < totalLevels - 1; i++) {
      final currentIsLeft = i % 2 == 0;
      final currentX =
          currentIsLeft ? (24.0 + 32.0) : (size.width - 24.0 - 32.0);
      final currentY = i * verticalGap + startY;

      final nextIsLeft = (i + 1) % 2 == 0;
      final nextX = nextIsLeft ? (24.0 + 32.0) : (size.width - 24.0 - 32.0);
      final nextY = (i + 1) * verticalGap + startY;

      final controlX1 = currentX;
      final controlY1 = currentY + verticalGap / 2;
      final controlX2 = nextX;
      final controlY2 = nextY - verticalGap / 2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, nextX, nextY);
    }

    final shadow = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
