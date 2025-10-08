import 'puzzle_piece.dart';

class PuzzleImage {
  final int id;
  final String fullImagePath;
  final List<PuzzlePiece> pieces;

  PuzzleImage({
    required this.id,
    required this.fullImagePath,
    required this.pieces,
  });

  bool get isCompleted => pieces.every((p) => p.collected);
  int get collectedCount => pieces.where((p) => p.collected).length;
  int get totalCount => pieces.length;
}
