import 'dart:typed_data';

/// In-memory cache for generated story images.
///
/// Stores image bytes outside of Riverpod state to avoid
/// copying large binary data on every state update.
class ImageCache {
  final Map<int, Uint8List> _images = {};

  /// Store image bytes at the given index.
  void store(int index, Uint8List bytes) {
    _images[index] = bytes;
  }

  /// Retrieve image bytes at the given index, or null if not found.
  Uint8List? get(int index) => _images[index];

  /// Get all stored images in index order.
  List<Uint8List> getAll() {
    final keys = _images.keys.toList()..sort();
    return keys.map((k) => _images[k]!).toList();
  }

  /// Number of stored images.
  int get count => _images.length;

  /// Clear all stored images.
  void clear() {
    _images.clear();
  }
}
