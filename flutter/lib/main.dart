import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

const ink = Color(0xff21132f);
const lavender = Color(0xffc9a9ef);
const parchment = Color(0xffffe7bb);
const brass = Color(0xffe9b568);

void main() => runApp(const PotionShop());

class PotionShop extends StatelessWidget {
  const PotionShop({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '달빛 물약 상점', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8055b5), brightness: Brightness.dark),
      textTheme: const TextTheme(bodyMedium: TextStyle(height: 1.5)),
      useMaterial3: true),
    home: const ShopScreen(),
  );
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Game game = Game();
  SharedPreferences? prefs;
  bool ready = false;
  String status = '달빛이 머무는 작은 상점에 오신 걸 환영해요.';
  Future<void> saveQueue = Future<void>.value();
  @override
  void initState() { super.initState(); unawaited(load()); }
  Future<void> load() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final saved = prefs!.getString('potionshop.v1');
      if (saved != null) game = Game.decode(saved);
    } catch (_) { status = '저장 기록을 불러오지 못했어요. 새 상점으로 시작합니다.'; }
    if (mounted) setState(() => ready = true);
  }
  void persist() {
    final encoded = game.encode();
    saveQueue = saveQueue.then((_) async {
      try {
        final stored = await prefs?.setString('potionshop.v1', encoded);
        if (stored != true && mounted) setState(() => status = '저장할 수 없어요. 이번 플레이는 현재 화면에서 유지됩니다.');
      } catch (_) { if (mounted) setState(() => status = '저장에 실패했어요. 현재 플레이는 계속할 수 있습니다.'); }
    });
  }
  void sell(Potion potion) {
    final error = game.sell(potion.id);
    setState(() => status = error ?? '${potion.name} 판매 완료! +${potion.price} G');
    if (error == null) persist();
  }
  void brew(Potion potion) {
    final error = game.brew(potion.id);
    setState(() => status = error ?? '${potion.name} ${game.level}병을 만들었어요.');
    if (error == null) persist();
  }
  Future<void> recipes() async {
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, refresh) => Dialog(
        backgroundColor: ink,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('나의 레시피북', style: TextStyle(fontSize: 23, color: brass, fontWeight: FontWeight.bold))), IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close), tooltip: '닫기')]),
            const Text('발견한 레시피는 언제든 다시 만들 수 있어요.', style: TextStyle(color: lavender)),
            const SizedBox(height: 16),
            for (final p in potions) Padding(padding: const EdgeInsets.only(bottom: 14), child: PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Bottle(id: p.id), const SizedBox(width: 12), Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))]),
              const SizedBox(height: 8), Text(p.description), Text(p.ingredients, style: const TextStyle(color: lavender, fontSize: 12)),
              const SizedBox(height: 12),
              PixelButton(label: '${game.level}병 생산 · ${p.cost * game.level} G', icon: Icons.science_outlined,
                onPressed: game.gold >= p.cost * game.level ? () { brew(p); refresh(() {}); } : null),
              const SizedBox(height: 6), Text('재고 ${game.stock[p.id]}병 · 보유 ${game.gold} G', style: const TextStyle(color: brass)),
            ]))),
          ])),
        ),
      ),
    ));
  }
  Future<void> upgrades() async {
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => Dialog(
      backgroundColor: ink, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [const Expanded(child: Text('가마솥 공방', style: TextStyle(fontSize: 22, color: brass))), IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close), tooltip: '닫기')]),
        const Icon(Icons.auto_awesome, size: 56, color: lavender), const SizedBox(height: 16),
        Text('가마솥 Lv.${game.level}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10), Text(game.level >= 3 ? '가마솥이 최고 단계에 도달했어요!' : '한 번에 ${game.level + 1}병을 생산할 수 있어요.\n재료비는 생산하는 병 수만큼 필요합니다.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        PixelButton(label: game.level >= 3 ? '개선 완료' : '설비 개선 · ${game.upgradeCost} G', icon: Icons.build_outlined,
          onPressed: game.level < 3 && game.gold >= game.upgradeCost ? () {
            if (game.upgrade()) { setState(() => status = '가마솥이 Lv.${game.level}로 성장했어요!'); persist(); refresh(() {}); }
          } : null),
        const SizedBox(height: 12), Text('보유 ${game.gold} G', style: const TextStyle(color: brass)),
      ]))),
    )));
  }
  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(body: SafeArea(child: LayoutBuilder(builder: (context, limits) {
      final wide = limits.maxWidth >= 950;
      final scene = ShopRoom(game: game);
      final controls = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OrderPanel(game: game), const SizedBox(height: 12),
        if (!game.closed) ...[
          const Text('손님에게 건넬 물약', style: TextStyle(color: lavender, fontSize: 13)), const SizedBox(height: 8),
          for (final p in potions) Padding(padding: const EdgeInsets.only(bottom: 8), child: PixelButton(
            label: '${p.name}\n${p.price} G · 재고 ${game.stock[p.id]}병', icon: null, leading: Bottle(id: p.id),
            onPressed: (game.stock[p.id] ?? 0) > 0 ? () => sell(p) : null)),
        ] else ...[
          PixelPanel(child: Column(children: [
            const Text('오늘도 수고했어요!', style: TextStyle(fontSize: 20, color: brass)),
            Text('판매 ${game.served}건 · 매출 ${game.revenue} G'),
            Text('생산 재료비 ${game.spending} G'),
          ])), const SizedBox(height: 12),
          PixelButton(label: '다음 날 영업 시작', icon: Icons.wb_sunny_outlined, onPressed: () {
            if (game.nextDay()) { setState(() => status = '새로운 하루, 새로운 손님이 기다려요.'); persist(); }
          }),
        ],
        const SizedBox(height: 12),
        Row(children: [Expanded(child: PixelButton(label: '레시피북', icon: Icons.menu_book, onPressed: recipes)), const SizedBox(width: 10), Expanded(child: PixelButton(label: '설비 개선', icon: Icons.settings_outlined, onPressed: upgrades))]),
        const SizedBox(height: 12), Semantics(liveRegion: true, child: Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: lavender))),
        const SizedBox(height: 8), const Text('상점 화면 프로토타입 · 연구와 주간 경영은 다음 단계', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xff9279aa))),
      ]);
      return Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), child: Row(children: [
          const Icon(Icons.nightlight_round, color: brass, size: 22), const SizedBox(width: 8),
          const Expanded(child: Text('달빛 물약 상점', style: TextStyle(fontSize: 19, color: parchment, fontWeight: FontWeight.bold))),
          Text('${game.day}일째', style: const TextStyle(color: lavender)), const SizedBox(width: 18),
          Text('${game.gold} G', style: const TextStyle(color: brass, fontWeight: FontWeight.bold, fontSize: 18)),
        ])),
        Expanded(child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Center(child: scene)),
          SizedBox(width: 360, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(10, 12, 20, 20), child: controls)),
        ]) : SingleChildScrollView(child: Column(children: [scene, Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), child: controls)]))),
      ]);
    })));
  }
}

