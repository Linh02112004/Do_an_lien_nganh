import 'package:flutter/material.dart';
import '../models/level.dart';

class LevelNode extends StatelessWidget {
  final Level level;
  final VoidCallback onTap;
  const LevelNode({super.key, required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: level.unlocked ? onTap : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: level.unlocked ? Color(0xFFFFC1E3) : Color(0xFFBDBDBD),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child:
            Text('${level.id}', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
