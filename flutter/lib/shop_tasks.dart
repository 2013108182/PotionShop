import 'package:flutter/material.dart';
import 'game.dart';
import 'game_skin.dart';
import 'research_art.dart';
import 'shop_world.dart';

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
  @override
  Widget build(BuildContext context) {
    final choices = widget.catalog.where((p) => widget.game.knows(p.id)).toList();
    final choice = selected == null ? null : choices.where((p) => p.id == selected).firstOrNull;
    Widget bottle(Potion p, double size) => SizedBox(width: size, height: size, child: FutureBuilder<WorldArt>(future: WorldArt.load(), builder: (_, state) =>
      state.hasData ? CustomPaint(painter: _BottleSprite(state.data!, p.id)) : const SizedBox()));
    Widget details = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(choice?.name ?? '어떤 약을 권할까요?', style: const TextStyle(color: worldGold, fontSize: 16)),
      const SizedBox(height: 10),
      if (choice != null) Center(child: bottle(choice, 48)),
      const SizedBox(height: 8),
      Text(choice?.description ?? '손님의 부탁을 읽고 진열장에서 물약을 골라 주세요.', style: const TextStyle(fontSize: 13)),
      const Spacer(),
      if (choice != null) Text('${choice.price} G · 재고 ${widget.game.stock[choice.id] ?? 0}병', style: const TextStyle(color: worldGold)),
      const SizedBox(height: 8),
      GameAction(label: '물약 건네기', onPressed: widget.enabled && choice != null && (widget.game.stock[choice.id] ?? 0) > 0
        ? () { final id = choice.id; setState(() => selected = null); widget.onGive(id); } : null),
    ]);
    return LayoutBuilder(builder: (context, bounds) {
      final wide = bounds.maxWidth >= 850;
      final grid = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('물약 진열장 · ${choices.length}종', style: const TextStyle(color: worldGold, fontSize: 15)),
        const SizedBox(height: 8),
        Expanded(child: GridView.builder(key: const ValueKey('potion-grid'),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: wide ? 5 : 3, mainAxisExtent: 52, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemCount: choices.length, itemBuilder: (context, index) {
            final p = choices[index]; final count = widget.game.stock[p.id] ?? 0;
            return Tooltip(message: '${p.name}\n${p.description}\n${p.price} G · 재고 $count병', child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(3), shape: const RoundedRectangleBorder(),
                backgroundColor: selected == p.id ? const Color(0xff624553) : const Color(0xff2c2032),
                side: BorderSide(color: selected == p.id ? worldGold : const Color(0xff725967))),
              onPressed: widget.enabled ? () => setState(() => selected = p.id) : null,
              child: Column(children: [Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [bottle(p, 24),
                Text(' ×$count', style: TextStyle(fontSize: 11, color: count == 0 ? Colors.grey : worldGold))])),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
              ])));
          })),
      ]);
      if (wide) return SizedBox(height: 262, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.order != null) ...[SizedBox(width: 245, child: SingleChildScrollView(child: widget.order!)), const VerticalDivider(width: 28, color: Color(0xff725967))],
        Expanded(child: grid), const VerticalDivider(width: 28, color: Color(0xff725967)), SizedBox(width: 215, child: details),
      ]));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (widget.order != null) widget.order!,
        const SizedBox(height: 12), SizedBox(height: 245, child: grid), const SizedBox(height: 12), SizedBox(height: 250, child: details)]);
    });
  }
}

class _BottleSprite extends CustomPainter {
  final WorldArt art;
  final String id;
  _BottleSprite(this.art, this.id);
  @override
  void paint(Canvas canvas, Size size) {
    final src = actorFrame(art.actors, 7, id == 'sleep' ? 0 : 4);
    canvas.drawImageRect(art.actors, src, Offset.zero & size, Paint()..filterQuality = FilterQuality.none);
  }
  @override
  bool shouldRepaint(_BottleSprite old) => old.id != id || old.art != art;
}

class ShopTasks extends StatelessWidget {
  final Game game;
  final bool management, canResearch;
  final VoidCallback onResearch;
  final ValueChanged<String> onChanged;
  const ShopTasks({super.key, required this.game, required this.management, required this.canResearch,
    required this.onResearch, required this.onChanged});
  Widget card(String title, String detail, Widget action) => Padding(padding: const EdgeInsets.only(bottom: 16),
    child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xff2c2237), borderRadius: BorderRadius.circular(10)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title == '새 물약 연구') const SizedBox(height: 110, child: ResearchCauldron(brewing: false, solved: false)),
        Text(title, style: const TextStyle(fontSize: 18, color: Color(0xffe9b568))), const SizedBox(height: 8),
        Text(detail, style: const TextStyle(height: 1.5)), const SizedBox(height: 12), action,
      ]))));
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: management ? [
    card('상점 현황', '보유 ${game.gold} G\n판매 ${game.served}건 · 매출 ${game.revenue} G\n가마솥 Lv.${game.level}\n개선하면 한 번에 ${game.level + 1}병 제조 · 재료도 각 ${game.level + 1}개 사용',
      OutlinedButton(onPressed: game.level < 3 && game.gold >= game.upgradeCost && !game.completed ? () {
        if (game.upgrade()) onChanged('가마솥을 Lv.${game.level}로 개선했어요.');
      } : null, child: Padding(padding: const EdgeInsets.all(12), child: Text(game.level >= 3 ? '설비 개선 완료' : '설비 개선 · ${game.upgradeCost} G')))),
    const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('재료 구매', style: TextStyle(fontSize: 20))),
    for (final i in ingredients.where((i) => !i.rare || game.supplierUnlocked)) Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [IngredientSprite(id: i.id, size: 48), const SizedBox(width: 10), Expanded(child: Text('${i.name}\n보유 ${game.materials[i.id]}개')),
        SizedBox(width: 130, height: 52, child: OutlinedButton(onPressed: game.gold >= i.price * 3 ? () {
          if (game.buy(i.id)) onChanged('${i.name} 3개를 구입했어요.');
        } : null, child: Text('3개 · ${i.price * 3} G'))),
      ])),
  ] : [
    card('새 물약 연구', canResearch ? '손님의 부탁을 실험으로 풀어 보세요.' : game.knows('sight') ? '현재 받은 부탁의 연구를 마쳤어요. 발견한 물약을 아래에서 제조할 수 있어요.' : '새로운 부탁을 받은 뒤, 밤에 연구할 수 있어요.',
      GameAction(label: '연구 시작', onPressed: canResearch ? onResearch : null)),
    const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('레시피로 제조', style: TextStyle(fontSize: 20))),
    for (final p in potions.where((p) => game.knows(p.id))) card(p.name,
      '${p.description}\n재고 ${game.stock[p.id]}병 · ${p.ingredientText}\n필요 재료 각 ${game.level}개',
      GameAction(label: '${game.level}병 만들기', onPressed: game.canBrew(p) ? () {
        final error = game.brew(p.id); onChanged(error ?? '${p.name} ${game.level}병을 만들었어요.');
      } : null)),
  ]);
}
