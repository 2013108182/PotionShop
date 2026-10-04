import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/opening_screen.dart';
import 'package:potionshop/tutorial_session.dart';
import 'package:potionshop/tutorial_screen.dart';

void main() {
  test('Every tutorial step locks commands and round trips all progress', () {
    var session = TutorialSession();
    final game = Game();
    final before = game.encode();
    while (!session.satisfied) {
      final snapshot = session.toJson();
      session = TutorialSession.fromJson(jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>);
      expect(session.toJson(), snapshot);
      final revision = session.revision;
      final step = session.current;
      for (final action in TutorialAction.values) {
        if (action != step.action) expect(session.apply(revision, action), isFalse);
      }
      for (final id in [...tutorialSamples.keys, 'unknown']) {
        if (id != step.ingredient) {
          expect(session.apply(revision, TutorialAction.select, ingredient: id), isFalse);
        }
      }
      expect(session.toJson(), snapshot);
      expect(session.apply(revision, step.action, ingredient: step.ingredient), isTrue);
      expect(session.apply(revision, step.action, ingredient: step.ingredient), isFalse);
    }
    expect(session.attempts.map((a) => [a.strikes, a.balls]).toList(), [[1, 2], [0, 0], [3, 0]]);
    expect(session.attempts.map((a) => a.guess).toList(), tutorialGuesses);
    expect(TutorialSession.fromJson(session.toJson()).satisfied, isTrue);
    expect(session.apply(session.revision, TutorialAction.next), isFalse);
    expect(game.encode(), before); // Session has no Game mutation or reward API.
    expect(ingredients.any((i) => i.id == 'tutorial_unicorn'), isFalse);
    expect(potions.any((p) => p.recipe.contains('tutorial_unicorn')), isFalse);
  });

  test('Corrupt tutorial progress is rejected and legacy saves are exempt', () {
    final bad = TutorialSession().toJson()..['step'] = 99;
    expect(() => TutorialSession.fromJson(bad), throwsFormatException);
    final forged = TutorialSession().toJson()..['status'] = 'completed';
    expect(() => TutorialSession.fromJson(forged), throwsFormatException);
    final wrongSlots = TutorialSession().toJson()..['slots'] = ['moon'];
    expect(() => TutorialSession.fromJson(wrongSlots), throwsFormatException);
    final old = jsonDecode(Game().encode()) as Map<String, dynamic>;
    old['version'] = 2;
    old.remove('tutorialProgress');
    final migrated = Game.decode(jsonEncode(old));
    expect(TutorialSession.fromJson(migrated.tutorialProgress).satisfied, isTrue);
    expect(migrated.gold, 128); expect(migrated.stock['sleep'], 3);
  });

  for (final reduced in [false, true]) {
    testWidgets('Tutorial restores a middle experiment with motion setting $reduced', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      var session = TutorialSession();
      while (session.current.id != 'guess_2_2') {
        session.apply(session.revision, session.current.action, ingredient: session.current.ingredient);
      }
      Map<String, dynamic>? stored;
      await tester.pumpWidget(MaterialApp(home: TutorialScreen(session: session, onChanged: (data) async { stored = data; })));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tutorial-attempt-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('tutorial-attempt-1')), findsNothing);
      expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('tutorial-sample-web'))).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('tutorial-sample-salt')));
      await tester.pumpAndSettle();
      expect(stored, isNotNull);
      await tester.pumpWidget(const SizedBox());
      session = TutorialSession.fromJson(stored);
      await tester.pumpWidget(MaterialApp(home: TutorialScreen(session: session, onChanged: (_) async {})));
      await tester.pumpAndSettle();
      expect(session.current.id, 'guess_2_3');
      expect(session.slots, ['fairy', 'salt']);
      expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('tutorial-sample-tutorial_unicorn'))).onPressed, isNotNull);
      expect(session.attempts.length, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Invalid opening retains original save and blocks mutations', (tester) async {
    const source = '{damaged opening';
    SharedPreferences.setMockInitialValues({openingSaveKey: source});
    await tester.pumpWidget(MaterialApp(home: OpeningJourney(onFinished: () => const Text('done'))));
    await tester.pumpAndSettle();
    expect(find.text('기록 다시 불러오기'), findsOneWidget);
    expect(find.text('상점 문 열기'), findsNothing);
    await tester.tap(find.text('기록 다시 불러오기'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(openingSaveKey), source);
    expect(find.byType(TutorialScreen), findsNothing);
  });

  testWidgets('A durably completed opening hands off without another story beat', (tester) async {
    final game = Game()..day = 2..customer = 1;
    game.discovered.add('sight');
    SharedPreferences.setMockInitialValues({openingSaveKey: jsonEncode({'stage': 13, 'game': game.encode()})});
    await tester.pumpWidget(MaterialApp(home: OpeningJourney(onFinished: () => const Text('shop handoff'))));
    await tester.pumpAndSettle();
    expect(find.text('shop handoff'), findsOneWidget);
    expect(find.text('영업 기록 저장'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed completion save stays in practice and retries without replay', (tester) async {
    final session = TutorialSession();
    while (session.current.id != 'return_shop') {
      session.apply(session.revision, session.current.action, ingredient: session.current.ingredient);
    }
    var writes = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<bool>(builder: (_) => TutorialScreen(
        session: session, onChanged: (_) async {
          writes++;
          if (writes == 1) throw StateError('Storage unavailable');
        }))), child: const Text('open practice'))))));
    await tester.tap(find.text('open practice')); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-next'))); await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.text('연습 기록 저장 다시 시도'), findsOneWidget);
    expect(session.satisfied, isTrue); expect(session.attempts.length, 3);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop(); await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(writes, 1);
    await tester.tap(find.text('연습 기록 저장 다시 시도')); await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(writes, 2); expect(session.attempts.length, 3);
  });

  testWidgets('A version 2 opening resumes first sale without forced education', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final old = jsonDecode(Game().encode()) as Map<String, dynamic>;
    old['version'] = 2; old.remove('tutorialProgress');
    final legacySource = jsonEncode({'stage': 1, 'game': jsonEncode(old)});
    SharedPreferences.setMockInitialValues({openingSaveKey: legacySource});
    await tester.pumpWidget(MaterialApp(home: OpeningJourney(onFinished: () => const Text('done'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('손님 대화')); await tester.pumpAndSettle();
    await tester.tap(find.text('물약 고르기')); await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '깊은 밤의\n숙면 물약')); await tester.pumpAndSettle();
    final give = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '물약 건네기')).onPressed!;
    give(); give(); // A stale second callback cannot sell again or skip a beat.
    await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('$openingSaveKey.backup.v2'), legacySource);
    final snapshot = jsonDecode(prefs.getString(openingSaveKey)!) as Map<String, dynamic>;
    final restored = Game.decode(snapshot['game'] as String);
    expect(snapshot['stage'], 2);
    expect(restored.gold, 163); expect(restored.stock['sleep'], 2);
    expect(restored.customer, 1);
  });
}
