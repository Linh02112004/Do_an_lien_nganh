import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/puzzle_image.dart';
import '../models/puzzle_piece.dart';

class PuzzleService {
  final List<PuzzleImage> puzzles = [];
  final Random _rnd = Random();

  Future<void> loadPuzzles() async {
    if (puzzles.isNotEmpty) return;
    for (int i = 1; i <= 20; i++) {
      try {
        final path = 'assets/puzzles/$i.jpg';
        final img = await _loadImage(path);
        final pieces = await _cutImageIntoPieces(img, i, path);
        puzzles.add(PuzzleImage(id: i, fullImagePath: path, pieces: pieces));
      } catch (e) {
        debugPrint("Error loading puzzle $i: $e");
      }
    }
  }

  Future<List<PuzzlePiece>> _cutImageIntoPieces(
    ui.Image image,
    int imageId,
    String fullPath,
  ) async {
    final pieces = <PuzzlePiece>[];
    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();
    final double sourceCropWidth = imgWidth;
    final double sourceCropHeight = imgHeight;
    const double sourceCropX = 0;
    const double sourceCropY = 0;

    final int rows;
    final int cols;
    if (imageId % 2 == 0) {
      rows = 4;
      cols = 3;
    } else {
      rows = 3;
      cols = 4;
    }
    final pieceWidthInSource = sourceCropWidth / cols;
    final pieceHeightInSource = sourceCropHeight / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double pieceX = sourceCropX + (c * pieceWidthInSource);
        final double pieceY = sourceCropY + (r * pieceHeightInSource);
        final srcRect = Rect.fromLTWH(
          pieceX,
          pieceY,
          pieceWidthInSource,
          pieceHeightInSource,
        );

        final bool isSpecialPiece = (r == 0 && c == 0 && imageId <= 5);
        final type =
            isSpecialPiece ? PuzzlePieceType.special : PuzzlePieceType.normal;

        pieces.add(
          PuzzlePiece(
            id: '${imageId}_${r}_${c}',
            imagePath: fullPath,
            imageId: imageId,
            row: r,
            col: c,
            position: srcRect,
            type: type,
          ),
        );
      }
    }
    return pieces;
  }

  /// Lấy một mảnh ngẫu nhiên (chỉ lấy mảnh thường)
  PuzzlePiece? getRandomPiece({Set<int>? allowedPuzzleIds}) {
    if (puzzles.isEmpty) return null;

    final availableNormalPieces =
        puzzles.expand((p) => p.pieces).where((piece) {
      final bool isAllowed = allowedPuzzleIds == null ||
          allowedPuzzleIds.isEmpty ||
          allowedPuzzleIds.contains(piece.imageId);
      return isAllowed && !piece.isSpecial && !piece.collected;
    }).toList();

    if (availableNormalPieces.isEmpty) return null;

    final piece =
        availableNormalPieces[_rnd.nextInt(availableNormalPieces.length)];
    return piece;
  }

  /// Lấy một mảnh ghép đặc biệt theo ID
  PuzzlePiece? getSpecialPieceById(String id) {
    try {
      return puzzles
          .expand((p) => p.pieces)
          .firstWhere((pc) => pc.id == id && pc.isSpecial);
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Rơi mảnh puzzle ngẫu nhiên (không hiệu ứng)
  List<PuzzlePiece> dropRandomPieces({Set<int>? allowedPuzzleIds}) {
    final result = <PuzzlePiece>[];
    final chance = _rnd.nextInt(100);

    int piecesToDrop = 0;
    if (chance < 60) {
      piecesToDrop = 1;
    } else if (chance < 70) {
      piecesToDrop = 2;
    }

    for (int i = 0; i < piecesToDrop; i++) {
      final piece = getRandomPiece(allowedPuzzleIds: allowedPuzzleIds);
      if (piece != null) {
        result.add(piece);
      }
    }
    return result;
  }

  /// Rơi mảnh puzzle ngẫu nhiên (có hiệu ứng)
  Future<void> dropRandomPiecesWithEffect(
    BuildContext context,
    List<PuzzlePiece> piecesToDrop,
  ) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    for (final piece in piecesToDrop) {
      final entry = OverlayEntry(
        builder: (context) => _FallingPieceEffect(
          piece: piece,
          duration: const Duration(seconds: 3),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 3), () => entry.remove());
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }
}

class _PiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;
  _PiecePainter({required this.image, required this.srcRect});

  @override
  void paint(Canvas canvas, Size size) {
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.srcRect != srcRect;
  }
}

class _FallingPieceEffect extends StatefulWidget {
  final PuzzlePiece piece;
  final Duration duration;
  const _FallingPieceEffect({
    required this.piece,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<_FallingPieceEffect> createState() => _FallingPieceEffectState();
}

class _FallingPieceEffectState extends State<_FallingPieceEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadUiImage();
    final rnd = Random();
    final startX = (rnd.nextDouble() * 0.8) - 0.4;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _offset = Tween<Offset>(
      begin: Offset(startX, -1.2),
      end: Offset(startX, 1.4),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  Future<void> _loadUiImage() async {
    try {
      final data = await rootBundle.load(widget.piece.imagePath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() => _image = frame.image);
      }
    } catch (e) {
      debugPrint("Error loading image for falling piece: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _PiecePainter(
                  image: _image!,
                  srcRect: widget.piece.position,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
