import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/research_screen.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/research_session.dart';

void main() {
  test('Every catalog recipe has an isolated free research notebook', () {
    for (final potion in potions) {
      final notebook = ResearchSession(potionId: potion.id);
      expect(notebook.slotCount, 3);
      for (final id in potion.recipe) { notebook.place(id); }
      expect(notebook.submit()!.strikes, 3, reason: potion.id);
      final restored = ResearchSession.decode(notebook.encode());
      expect(restored.potionId, potion.id);
      expect(restored.solved, isTrue);
      expect(restored.submit(), isNull);
    }
  });
  test('Research state is independent of empty shop stock and material ownership', () {
    final game = Game();
    game.materials.updateAll((key, value) => 0);
    final before = game.encode();
    final notebook = ResearchSession(potionId: 'sprout');
    for (final id in notebook.target.recipe) { notebook.place(id); }
    expect(notebook.submit()!.strikes, 3);
    expect(game.encode(), before);
  });
  test('Legacy v1 notes migrate to sight without losing empty slots or history', () {
    final restored = ResearchSession.decode(jsonEncode({
      'version': 1, 'slots': ['salt', null, 'mushroom'], 'active': 1,
      'attempts': [{'guess': ['salt', 'moon', 'mushroom'], 'strikes': 1, 'balls': 2}],
    }));
    expect(restored.potionId, 'sight');
    expect(restored.slots, ['salt', null, 'mushroom']);
    expect(restored.attempts.single.strikes, 1);
    expect(restored.marks, isEmpty);
    expect(restored.memo, isEmpty);
    expect(jsonDecode(restored.encode())['version'], 2);
  });
  test('Marks never infer an answer and excluded ingredients can be tested', () {
    final notebook = ResearchSession();
    notebook.setMark('moon', 'excluded');
    for (final id in notebook.target.recipe) { notebook.place(id); }
    expect(notebook.submit()!.strikes, 3);
    expect(notebook.marks, {'moon': 'excluded'});
    final restored = ResearchSession.decode(notebook.encode());
    expect(restored.marks, notebook.marks);
  });
  test('Clear slots, clear annotations and fresh practice have separate effects', () {
    final notebook = ResearchSession()..setMemo('소금과 달빛을 바꿔 보기')..setMark('salt', 'candidate');
    for (final id in ['salt', 'moon', 'mushroom']) { notebook.place(id); }
    notebook.submit(); notebook.clearSlots();
    expect(notebook.attempts, hasLength(1));
    expect(notebook.memo, isNotEmpty);
    final fresh = notebook.freshNotebook();
    expect(fresh.attempts, isEmpty);
    expect(fresh.memo, notebook.memo);
    expect(fresh.marks, notebook.marks);
    notebook.reuse(notebook.attempts.single);
    final draft = [...notebook.slots];
    notebook.clearMemo();
    expect(notebook.slots, draft);
    expect(notebook.attempts, hasLength(1));
    expect(notebook.marks, isEmpty);
    expect(notebook.memo, isEmpty);
  });
  test('Annotations sanitize independently while invalid scores and definitions fail', () {
    final notebook = ResearchSession()..setMemo(List.filled(210, '한').join());
    expect(notebook.memo.runes.length, 200);
    final data = jsonDecode(notebook.encode()) as Map<String, dynamic>;
    data['marks'] = {'moon': 'excluded', 'unknown': 'candidate', 'salt': 'invalid'};
    expect(ResearchSession.decode(jsonEncode(data)).marks, {'moon': 'excluded'});
    data['recipeVersion'] = 99;
    expect(() => ResearchSession.decode(jsonEncode(data)), throwsFormatException);
    expect(() => ResearchSession(potionId: 'not-a-potion'), throwsFormatException);
  });
  test('Switching targets preserves each target and discovery is idempotent', () {
    final game = Game();
    for (final id in ['sight', 'warmth']) {
      final notebook = ResearchSession(potionId: id)..setMemo('$id 메모');
      for (final ingredient in notebook.target.recipe) { notebook.place(ingredient); }
      notebook.submit();
      game.setNotebook(id, notebook.encode());
      expect(game.discoverRecipe(id), isTrue);
      expect(game.discoverRecipe(id), isFalse);
      expect(game.stock[id], 1);
    }
    expect(ResearchSession.decode(game.notebookFor('sight')!).memo, 'sight 메모');
    expect(ResearchSession.decode(game.notebookFor('warmth')!).memo, 'warmth 메모');
  });
  testWidgets('Failed persistence blocks further edits until an explicit retry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final game = Game();
    await tester.pumpWidget(MaterialApp(home: ResearchStudio(game: game,
      persistGame: (_) async => ++calls > 1)));
    await tester.pumpAndSettle();
    if (find.text('재료').evaluate().isNotEmpty) {
      await tester.tap(find.text('재료')); await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '달빛 결정'));
    await tester.tap(find.widgetWithText(OutlinedButton, '달빛 결정'));
    await tester.pumpAndSettle();
    expect(find.text('저장 다시 시도'), findsOneWidget);
    expect(ResearchSession.decode(game.notebookFor('sight')!).slots.whereType<String>(), ['moon']);
    await tester.tap(find.text('저장 다시 시도')); await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('저장 다시 시도'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unreadable notebook is preserved and research cannot overwrite it', (tester) async {
    SharedPreferences.setMockInitialValues({'potionshop.research.v1': 'broken-notebook'});
    await tester.pumpWidget(const MaterialApp(home: ResearchStudio()));
    await tester.pumpAndSettle();
    expect(find.textContaining('원본을 보존했어요'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '조합 실험하기'));
    expect(button.onPressed, isNull);
    expect((await SharedPreferences.getInstance()).getString('potionshop.research.v1'), 'broken-notebook');
    expect(tester.takeException(), isNull);
  });

  test('V3 shop restores sight experiments using rare samples without unlocking trade', () {
    final game = Game();
    final notebook = ResearchSession();
    for (final id in ['root', 'fairy', 'tear']) { notebook.place(id); }
    final attempt = notebook.submit()!;
    expect(attempt.strikes + attempt.balls, 0);
    game.attempts = [...notebook.attempts];
    game.setNotebook('sight', notebook.encode());
    final restored = Game.decode(game.encode());
    expect(restored.attempts.single.guess, ['root', 'fairy', 'tear']);
    expect(ResearchSession.decode(restored.notebookFor('sight')!).attempts.single.guess,
      ['root', 'fairy', 'tear']);
    expect(restored.supplierUnlocked, isFalse);
  });

}
