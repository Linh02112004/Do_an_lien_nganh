import 'package:flutter/material.dart';

class CurrencyDisplay extends StatelessWidget {
  final int coins;
  final int stars;
  final VoidCallback onTap;
  const CurrencyDisplay(
      {super.key,
      required this.coins,
      required this.stars,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(children: [
            Icon(Icons.monetization_on),
            SizedBox(width: 6),
            Text('$coins')
          ]),
        ),
        SizedBox(width: 16),
        Row(children: [Icon(Icons.star), SizedBox(width: 6), Text('$stars')]),
      ],
    );
  }
}
