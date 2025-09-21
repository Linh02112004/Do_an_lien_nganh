import 'package:flutter/material.dart';

class CardTile extends StatelessWidget {
  final bool revealed;
  final String content;
  final VoidCallback onTap;

  const CardTile({
    Key? key,
    required this.revealed,
    required this.content,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: revealed ? Colors.white : Colors.blueAccent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: revealed
              ? Text(
                  content,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.help_outline, color: Colors.white),
        ),
      ),
    );
  }
}
