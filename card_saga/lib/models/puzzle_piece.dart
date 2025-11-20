import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PuzzlePieceType { normal, special }

class PuzzlePiece {
  final String id;
  final String imagePath;
  final int imageId;
  final int row;
  final int col;
  final Rect position;
  final PuzzlePieceType type;
  bool collected;

  PuzzlePiece({
    required this.id,
    required this.imagePath,
    required this.imageId,
    required this.row,
    required this.col,
    required this.position,
    this.type = PuzzlePieceType.normal,
    this.collected = false,
  });

  bool get isSpecial => type == PuzzlePieceType.special;

  Widget buildWidget({
    double size = 80,
    double borderRadius = 10,
  }) {
    return FutureBuilder<ui.Image>(
      future: _loadImage(imagePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final image = snapshot.data!;
        final srcRect = position;

        // Tính toán tỷ lệ aspect ratio của mảnh gốc
        final double srcAspectRatio = srcRect.width / srcRect.height;

        // Tính toán kích thước hiển thị mới, giữ đúng tỷ lệ
        final double displayWidth;
        final double displayHeight;
        if (srcAspectRatio >= 1) {
          displayWidth = size;
          displayHeight = size / srcAspectRatio;
        } else {
          displayHeight = size;
          displayWidth = size * srcAspectRatio;
        }

        final dstRect = Rect.fromLTWH(0, 0, displayWidth, displayHeight);

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CustomPaint(
            size: Size(displayWidth, displayHeight),
            painter: _PiecePainter(image, srcRect, dstRect),
          ),
        );
      },
    );
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class _PiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;
  final Rect dstRect;

  _PiecePainter(this.image, this.srcRect, this.dstRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.srcRect != srcRect ||
        oldDelegate.dstRect != dstRect;
  }
}
