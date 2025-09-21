class Level {
  final int id;
  final int pairCount;
  final int timeLimit;
  bool unlocked;
  int stars;

  Level({
    required this.id,
    this.pairCount = 6,
    this.timeLimit = 60,
    this.unlocked = false,
    this.stars = 0,
  });
}
