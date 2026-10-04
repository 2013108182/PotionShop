import 'ui_art.dart';
import 'title_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'research_screen.dart';
import 'research_session.dart';
import 'opening_screen.dart';
import 'shop_world.dart';
import 'game_skin.dart';
import 'shop_tasks.dart';

const ink = Color(0xff21132f);
const lavender = Color(0xffc9a9ef);
const parchment = Color(0xffffe7bb);
const brass = Color(0xffe9b568);
const gap = SizedBox(height: 12);
void main() => runApp(const PotionShop());
class PotionShop extends StatelessWidget {
  final bool? researchFirst; const PotionShop({super.key, this.researchFirst});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '달빛 물약 상점', debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Galmuri', brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8055b5), brightness: Brightness.dark),
      textTheme: const TextTheme(bodyMedium: TextStyle(height: 1.5)), useMaterial3: true),
    routes: {'/shop': (_) => const ShopScreen(), '/research': (_) => const ResearchStudio()}, home: researchFirst == true ? const ResearchStudio()
      : researchFirst == false ? const ShopScreen() : TitleScreen(
        opening: () => OpeningJourney(onFinished: () => const ShopScreen(saveKey: storySaveKey)),
        shop: (key) => ShopScreen(saveKey: key)));
}
class ShopScreen extends StatefulWidget {
  final String saveKey;
  const ShopScreen({super.key, this.saveKey = 'potionshop.v2'});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}
