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
  @override
  Widget build(BuildContext context) {
    final choices = widget.catalog.where((p) => widget.game.knows(p.id)).toList();
    final choice = choices.where((p) => p.id == selected).firstOrNull;
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
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Opacity(opacity: count > 0 ? 1 : .35, child: potionArt(p, math.max(20, math.min(76, shelfSize.maxHeight * .35 - 52)))),
                SkinPanel(skin: Skin.parchment, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  child: Text('×$count', style: const TextStyle(color: Color(0xff402d36), fontSize: 12)))),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xffffe7bb), fontSize: 11)),
              ])));
          }))))))),
      if (pages > 1) SizedBox(height: 36, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(tooltip: '이전 선반', onPressed: current > 0 ? () => setState(() => page--) : null, icon: const GameIcon(GameGlyph.back, size: 22)),
        Text('${current + 1} / $pages'),
        IconButton(tooltip: '다음 선반', onPressed: current + 1 < pages ? () => setState(() => page++) : null, icon: const GameIcon(GameGlyph.next, size: 22)),
      ])),
    ]);
    final receipt = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.order != null) SizedBox(height: 105, child: SingleChildScrollView(child: widget.order!)),
      const SizedBox(height: 8),
      if (choice != null) ...[
        Text(choice.name, style: const TextStyle(color: worldGold, fontSize: 16)),
        const SizedBox(height: 6), Text(choice.description, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6), Text('${choice.price} G · 재고 ${widget.game.stock[choice.id] ?? 0}병', style: const TextStyle(color: worldGold)),
      ] else const Text('선반에서 물약을 골라 주세요.', style: TextStyle(color: worldGold)),
      const Spacer(),
      GameAction(label: '물약 건네기', onPressed: widget.enabled && choice != null && (widget.game.stock[choice.id] ?? 0) > 0
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
  final ValueChanged<String> onChanged;
  const ShopTasks({super.key, required this.game, required this.management, required this.canResearch,
    required this.onResearch, required this.onChanged});
  @override
  State<ShopTasks> createState() => _ShopTasksState();
}
class _ShopTasksState extends State<ShopTasks> {
  int section = 0, recipe = 0, material = 0;
  Game get game => widget.game;
  bool get compactBook => MediaQuery.sizeOf(context).height < 850;
  static const ink = Color(0xff3c2938);
  Widget heading(String text) => Padding(padding: const EdgeInsets.only(bottom: 14),
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
    final p = known[math.min(recipe, known.length - 1)];
    return spread(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('레시피로 제조'),
      for (var i = 0; i < known.length; i++) TextButton(onPressed: () => setState(() => recipe = i),
        style: TextButton.styleFrom(foregroundColor: ink, backgroundColor: recipe == i ? const Color(0x22774f54) : Colors.transparent),
        child: Row(children: [potionArt(known[i], 54), const SizedBox(width: 10), Expanded(child: Text(known[i].name))])),
      const SizedBox(height: 12), const Text('기록해 둔 레시피를 골라 제조합니다.'),
    ]), Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading(p.name), if (!compactBook) Text(p.description), const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final id in p.recipe)
        Expanded(child: Column(children: [Tooltip(message: ingredientName(id), child: IngredientSprite(id: id, size: compactBook ? 32 : 45)),
          if (!compactBook) Text(ingredientName(id), style: const TextStyle(fontSize: 11)),
          Text('${game.materials[id]} / ${game.level}', style: TextStyle(color: game.materials[id]! < game.level ? Colors.red.shade900 : ink))]))]),
      const SizedBox(height: 12), Text('완성품 ${game.stock[p.id]}병 · ${game.level}병씩 제조', style: const TextStyle(fontSize: 12)), const SizedBox(height: 12),
      GameAction(compact: compactBook, label: '${game.level}병 만들기', onPressed: game.canBrew(p) ? () {
        final error = game.brew(p.id); widget.onChanged(error ?? '${p.name} ${game.level}병을 만들었어요.');
      } : null),
    ]));
  }
  Widget supplies() {
    final items = ingredients.where((i) => !i.rare || game.supplierUnlocked).toList();
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
      Text(game.level >= 3 ? '최고 단계의 가마솥입니다.' : '다음 단계에서는 한 번에 ${game.level + 1}병을 제조합니다.'),
      const SizedBox(height: 14), Text('재료도 병 수만큼 사용합니다.\n현재 보유 ${game.gold} G'), const SizedBox(height: 24),
      GameAction(compact: compactBook, label: game.level >= 3 ? '개선 완료' : '설비 개선 · ${game.upgradeCost} G',
        onPressed: game.level < 3 && game.gold >= game.upgradeCost && !game.completed ? () {
          if (game.upgrade()) widget.onChanged('가마솥을 Lv.${game.level}로 개선했어요.');
        } : null),
    ]));
  Widget research() => spread(Column(children: [heading('달빛 연구'),
    const SizedBox(height: 180, child: ResearchCauldron(brewing: false, solved: false))]),
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('새로운 레시피'),
      Text(widget.canResearch ? '어둠 속에서도 길을 볼 수 있는 물약.\n엘리의 부탁을 실험으로 풀어 봅시다.' :
        game.knows('sight') ? '현재 받은 부탁의 연구를 마쳤습니다.\n발견한 약은 제조 장부에 기록되어 있어요.' : '새로운 부탁을 받은 뒤, 밤에 연구할 수 있어요.'),
      const SizedBox(height: 26), if (widget.canResearch) GameAction(label: '연구 시작', onPressed: widget.onResearch),
    ]));
  @override
  Widget build(BuildContext context) {
    final labels = widget.management ? ['재료 주문서', '설비', '영업 장부'] : ['제조 장부', '새 물약 연구'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [for (var i = 0; i < labels.length; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SkinPanel(skin: section == i ? Skin.selected : Skin.button, child: TextButton(onPressed: () => setState(() => section = i),
          style: TextButton.styleFrom(foregroundColor: const Color(0xffffe7bb), minimumSize: const Size(0, 42)), child: Text(labels[i])))))]),
      const SizedBox(height: 12),
      if (!widget.management) (section == 0 ? recipeBook() : research())
      else if (section == 0) supplies()
      else if (section == 1) equipment()
      else paper(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('${game.day}일째 영업 장부'),
        Text('판매 ${game.served}건\n매출 ${game.revenue} G\n재료 지출 ${game.spending} G\n설비 투자 ${game.investment} G', style: const TextStyle(height: 2.3)),
        const Divider(color: Color(0xff9b7a65)), Text('보유 금액 ${game.gold} G'),
      ])),
    ]);
  }
}
