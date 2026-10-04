import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/shop_tasks.dart';

void main() {
  Widget book(Game game, {bool management = false, ValueChanged<String>? onResearch}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ShopTasks(
      game: game, management: management, canResearch: true,
      onResearch: () {}, onResearchPotion: onResearch, onChanged: (_) {}))));

  testWidgets('Ledger separates sales and association income with missed reasons', (tester) async {
    final game = Game()..day = 3;
    game.sell('sleep');
    game.discovered.add('sight'); game.stock['sight'] = 3;
    game.deliver();
    await tester.pumpWidget(book(game, management: true));
    await tester.tap(find.text('영업 장부')); await tester.pumpAndSettle();
    expect(find.textContaining('판매 수입 35 G'), findsOneWidget);
    expect(find.textContaining('협회 보상 120 G'), findsOneWidget);
    expect(find.textContaining('오판매'), findsOneWidget);
  });
  testWidgets('Research selection passes the selected target without a solution', (tester) async {
    final game = Game();
    game.requestResearch('sight'); game.requestResearch('warmth');
    String? requested;
    await tester.pumpWidget(book(game, onResearch: (id) => requested = id));
    await tester.tap(find.text('새 물약 연구')); await tester.pumpAndSettle();
    final label = '연구 시작 · ${potions.firstWhere((p) => p.id == 'warmth').name}';
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label)); await tester.pump();
    expect(requested, 'warmth');
    expect(find.textContaining('꽃잎 →'), findsNothing);
  });
  testWidgets('Investment comparison changes assumptions at level two', (tester) async {
    final game = Game()..level = 2;
    await tester.pumpWidget(book(game, management: true));
    await tester.tap(find.text('설비')); await tester.pumpAndSettle();
    expect(find.textContaining('약 180병'), findsOneWidget);
    expect(find.textContaining('약 30병'), findsNothing);
  });
}
