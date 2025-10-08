import 'item.dart';
import 'puzzle_piece.dart';

class UserData {
  int coins;
  int stars;
  Map<String, Item> inventory;

  // Danh sách mảnh ghép đã thu thập
  List<PuzzlePiece> puzzlePieces;

  UserData({
    this.coins = 0,
    this.stars = 0,
    Map<String, Item>? inventory,
    List<PuzzlePiece>? puzzlePieces,
  })  : inventory = inventory ?? {},
        puzzlePieces = puzzlePieces ?? [];
}
