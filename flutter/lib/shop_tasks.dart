import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game.dart';
import 'game_skin.dart';
import 'research_art.dart';
import 'shop_world.dart';
import 'sprite_layout.dart';
import 'ui_art.dart';

Widget potionArt(Potion p, double size) => SizedBox.square(dimension: size,
  child: FutureBuilder<WorldArt>(future: WorldArt.load(), builder: (_, state) =>
    state.hasData ? CustomPaint(painter: _BottleSprite(state.data!, p.id)) : const SizedBox()));

class PotionSelection extends StatefulWidget {
  final Game game;
  final Widget? order;
  final List<Potion> catalog;
  final bool enabled;
  final ValueChanged<String> onGive;
  const PotionSelection({super.key, required this.game, required this.enabled, required this.onGive, this.order, this.catalog = potions});
  @override
  State<PotionSelection> createState() => _PotionSelectionState();
}
class _PotionSelectionState extends State<PotionSelection> {
  String? selected;
  int page = 0;
  bool directBusy = false;
  @override
  void didUpdateWidget(PotionSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) directBusy = false;
  }
  @override
  Widget build(BuildContext context) {
    final choices = widget.catalog.where((p) => widget.game.knows(p.id)).toList();
    final choice = choices.where((p) => p.id == selected).firstOrNull;
    final direct = potions.where((p) => widget.game.knows(p.id)).length == 1 && choices.length == 1 &&
      (widget.game.served > 0 || widget.game.day > 1) ? choices.single : null;
    final pages = math.max(1, (choices.length / 8).ceil());
    final current = math.min(page, pages - 1);
    final visible = choices.skip(current * 8).take(8).toList();
    final shelf = Column(children: [
      Expanded(child: Center(child: AspectRatio(aspectRatio: 1.12, child: PropSurface(prop: ShopProp.shelf,
        child: LayoutBuilder(builder: (context, shelfSize) => Padding(padding: EdgeInsets.fromLTRB(shelfSize.maxWidth * .08, shelfSize.maxHeight * .20, shelfSize.maxWidth * .08, shelfSize.maxHeight * .10),
        child: GridView.builder(key: const ValueKey('potion-grid'), physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisExtent: shelfSize.maxHeight * .35, crossAxisSpacing: 4, mainAxisSpacing: 0),
          itemCount: 8, itemBuilder: (context, index) {
            if (index >= visible.length) return const SizedBox();
            final p = visible[index], count = widget.game.stock[p.id] ?? 0;
            return Tooltip(message: '${p.name} · $count병', child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(3), side: BorderSide.none,
                backgroundColor: selected == p.id ? const Color(0x507e597b) : Colors.transparent, shape: const RoundedRectangleBorder()),
              onPressed: widget.enabled ? () => setState(() => selected = p.id) : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Opacity(opacity: count > 0 ? 1 : .35, child: potionArt(p, math.max(20, math.min(76, shelfSize.maxHeight * .35 - 68)))),
                SkinPanel(skin: Skin.parchment, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  child: Text('×$count', style: const TextStyle(color: Color(0xff402d36), fontSize: 12)))),
                Text(p.name.replaceFirst(' 숙면', '\n숙면').replaceFirst(' 시야', '\n시야'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xffffe7bb), fontSize: 12, height: 1.2)),
              ])));
          }))))))),
      if (pages > 1) SizedBox(height: 36, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(tooltip: '이전 선반', onPressed: current > 0 ? () => setState(() => page--) : null, icon: const GameIcon(GameGlyph.back, size: 22)),
        Text('${current + 1} / $pages'),
        IconButton(tooltip: '다음 선반', onPressed: current + 1 < pages ? () => setState(() => page++) : null, icon: const GameIcon(GameGlyph.next, size: 22)),
      ])),
    ]);
    final receipt = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.order != null) widget.order!,
      const SizedBox(height: 8),
      if (choice != null) ...[
        Text(choice.name, style: const TextStyle(color: worldGold, fontSize: 16)),
        const SizedBox(height: 6), Text(choice.description, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6), Text('${choice.price} G · 재고 ${widget.game.stock[choice.id] ?? 0}병', style: const TextStyle(color: worldGold)),
      ] else const Text('선반에서 물약을 골라 주세요.', style: TextStyle(color: worldGold)),
      ]))), const SizedBox(height: 14),
      if (direct != null) GameAction(label: '${direct.name} 건네기 · ${direct.price} G',
        onPressed: widget.enabled && !directBusy && (widget.game.stock[direct.id] ?? 0) > 0
          ? () {
              if (directBusy) return;
              setState(() => directBusy = true);
              try { widget.onGive(direct.id); }
              finally {
                // Guard duplicate events in this frame, then let the parent's
                // save/response gate control input. Wrong offers retain a retry.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => directBusy = false);
                });
              }
            } : null)
      else GameAction(label: '물약 건네기', onPressed: widget.enabled && choice != null && (widget.game.stock[choice.id] ?? 0) > 0
        ? () { final id = choice.id; setState(() => selected = null); widget.onGive(id); } : null),
    ]);
    return LayoutBuilder(builder: (context, bounds) => bounds.maxWidth >= 700
      ? SizedBox(height: math.min(470, (bounds.maxWidth - 290) / 1.12 + (pages > 1 ? 36 : 0)), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: shelf), const SizedBox(width: 18), SizedBox(width: 260, child: SkinPanel(skin: Skin.dialogue,
            child: Padding(padding: const EdgeInsets.all(16), child: receipt)))]))
      : Column(children: [SizedBox(height: pages > 1 ? 356 : 320, child: shelf), const SizedBox(height: 16), SizedBox(height: 310, child: receipt)]));
  }
}

