import 'ui_art.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'shop_motion.dart';
import 'sprite_layout.dart';
import 'game_skin.dart';

const worldInk = Color(0xff171024), worldGold = Color(0xffe9b568);

// Keep Korean syllables in each word together; retain explicit paragraph breaks.
String keepDialogueWords(String text, TextStyle style, double width, TextScaler scaler) =>
  text.replaceAllMapped(RegExp(r'\S+'), (match) {
    final word = match[0]!;
    final measure = TextPainter(text: TextSpan(text: word, style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout();
    final fits = measure.width <= width; measure.dispose();
    return fits ? word.runes.map(String.fromCharCode).join('\u2060') : word;
  });

int customerAppearance(String name) => name.contains('미나') ? 2 : name.contains('엘리') ? 3 : name.contains('준') ? 4 : 1;

Rect actorFrame(ui.Image image, int row, int frame) {
  const rows = [0.0, .144, .273, .403, .536, .671, .776, .888, 1.0];
  final w = image.width / 8, y = rows[row] * image.height;
  return Rect.fromLTWH(frame * w + 2, y + 2, w - 4, (rows[row + 1] - rows[row]) * image.height - 4);
}

class WorldArt {
  final ui.Image tiles, actors, decor, cat, architecture, bookcase, cauldron, walls;
  final List<Rect> tileFrames, decorFrames, catFrames, architectureFrames, bookcaseFrames, wallFrames, bottleFrames;
  WorldArt(this.tiles, this.actors, this.decor, this.cat, this.architecture, this.bookcase, this.cauldron, this.walls,
    this.tileFrames, this.decorFrames, this.catFrames, this.architectureFrames, this.bookcaseFrames, this.wallFrames, this.bottleFrames);
  static Future<WorldArt>? _cached;
  static Future<WorldArt> load() => _cached ??= _load();
  static Future<WorldArt> _load() async {
    Future<ui.Image> image(String path) async {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame(); codec.dispose(); return frame.image;
    }
    final tiles = await image('assets/art/tiles-v3.png');
    final actors = await image('assets/art/actors-v3.png');
    final decor = await image('assets/art/decor-v3.png');
    final cat = await image('assets/art/cat-idle-v4.png');
    final architecture = await image('assets/art/architecture-v4.png');
    final bookcase = await image('assets/art/architecture-v5.png');
    final cauldron = await image('assets/art/cauldron-idle-v4.png');
    final walls = await image('assets/art/wall-modules-v5.png');
    Future<List<Rect>> bounds(ui.Image atlas, int columns, List<double> rowEdges) async {
      final pixels = (await atlas.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      return [for (var r = 0; r < rowEdges.length - 1; r++) for (var c = 0; c < columns; c++)
        spriteInkBounds(pixels, atlas.width, atlas.height, Rect.fromLTRB(
          c * atlas.width / columns + 8, rowEdges[r] * atlas.height + 8,
          (c + 1) * atlas.width / columns - 8, rowEdges[r + 1] * atlas.height - 8))];
    }
    final actorPixels = (await actors.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return WorldArt(tiles, actors, decor, cat, architecture, bookcase, cauldron, walls,
      await bounds(tiles, 4, [0, .25, .5, .75, 1]),
      await bounds(decor, 4, [0, .28, .49, .745, 1]),
      await bounds(cat, 4, [0, .5, 1]), await bounds(architecture, 1, [0, .57, 1]), await bounds(bookcase, 1, [0, .43, .715, 1]),
      await bounds(walls, 2, [0, 1]), [for (final frame in [0, 4]) spriteInkBounds(actorPixels, actors.width, actors.height, actorFrame(actors, 7, frame))]);
  }
}

class ShopWorld extends StatefulWidget {
  final String? customerId;
  final String customerName;
  final String? speech;
  final bool? dialogueVisible;
  final VoidCallback? onTalk, onDialogueAction;
  final String dialogueAction;
  ShopWorld interaction({required bool visible, required VoidCallback talk, required VoidCallback action, required String label, required ValueChanged<String> station}) => ShopWorld(
    key: key, customerId: customerId, customerName: customerName, speech: speech,
    night: night, level: level, bottles: bottles, onReady: onReady, onStation: onStation == null ? null : station,
    dialogueVisible: visible, onTalk: talk, onDialogueAction: action, dialogueAction: label);
  final bool night;
  final int level, bottles;
  final ValueChanged<bool>? onReady;
  final ValueChanged<String>? onStation;
  const ShopWorld({super.key, this.customerId, this.customerName = '', this.night = false,
    this.level = 1, this.bottles = 3, this.onReady, this.onStation, this.speech, this.dialogueVisible, this.onTalk, this.onDialogueAction, this.dialogueAction = '물약 고르기'});
  @override
  State<ShopWorld> createState() => _ShopWorldState();
}
class _ShopWorldState extends State<ShopWorld> with SingleTickerProviderStateMixin {
  final traffic = ShopTraffic();
  final paintClock = ValueNotifier<double>(0);
  late final Ticker ticker;
  WorldArt? art;
  String? artError;
  Duration previous = Duration.zero;
  bool reduced = false, ready = false;
  String catMessage = '';
  bool speechOpen = false;
  Timer? catTimer;
  @override
  void initState() {
    super.initState(); ticker = createTicker(tick);
    WorldArt.load().then((value) { if (mounted) setState(() => art = value); }, onError: (Object e) {
      if (mounted) setState(() => artError = '상점 아트를 불러오지 못했어요. 화면을 새로고침해 주세요.');
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    sync();
    if (reduced) { ticker.stop(); } else if (!ticker.isActive) { previous = Duration.zero; ticker.start(); }
  }
  @override
  void didUpdateWidget(ShopWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) { speechOpen = false; sync(); }
    else if (oldWidget.speech != widget.speech) { speechOpen = true; }
  }
  void sync() {
    traffic.request(widget.customerId, customerAppearance(widget.customerName), reducedMotion: reduced);
    report(force: true);
  }
  void report({bool force = false}) {
    final next = traffic.ready;
    if (next == ready && !force) return;
    ready = next;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { widget.onReady?.call(ready); setState(() {}); } });
  }
  void tick(Duration elapsed) {
    // A suspended tab must not teleport a visitor across the entire shop.
    final dt = math.min(.1, (elapsed - previous).inMicroseconds / 1000000);
    previous = elapsed; traffic.update(dt); report(); paintClock.value += dt;
  }
  @override
  void dispose() { ticker.dispose(); paintClock.dispose(); catTimer?.cancel(); super.dispose(); }
  void petCat() {
    setState(() => catMessage = '골골… 오늘도 잘될 거야.');
    catTimer?.cancel(); catTimer = Timer(const Duration(seconds: 3), () { if (mounted) setState(() => catMessage = ''); });
  }
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final scale = math.min(constraints.maxWidth / 640, constraints.maxHeight / 352);
    final left = (constraints.maxWidth - 640 * scale) / 2;
    final top = (constraints.maxHeight - 352 * scale) / 2;
    final speechStyle = DefaultTextStyle.of(context).style.merge(const TextStyle(color: Color(0xff30202b), fontSize: 16, height: 1.5));
    final textScaler = MediaQuery.textScalerOf(context);
    final measure = TextPainter(text: TextSpan(text: widget.speech ?? '', style: speechStyle), textDirection: TextDirection.ltr, textScaler: textScaler)..layout();
    final bubbleWidth = math.min(math.min(540.0, constraints.maxWidth - 24), math.max(300.0, measure.width + 48));
    final wrappedSpeech = keepDialogueWords(widget.speech ?? '', speechStyle, bubbleWidth - 40, textScaler);
    measure.text = TextSpan(text: wrappedSpeech, style: speechStyle); measure.layout(maxWidth: bubbleWidth - 40);
    final bubbleHeight = measure.height + 150;
    measure.dispose();
    Widget station(String label, String id, Rect rect, {VoidCallback? action}) => Positioned(
      left: left + rect.left * scale, top: top + rect.top * scale,
      width: rect.width * scale, height: rect.height * scale,
      child: Semantics(button: true, label: label, child: Tooltip(message: label,
        child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(6), hoverColor: const Color(0x18ffe7bb),
          onTap: action ?? (widget.onStation == null ? null : () => widget.onStation!(id)),
          child: const SizedBox.expand())))));    return Stack(children: [
      Positioned.fill(child: RepaintBoundary(child: art == null
        ? Center(child: Text(artError ?? '상점에 불을 켜는 중…'))
        : CustomPaint(painter: _WorldPainter(art!, traffic, paintClock, widget.night, widget.level, widget.bottles)))),
      if (widget.onStation != null) ...[
        station('레시피북 열기', 'book', const Rect.fromLTWH(162, 106, 180, 78)),
        station(widget.night ? '물약 연구하기' : '가마솥 개선', widget.night ? 'research' : 'upgrade', const Rect.fromLTWH(465, 71, 67, 87)),
        station('재료 주문하기', 'materials', const Rect.fromLTWH(97, 30, 77, 116)),
      ],
      station('고양이 쓰다듬기', 'cat', const Rect.fromLTWH(486, 159, 51, 31), action: petCat),
      if (ready && widget.speech != null) ...[
        Positioned(left: left + 247 * scale, top: top + 139 * scale,
          child: Tooltip(message: '손님 대화', child: SpeechFrame(child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: worldInk, shadowColor: Colors.transparent, minimumSize: const Size(64, 38), shape: const RoundedRectangleBorder()),
            onPressed: widget.onTalk ?? () => setState(() => speechOpen = !speechOpen), child: AnimatedBuilder(animation: paintClock, builder: (context, _) => Semantics(label: '손님과 대화하기', child: ExcludeSemantics(child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) Transform.translate(offset: Offset(0, reduced ? 0 : -4 * math.max(0, math.sin(paintClock.value * 5 - i * .9))), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('·', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold))))])))))))),
        Positioned(left: math.max(12, math.min(left + 282 * scale, constraints.maxWidth - bubbleWidth - 12)),
          top: math.max(8, math.min(top + 105 * scale, constraints.maxHeight - bubbleHeight - 8)), width: bubbleWidth,
          child: GameReveal(visible: widget.dialogueVisible ?? speechOpen, child: SpeechFrame(key: const ValueKey('npc-speech'), child: Padding(padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.customerName, style: const TextStyle(color: Color(0xff765037), fontSize: 13)),
              const SizedBox(height: 8), Text(wrappedSpeech, semanticsLabel: widget.speech, style: speechStyle),
              if (widget.onDialogueAction != null) ...[const SizedBox(height: 12), GameAction(label: widget.dialogueAction, onPressed: widget.onDialogueAction)],
            ]))))),
      ],
      if (catMessage.isNotEmpty) Positioned(left: left + 440 * scale, top: top + 144 * scale,
        child: _WorldBubble(catMessage)),    ]);
  });
}