class ShopRoom extends StatelessWidget {
  final Game game;
  const ShopRoom({super.key, required this.game});
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 4 / 3, child: LayoutBuilder(builder: (context, size) {
    final w = size.maxWidth, h = size.maxHeight;
    return Stack(children: [
      Positioned.fill(child: Image.asset('assets/art/shop.png', fit: BoxFit.fill, filterQuality: FilterQuality.none, semanticLabel: '보라색 벽, 촛불, 가마솥과 물약 진열대가 있는 상점')),
      // Only the head and shoulders show above the existing background counter.
      Positioned(left: w * .435, top: h * .292, width: w * .13, height: h * .154,
        child: ClipRect(child: OverflowBox(alignment: Alignment.topCenter,
          minWidth: w * .13, maxWidth: w * .13, minHeight: h * .26, maxHeight: h * .26,
          child: Image.asset('assets/art/witch.png', fit: BoxFit.contain, filterQuality: FilterQuality.none)))),
      if (!game.closed) Positioned(left: w * .458, top: h * .57, width: w * .10, height: h * .20,
        child: Image.asset('assets/art/customer.png', fit: BoxFit.contain, filterQuality: FilterQuality.none, semanticLabel: '초록 망토를 입은 손님')),
      Positioned(left: 14, bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: ink.withAlpha(220), child: Text('영업 중  ·  ${game.customer}/${orders.length}명 응대', style: const TextStyle(color: parchment, fontSize: 12)))),
      Positioned(right: 14, bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: ink.withAlpha(220), child: Text('가마솥 Lv.${game.level}', style: const TextStyle(color: brass, fontSize: 12)))),
    ]);
  }));
}

class OrderPanel extends StatelessWidget {
  final Game game;
  const OrderPanel({super.key, required this.game});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: parchment, border: Border.all(color: brass, width: 3), boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 4))]),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!game.closed) ...[SizedBox(width: 46, height: 66, child: Image.asset('assets/art/customer.png', fit: BoxFit.contain, filterQuality: FilterQuality.none)), const SizedBox(width: 12)],
      Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Column(key: ValueKey('${game.day}-${game.customer}'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(game.closed ? '영업 마감' : orders[game.customer].$1, style: const TextStyle(color: Color(0xff775038), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(game.closed ? '모든 손님이 돌아갔어요.\n내일을 위해 물약을 준비해 볼까요?' : orders[game.customer].$2, style: const TextStyle(color: ink, fontSize: 15, height: 1.55)),
      ]))),
    ]),
  );
}

class PixelPanel extends StatelessWidget {
  final Widget child;
  const PixelPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xff322043), border: Border.all(color: const Color(0xff775593), width: 2)), child: child);
}

class PixelButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  const PixelButton({super.key, required this.label, required this.icon, this.leading, this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff493065), foregroundColor: parchment, disabledForegroundColor: const Color(0xff8c7a9a), minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), shape: const RoundedRectangleBorder(), side: BorderSide(color: onPressed == null ? const Color(0xff574365) : brass, width: 2)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (leading != null) ...[leading!, const SizedBox(width: 10)] else if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
      Flexible(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.5))),
    ]),
  );
}

class Bottle extends StatelessWidget {
  final String id;
  const Bottle({super.key, required this.id});
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(28, 36), painter: BottlePainter(id));
}

class BottlePainter extends CustomPainter {
  final String id;
  BottlePainter(this.id);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 14, size.height / 18);
    void block(double x, double y, double w, double h, Color color) => canvas.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = color..isAntiAlias = false);
    final color = id == 'sleep' ? const Color(0xffab6ae8) : id == 'sight' ? const Color(0xff6ad5ef) : const Color(0xff83cf81);
    block(4, 0, 6, 3, const Color(0xffbf8651)); block(3, 3, 8, 4, lavender);
    block(1, 7, 12, 10, lavender); block(0, 9, 14, 6, lavender);
    block(2, 9, 10, 7, color); block(4, 4, 6, 5, const Color(0xff4b385e));
    block(3, 9, 2, 4, const Color(0xfff2e5ff)); block(4, 8, 2, 1, Colors.white);
    block(3, 17, 8, 1, const Color(0xff74508c));
  }
  @override
  bool shouldRepaint(BottlePainter oldDelegate) => oldDelegate.id != id;
}
