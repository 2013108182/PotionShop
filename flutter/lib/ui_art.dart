import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sprite_layout.dart';

enum GameGlyph { coin, close, talk, flask, shop, book, herbs, hammer, moon, sun, back, next, crate, restart }

class UiArt {
  final ui.Image image;
  final List<Rect> frames;
  UiArt(this.image, this.frames);
  static Future<UiArt>? _pending;
  static Future<UiArt> load() => _pending ??= _load();
  static Future<UiArt> _load() async {
    final bytes = await rootBundle.load('assets/art/ui-icons-v6.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    // Explicit atlas regions preserve the wide panel and the taller flask.
    const regions = [
      Rect.fromLTRB(15, 65, 390, 305), Rect.fromLTRB(440, 145, 610, 280),
      Rect.fromLTRB(670, 65, 910, 305), Rect.fromLTRB(985, 70, 1220, 305),
      Rect.fromLTRB(20, 375, 320, 635), Rect.fromLTRB(370, 325, 585, 660),
      Rect.fromLTRB(610, 320, 935, 665), Rect.fromLTRB(940, 375, 1255, 650),
      Rect.fromLTRB(35, 670, 320, 975), Rect.fromLTRB(350, 670, 620, 955),
      Rect.fromLTRB(650, 680, 940, 950), Rect.fromLTRB(940, 660, 1240, 970),
      Rect.fromLTRB(35, 995, 300, 1205), Rect.fromLTRB(350, 995, 610, 1205),
      Rect.fromLTRB(635, 970, 925, 1220), Rect.fromLTRB(975, 965, 1225, 1215),
    ];
    return UiArt(image, [for (final region in regions)
      spriteInkBounds(pixels, image.width, image.height, Rect.fromLTRB(
        region.left / 1280 * image.width, region.top / 1280 * image.height,
        region.right / 1280 * image.width, region.bottom / 1280 * image.height))]);
  }
}

class GameIcon extends StatelessWidget {
  final GameGlyph glyph;
  final double size;
  const GameIcon(this.glyph, {super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size,
    child: FutureBuilder<UiArt>(future: UiArt.load(), builder: (context, snapshot) =>
      snapshot.hasData ? CustomPaint(painter: _GlyphPainter(snapshot.data!, glyph)) : const SizedBox()));
}

class _GlyphPainter extends CustomPainter {
  final UiArt art;
  final GameGlyph glyph;
  _GlyphPainter(this.art, this.glyph);
  @override
  void paint(Canvas canvas, Size size) {
    final src = art.frames[glyph.index + 2];
    canvas.drawImageRect(art.image, src, fitSprite(src, Offset.zero & size), Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  }
  @override
  bool shouldRepaint(_GlyphPainter old) => old.art != art || old.glyph != glyph;
}

/// The body stretches in nine regions; the tail is a separate fixed-size sprite.
class SpeechFrame extends StatelessWidget {
  final Widget child;
  const SpeechFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) => FutureBuilder<UiArt>(future: UiArt.load(), builder: (context, snapshot) =>
    CustomPaint(painter: snapshot.hasData ? _SpeechPainter(snapshot.data!) : null,
      child: Padding(padding: const EdgeInsets.only(bottom: 9), child: child)));
}

class _SpeechPainter extends CustomPainter {
  final UiArt art;
  _SpeechPainter(this.art);
  @override
  void paint(Canvas canvas, Size size) {
    final src = art.frames[0];
    final inset = math.min(src.width, src.height) * .22;
    final cap = math.min(10.0, math.min(size.width, size.height - 9) / 3);
    final sx = [src.left, src.left + inset, src.right - inset, src.right];
    final sy = [src.top, src.top + inset, src.bottom - inset, src.bottom];
    final dx = [0.0, cap, size.width - cap, size.width];
    final dy = [0.0, cap, size.height - 9 - cap, size.height - 9];
    final paint = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
    for (var y = 0; y < 3; y++) { for (var x = 0; x < 3; x++) {
      canvas.drawImageRect(art.image, Rect.fromLTRB(sx[x], sy[y], sx[x+1], sy[y+1]),
        Rect.fromLTRB(dx[x], dy[y], dx[x+1], dy[y+1]), paint);
    } }
    canvas.drawImageRect(art.image, art.frames[1], Rect.fromLTWH(size.width * .3 - 7, size.height - 12, 14, 12), paint);
  }
  @override
  bool shouldRepaint(_SpeechPainter old) => old.art != art;
}

enum ShopProp { shelf, book, order, counter }
class PropSurface extends StatelessWidget {
  final ShopProp prop;
  final Widget child;
  final bool painted;
  const PropSurface({super.key, required this.prop, required this.child, this.painted = true});
  static Future<UiArt>? _art;
  static Future<UiArt> load() => _art ??= _load();
  static Future<UiArt> _load() async {
    final bytes = await rootBundle.load('assets/art/ui-props-v6.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image; codec.dispose();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    const regions = [Rect.fromLTRB(15, 10, 610, 540), Rect.fromLTRB(630, 60, 1250, 545),
      Rect.fromLTRB(40, 550, 575, 1230), Rect.fromLTRB(600, 680, 1245, 1170)];
    return UiArt(image, [for (final r in regions) spriteInkBounds(rgba, image.width, image.height,
      Rect.fromLTRB(r.left / 1280 * image.width, r.top / 1280 * image.height,
        r.right / 1280 * image.width, r.bottom / 1280 * image.height))]);
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<UiArt>(future: load(), builder: (context, state) =>
    CustomPaint(painter: state.hasData && painted ? _PropPainter(state.data!, prop) : null, child: child));
}
class _PropPainter extends CustomPainter {
  final UiArt art; final ShopProp prop;
  _PropPainter(this.art, this.prop);
  @override
  void paint(Canvas c, Size size) {
    final src = art.frames[prop.index];
    final paint = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
    if (prop == ShopProp.shelf || prop == ShopProp.book) {
      c.drawImageRect(art.image, src, fitSprite(src, Offset.zero & size), paint); return;
    }
    final edge = math.min(45.0, size.width / 5), cap = math.min(32.0, size.height / 4);
    final sx = [src.left, src.left + src.width * .13,
      if (prop == ShopProp.book) ...[src.center.dx - src.width * .025, src.center.dx + src.width * .025],
      src.right - src.width * .13, src.right];
    final dx = [0.0, edge, if (prop == ShopProp.book) ...[size.width / 2 - 12, size.width / 2 + 12], size.width - edge, size.width];
    final sy = [src.top, src.top + src.height * .13, src.bottom - src.height * .13, src.bottom];
    final dy = [0.0, cap, size.height - cap, size.height];
    for (var y = 0; y < 3; y++) { for (var x = 0; x < sx.length - 1; x++) {
      c.drawImageRect(art.image, Rect.fromLTRB(sx[x], sy[y], sx[x+1], sy[y+1]),
        Rect.fromLTRB(dx[x], dy[y], dx[x+1], dy[y+1]), paint);
    } }
  }
  @override
  bool shouldRepaint(_PropPainter old) => old.art != art || old.prop != prop;
}
