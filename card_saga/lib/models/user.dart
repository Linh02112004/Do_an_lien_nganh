import 'item.dart';

class UserData {
  int coins;
  int stars;
  Map<String, Item> inventory;

  UserData({
    this.coins = 0,
    this.stars = 0,
    Map<String, Item>? inventory,
  }) : inventory = inventory ?? {};
}
