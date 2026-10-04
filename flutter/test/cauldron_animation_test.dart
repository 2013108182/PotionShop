import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/shop_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Cauldron body and stone pixels stay identical throughout the animation', () async {
    final asset = await rootBundle.load('assets/art/cauldron-idle-v4.png');
    final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List());
    final atlas = (await codec.getNextFrame()).image;
    codec.dispose();
    final frames = <List<int>>[];
    for (var frame = 0; frame < 6; frame++) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..translate(-450, -35);
      paintCauldronAssembly(canvas, atlas, (frame + .1) / 6);
      final picture = recorder.endRecording();
      final image = await picture.toImage(110, 130);
      frames.add((await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List().toList());
      image.dispose(); picture.dispose();
    }
    for (final current in frames.skip(1)) {
      for (final rect in [const ui.Rect.fromLTRB(30, 70, 64, 78), const ui.Rect.fromLTRB(10, 108, 100, 118)]) {
        for (var y = rect.top.toInt(); y < rect.bottom; y++) {
          for (var x = rect.left.toInt(); x < rect.right; x++) {
            final offset = (y * 110 + x) * 4;
            expect(current.sublist(offset, offset + 4), frames.first.sublist(offset, offset + 4), reason: 'Structural pixel ($x, $y) moved');
          }
        }
      }
    }
    expect(frames[1], isNot(orderedEquals(frames.first)), reason: 'Fire, liquid and smoke must still animate');
    atlas.dispose();
  });
}
