import 'item.dart';
import 'puzzle_piece.dart';

class UserData {
  int coins;
  int stars;
  Map<String, Item> inventory;
  List<PuzzlePiece> puzzlePieces;

  UserData({
    required this.coins,
    required this.stars,
    Map<String, Item>? inventory,
    List<PuzzlePiece>? puzzlePieces,
  })  : this.inventory = inventory ?? {},
        this.puzzlePieces = puzzlePieces ?? [];

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'stars': stars,
      'inventory': inventory.values.map((i) => i.toJson()).toList(),
      'collectedPieceIds': puzzlePieces.map((p) => p.id).toList(),
    };
  }
}
