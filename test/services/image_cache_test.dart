import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/services/image_cache.dart';

void main() {
  group('ImageCache', () {
    late ImageCache cache;

    setUp(() {
      cache = ImageCache();
    });

    test('store and retrieve image by index', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      cache.store(0, bytes);

      expect(cache.get(0), equals(bytes));
    });

    test('get returns null for missing index', () {
      expect(cache.get(99), isNull);
    });

    test('getAll returns all stored images in order', () {
      final img0 = Uint8List.fromList([1, 2]);
      final img1 = Uint8List.fromList([3, 4]);
      final img2 = Uint8List.fromList([5, 6]);

      cache.store(0, img0);
      cache.store(1, img1);
      cache.store(2, img2);

      final all = cache.getAll();
      expect(all.length, 3);
      expect(all[0], equals(img0));
      expect(all[1], equals(img1));
      expect(all[2], equals(img2));
    });

    test('count returns number of stored images', () {
      expect(cache.count, 0);

      cache.store(0, Uint8List.fromList([1]));
      expect(cache.count, 1);

      cache.store(1, Uint8List.fromList([2]));
      expect(cache.count, 2);
    });

    test('clear removes all images', () {
      cache.store(0, Uint8List.fromList([1]));
      cache.store(1, Uint8List.fromList([2]));

      cache.clear();

      expect(cache.count, 0);
      expect(cache.get(0), isNull);
    });

    test('overwrite existing index', () {
      final original = Uint8List.fromList([1, 2]);
      final updated = Uint8List.fromList([3, 4]);

      cache.store(0, original);
      cache.store(0, updated);

      expect(cache.get(0), equals(updated));
      expect(cache.count, 1);
    });
  });
}
