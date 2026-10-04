import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sprite_layout.dart';

enum Skin { dialogue, parchment, button, selected }

class GameSkin {
  final ui.Image image;
  final List<Rect> frames;
  GameSkin(this.image, this.frames);
  static Future<GameSkin>? _pending;
  static Future<GameSkin> load() => _pending ??= _load();
  static Future<GameSkin> _load() async {
    final bytes = await rootBundle.load('assets/art/ui-ninepatch-v5.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return GameSkin(image, [for (var row = 0; row < 2; row++) for (var col = 0; col < 2; col++)
      spriteInkBounds(rgba, image.width, image.height, Rect.fromLTWH(
        col * image.width / 2 + 4, row * image.height / 2 + 4, image.width / 2 - 8, image.height / 2 - 8))]);
  }
}

/// Nine regions are sampled from the atlas; only the center and edge strips stretch.
class SkinPanel extends StatelessWidget {
  final Skin skin;
  final Widget child;
  const SkinPanel({super.key, required this.skin, required this.child});
  @override
  Widget build(BuildContext context) => FutureBuilder<GameSkin>(future: GameSkin.load(), builder: (context, state) =>
    CustomPaint(painter: state.hasData ? _SkinPainter(state.data!, skin) : null, child: child));
}

class _SkinPainter extends CustomPainter {
  final GameSkin art;
  final Skin skin;
  _SkinPainter(this.art, this.skin);
  @override
  void paint(Canvas canvas, Size size) {
    final src = art.frames[skin.index];
    final inset = math.min(64.0, math.min(src.width, src.height) / 4);
    final cap = math.min(20.0, math.min(size.width, size.height) / 3);
    final sx = [src.left, src.left + inset, src.right - inset, src.right];
    final sy = [src.top, src.top + inset, src.bottom - inset, src.bottom];
    final dx = [0.0, cap, size.width - cap, size.width];
    final dy = [0.0, cap, size.height - cap, size.height];
    final paint = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 3; x++) {
        canvas.drawImageRect(art.image, Rect.fromLTRB(sx[x], sy[y], sx[x+1], sy[y+1]),
          Rect.fromLTRB(dx[x], dy[y], dx[x+1], dy[y+1]), paint);
      }
    }
  }
  @override
  bool shouldRepaint(_SkinPainter old) => old.art != art || old.skin != skin;
}

class GameAction extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const GameAction({super.key, required this.label, this.onPressed});
  @override
  State<GameAction> createState() => _GameActionState();
}
class _GameActionState extends State<GameAction> {
  bool hover = false, focused = false;
  @override
  Widget build(BuildContext context) => MouseRegion(onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false), child: Opacity(opacity: widget.onPressed == null ? .6 : 1,
      child: SkinPanel(skin: hover || focused ? Skin.selected : Skin.button,
        child: FilledButton(onPressed: widget.onPressed, onFocusChange: (v) => setState(() => focused = v),
          style: FilledButton.styleFrom(backgroundColor: Colors.transparent, disabledBackgroundColor: Colors.transparent,
            foregroundColor: const Color(0xffffdfab), disabledForegroundColor: const Color(0xffa99480),
            shadowColor: Colors.transparent, overlayColor: Colors.transparent, minimumSize: const Size(0, 64),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), shape: const RoundedRectangleBorder()),
          child: Text(widget.label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Galmuri', fontSize: 20, height: 1.4))))));
}
