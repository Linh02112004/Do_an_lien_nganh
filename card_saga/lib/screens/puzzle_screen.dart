import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/puzzle_image.dart';
import '../models/puzzle_piece.dart';
import '../services/game_service.dart';
import '../widgets/top_status_bar.dart';
import '../providers/lang_provider.dart';
import '../utils/constants.dart';

class PuzzleScreen extends StatefulWidget {
  final PuzzleImage puzzleImage;
  const PuzzleScreen({super.key, required this.puzzleImage});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  Map<String, Offset> placedPieces = {};
  Map<String, bool> correctPieces = {};
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isComplete = false;

  final double targetAspectRatio = 9.0 / 16.0;
  final GlobalKey puzzleAreaKey = GlobalKey();

  late double cellWidth;
  late double cellHeight;
  late Size puzzleSize;
  late double imageAspectRatio;

  List<PuzzlePiece> userCollectedPieces = [];
  List<PuzzlePiece> availablePieces = [];

  @override
  void initState() {
    super.initState();
    final allUserPieces = context.read<GameService>().user.puzzlePieces;
    userCollectedPieces =
        allUserPieces.where((p) => p.imageId == widget.puzzleImage.id).toList();

    availablePieces = List.from(userCollectedPieces);

    _calculateSizes();

    _checkCompletion();
  }

  void _calculateSizes() {
    _loadImageInfo(widget.puzzleImage.fullImagePath).then((imgInfo) {
      if (imgInfo != null && mounted) {
        final originalImageWidth = imgInfo.image.width.toDouble();
        final originalImageHeight = imgInfo.image.height.toDouble();

        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final appBarHeight = AppBar().preferredSize.height;
        final bottomAreaHeight = screenHeight * (1 / 4);
        final availableHeight =
            screenHeight - appBarHeight - bottomAreaHeight - 40;
        final availableWidth = screenWidth * 0.95;

        double calculatedWidth = availableWidth;
        double calculatedHeight = calculatedWidth / targetAspectRatio;

        if (calculatedHeight > availableHeight) {
          calculatedHeight = availableHeight;
          calculatedWidth = calculatedHeight * targetAspectRatio;
        }

        puzzleSize = Size(calculatedWidth, calculatedHeight);

        final firstPiece = widget.puzzleImage.pieces.first;
        int numCols = 0;
        int numRows = 0;
        widget.puzzleImage.pieces.forEach((p) {
          if (p.col + 1 > numCols) numCols = p.col + 1;
          if (p.row + 1 > numRows) numRows = p.row + 1;
        });

        if (numCols > 0 && numRows > 0 && mounted) {
          setState(() {
            cellWidth = puzzleSize.width / numCols;
            cellHeight = puzzleSize.height / numRows;
          });
        } else {
          print("Lỗi: Không xác định được số hàng/cột từ mảnh ghép.");
        }
      }
    });
  }

