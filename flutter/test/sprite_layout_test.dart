import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/sprite_layout.dart';

void main() {
  test('Wide counter and thin posts keep their source ratio and bottom anchor', () {
    for (final source in [const Rect.fromLTWH(0, 0, 300, 210), const Rect.fromLTWH(0, 0, 120, 280)]) {
      const box = Rect.fromLTWH(50, 70, 180, 90);
      final result = fitSprite(source, box);
      expect(result.width / result.height, closeTo(source.width / source.height, .00001));
      expect(result.bottom, box.bottom); expect(result.center.dx, box.center.dx);
      expect(result.width <= box.width && result.height <= box.height, isTrue);
    }
  });
  test('Transparent atlas margins do not change the visible object proportions', () {
    final data = ByteData(40 * 40 * 4);
    for (var y = 5; y < 35; y++) {
      for (var x = 14; x < 26; x++) { data.setUint8((y * 40 + x) * 4 + 3, 255); }
    }
    final bounds = spriteInkBounds(data, 40, 40, const Rect.fromLTWH(0, 0, 40, 40));
    expect(bounds, const Rect.fromLTRB(12, 3, 28, 37));
  });
  test('Cat breathes, blinks and swishes using only its dedicated idle frames', () {
    expect(catIdleFrame(0), 0); expect(catIdleFrame(.8), 1); expect(catIdleFrame(1.6), 2);
    expect(catIdleFrame(5.9), 3); expect(catIdleFrame(6.0), 4); expect(catIdleFrame(6.2), 3);
    expect(catIdleFrame(2.6), 5); expect(catIdleFrame(2.9), 6); expect(catIdleFrame(3.2), 7);
    final seen = {for (var i = 0; i < 3000; i++) catIdleFrame(i / 100)};
    expect(seen, {0, 1, 2, 3, 4, 5, 6, 7});
  });
}