class _WorldBubble extends StatelessWidget {
  final String text;
  const _WorldBubble(this.text);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: worldInk.withAlpha(235), border: Border.all(color: const Color(0xff806494)), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xffefdcff))));
}

class _WorldPainter extends CustomPainter {
  final WorldArt art;
  final ShopTraffic traffic;
  final ValueNotifier<double> clock;
  final bool night;
  final int level, bottles;
  _WorldPainter(this.art, this.traffic, this.clock, this.night, this.level, this.bottles) : super(repaint: clock);
  final pixel = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
  void tile(Canvas c, int index, Rect dest, {bool decoration = false}) {
    final image = decoration ? art.decor : art.tiles;
    final src = (decoration ? art.decorFrames : art.tileFrames)[index];
    final texture = !decoration && [0, 1, 2, 4].contains(index);
    c.drawImageRect(image, src, texture ? dest : fitSprite(src, dest), pixel);
  }
  void strip(Canvas c, int index, Rect dest, {bool vertical = false, bool decoration = true}) {
    final image = decoration ? art.decor : art.tiles;
    final src = (decoration ? art.decorFrames : art.tileFrames)[index];
    final scale = vertical ? dest.width / src.width : dest.height / src.height;
    final w = src.width * scale, h = src.height * scale;
    c.save(); c.clipRect(dest);
    if (vertical) {
      for (var y = dest.top; y < dest.bottom; y += h) {
        c.drawImageRect(image, src, Rect.fromLTWH(dest.left, y, w, h), pixel);
      }
    } else {
      for (var x = dest.left; x < dest.right; x += w) {
        c.drawImageRect(image, src, Rect.fromLTWH(x, dest.top, w, h), pixel);
      }
    }
    c.restore();
  }
  void sprite(Canvas c, int row, int frame, Rect dest) {
    final src = actorFrame(art.actors, row, frame);
    c.drawImageRect(art.actors, src, fitSprite(src, dest), pixel);
  }
  void cat(Canvas c) {
    final src = art.catFrames[catIdleFrame(clock.value)];
    final maxW = art.catFrames.map((r) => r.width).reduce(math.max);
    final maxH = art.catFrames.map((r) => r.height).reduce(math.max);
    final scale = math.min(53 / maxW, 33 / maxH);
    final dest = Rect.fromLTWH(512 - src.width * scale / 2, 190 - src.height * scale, src.width * scale, src.height * scale);
    c.drawImageRect(art.cat, src, dest, pixel);
  }
  void architecture(Canvas c, int frame, Rect dest) {
    final src = art.architectureFrames[frame];
    c.drawImageRect(art.architecture, src, fitSprite(src, dest), pixel);
  }
  void cauldron(Canvas c) => paintCauldronAssembly(c, art.cauldron, clock.value);
  void glow(Canvas c, Offset center, Color color, double radius) {
    c.drawCircle(center, radius, Paint()..shader = RadialGradient(colors: [color.withAlpha(night ? 60 : 36), color.withAlpha(0)]).createShader(Rect.fromCircle(center: center, radius: radius)));
  }
  void shadow(Canvas c, Rect rect) => c.drawOval(rect, Paint()..color = const Color(0x38301829));
  void person(Canvas c, int row, double x, double y, Facing facing, bool walking) {
    final center = Offset((x + .5) * ShopMap.tileSize, (y + .82) * ShopMap.tileSize);
    shadow(c, Rect.fromCenter(center: center, width: 25, height: 8));
    final frame = facing.index * 2 + (walking ? (clock.value * 6).floor() % 2 : 0);
    sprite(c, row, frame, Rect.fromLTWH(center.dx - 25, center.dy - 59, 50, 64));
  }
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 640, size.height / 352);
    canvas.save(); canvas.translate((size.width - 640 * scale) / 2, (size.height - 352 * scale) / 2); canvas.scale(scale);
    // Coordinates follow the approved 1536 x 1024 composition at 2.4 image pixels per world pixel.
    final room = Path()..moveTo(100, 13)..lineTo(178, 13)..lineTo(178, 7)..lineTo(281, 7)
      ..lineTo(281, 15)..lineTo(380, 15)..lineTo(380, 8)..lineTo(530, 8)
      ..lineTo(530, 29)..lineTo(570, 49)..lineTo(592, 95)..lineTo(615, 130)
      ..lineTo(620, 264)..lineTo(597, 289)..lineTo(579, 289)..lineTo(579, 328)
      ..lineTo(538, 341)..lineTo(399, 341)..lineTo(399, 326)..lineTo(365, 326)
      ..lineTo(354, 335)..lineTo(125, 335)..lineTo(100, 319)..lineTo(22, 308)
      ..lineTo(15, 258)..lineTo(29, 230)..lineTo(29, 156)..lineTo(16, 156)
      ..lineTo(16, 125)..lineTo(43, 122)..lineTo(43, 63)..lineTo(66, 54)..close();
    canvas.drawShadow(room, Colors.black, 9, false);
    canvas.save(); canvas.clipPath(room);
    canvas.drawRect(const Rect.fromLTWH(20, 14, 596, 334), Paint()..color = const Color(0xff6b4940));
    for (var y = 100.0; y < 344; y += 48) {
      for (var x = 24.0; x < 616; x += 64) { tile(canvas, 0, Rect.fromLTWH(x, y, 64, 48)); }
    }
    for (var x = 24.0; x < 616; x += 96) { tile(canvas, 4, Rect.fromLTWH(x, 15, 96, 108)); }
    // Continuous timber cornice joins independently placed wall modules.
    for (var x = 98.0; x < 545; x += 56) {
      canvas.drawRect(Rect.fromLTWH(x, 10, 55, 10), Paint()..color = const Color(0xff36222b));
      canvas.drawRect(Rect.fromLTWH(x, 12, 54, 4), Paint()..color = const Color(0xff684136));
      canvas.drawRect(Rect.fromLTWH(x, 17, 54, 2), Paint()..color = const Color(0xff241a25));
    }
    strip(canvas, 4, const Rect.fromLTWH(65, 101, 530, 43));
    canvas.drawRect(const Rect.fromLTWH(57, 140, 541, 5), Paint()..color = const Color(0x5032212b));
    for (var y = 75.0; y <= 270; y += 60) {
      tile(canvas, 4, Rect.fromLTWH(31, y, 27, 60)); tile(canvas, 4, Rect.fromLTWH(589, y, 25, 60));
    }
    for (final x in [33.0, 588.0]) {
      for (final y in [73.0, 226.0]) { tile(canvas, 12, Rect.fromLTWH(x, y, 21, 58), decoration: true); }
    }
    for (final edge in [
      Path()..moveTo(100, 18)..lineTo(52, 64)..lineTo(38, 125)..lineTo(38, 265),
      Path()..moveTo(530, 19)..lineTo(570, 51)..lineTo(600, 122)..lineTo(600, 270),
    ]) {
      canvas.drawPath(edge, Paint()..color = const Color(0xff30212e)..style = PaintingStyle.stroke..strokeWidth = 11..isAntiAlias = false);
      canvas.drawPath(edge, Paint()..color = const Color(0xff664438)..style = PaintingStyle.stroke..strokeWidth = 6..isAntiAlias = false);
    }
    // Rug, hearth and wall fixtures are independent tiles layered over the room shell.
    strip(canvas, 3, const Rect.fromLTWH(387, 159, 51, 159), vertical: true, decoration: false);
    for (var x = 456.0; x < 537; x += 27) {
      for (var y = 117.0; y < 161; y += 22) { tile(canvas, 2, Rect.fromLTWH(x, y, 27, 22)); }
    }
    for (var i = 0; i < 2; i++) {
      final src = art.wallFrames[i];
      final box = i == 0 ? const Rect.fromLTWH(174, 0, 160, 145) : const Rect.fromLTWH(378, 0, 169, 145);
      canvas.drawImageRect(art.walls, src, fitSprite(src, box), pixel);
    }
    tile(canvas, 2, const Rect.fromLTWH(349, 38, 34, 57), decoration: true);
    tile(canvas, 3, const Rect.fromLTWH(346, 99, 35, 47), decoration: true);
    tile(canvas, 3, const Rect.fromLTWH(532, 87, 40, 49), decoration: true);
    tile(canvas, 13, const Rect.fromLTWH(535, 42, 37, 54), decoration: true);
    tile(canvas, 2, const Rect.fromLTWH(548, 140, 29, 37), decoration: true);
    tile(canvas, 14, const Rect.fromLTWH(48, 112, 24, 35));
    tile(canvas, 14, const Rect.fromLTWH(570, 111, 25, 39));
    final visitor = traffic.visitor;
    final layers = <({double y, void Function() draw})>[
      (y: 150, draw: () { shadow(canvas, const Rect.fromLTWH(68, 138, 108, 13)); final src = art.bookcaseFrames.first; canvas.drawImageRect(art.bookcase, src, fitSprite(src, const Rect.fromLTWH(48, 0, 138, 152)), pixel); }),
      (y: 135, draw: () => person(canvas, 0, 9.5, 4.9, Facing.down, false)),
      (y: 159, draw: () {
        shadow(canvas, const Rect.fromLTWH(387, 146, 153, 16));
        tile(canvas, 11, const Rect.fromLTWH(386, 95, 77, 65));
        cauldron(canvas);
      }),
      (y: 185, draw: () { shadow(canvas, const Rect.fromLTWH(165, 171, 175, 18)); architecture(canvas, 0, const Rect.fromLTWH(160, 99, 182, 86)); }),
      (y: 190, draw: () => cat(canvas)),
      (y: 222, draw: () => tile(canvas, 12, const Rect.fromLTWH(538, 187, 31, 38))),
      (y: 246, draw: () => tile(canvas, 12, const Rect.fromLTWH(39, 191, 48, 58))),
      (y: 269, draw: () {
        shadow(canvas, const Rect.fromLTWH(225, 254, 119, 18));
        tile(canvas, 8, const Rect.fromLTWH(225, 190, 119, 79));
      }),
      (y: 265, draw: () => tile(canvas, 12, const Rect.fromLTWH(567, 225, 34, 43))),
      (y: 278, draw: () => tile(canvas, 10, const Rect.fromLTWH(70, 230, 41, 45), decoration: true)),
      (y: 284, draw: () => tile(canvas, 8, const Rect.fromLTWH(109, 252, 25, 30), decoration: true)),
      (y: 287, draw: () => tile(canvas, 14, const Rect.fromLTWH(548, 247, 44, 44), decoration: true)),
      if (visitor != null) (y: (visitor.y + .82) * ShopMap.tileSize, draw: () => person(canvas, visitor.appearance, visitor.x, visitor.y, visitor.facing, visitor.moving)),
    ]..sort((a, b) => a.y.compareTo(b.y));
    for (final layer in layers) { layer.draw(); }
    // Local shadows connect the modular furniture to the room instead of flattening the scene.
    // Cutaway front wall and wide entrance retain their original sprite proportions.
    strip(canvas, 5, const Rect.fromLTWH(114, 307, 258, 28));
    tile(canvas, 6, const Rect.fromLTWH(348, 288, 49, 44), decoration: true);
    tile(canvas, 7, const Rect.fromLTWH(548, 281, 56, 44), decoration: true);
    tile(canvas, 6, const Rect.fromLTWH(21, 253, 55, 41), decoration: true);
    tile(canvas, 11, const Rect.fromLTWH(68, 270, 49, 61), decoration: true);
    tile(canvas, 11, const Rect.fromLTWH(568, 278, 34, 52), decoration: true);
    architecture(canvas, 1, const Rect.fromLTWH(393, 282, 158, 62));
    canvas.drawRect(const Rect.fromLTWH(20, 8, 605, 340), Paint()..shader = const RadialGradient(
      center: Alignment(-.15, .05), radius: .85, colors: [Color(0x001c1026), Color(0x201c1026), Color(0x70180e24)],
      stops: [0, .65, 1]).createShader(const Rect.fromLTWH(20, 8, 605, 340)));
    if (night) canvas.drawRect(const Rect.fromLTWH(20, 14, 596, 334), Paint()..color = const Color(0xff231632).withAlpha(50));
    glow(canvas, const Offset(270, 61), const Color(0xffffc475), 68);
    glow(canvas, const Offset(500, 142), const Color(0xffffa75c), 54);
    glow(canvas, const Offset(500, 98), const Color(0xff8dd3b4), 28);
    glow(canvas, const Offset(59, 131), const Color(0xffffba70), 51);
    glow(canvas, const Offset(582, 136), const Color(0xffffba70), 47);
    if (!night) {
      final sunlight = Path()..moveTo(424, 319)..lineTo(505, 309)..lineTo(520, 266)..lineTo(453, 284)..close();
      canvas.drawPath(sunlight, Paint()..color = const Color(0xffffd28f).withAlpha(45));
    }
    canvas.restore(); canvas.restore();
  }  @override
  bool shouldRepaint(_WorldPainter old) => old.art != art || old.night != night || old.level != level || old.bottles != bottles || old.traffic != traffic;
}
/// One viewport: the world, a small HUD and a bottom dialogue overlay.
class ShopViewport extends StatefulWidget {
  final ShopWorld world;
  final Widget dialogue;
  final VoidCallback? onDialogueAction;
  final String dialogueAction;
  final Widget? workbench, management;
  final String dayLabel, goldLabel, stockLabel;
  final List<TextButton> actions;
  final String? guildLabel;
  final String? speakerName;
  final String systemMessage;
  final bool waiting;
  const ShopViewport({super.key, required this.world, required this.dialogue,
    required this.dayLabel, required this.goldLabel, required this.stockLabel, this.actions = const [], this.speakerName, this.guildLabel,
    this.workbench, this.management, this.waiting = false, this.systemMessage = '', this.onDialogueAction, this.dialogueAction = '물약 고르기'});
  @override
  State<ShopViewport> createState() => _ShopViewportState();
}
class _ShopViewportState extends State<ShopViewport> {
  int tab = 0;
  int guildVisit = 0;
  bool panelOpen = false, talking = false;
  Size? visiblePanelSize;
  bool get hasCustomer => widget.world.customerId != null;
  @override
  void initState() { super.initState(); panelOpen = !hasCustomer; }
  @override
  void didUpdateWidget(ShopViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.world.customerId != widget.world.customerId) {
      talking = false; tab = 0; panelOpen = !hasCustomer;
    } else if (oldWidget.world.speech != widget.world.speech && hasCustomer) {
      panelOpen = false; tab = 0; talking = true;
    }
  }
  void close() => setState(() { panelOpen = false; talking = false; });
  void talk() { if (!widget.waiting) setState(() { tab = 0; panelOpen = false; talking = !talking; }); }
  void choose() {
    if (widget.waiting) return;
    if (widget.onDialogueAction != null) { widget.onDialogueAction!(); return; }
    setState(() { talking = false; tab = 0; panelOpen = true; });
  }
  void menu(int index) {
    if (index == 0 && hasCustomer) { talk(); return; }
    setState(() { tab = index; talking = false; panelOpen = true; });
  }
  void openGuildOrder() {
    // A direct order shortcut starts at the order page, not a remembered subtab.
    setState(() { guildVisit++; tab = 2; talking = false; panelOpen = true; });
    if (scrolls[2].hasClients) scrolls[2].jumpTo(0);
  }
  final scrolls = List.generate(3, (_) => ScrollController());
  @override
  void dispose() { for (final s in scrolls) { s.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => CallbackShortcuts(bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
    child: Focus(autofocus: true, child: Scaffold(backgroundColor: worldInk, body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
      if (Navigator.canPop(context)) IconButton(tooltip: '타이틀로 돌아가기',
        icon: const GameIcon(GameGlyph.back), onPressed: () => Navigator.maybePop(context)),
      Expanded(child: Align(alignment: Alignment.centerLeft, child: SkinPanel(skin: Skin.parchment, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(widget.dayLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff392433), fontSize: 14, fontWeight: FontWeight.bold)))))),
      if (widget.guildLabel != null) Padding(padding: const EdgeInsets.only(right: 12),
        child: SkinPanel(skin: Skin.parchment, child: TextButton(onPressed: openGuildOrder,
          child: Text(widget.guildLabel!, style: const TextStyle(color: Color(0xff392433), fontSize: 13))))),
      SkinPanel(skin: Skin.dialogue, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const GameIcon(GameGlyph.coin, size: 24), const SizedBox(width: 6), Text(widget.goldLabel, style: const TextStyle(color: worldGold, fontSize: 18))]))),
      SizedBox(width: 48, height: 48, child: panelOpen ? null : IconButton(tooltip: talking ? '대화 닫기' : '손님 응대 열기',
        icon: GameIcon(panelOpen || talking ? GameGlyph.close : GameGlyph.talk),
        onPressed: panelOpen || talking ? close : () => menu(0))),
    ])),
    Expanded(child: LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final proposedHeight = math.min(constraints.maxHeight * .95, tab == 0 && !hasCustomer ? 380.0 : compact ? 540.0 : tab == 0 ? 600.0 : 760.0);
      final proposedWidth = compact ? constraints.maxWidth - 16 : tab == 0
        ? math.min(hasCustomer ? math.min(850.0, (proposedHeight - 90) * 1.12 + 290) : 660.0, constraints.maxWidth - 60)
        : math.min(800.0, (proposedHeight - 120) * 1.3);
      if (panelOpen || visiblePanelSize == null) visiblePanelSize = Size(proposedWidth, proposedHeight);
      final panelWidth = visiblePanelSize!.width;
      final panelHeight = visiblePanelSize!.height;
      return Stack(children: [
        // The live world stays visible and mounted while any menu is open.
        Positioned(left: 0, right: 0, top: 0, bottom: 0,
          child: widget.world.interaction(visible: talking && !panelOpen, talk: talk, action: choose, label: widget.dialogueAction,
            station: (id) => menu(id == 'book' || id == 'research' ? 1 : 2))),
        Positioned.fill(child: IgnorePointer(ignoring: !panelOpen, child: AnimatedOpacity(opacity: panelOpen ? 1 : 0, duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180), child: GestureDetector(onTap: close, child: const ColoredBox(color: Color(0x700c0814)))))),
        Positioned(key: const ValueKey('shop-panel'), left: (constraints.maxWidth - panelWidth) / 2,
          width: panelWidth, top: (constraints.maxHeight - panelHeight) / 2, height: panelHeight,
          child: GameReveal(visible: panelOpen,
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1060),
              child: panelFrame(Column(children: [
                Padding(padding: const EdgeInsets.fromLTRB(18, 4, 6, 0), child: Row(children: [
                  SkinPanel(skin: Skin.dialogue, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text([widget.speakerName == null ? '상점 수첩' : '물약 진열장', '작업대', '상점 관리'][tab], style: const TextStyle(color: worldGold)))),
                  const Spacer(),
                  IconButton(tooltip: '패널 닫기', onPressed: close, icon: const GameIcon(GameGlyph.close),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
                ])),
                Expanded(child: IndexedStack(index: tab, children: [
                  page(0, widget.dialogue),
                  page(1, widget.workbench ?? const Text('연구와 제조를 준비하고 있어요.')),
                  page(2, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (widget.management != null) KeyedSubtree(key: ValueKey(guildVisit), child: widget.management!), ...widget.actions,
                  ])),
                ])),
              ])),
            )))),
      ]);
    })),    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: Row(children: [for (var i = 0; i < 3; i++) Expanded(child: Semantics(selected: tab == i,
        child: SkinPanel(skin: tab == i && (panelOpen || talking) ? Skin.selected : Skin.dialogue,
          child: TextButton(onPressed: i == 0 && widget.waiting ? null : () => menu(i), style: TextButton.styleFrom(minimumSize: const Size(0, 72),
          foregroundColor: tab == i ? worldGold : const Color(0xffc5b6ce), backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder()), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Badge(isLabelVisible: i == 0 && tab != 0 && widget.speakerName != null,
              child: GameIcon([GameGlyph.talk, GameGlyph.flask, GameGlyph.shop][i], size: 30)),
            const SizedBox(height: 6), Text(['손님 응대', '작업대', '상점 관리'][i], style: const TextStyle(fontSize: 13)),
          ]))))),
      ])))),
  ])))));
  Widget panelFrame(Widget child) => SkinPanel(skin: Skin.dialogue, painted: tab == 0 && !hasCustomer, child: child);
  Widget page(int index, Widget child) => SingleChildScrollView(controller: scrolls[index], padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child)));
}
class WorldPortrait extends StatelessWidget {
  final String name;
  const WorldPortrait({super.key, required this.name});
  @override
  Widget build(BuildContext context) => FutureBuilder<WorldArt>(future: WorldArt.load(), builder: (context, snapshot) =>
    snapshot.hasData ? CustomPaint(painter: _PortraitPainter(snapshot.data!.actors, customerAppearance(name))) : const SizedBox());
}
class _PortraitPainter extends CustomPainter {
  final ui.Image image;
  final int row;
  _PortraitPainter(this.image, this.row);
  @override
  void paint(Canvas canvas, Size size) {
    final frame = actorFrame(image, row, 0);
    final src = Rect.fromLTWH(frame.left + frame.width * .22, frame.top,
      frame.width * .64, frame.height * .70);
    canvas.drawImageRect(image, src, fitSprite(src, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  }
  @override
  bool shouldRepaint(_PortraitPainter old) => old.image != image || old.row != row;
}




void paintCauldronAssembly(Canvas c, ui.Image atlas, double seconds) {
    final pixel = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
    final w = atlas.width / 4, h = atlas.height / 2;
    final base = Rect.fromLTWH(0, 0, w, h);
    final dest = fitSprite(base, const Rect.fromLTWH(452, 39, 98, 118));
    final scale = dest.width / w;
    // All structural pixels come from ONE source frame. Generated frames are not registered.
    // Only animated regions can change: smoke, liquid inside the rim and the central flame.
    c.save();
    c.clipRect(Rect.fromLTRB(dest.left, dest.top + h * .438 * scale, dest.right, dest.bottom));
    c.drawImageRect(atlas, base, dest, pixel);
    c.restore();
    final frame = [0, 1, 2, 3, 2, 1][(seconds * 6).floor() % 6];
    final src = Rect.fromLTWH(frame * w, 0, w, h);
    final smoke = Rect.fromLTRB(dest.left, dest.top, dest.right, dest.top + h * .438 * scale);
    final liquid = Rect.fromLTWH(dest.left + w * .34 * scale, dest.top + h * .463 * scale, w * .33 * scale, h * .066 * scale);
    final fire = Path()
      ..moveTo(dest.left + w * .37 * scale, dest.top + h * .805 * scale)
      ..lineTo(dest.left + w * .40 * scale, dest.top + h * .73 * scale)
      ..lineTo(dest.left + w * .49 * scale, dest.top + h * .655 * scale)
      ..lineTo(dest.left + w * .60 * scale, dest.top + h * .73 * scale)
      ..lineTo(dest.left + w * .65 * scale, dest.top + h * .805 * scale)..close();
    for (final clip in [Path()..addRect(smoke), Path()..addOval(liquid), fire]) {
      c.save(); c.clipPath(clip); c.drawImageRect(atlas, src, dest, pixel); c.restore();
    }
  }


