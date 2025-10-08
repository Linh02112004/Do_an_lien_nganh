import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

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
      _scrollController.addListener(_onScroll);
    });
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
    final gs = context.watch<GameService>();
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    /// Hiển thị màn hình tải dữ liệu
    if (gs.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFEAF4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.pinkAccent),
              const SizedBox(height: 20),
              Text(
                'Đang tải dữ liệu game...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.pink.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      child: Column(
                        children: [
                          SizedBox(
                            width: nodeSize,
                            height: nodeSize,
                            child: LevelNode(
                              level: level,
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
                                      content:
                                          Text('Level ${level.id} is locked'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (starIndex) {
                              final filled = level.stars > starIndex;
                              return Icon(
                                filled ? Icons.star : Icons.star_border,
                                size: 16,
                                color: filled
                                    ? Colors.amber
                                    : Colors.grey.shade400,
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                  Positioned(
                    left: (screenWidth - 140) / 2,
                    top: 8,
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, color: Colors.pink),
                          const SizedBox(width: 8),
                          Text(
                            t['map_title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    path.moveTo(size.width / 2, startY);

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
