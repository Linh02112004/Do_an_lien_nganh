import 'dart:math';
import '../models/level.dart';

class LevelGenerator {
  final Random _rng = Random();

  Level firstLevel() {
    // Bắt đầu với 3 cặp (6 card), 100s
    return Level(
      id: 1,
      pairCount: 3,
      timeLimit: 100,
      unlocked: true,
    );
  }

  // Sinh level tiếp theo dựa trên level trước
  Level generateNext(Level last) {
    int nextPair = last.pairCount;
    int nextTime = last.timeLimit;

    const List<int> badPairCounts = [5, 7, 11, 13, 14, 17, 19];
    bool pairCountIncreased = false;

    if (last.pairCount < 20) {
      if (_rng.nextDouble() < 0.15) {
        nextPair = last.pairCount + 1;
        while (badPairCounts.contains(nextPair)) {
          nextPair++;
        }
        if (nextPair > 20) nextPair = 20;
        if (nextPair != last.pairCount) {
          pairCountIncreased = true;
        }
      }
    }

    int reduce = 2 + _rng.nextInt(3);

    if (!pairCountIncreased) {
      nextTime = last.timeLimit - reduce;
    } else if (_rng.nextDouble() < 0.2) {
      nextTime = last.timeLimit - reduce;
    }

    int minTime = (nextPair * 10).clamp(40, 200); // 10s/cặp, sàn 40s

    nextTime = max(minTime, nextTime);

    return Level(
      id: last.id + 1,
      pairCount: nextPair,
      timeLimit: nextTime,
      unlocked: false,
    );
  }
}
