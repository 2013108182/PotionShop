import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/research_session.dart';
import 'package:potionshop/game.dart';

void main() {
  testWidgets('Standalone discovery reaches the shop once without duplicate rewards', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final session = ResearchSession();
    for (final id in ['moon', 'salt', 'mushroom']) { session.place(id); }
    session.submit();
    SharedPreferences.setMockInitialValues({'potionshop.research.v1': session.encode()});
    await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final saved = Game.decode(prefs.getString('potionshop.v2')!);
    expect(saved.knows('sight'), isTrue); expect(saved.stock['sight'], 1);
    await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    expect(Game.decode(prefs.getString('potionshop.v2')!).stock['sight'], 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Night research updates and persists the current shop', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final g = Game();
    while (!g.serviceFinished) { g.skipCustomer(); }
    g.startNight();
    g.materials.updateAll((key, value) => 0);
    SharedPreferences.setMockInitialValues({'potionshop.v2': g.encode()});
    await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('엘리의 물약 연구하기'));
    await tester.tap(find.text('엘리의 물약 연구하기')); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    for (final name in ['달빛 결정', '심해 소금', '별빛 버섯']) {
      if (find.text('재료').evaluate().isNotEmpty) { await tester.tap(find.text('재료')); await tester.pumpAndSettle(); }
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, name));
      await tester.tap(find.widgetWithText(OutlinedButton, name)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final draft = Game.decode(prefs.getString('potionshop.v2')!).researchNotebook!;
      expect(ResearchSession.decode(draft).slots.whereType<String>().length, ['달빛 결정', '심해 소금', '별빛 버섯'].indexOf(name) + 1);
    }
    await tester.ensureVisible(find.widgetWithText(FilledButton, '조합 실험하기'));
    await tester.tap(find.widgetWithText(FilledButton, '조합 실험하기')); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final saved = Game.decode(prefs.getString('potionshop.v2')!);
    expect(saved.knows('sight'), isTrue); expect(saved.stock['sight'], 1);
    expect(saved.materials.values.every((value) => value == 0), isTrue);
    expect(tester.takeException(), isNull);
  });
  test('Replacing and swapping preserve fixed positions and historical guesses', () {
    final s = ResearchSession();
    for (final id in ['salt', 'moon', 'mushroom']) { s.place(id); }
    final attempt = s.submit()!;
    expect(attempt.strikes, 1); expect(attempt.balls, 2);
    expect(s.slots, ['salt', 'moon', 'mushroom']);
    s.clearSlot(1);
    expect(s.slots, ['salt', null, 'mushroom']);
    s.place('moon'); s.selectSlot(0); s.place('moon');
    expect(s.slots, ['moon', 'salt', 'mushroom']);
    expect(attempt.guess, ['salt', 'moon', 'mushroom']);
    s.reuse(attempt); expect(s.slots, attempt.guess);
    s.selectSlot(0); s.place('moon');
    expect(s.submit()!.strikes, 3); expect(s.ready, isFalse);
    expect(ResearchSession.decode(s.encode()).encode(), s.encode());
  });
  test('Saving retains empty positions, selected slot and scored history', () {
    final s = ResearchSession();
    for (final id in ['web', 'moon', 'mushroom']) { s.place(id); }
    s.submit(); s.clearSlot(1);
    final restored = ResearchSession.decode(s.encode());
    expect(restored.slots, ['web', null, 'mushroom']);
    expect(restored.activeSlot, 1); expect(restored.attempts.length, 1);
    expect(restored.attempts.single.strikes, 1);
    expect(() => ResearchSession.decode(s.encode().replaceFirst('"strikes":1', '"strikes":3')), throwsFormatException);
  });
  for (final size in [const Size(1280, 720), const Size(360, 800)]) {
    testWidgets('Research remains usable at $size, retains draft and unlocks after swapping', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const PotionShop(researchFirst: true)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      for (final name in ['심해 소금', '달빛 결정', '별빛 버섯']) {
        if (find.text('재료').evaluate().isNotEmpty) { await tester.tap(find.text('재료')); await tester.pumpAndSettle(); }
        final tile = find.widgetWithText(OutlinedButton, name);
        expect(tile.hitTestable(), findsOneWidget);
        await tester.tap(tile); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      }
      final button = find.widgetWithText(FilledButton, '조합 실험하기');
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      expect(find.textContaining('1 완벽 · 2 불안정'), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      var saved = ResearchSession.decode(prefs.getString('potionshop.research.v1')!);
      expect(saved.slots, ['salt', 'moon', 'mushroom']);
      expect(saved.attempts.length, 1);
      await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.pumpWidget(const PotionShop(researchFirst: true)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      if (find.text('기록').evaluate().isNotEmpty) { await tester.tap(find.text('기록')); await tester.pumpAndSettle(); }
      expect(find.textContaining('1 완벽 · 2 불안정'), findsWidgets);
      if (find.text('조합').evaluate().isNotEmpty) { await tester.tap(find.text('조합')); await tester.pumpAndSettle(); }
      final first = find.widgetWithText(TextButton, '1번째 칸');
      await tester.tap(first); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '달빛 결정')); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.tap(button); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      expect(find.textContaining('시야 물약 완성!'), findsOneWidget);
      saved = ResearchSession.decode(prefs.getString('potionshop.research.v1')!);
      expect(saved.solved, isTrue); expect(saved.attempts.length, 2);
      expect(tester.takeException(), isNull);
    });
  }
}




