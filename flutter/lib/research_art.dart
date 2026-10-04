import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sprite_layout.dart';

const researchIngredientOrder = ['web', 'tear', 'moon', 'salt', 'mushroom', 'petal', 'root', 'fairy'];

class ResearchArt {
  final ui.Image ingredients, cauldron;
  final List<Rect> ingredientFrames;
  final Rect cauldronFrame;
  ResearchArt(this.ingredients, this.cauldron, this.ingredientFrames, this.cauldronFrame);
  static Future<ResearchArt>? _cached;
  static Future<ResearchArt> load() => _cached ??= _load();
  static Future<ResearchArt> _load() async {
    Future<ui.Image> decode(String asset) async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      codec.dispose(); return image;
    }
    final ingredients = await decode('assets/art/research-ingredients-v1.png');
    final cauldron = await decode('assets/art/research-cauldron-v1.png');
    final rgba = (await ingredients.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final frames = [for (var row = 0; row < 2; row++) for (var col = 0; col < 4; col++)
      spriteInkBounds(rgba, ingredients.width, ingredients.height, Rect.fromLTWH(
        col * ingredients.width / 4 + 6, row * ingredients.height / 2 + 6,
        ingredients.width / 4 - 12, ingredients.height / 2 - 12))];
    final potRgba = (await cauldron.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return ResearchArt(ingredients, cauldron, frames, spriteInkBounds(potRgba, cauldron.width, cauldron.height,
      Rect.fromLTWH(0, 0, cauldron.width.toDouble(), cauldron.height.toDouble())));
  }
}

class IngredientSprite extends StatelessWidget {
  final String id;
  final double size;
  const IngredientSprite({super.key, required this.id, this.size = 48});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: FutureBuilder<ResearchArt>(future: ResearchArt.load(), builder: (context, state) {
      if (!state.hasData) return const SizedBox();
      final index = researchIngredientOrder.indexOf(id);
      if (index < 0) return const SizedBox();
      return CustomPaint(painter: _ResearchSpritePainter(state.data!.ingredients, state.data!.ingredientFrames[index]));
    }));
}

class ResearchCauldron extends StatefulWidget {
  final bool brewing, solved;
  final int phase;
  const ResearchCauldron({super.key, required this.brewing, required this.solved, this.phase = 0});
  @override
  State<ResearchCauldron> createState() => _ResearchCauldronState();
}
class _ResearchCauldronState extends State<ResearchCauldron> with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didChangeDependencies() { super.didChangeDependencies(); sync(); }
  @override
  void didUpdateWidget(ResearchCauldron old) { super.didUpdateWidget(old); sync(); }
  void sync() { if (widget.brewing && !MediaQuery.disableAnimationsOf(context)) { if (!motion.isAnimating) motion.repeat(); } else { motion.stop(); } }
  @override
  void dispose() { motion.dispose(); super.dispose(); }
  bool get brewing => widget.brewing;
  bool get solved => widget.solved;
  @override
  Widget build(BuildContext context) => Semantics(label: solved ? '완성된 물약이 담긴 가마솥' : brewing ? '조합을 실험 중인 가마솥' : '연구용 가마솥',
    child: AspectRatio(aspectRatio: 1.2, child: Stack(fit: StackFit.expand, children: [
      AnimatedOpacity(duration: const Duration(milliseconds: 180), opacity: brewing || solved ? 1 : .3,
        child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(radius: .48,
          colors: [Color(solved ? 0x659adbb6 : 0x65bb8cea), const Color(0x0021162e)])))),
      FutureBuilder<ResearchArt>(future: ResearchArt.load(), builder: (context, state) => state.hasData
        ? Padding(padding: const EdgeInsets.all(8), child: CustomPaint(painter: _ResearchSpritePainter(state.data!.cauldron, state.data!.cauldronFrame)))
        : const SizedBox()),
      if (brewing) IgnorePointer(child: AnimatedBuilder(animation: motion, builder: (_, child) => CustomPaint(painter: _ReactionPainter(motion.value, widget.phase)))),
    ])));
}
class _ReactionPainter extends CustomPainter {
  final double t; final int phase;
  _ReactionPainter(this.t, this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .38);
    final radius = math.min(size.width, size.height) * .23;
    final color = phase == 2 ? const Color(0xffffdd98) : const Color(0xffb9a2ff);
    canvas.drawCircle(center, radius * (1 + .1 * math.sin(t * math.pi * 2)), Paint()..color = color.withAlpha(35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    for (var i = 0; i < 10; i++) {
      final angle = (t + i / 10) * math.pi * 2;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius * .4 - (phase == 2 ? 12 : 0));
      canvas.drawCircle(point, i % 3 == 0 ? 3 : 2, Paint()..color = color.withAlpha(170));
    }
    for (var i = 0; i < 5; i++) {
      final rise = (t + i * .2) % 1;
      canvas.drawCircle(center + Offset(math.sin(i * 2 + t * 4) * radius * .45, -rise * radius * 1.6), 2 + rise * 3,
        Paint()..color = color.withAlpha(((1 - rise) * 160).round())..style = PaintingStyle.stroke);
    }
  }
  @override
  bool shouldRepaint(_ReactionPainter old) => old.t != t || old.phase != phase;
}

class _ResearchSpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect source;
  _ResearchSpritePainter(this.image, this.source);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(image, source, fitSprite(source, Offset.zero & size),
    Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  @override
  bool shouldRepaint(_ResearchSpritePainter old) => old.image != image || old.source != source;
}
