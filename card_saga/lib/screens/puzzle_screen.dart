import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/puzzle_image.dart';
import '../widgets/puzzle_display_widget.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import '../widgets/top_status_bar.dart';

class PuzzleScreen extends StatefulWidget {
  final PuzzleImage puzzleImage;

  const PuzzleScreen({Key? key, required this.puzzleImage}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // Đặt chiều rộng tối đa cho phần tiến độ
  static const double _maxProgressWidth = 500.0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final collectedCount = widget.puzzleImage.collectedCount;
    final totalCount = widget.puzzleImage.totalCount;
    final isCompleted = widget.puzzleImage.isCompleted;

    return Scaffold(
      appBar: TopStatusBar(
        title: '${t['puzzle_gallery_title'] ?? 'Puzzle'}',
        showBack: true,
        showShopButton: false,
        showCoinsAndStars: false,
        showGalleryButton: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PuzzleDisplayWidget(
                  puzzleImage: widget.puzzleImage,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxProgressWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 30.0),
                child: Column(
                  children: [
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          t['puzzle_complete'] ?? 'Puzzle Complete!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Text(
                      '$collectedCount / $totalCount',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? collectedCount / totalCount : 0,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.pinkAccent),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