class _BottleSprite extends CustomPainter {
  final WorldArt art;
  final String id;
  _BottleSprite(this.art, this.id);
  @override
  void paint(Canvas canvas, Size size) {
    final src = art.bottleFrames[id == 'sleep' ? 0 : 1];
    canvas.drawImageRect(art.actors, src, fitSprite(src, Offset.zero & size), Paint()..filterQuality = FilterQuality.none);
  }
  @override
  bool shouldRepaint(_BottleSprite old) => old.id != id || old.art != art;
}

class ShopTasks extends StatefulWidget {
  final Game game;
  final bool management, canResearch;
  final VoidCallback onResearch;
  final ValueChanged<String>? onResearchPotion;
  final ValueChanged<String> onChanged;
  const ShopTasks({super.key, required this.game, required this.management, required this.canResearch,
    required this.onResearch, required this.onChanged, this.onResearchPotion});
  @override
  State<ShopTasks> createState() => _ShopTasksState();
}
class _ShopTasksState extends State<ShopTasks> {
  int section = 0, recipe = 0, material = 0, quantity = 1;
  Game get game => widget.game;
  bool get compactBook => MediaQuery.sizeOf(context).height < 850;
  static const ink = Color(0xff3c2938);
  Widget heading(String text) => Padding(padding: EdgeInsets.only(bottom: compactBook ? 8 : 14),
    child: Text(text, style: TextStyle(color: ink, fontSize: compactBook ? 16 : 20, fontWeight: FontWeight.bold)));
  Widget spread(Widget left, Widget right) => LayoutBuilder(builder: (context, box) {
    if (box.maxWidth < 400) return Column(children: [paper(left), const SizedBox(height: 14), paper(right)]);
    return AspectRatio(aspectRatio: 1.3, child: PropSurface(prop: ShopProp.book, child: Padding(padding: EdgeInsets.fromLTRB(box.maxWidth * .10, box.maxWidth * .10, box.maxWidth * .09, 44),
      child: DefaultTextStyle.merge(style: const TextStyle(color: ink, fontSize: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SingleChildScrollView(child: left)), SizedBox(width: box.maxWidth * .08), Expanded(child: SingleChildScrollView(child: right))])))));
  });
  Widget paper(Widget child) => PropSurface(prop: ShopProp.order, child: Padding(padding: const EdgeInsets.all(32),
    child: DefaultTextStyle.merge(style: const TextStyle(color: ink), child: child)));
  Widget recipeBook() {
    final known = potions.where((p) => game.knows(p.id)).toList();
    if (known.isEmpty) return paper(const Text('발견한 제조법이 아직 없어요. 부탁을 받아 연구해 보세요.'));
    final p = known[math.min(recipe, known.length - 1)];
    final batchCost = p.recipe.fold<int>(0, (sum, id) => sum + ingredients.firstWhere((i) => i.id == id).price);
    return spread(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('레시피로 제조'),
      for (var i = 0; i < known.length; i++) TextButton(onPressed: () => setState(() => recipe = i),
        style: TextButton.styleFrom(foregroundColor: ink, backgroundColor: recipe == i ? const Color(0x22774f54) : Colors.transparent),
        child: Row(children: [potionArt(known[i], 54), const SizedBox(width: 10), Expanded(child: Text(known[i].name))])),
      const SizedBox(height: 12), const Text('물약과 수량 선택\n부족한 재료는 함께\n구매합니다.'),
    ]), Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading(p.name),
      Text('재고 ${game.stock[p.id]}병 · 판매가 ${p.price} G', style: const TextStyle(fontSize: 12)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(tooltip: '제조 수량 줄이기', constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: const EdgeInsets.all(4), onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
          icon: const GameIcon(GameGlyph.back, size: 22)),
        Text('${quantity * game.level}병', style: const TextStyle(fontSize: 20)),
        IconButton(tooltip: '제조 수량 늘리기', constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: const EdgeInsets.all(4), onPressed: quantity < 10 ? () => setState(() => quantity++) : null,
          icon: const GameIcon(GameGlyph.next, size: 22)),
      ]),
      Text('재료 원가 ${quantity * batchCost} G', style: const TextStyle(fontSize: 12)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final id in p.recipe)
        Tooltip(message: '${ingredientName(id)} · 보유 ${game.materials[id]} / 필요 ${quantity}',
          child: IngredientSprite(id: id, size: compactBook ? 24 : 40))]),
      Text('부족분 구매 ${game.prepareCost(p, quantity * game.level)} G', style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      GameAction(compact: true, label: '구매·제조하기', onPressed: game.gold >= game.prepareCost(p, quantity * game.level) ? () {
        final count = quantity * game.level;
        final error = game.prepare(p.id, quantity * game.level);
        widget.onChanged(error ?? '${p.name} $count병을 준비했어요.');
      } : null),
      if (game.gold < game.prepareCost(p, quantity * game.level)) const Text('구매 비용이 부족해요.', style: TextStyle(fontSize: 12)),
    ]));
  }
  Widget supplies() {
    final items = ingredients.where((i) => game.isIngredientUnlocked(i.id)).toList();
    final item = items[math.min(material, items.length - 1)];
    return spread(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('재료 구매'),
      Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < items.length; i++) SizedBox(width: 85,
        child: TextButton(onPressed: () => setState(() => material = i),
          style: TextButton.styleFrom(padding: const EdgeInsets.all(4), foregroundColor: ink,
            backgroundColor: material == i ? const Color(0x22774f54) : Colors.transparent),
          child: Column(children: [IngredientSprite(id: items[i].id, size: 43), Text(items[i].name, style: const TextStyle(fontSize: 11))])))]),
    ]), Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading(item.name),
      Center(child: IngredientSprite(id: item.id, size: compactBook ? 42 : 70)), const SizedBox(height: 8), Text(item.lore, style: TextStyle(fontSize: compactBook ? 12 : 14)),
      const SizedBox(height: 10), Text('창고에 ${game.materials[item.id]}개'), const SizedBox(height: 10),
      GameAction(compact: compactBook, label: '3개 주문 · ${item.price * 3} G', onPressed: game.gold >= item.price * 3 ? () {
        if (game.buy(item.id)) widget.onChanged('${item.name} 3개가 창고에 도착했어요.');
      } : null),
    ]));
  }
  Widget equipment() => spread(Column(children: [heading('가마솥 공방'),
    const SizedBox(height: 180, child: ResearchCauldron(brewing: false, solved: false))]),
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('가마솥 Lv.${game.level}'),
      Text(game.level >= 3 ? '최고 단계의 가마솥입니다.' : '같은 재료 1세트로 ${game.level}병 → ${game.level + 1}병을 만듭니다.'),
      const SizedBox(height: 14), Text('기본 숙면 제조법 기준 1세트 6 G · 현재 병당 ${(6 / game.level).toStringAsFixed(1)} G\n현재 보유 ${game.gold} G'),
      if (game.level < 3) Text(game.level == 1
        ? '6 G짜리 재료 세트를 모두 활용하면 6 → 3 G/병. 약 30병의 재료 절감액이 개선비 90 G와 같아요.'
        : '6 G짜리 재료 세트를 모두 활용하면 3 → 2 G/병. 약 180병의 재료 절감액이 개선비 180 G와 같아요.'),
      if (game.level < 3) const Text('전량 생산·판매하고 현재 가격으로 재료를 사는 비교예요. 보유 재료와 남는 물약에 따라 실제 지출이 달라져요. 다른 레시피의 원가는 제조 장부에서 확인하세요.', style: TextStyle(fontSize: 12)), const SizedBox(height: 24),
      GameAction(compact: compactBook, label: game.level >= 3 ? '개선 완료' : '설비 개선 · ${game.upgradeCost} G',
        onPressed: game.level < 3 && game.gold >= game.upgradeCost ? () {
          if (game.upgrade()) widget.onChanged('가마솥을 Lv.${game.level}로 개선했어요.');
        } : null),
    ]));
  Widget guildOrder() => spread(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    heading('길잡이 조합의 편지'),
    const Center(child: GameIcon(GameGlyph.book, size: 64)),
    GameParagraph(game.day < 3 ? '3일째에 조합의 첫 주문서가 도착합니다.' :
      game.completed ? '보내 주신 물약 덕분에 밤길을 안전하게 안내하고 있어요. 고맙습니다!' :
      '야간 안내를 시작하려 합니다. 시야 물약 3병을 부탁드립니다.'),
  ]), Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    heading(game.completed ? '납품 완료' : '시야 물약 3병'),
    GameParagraph(game.completed ? '희귀 재료 상인과 거래가 열렸어요. 영업은 계속할 수 있습니다.' :
      '준비 ${game.stock['sight']} / 3병\n보상 120 G\n희귀 재료 거래 해금\n마감 없음'),
    const SizedBox(height: 12),
    if (!game.completed) GameAction(compact: true, label: '3병 납품하기',
      onPressed: game.day >= 3 && game.knows('sight') && game.stock['sight']! >= 3 ? () {
        if (game.deliver()) widget.onChanged('조합 납품 완료 · +120 G · 희귀 재료 거래 해금');
      } : null),
    if (!game.completed) const Text('납품할 물약은 영업 준비에서 제조하세요.', style: TextStyle(fontSize: 12)),
    if (game.completed) GameAction(compact: true, label: '재료 상인', onPressed: () => setState(() => section = 3)),
  ]));
  Widget research() {
    final pending = game.pendingResearchIds;
    return spread(Column(children: [heading('달빛 연구'),
      const SizedBox(height: 180, child: ResearchCauldron(brewing: false, solved: false))]),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('새로운 레시피'),
        if (pending.isEmpty) const Text('현재 받은 부탁의 연구를 마쳤습니다. 새로운 부탁을 듣고 다시 들러 주세요.'),
        for (final id in pending) ...[
          Text(potions.firstWhere((p) => p.id == id).name),
          Text(potions.firstWhere((p) => p.id == id).description),
          const SizedBox(height: 8),
          GameAction(label: '연구 시작 · ${potions.firstWhere((p) => p.id == id).name}',
            onPressed: widget.canResearch && game.canResearchPotion(id)
              ? () => widget.onResearchPotion != null ? widget.onResearchPotion!(id) : widget.onResearch() : null),
          const SizedBox(height: 18),
        ],
        if (pending.isNotEmpty && !widget.canResearch) const Text('영업을 마친 뒤 밤에 연구할 수 있어요.'),
      ]));
  }
  Widget forecast() {
    if (!game.night) return paper(const Text('영업을 마치면 내일의 방문 계획과 준비할 수량을 볼 수 있어요.'));
    final demand = game.nextDayDemand;
    return paper(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('내일의 준비 목록'),
      const Text('주문 때 바로 건넬 수 있도록 준비해 보세요. 낮에도 구매·제조할 수 있어요.'),
      for (final entry in demand.entries) Padding(padding: const EdgeInsets.only(top: 10), child: Text(
        '${potions.firstWhere((p) => p.id == entry.key).name} · 예상 ${entry.value}병\n'
        '재고 ${game.stock[entry.key] ?? 0}병 · 부족 ${math.max(0, entry.value - (game.stock[entry.key] ?? 0))}병'
        '${game.knows(entry.key) ? '' : ' · 연구가 먼저 필요해요'}')),
      if (demand.isEmpty) const Text('예고된 물약 주문이 없어요. 이웃의 이야기를 들어 주세요.'),
      if (!game.completed && game.day >= 2) const Padding(padding: EdgeInsets.only(top: 12),
        child: Text('협회 주문 별도: 시야 3병 · 마감 없음\n일반 손님용 재고와 함께 사용합니다. 재고를 자동 예약하지 않아요.')),
    ]));
  }
  Widget ledger() => paper(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    heading('${game.day}일째 영업 장부'),
    Text('판매 ${game.served}건 · 놓친 주문 ${game.lostSales}건\n'
      '판매 수입 ${game.salesRevenue} G\n협회 보상 ${game.guildRewards} G\n'
      '${game.unclassifiedRevenue > 0 ? '이전 저장의 미분류 수입 ${game.unclassifiedRevenue} G\n' : ''}'
      '총수입 ${game.revenue} G\n재료 지출 ${game.spending} G\n설비 투자 ${game.investment} G', style: const TextStyle(height: 1.8)),
    const Divider(color: Color(0xff9b7a65)),
    Text('미구매 이유\n오판매 ${game.missedOrders['wrongPotion'] ?? 0}건 · 품절 ${game.missedOrders['outOfStock'] ?? 0}건\n'
      '거절 ${game.missedOrders['declined'] ?? 0}건 · 이전 저장 미분류 ${game.missedOrders['unknown'] ?? 0}건\n'
      '연구 부탁 대기 ${game.researchPendingOrders}건'),
    if (game.receivedMaterials.isNotEmpty) ...[
      const SizedBox(height: 12), const Text('받은 재료 · 현금 수입에 포함하지 않아요'),
      for (final item in game.receivedMaterials.entries) Text('${ingredientName(item.key)} +${item.value}'),
    ],
    const Divider(color: Color(0xff9b7a65)), Text('보유 금액 ${game.gold} G'),
  ]));
  @override
  Widget build(BuildContext context) {
    final labels = widget.management ? ['협회 주문', '설비', '영업 장부'] : ['영업 준비', '새 물약 연구', '내일 준비'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [for (var i = 0; i < labels.length; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SkinPanel(skin: section == i ? Skin.selected : Skin.button, child: TextButton(onPressed: () => setState(() => section = i),
          style: TextButton.styleFrom(foregroundColor: const Color(0xffffe7bb), minimumSize: const Size(0, 42)), child: Text(labels[i])))))]),
      const SizedBox(height: 12),
      if (!widget.management) (section == 0 ? recipeBook() : section == 1 ? research() : forecast())
      else if (section == 0) guildOrder()
      else if (section == 1) equipment()
      else if (section == 3) supplies()
      else ledger(),
    ]);
  }
}
