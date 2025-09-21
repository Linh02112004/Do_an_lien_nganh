import 'dart:math';
import '../models/level.dart';

class LevelGenerator {
  final Random _rng = Random();

  Level firstLevel() {
    return Level(
      id: 1,
      pairCount: 3,
      timeLimit: 80,
      unlocked: true,
    );
  }

  // Sinh level tiếp theo dựa trên level trước
  Level generateNext(Level last) {
    int nextPair = last.pairCount;
    int nextTime = last.timeLimit;

    if (last.pairCount < 12) {
      if (_rng.nextDouble() < 0.7) {
        nextPair = last.pairCount + 1;
      }
    }

    if (last.timeLimit > 20) {
      if (_rng.nextDouble() < 0.6) {
        int reduce = 5 + _rng.nextInt(6);
        nextTime = max(20, last.timeLimit - reduce);
      }
    }

    return Level(
      id: last.id + 1,
      pairCount: nextPair,
      timeLimit: nextTime,
      unlocked: false,
    );
  }
}
