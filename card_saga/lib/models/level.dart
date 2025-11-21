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

  Map<String, dynamic> toJson() => {
        'id': id,
        'pairCount': pairCount,
        'timeLimit': timeLimit,
        'unlocked': unlocked,
        'stars': stars,
      };

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      pairCount: json['pairCount'],
      timeLimit: json['timeLimit'],
      unlocked: json['unlocked'],
      stars: json['stars'],
    );
  }
}
