enum ItemType { freezeTime, doubleCoins }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'price': price,
        'owned': owned,
      };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      type: ItemType.values[json['type']], // Đọc số nguyên thành enum
      price: json['price'],
      owned: json['owned'],
    );
  }
}
