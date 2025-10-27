import 'dart:math';
import '../models/level.dart';

class LevelGenerator {
  final Random _rng = Random();

  final int minPairs = 2;
  final int maxPairs = 15;

  Level firstLevel() {
    int initialPairs = 3;
    while ((initialPairs * 2) % 3 != 0 && (initialPairs * 2) % 4 != 0) {
      initialPairs++;
    }
    initialPairs = initialPairs.clamp(minPairs, maxPairs);

    return Level(
      id: 1,
      pairCount: initialPairs,
      timeLimit: (initialPairs * 15).clamp(0, 200),
      unlocked: true,
    );
  }

  Level generateNext(Level last) {
    int currentPair = last.pairCount;
    int pairChange = 0;

    double randomValue = _rng.nextDouble();

    // Xác suất thay đổi số cặp thẻ
    if (randomValue < 0.5) {
      pairChange = 1;
    } else if (randomValue < 0.5) {
      pairChange = -1;
    }

    int tentativeNextPair =
        (currentPair + pairChange).clamp(minPairs, maxPairs);
    int finalNextPair = tentativeNextPair;
    int totalCards = finalNextPair * 2;
    bool fitsGridWell = (totalCards % 3 == 0) || (totalCards % 4 == 0);

    if (!fitsGridWell) {
      int increasedPair = tentativeNextPair + 1;
      if (increasedPair <= maxPairs) {
        int increasedTotalCards = increasedPair * 2;
        if ((increasedTotalCards % 3 == 0) || (increasedTotalCards % 4 == 0)) {
          finalNextPair = increasedPair;
          fitsGridWell = true;
        }
      }

      if (!fitsGridWell) {
        int decreasedPair = tentativeNextPair - 1;
        if (decreasedPair >= minPairs) {
          int decreasedTotalCards = decreasedPair * 2;
          if ((decreasedTotalCards % 3 == 0) ||
              (decreasedTotalCards % 4 == 0)) {
            finalNextPair = decreasedPair;
            fitsGridWell = true;
          }
        }
      }
      if (!fitsGridWell) {
        finalNextPair = tentativeNextPair;
      }
    }

    int nextTime = (finalNextPair * 15).clamp(0, 200);

    return Level(
      id: last.id + 1,
      pairCount: finalNextPair,
      timeLimit: nextTime,
      unlocked: false,
    );
  }
}
