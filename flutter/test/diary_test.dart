import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/diary_screen.dart';

void main() {
  testWidgets('Practice replay changes neither game progress nor inventory', (tester) async {
    final game = Game();
    final before = game.encode();
    var changes = 0;
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(game: game, onChanged: () => changes++)));
    await tester.tap(find.text('실험 기록 읽기 연습'));
    await tester.pumpAndSettle();
    expect(find.text('스승의 숙면 연습'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('tutorial-next')));
    await tester.tap(find.byKey(const ValueKey('tutorial-next')));
    await tester.pumpAndSettle();
    await tester.pageBack(); await tester.pumpAndSettle();
    expect(find.text('주민 다이어리'), findsOneWidget);
    expect(game.encode(), before);
    expect(changes, 0);
  });
  testWidgets('Diary shows witnessed facts, hides unmet residents and future stories', (tester) async {
    final game = Game();
    game.residents['robin']!.met = true;
    game.diary.add(DiaryEntry(id: 'robin.fact', residentId: 'robin', kind: 'fact',
      title: '새벽의 약초', text: '새벽마다 약초를 돌본다.', day: 1));
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(game: game, onChanged: () {})));
    expect(find.text('새벽마다 약초를 돌본다.'), findsOneWidget);
    expect(find.text('나리'), findsNothing);
    expect(find.textContaining('교환회'), findsNothing);
    expect(find.text('낯익은 손님'), findsOneWidget);
  });
  testWidgets('Reading a record never raises affinity and persists only read state', (tester) async {
    final game = Game();
    game.residents['robin']!.met = true;
    game.diary.add(DiaryEntry(id: 'robin.fact', residentId: 'robin', kind: 'fact',
      title: '새벽의 약초', text: '새벽마다 약초를 돌본다.', day: 1));
    final trust = game.residents['robin']!.trustStage;
    var saves = 0;
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(game: game, onChanged: () {},
      onPersist: () async { saves++; return true; })));
    await tester.tap(find.text('읽음 표시'));
    await tester.pumpAndSettle();
    expect(game.diary.single.read, isTrue);
    expect(game.residents['robin']!.trustStage, trust);
    expect(saves, 1);
    expect(find.text('읽음 표시'), findsNothing);
  });
  testWidgets('Failed diary persistence offers retry without replaying events', (tester) async {
    final game = Game();
    game.residents['robin']!.met = true;
    game.diary.add(DiaryEntry(id: 'robin.fact', residentId: 'robin', kind: 'fact',
      title: '새벽의 약초', text: '새벽마다 약초를 돌본다.', day: 1));
    var saves = 0;
    await tester.pumpWidget(MaterialApp(home: DiaryScreen(game: game, onChanged: () {},
      onPersist: () async => ++saves > 1)));
    await tester.tap(find.text('읽음 표시'));
    await tester.pumpAndSettle();
    expect(find.text('저장 다시 시도'), findsOneWidget);
    await tester.tap(find.text('저장 다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('저장 다시 시도'), findsNothing);
    expect(game.diary.length, 1);
    expect(saves, 2);
  });
}
