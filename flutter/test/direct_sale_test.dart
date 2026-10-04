import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/shop_tasks.dart';

void main() {
  Widget selection(Game game, ValueChanged<String> give, {List<Potion> catalog = potions}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PotionSelection(
      game: game, enabled: true, catalog: catalog, onGive: give))));
  testWidgets('First sale retains selection, learned single recipe can be handed directly', (tester) async {
    final game = Game();
    var calls = 0;
    await tester.pumpWidget(selection(game, (_) => calls++));
    expect(find.text('물약 건네기'), findsOneWidget);
    game.served = 1;
    await tester.pumpWidget(selection(game, (_) => calls++));
    final direct = find.text('${potions.first.name} 건네기 · 35 G');
    await tester.ensureVisible(direct);
    await tester.tap(direct); await tester.tap(direct);
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('A wrong direct offer can be retried after the parent saves', (tester) async {
    final game = Game()..day = 2;
    var calls = 0;
    await tester.pumpWidget(selection(game, (id) { calls++; game.sell(id); }));
    final direct = find.text('${potions.first.name} 건네기 · 35 G');
    await tester.ensureVisible(direct);
    await tester.tap(direct); await tester.pumpAndSettle();
    expect(game.wrongOffers, 1);
    await tester.tap(direct); await tester.pumpAndSettle();
    expect(calls, 2);
    expect(game.lostSales, 1);
  });
  testWidgets('Filtered catalog or sole remaining stock does not suggest correct potion', (tester) async {
    final game = Game()..served = 1..discovered.add('sight');
    game.stock['sight'] = 0;
    await tester.pumpWidget(selection(game, (_) {}, catalog: [potions.first]));
    expect(find.text('물약 건네기'), findsOneWidget);
    expect(find.text('${potions.first.name} 건네기 · 35 G'), findsNothing);
  });
}
