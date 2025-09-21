enum ItemType { freezeTime, doubleCoins, worldPiece }

class Item {
  final String id;
  final String name;
  final ItemType type;
  final int price;
  int owned;

  Item({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.owned = 0,
  });
}