  Future<ImageInfo?> _loadImageInfo(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Completer<ImageInfo> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      completer.complete(ImageInfo(image: img));
    });
    return completer.future;
  }

  void _checkCompletion() {
    bool allCorrect = true;
    if (placedPieces.length != widget.puzzleImage.pieces.length) {
      allCorrect = false;
    } else {
      for (var correct in correctPieces.values) {
        if (!correct) {
          allCorrect = false;
          break;
        }
      }
    }
    if (mounted && allCorrect != _isComplete) {
      setState(() {
        _isComplete = allCorrect;
      });
      if (_isComplete) {
        _showCompletionDialog();
      }
    }
  }

  void _showCompletionDialog() {
    final lang = context.read<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t['puzzle_complete'] ?? 'Puzzle Complete!'),
        content: Text('Chúc mừng bạn đã hoàn thành bức tranh!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _onAcceptPiece(PuzzlePiece piece, Offset dropPosition) {
    // Tính toán vị trí tương đối trên grid
    // Vị trí dropPosition là vị trí tuyệt đối trên màn hình, cần chuyển đổi
    // sang vị trí tương đối trong khu vực ghép hình (puzzleArea)

    // (Cần có GlobalKey cho khu vực ghép hình để lấy vị trí chính xác)
    // RenderBox box = puzzleAreaKey.currentContext?.findRenderObject() as RenderBox;
    // Offset localDropPos = box.globalToLocal(dropPosition);

    // Giả sử dropPosition đã là local trong puzzleArea (cần điều chỉnh sau)
    final targetCol = (dropPosition.dx / cellWidth).floor();
    final targetRow = (dropPosition.dy / cellHeight).floor();

    final snapOffset = Offset(
      targetCol * cellWidth + cellWidth / 2,
      targetRow * cellHeight + cellHeight / 2,
    );

    bool isCorrect = (piece.col == targetCol && piece.row == targetRow);

    setState(() {
      placedPieces[piece.id] = snapOffset;
      correctPieces[piece.id] = isCorrect;
      availablePieces.removeWhere((p) => p.id == piece.id);
    });

    _checkCompletion();
    return true;
  }

  void _returnPiece(String pieceId) {
    setState(() {
      final piece = userCollectedPieces.firstWhere((p) => p.id == pieceId);
      placedPieces.remove(pieceId);
      correctPieces.remove(pieceId);
      if (!availablePieces.any((p) => p.id == pieceId)) {
        availablePieces.add(piece);
      }
    });
    _checkCompletion();
  }

  Future<void> _savePuzzleImage() async {
    // 1. Yêu cầu quyền
    PermissionStatus status = await Permission.storage.request();
    if (await Permission.photos.isDenied ||
        await Permission.photos.isPermanentlyDenied) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      try {
        // 2. Chụp ảnh màn hình
        Uint8List? pngBytes = await _screenshotController.capture();

        if (pngBytes != null) {
          // 3. Chuẩn bị tên file và tên album
          final String fileName =
              'puzzle_${widget.puzzleImage.id}_${DateTime.now().millisecondsSinceEpoch}';
          final String albumName = 'Card Saga Puzzles';

          // 4. SỬA LỖI: Dùng đúng tham số
          final SaveResult result = await SaverGallery.saveImage(
            pngBytes,
            name: fileName,
            androidRelativePath: 'Pictures/$albumName',
            // Dùng 'androidExistNotSave: false'
            // 'false' có nghĩa là "nếu tồn tại, đừng bỏ qua việc lưu" -> nó sẽ tự động đổi tên.
            androidExistNotSave: false,
          );

          // 5. SỬA LỖI: Dùng 'errorMessage' thay vì 'filePath'
          print(
              "Kết quả lưu ảnh: ${result.isSuccess}, error: ${result.errorMessage}");

          if (mounted) {
            final lang = context.read<LangProvider>();
            final t =
                lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.isSuccess
                    ? (t['save_image_success'] ?? 'Lưu ảnh thành công!')
                    : (t['save_image_failed'] ?? 'Lưu ảnh thất bại!')),
              ),
            );
          }
        }
      } catch (e) {
        print("Lỗi khi lưu ảnh: $e");
        if (mounted) {
          final lang = context.read<LangProvider>();
          final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(t['save_image_failed'] ?? 'Lưu ảnh thất bại!')),
          );
        }
      }
    } else {
      if (mounted) {
        final lang = context.read<LangProvider>();
        final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t['permission_denied'] ?? 'Quyền bị từ chối!')),
        );
      }
      print("Quyền truy cập bộ nhớ/ảnh bị từ chối.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    if (cellWidth == null || cellHeight == null) {
      return Scaffold(
        appBar: TopStatusBar(
          title: 'Puzzle ${widget.puzzleImage.id}',
          showBack: true,
          showShopButton: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: TopStatusBar(
        title: 'Puzzle ${widget.puzzleImage.id}', // Có thể lấy tên từ đâu đó
        showBack: true,
        showShopButton: false,
        // Thêm nút Lưu nếu đã hoàn thành
        // actions: _isComplete ? [
        //      IconButton(
        //        icon: Icon(Icons.save_alt),
        //        tooltip: t['save_image'] ?? 'Lưu ảnh',
        //        onPressed: _savePuzzleImage,
        //      )
        // ] : null, // Tạm ẩn nút save
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Screenshot(
                controller: _screenshotController,
                child: DragTarget<PuzzlePiece>(
                  key: puzzleAreaKey,
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: puzzleSize.width,
                      height: puzzleSize.height,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15, // Giảm độ mờ hơn nữa
                              child: Image.asset(
                                widget.puzzleImage.fullImagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          ...placedPieces.entries.map((entry) {
                            final pieceId = entry.key;
                            final snapCenterOffset = entry.value;
                            final piece = userCollectedPieces
                                .firstWhere((p) => p.id == pieceId);
                            final isCorrect = correctPieces[pieceId] ?? false;

                            final pieceWidgetSize = Size(cellWidth, cellHeight);

                            final topLeftOffset = Offset(
                                snapCenterOffset.dx - pieceWidgetSize.width / 2,
                                snapCenterOffset.dy -
                                    pieceWidgetSize.height / 2);

                            return Positioned(
                              left: topLeftOffset.dx,
                              top: topLeftOffset.dy,
                              width: pieceWidgetSize.width,
                              height: pieceWidgetSize.height,
                              child: GestureDetector(
                                onTap: () {
                                  if (!isCorrect) {
                                    _returnPiece(pieceId);
                                  }
                                },
                                child: Opacity(
                                  opacity: 1.0,
                                  child: piece.buildWidget(
                                    size: pieceWidgetSize.width,
                                    borderRadius: 0,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                  onAcceptWithDetails: (details) {
                    final RenderBox renderBox = puzzleAreaKey.currentContext
                        ?.findRenderObject() as RenderBox;
                    if (renderBox != null) {
                      final localOffset =
                          renderBox.globalToLocal(details.offset);
                      if (localOffset.dx >= 0 &&
                          localOffset.dx <= puzzleSize.width &&
                          localOffset.dy >= 0 &&
                          localOffset.dy <= puzzleSize.height) {
                        _onAcceptPiece(details.data, localOffset);
                      }
                    } else {
                      print("Lỗi: Không lấy được RenderBox của khu vực ghép");
                    }
                  },
                ),
              ),
            ),
          ),
          if (_isComplete)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.save_alt),
                label: Text(t['save_image'] ?? 'Lưu ảnh'),
                onPressed: _savePuzzleImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Container(
                child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: availablePieces.length,
                    itemBuilder: (context, index) {
                      final piece = availablePieces[index];
                      final pieceWidgetSize =
                          Size(cellWidth * 0.7, cellHeight * 0.7);
                      return Draggable<PuzzlePiece>(
                        data: piece,
                        feedback:
                            piece.buildWidget(size: cellWidth, borderRadius: 0),
                        childWhenDragging: SizedBox(
                            width: pieceWidgetSize.width,
                            height: pieceWidgetSize.height,
                            child: Center(
                                child: Icon(Icons.drag_indicator,
                                    color: Colors.grey.shade300))),
                        child: piece.buildWidget(
                            size: pieceWidgetSize.width, borderRadius: 4),
                      );
                    })),
          ),
        ],
      ),
    );
  }
}
