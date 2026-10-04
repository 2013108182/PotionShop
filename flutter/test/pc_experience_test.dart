import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/shop_tasks.dart';
import 'package:potionshop/research_screen.dart';
import 'package:potionshop/research_session.dart';

void main() {
  testWidgets('Twenty potions and give action fit together on PC without scrolling', (tester) async {
    tester.view.physicalSize = const Size(1280, 720); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = List.generate(20, (i) => Potion('qa$i', '시험 물약 $i', '효과 $i', ['moon', 'salt', 'mushroom'], 35));
    final game = Game();
    for (final p in catalog) { game.discovered.add(p.id); game.stock[p.id] = 2; }
    String? given;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(32),
      child: PotionSelection(game: game, enabled: true, catalog: catalog, order: const Text('고정 주문'), onGive: (id) => given = id)))));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '시험 물약 19').hitTestable(), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '시험 물약 0').hitTestable(), findsOneWidget);
    final button = find.widgetWithText(FilledButton, '물약 건네기');
    final before = tester.getRect(button);
    await tester.tap(find.widgetWithText(OutlinedButton, '시험 물약 19')); await tester.pumpAndSettle();
    expect(given, isNull); expect(tester.getRect(button), before);
    expect(button.hitTestable(), findsOneWidget);
    await tester.tap(button); expect(given, 'qa19'); expect(tester.takeException(), isNull);
  });
  testWidgets('Research withholds result and reward until staged reveal finishes', (tester) async {
    tester.view.physicalSize = const Size(1280, 720); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final draft = ResearchSession();
    for (final id in ['moon', 'salt', 'mushroom']) { draft.place(id); }
    final game = Game()..researchNotebook = draft.encode();
    await tester.pumpWidget(MaterialApp(home: ResearchStudio(game: game, onGameChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('재료 선반'), findsOneWidget); expect(find.text('실험 노트'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '조합 실험하기')); await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(game.knows('sight'), isFalse); expect(game.attempts, isEmpty);
    expect(find.text('마법이 서로 반응해요…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 950));
    expect(game.attempts, isEmpty);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 380));
    expect(game.knows('sight'), isFalse);
    await tester.pump(const Duration(milliseconds: 380));
    await tester.pump(const Duration(milliseconds: 380)); await tester.pumpAndSettle();
    expect(game.knows('sight'), isTrue); expect(game.stock['sight'], 1); expect(game.attempts.length, 1);
    expect(tester.takeException(), isNull);
  });
}