class _ShopScreenState extends State<ShopScreen> {
  Game game = Game();
  SharedPreferences? prefs;
  bool ready = false, customerReady = false;
  String? arrivedId;
  String? responseId, responseName, responseText;
  Timer? statusTimer;
  String status = '';
  Future<void> saveQueue = Future<void>.value();
  @override
  void initState() { super.initState(); unawaited(load()); }
  Future<void> load() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final saved = prefs!.getString(widget.saveKey);
      if (saved != null) { game = Game.decode(saved); }
      else if (prefs!.containsKey('potionshop.v1')) { status = '새 이야기는 1일째부터 시작해요. 이전 상점 저장은 별도로 보관되어 있어요.'; }
      final studioSave = prefs!.getString('potionshop.research.v1');
      if (widget.saveKey == 'potionshop.v2' && studioSave != null && !game.knows('sight')) {
        final studio = ResearchSession.decode(studioSave);
        if (studio.solved) {
          game.attempts = [...studio.attempts];
          game.researchNotebook = studio.encode();
          game.researchRequested = true;
          game.discovered.add('sight');
          game.stock['sight'] = game.stock['sight']! + 1;
          status = '연구실에서 발견한 시야 물약을 레시피북에 옮겼어요. 실험 물약 1병도 보관했어요.';
          await prefs!.setString(widget.saveKey, game.encode());
        }
      }
    } catch (_) { status = '기록을 불러오지 못했어요. 새 상점으로 시작합니다.'; }
    if (mounted) setState(() => ready = true);
  }
  @override
  void dispose() { statusTimer?.cancel(); super.dispose(); }
  void change(String message) {
    statusTimer?.cancel();
    setState(() => status = message);
    statusTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() => status = ''); });
    final encoded = game.encode();
    saveQueue = saveQueue.then((_) async {
      try {
        final stored = await prefs?.setString(widget.saveKey, encoded);
        if (stored != true && mounted) setState(() => status = '저장할 수 없어요. 이번 플레이는 현재 화면에서 유지됩니다.');
      } catch (_) { if (mounted) setState(() => status = '저장에 실패했어요. 현재 플레이는 계속할 수 있어요.'); }
    });
  }
  Future<void> openBook() async {
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => Dialog(
      backgroundColor: ink, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        dialogTitle('나의 레시피북', dialogContext),
        const Text('생산에는 레시피의 재료가 각각 1개씩 필요해요.', style: TextStyle(color: lavender)), gap,
        for (final p in potions) Padding(padding: const EdgeInsets.only(bottom: 12), child: PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(game.knows(p.id) ? p.name : '미발견 · 어둠 속 시야를 밝히는 물약', style: const TextStyle(color: brass, fontSize: 17, fontWeight: FontWeight.bold)),
          if (game.knows(p.id)) ...[
            Text(p.description), Text(p.ingredientText, style: const TextStyle(color: lavender)),
            for (final id in p.recipe) Text('${ingredientName(id)} ${game.materials[id]}개 / 필요 ${game.level}개', style: const TextStyle(fontSize: 12)), gap,
            PixelButton(label: '${game.level}병 생산 · 재료 각 ${game.level}개', icon: Icons.science_outlined,
              onPressed: game.canBrew(p) ? () { final error = game.brew(p.id); change(error ?? '${p.name} ${game.level}병을 만들었어요.'); refresh(() {}); } : null),
            Text('완성품 재고 ${game.stock[p.id]}병', style: const TextStyle(color: brass)),
          ] else const Text('엘리의 부탁을 듣고 밤 연구실에서 발견해 보세요.'),
        ]))),
      ]))))));
  }
  Widget dialogTitle(String title, BuildContext dialogContext) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 22, color: brass, fontWeight: FontWeight.bold))),
    IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const GameIcon(GameGlyph.close), tooltip: '닫기'),
  ]);
  Future<void> openMaterials() async {
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => Dialog(
      backgroundColor: ink, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        dialogTitle(game.supplierUnlocked ? '희귀 재료 상인 세이지' : '재료 상인 로빈', dialogContext),
        Text('보유 ${game.gold} G · 연구와 생산이 같은 창고를 사용해요.', style: const TextStyle(color: lavender)), gap,
        for (final i in ingredients) Padding(padding: const EdgeInsets.only(bottom: 10), child: PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(i.name, style: const TextStyle(color: brass, fontWeight: FontWeight.bold)), Text(i.lore),
          Text('보유 ${game.materials[i.id]}개', style: const TextStyle(color: lavender)),
          if (i.rare && !game.supplierUnlocked) const Text('길잡이 조합의 특별 주문을 완료하면 거래할 수 있어요.', style: TextStyle(fontSize: 12))
          else PixelButton(label: '3개 구입 · ${i.price * 3} G', icon: Icons.shopping_bag_outlined,
            onPressed: game.gold >= i.price * 3 ? () { if (game.buy(i.id)) { change('${i.name} 3개를 구입했어요.'); refresh(() {}); } } : null),
        ]))),
      ]))))));
  }
  Future<void> openUpgrades() async {
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => Dialog(
      backgroundColor: ink, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        dialogTitle('가마솥 공방', dialogContext), const GameIcon(GameGlyph.flask, size: 50), gap,
        Text('가마솥 Lv.${game.level}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), gap,
        Text(game.level >= 3 ? '최고 단계에 도달했어요!' : '한 번에 ${game.level + 1}병을 생산해요.\n재료도 병 수만큼 필요해요.', textAlign: TextAlign.center), gap,
        PixelButton(label: game.level >= 3 ? '개선 완료' : '설비 개선 · ${game.upgradeCost} G', icon: Icons.build_outlined,
          onPressed: game.level < 3 && game.gold >= game.upgradeCost && !game.completed ? () {
            if (game.upgrade()) { change('가마솥이 Lv.${game.level}로 성장했어요!'); refresh(() {}); }
          } : null), gap, Text('보유 ${game.gold} G', style: const TextStyle(color: brass)),
      ]))))));
  }
  Future<void> restart() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('새 이야기로 시작할까요?'), content: const Text('현재 3일 이야기의 진행 기록을 새로 시작해요.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('이어 하기')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('1일째부터 시작'))]));
    if (confirmed == true && mounted) { game = Game(); change('새로운 상점의 첫날이에요.'); }
  }
  Widget milestone() => PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(game.completed ? '길잡이 조합의 감사 편지' : '특별 주문 · 밤 숲길을 밝히는 빛', style: const TextStyle(color: brass, fontSize: 18, fontWeight: FontWeight.bold)), gap,
    Text(game.completed ? '당신의 물약 덕분에 야간 안내가 시작됐어요.\n희귀 재료 상인 세이지가 거래를 제안합니다. 새로운 재료를 살펴보세요!' : '시야 물약 3병을 조합에 보내 주세요.\n보상 120 G · 희귀 재료 상인 해금\n마감 없이 준비되는 날 납품할 수 있어요.'), gap,
    if (!game.completed) PixelButton(label: '시야 물약 3병 납품 · 재고 ${game.stock['sight']}병', icon: Icons.local_shipping_outlined,
      onPressed: game.knows('sight') && game.stock['sight']! >= 3 ? () { if (game.deliver()) change('첫 특별 주문 완료! 세이지와의 거래가 열렸어요. +120 G'); } : null)
    else ...[
      PixelButton(label: '희귀 재료 상인 만나기', icon: Icons.storefront, onPressed: openMaterials), gap,
      const Text('첫 세 날의 이야기를 마쳤어요.\n맨드레이크와 요정 가루는 다음 연구를 위한 재료예요.', style: TextStyle(color: lavender)), gap,
      PixelButton(label: '새 이야기 시작', icon: Icons.replay, onPressed: restart),
    ],
  ]));
  String? get visitorId => responseId ?? (!game.night && !game.serviceFinished
      ? '${game.day}-${game.customer}' : null);
  bool get canServe => customerReady && arrivedId == visitorId;
  Future<void> research() async {
    if (!game.night) { change('연구는 영업을 마친 뒤에 할 수 있어요.'); return; }
    if (!game.researchRequested) { change('손님의 새로운 부탁이 생기면 연구할 수 있어요.'); return; }
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ResearchStudio(game: game, onGameChanged: change)));
    if (mounted) setState(() {});
  }
  void station(String id) {
    switch (id) {
      case 'book': openBook();
      case 'materials': openMaterials();
      case 'upgrade': openUpgrades();
      case 'research': research();
    }
  }
  Widget controls() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

    if (visitorId != null && !canServe) ...[
      const Text('손님이 진열대를 둘러보고 있어요.', style: TextStyle(color: parchment, fontSize: 16)),
      const Text('카운터에 도착하면 주문을 받을 수 있어요. 그동안 레시피북에서 재고를 준비해도 좋아요.', style: TextStyle(color: lavender, fontSize: 12)),
    ] else if (visitorId != null) ...[
      PotionSelection(key: ValueKey(visitorId), game: game, enabled: canServe,
        order: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(game.orders[game.customer].$1, style: TextStyle(color: brass, fontSize: 17)),
          const SizedBox(height: 12), Text(game.orders[game.customer].$2),
          TextButton(onPressed: () { setState(() => responseText = game.orderClarification); }, child: const Text('어떤 효능이 필요하세요?')),
      TextButton(onPressed: canServe ? () {
        final wanted = game.orders[game.customer].$3;
        if (game.skipCustomer()) { responseText = null; responseName = null; change(wanted == 'sight' ? '엘리의 부탁을 기록했어요. 밤에 연구하고 다시 만나 보세요.' : '손님이 다음 기회에 오기로 했어요.'); }
      } : null, child: Text(game.knows(game.orders[game.customer].$3) ? '오늘은 주문을 받지 않기' : '아직 없어요 · 요청 기록하기')),
        ]), onGive: (id) {
          final previousId = visitorId, name = game.orders[game.customer].$1;
          final before = game.gold, customerBefore = game.customer;
          final error = game.sell(id);
          if (error == null) {
            responseId = previousId; responseName = name;
            responseText = '고마워요! 잘 쓸게요. 다음에 또 들를게요.';
          }
          if (error != null && (game.wrongOffers > 0 || game.customer != customerBefore)) {
            responseName = name; responseText = error;
            if (game.customer != customerBefore) responseId = previousId;
          }
          change(error == null ? '+${game.gold - before} G · 판매 완료' :
            game.customer != customerBefore ? '손님이 구매하지 않고 떠났어요 · 놓친 주문 +1' : '');
        }),
    ] else ...[
      Text(game.night ? '연구실 · 어둠 속 시야' : '영업 마감', style: const TextStyle(color: brass, fontSize: 16)),
      Text('판매 ${game.served}건 · 매출 ${game.revenue} G · 지출 ${game.spending + game.investment} G', style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      if (!game.night) PixelButton(label: '밤 연구실로 가기', icon: Icons.nightlight_round,
        onPressed: () { if (game.startNight()) change('촛불을 켰어요. 손님의 부탁을 새로운 레시피로 바꿔 볼까요?'); }),
      if (game.night) ...[
        if (game.researchRequested && !game.knows('sight')) PixelButton(label: '엘리의 물약 연구하기', icon: Icons.science, onPressed: research),
        const SizedBox(height: 6),
        PixelButton(label: '준비를 마치고 ${game.day + 1}일째 시작', icon: Icons.wb_sunny_outlined,
          onPressed: () { if (game.nextDay()) change('새로운 하루예요. 연구 기록과 창고는 그대로 남아 있어요.'); }),
        if (game.gold < 18 && !game.aidDays.contains(game.day)) TextButton(onPressed: () {
          if (game.requestAid()) change('기본 재료 각 1개와 숙면 물약 1병을 받았어요.');
        }, child: const Text('스승의 지원 받기 · 오늘 밤 1회')),
      ],
    ],

  ]);
  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ShopViewport(systemMessage: status,
      guildLabel: game.day >= 3 ? (game.completed ? '협회 납품 완료' : '협회 주문 · ${game.stock['sight']}/3') : null,
      dialogueAction: responseId == null ? '물약 고르기' : '대화 마치기',
      onDialogueAction: responseId == null ? null : () => setState(() { responseId = null; responseName = null; responseText = null; customerReady = false; }),
      waiting: visitorId != null && !canServe,
      workbench: ShopTasks(game: game, management: false, canResearch: game.night && game.researchRequested && !game.knows('sight'), onResearch: research, onChanged: change),
      management: ShopTasks(game: game, management: true, canResearch: false, onResearch: research, onChanged: change),
      speakerName: visitorId == null ? null : responseName ?? game.orders[game.customer].$1,
      dayLabel: '${game.day}일째 · ${game.night ? '밤 연구와 준비' : '낮 영업'}',
      goldLabel: '${game.gold} G', stockLabel: '숙면 ${game.stock['sleep']} · 시야 ${game.stock['sight']}',
      world: ShopWorld(customerId: visitorId, customerName: visitorId == null ? '' : responseName ?? game.orders[game.customer].$1,
        speech: visitorId == null ? null : responseText ?? game.orders[game.customer].$2, night: game.night, level: game.level, bottles: game.stock['sleep']! + game.stock['sight']!, onStation: station,
        onReady: (value) { if (mounted) setState(() { customerReady = value; arrivedId = value ? visitorId : null; }); }),
      dialogue: responseId == null ? controls() : const SizedBox.shrink(),

    );
  }
}
class ResearchPanel extends StatelessWidget {
  final Game game;
  final ValueChanged<String> onChanged;
  const ResearchPanel({super.key, required this.game, required this.onChanged});
  @override
  Widget build(BuildContext context) => PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('연구실 · 어둠 속 시야', style: TextStyle(color: brass, fontSize: 19)), gap,
    Text(game.knows('sight') ? '시야 물약 연구가 끝났어요. 레시피북에서 생산할 수 있어요.' : '엘리가 밤 숲길을 밝힐 물약을 부탁했어요. 재료의 성질과 실험 기록으로 조합을 찾아보세요.'), gap,
    if (game.researchRequested) PixelButton(label: '연구실 열기', icon: Icons.science,
      onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ResearchStudio(game: game, onGameChanged: onChanged)))),
    const Text('연구는 재료를 소모하지 않아요. 생산할 때만 재료가 필요해요.', style: TextStyle(color: lavender, fontSize: 12)),
  ]));
}
class PixelPanel extends StatelessWidget {
  final Widget child;
  const PixelPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SkinPanel(skin: Skin.dialogue, child: Padding(padding: const EdgeInsets.all(20), child: child));
}

class PixelButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  const PixelButton({super.key, required this.label, required this.icon, this.leading, this.onPressed});
  @override
  Widget build(BuildContext context) => SkinPanel(skin: Skin.button, child: OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: parchment, disabledForegroundColor: const Color(0xff8c7a9a), minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), shape: const RoundedRectangleBorder(), side: BorderSide.none),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (leading != null) ...[leading!, const SizedBox(width: 10)] else if (icon != null) ...[GameIcon({Icons.science_outlined: GameGlyph.flask, Icons.science: GameGlyph.flask, Icons.shopping_bag_outlined: GameGlyph.herbs, Icons.build_outlined: GameGlyph.hammer, Icons.local_shipping_outlined: GameGlyph.crate, Icons.storefront: GameGlyph.shop, Icons.replay: GameGlyph.restart, Icons.nightlight_round: GameGlyph.moon, Icons.wb_sunny_outlined: GameGlyph.sun}[icon] ?? GameGlyph.next, size: 26), const SizedBox(width: 8)],
      Flexible(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.5))),
    ]),
  ));
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


