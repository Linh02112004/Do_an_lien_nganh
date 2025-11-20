import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../widgets/top_status_bar.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';
import 'puzzle_screen.dart';

class PuzzleGalleryScreen extends StatelessWidget {
  const PuzzleGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;
    final gameService = context.watch<GameService>();
    final allPuzzles = gameService.unlockedPuzzles;
    final userPieces = gameService.user.puzzlePieces;

    return Scaffold(
      appBar: TopStatusBar(
        title: t['puzzle_gallery_title'] ?? 'Puzzle Gallery',
        showBack: true,
        showShopButton: false,
        showGalleryButton: false,
        showCoinsAndStars: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250.0,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        // --------------------------------------------------------
        itemCount: allPuzzles.length,
        itemBuilder: (context, index) {
          final puzzle = allPuzzles[index];
          final collectedCount =
              userPieces.where((p) => p.imageId == puzzle.id).length;
          final totalCount = puzzle.pieces.length;
          final isCompleted = collectedCount >= totalCount;

          return GestureDetector(
            onTap: () {
              if (collectedCount > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzleScreen(puzzleImage: puzzle),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t['no_puzzle_pieces'] ??
                        'You have no piece for this puzzle yet!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      puzzle.fullImagePath,
                      fit: BoxFit.cover,
                      color: isCompleted ? null : Colors.black.withOpacity(0.4),
                      colorBlendMode: isCompleted ? null : BlendMode.darken,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '$collectedCount / $totalCount ${isCompleted ? '' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
