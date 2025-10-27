// lib/models/theme_data.dart
import 'package:flutter/foundation.dart';

@immutable
class GameTheme {
  final String id; // ID định danh duy nhất (vd: 'default', 'fruits', 'emoji')
  final String
      nameKey; // Key để lấy tên hiển thị từ Strings (vd: 'theme_default', 'theme_fruits')
  final int requiredStars; // Số sao cần để mở khóa
  final bool isDefault; // Chủ đề này có phải là mặc định không?
  final List<String>
      cardImagePaths; // Danh sách đường dẫn ảnh cho thẻ bài (trong assets)
  final List<int>
      puzzleImageIds; // Danh sách ID các ảnh puzzle thuộc chủ đề này

  const GameTheme({
    required this.id,
    required this.nameKey,
    required this.requiredStars,
    this.isDefault = false,
    required this.cardImagePaths,
    required this.puzzleImageIds,
  });
}
