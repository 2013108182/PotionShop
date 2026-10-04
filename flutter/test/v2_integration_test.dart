import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/resident_catalog.dart' as content;

void main() {
  test('All resident stories connect requests, free research, deliveries and later reviews across reloads', () {
    // A funded post-guild fixture isolates progression from economy tuning.
    var game = Game()..day = 3..gold = 10000..discovered.add('sight');
    game.stock['sight'] = 3;
    expect(game.deliver(), isTrue);
    var completedDays = 0;
    while (completedDays < 80 && game.residents.values.any((p) => p.storyIndex < 4)) {
      while (!game.serviceFinished) {
        game.recordArrival();
        final arrived = game.encode();
        game.recordArrival();
        expect(game.encode(), arrived, reason: 'Reopening an arrival must not replay gifts or facts');
        final beat = game.currentStory;
        final visitId = game.currentVisitId!;
        if (beat != null && (game.currentStoryNeedsReview || beat.potionId == null)) {
          final wasReview = game.currentStoryNeedsReview;
          final residentId = game.currentResidentId!;
          if (wasReview) {
            expect(game.residents[residentId]!.deliveredDay, lessThan(game.day));
            expect(game.residents[residentId]!.successfulServices[beat.potionId], greaterThan(0));
          }
          expect(game.resolveStory(visitId: visitId), isNull, reason: beat.id);
          expect(game.residents[residentId]!.completedBeatIds, contains(beat.id));
          final resolved = game.encode();
          expect(game.resolveStory(visitId: visitId), isNotNull);
          expect(game.encode(), resolved, reason: 'A stale completion callback must be harmless');
        } else {
          final wanted = game.orders[game.customer].$3;
          if (!game.knows(wanted)) {
            expect(game.skipCustomer(), isTrue);
          } else {
            if (game.stock[wanted] == 0) expect(game.prepare(wanted, 1), isNull);
            final residentId = game.currentResidentId!;
            expect(game.sell(wanted, visitId: visitId), isNull);
            if (beat != null) {
              expect(game.residents[residentId]!.pendingReview, beat.id);
              expect(game.residents[residentId]!.completedBeatIds, isNot(contains(beat.id)),
                  reason: 'A delivery is not yet evidence of successful use');
            }
            final sold = game.encode();
            expect(game.sell(wanted, visitId: visitId), isNotNull);
            expect(game.encode(), sold);
          }
        }
      }
      expect(game.startNight(), isTrue);
      final plan = jsonEncode(game.nextDayPlan!.map((v) => v.toJson()).toList());
      for (final id in [...game.pendingResearchIds]) {
        final gold = game.gold, materials = Map<String, int>.from(game.materials);
        expect(game.research(potionById(id).recipe, potionId: id), isNull);
        expect(game.gold, gold);
        expect(game.materials, materials);
        expect(game.stock[id], 1);
      }
      expect(jsonEncode(game.nextDayPlan!.map((v) => v.toJson()).toList()), plan,
          reason: 'Night discoveries must not change the announced visits');
      game = Game.decode(game.encode());
      expect(jsonEncode(game.nextDayPlan!.map((v) => v.toJson()).toList()), plan);
      expect(game.nextDay(), isTrue);
      expect(jsonEncode(game.visitQueue!.map((v) => v.toJson()).toList()), plan);
      completedDays++;
    }
    expect(game.residents.values.every((p) => p.storyIndex == 4), isTrue,
        reason: 'Every available resident needs a finite route to the ending');
    expect(game.discovered, containsAll(potions.map((p) => p.id)));
    for (final definition in content.residents) {
      final progress = game.residents[definition.id]!;
      expect(progress.completedBeatIds, containsAll(definition.story.map((b) => b.id)));
      expect(progress.trustStage, 2, reason: definition.id);
    }
    expect(game.diary.map((e) => e.id).toSet().length, game.diary.length);
  });

  testWidgets('A non-sale story is saved once and appears in the diary after reopening', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final game = Game()..day = 4..discovered.add('sight');
    game.stock['sight'] = 3;
    expect(game.deliver(), isTrue);
    final sage = content.residentById('sage'), beat = content.residentById('sage').story.first;
    game.visitQueue = [
      VisitPlan(visitId: '4:0:sage', day: 4, residentId: 'sage', name: sage.name,
          text: beat.request, storyBeatId: beat.id),
      const VisitPlan(visitId: '4:1:robin', day: 4, residentId: 'robin', name: '로빈', text: '숙면 물약 부탁해요.', potionId: 'sleep'),
      const VisitPlan(visitId: '4:2:mina', day: 4, residentId: 'mina', name: '미나', text: '숙면 물약 부탁해요.', potionId: 'sleep'),
    ];
    SharedPreferences.setMockInitialValues({'potionshop.v2': game.encode()});
    await tester.pumpWidget(const PotionShop(researchFirst: false));
    await tester.pumpAndSettle();
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder); await tester.tap(finder); await tester.pumpAndSettle();
    }
    await tap(find.byTooltip('손님 대화'));
    await tap(find.text('물약 고르기'));
    expect(find.text('이야기 나누기'), findsOneWidget);
    expect(find.text('물약 건네기'), findsNothing);
    await tap(find.text('이야기 나누기'));
    final prefs = await SharedPreferences.getInstance();
    final saved = Game.decode(prefs.getString('potionshop.v2')!);
    expect(saved.customer, 1); expect(saved.gold, game.gold); expect(saved.served, 0);
    expect(saved.residents['sage']!.storyIndex, 1);
    expect(saved.diary.where((e) => e.id == 'completed:${beat.id}'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const PotionShop(researchFirst: false));
    await tester.pumpAndSettle();
    await tap(find.text('주민 다이어리'));
    await tap(find.widgetWithText(ChoiceChip, sage.name));
    expect(find.text(beat.success), findsOneWidget);
    final reopened = Game.decode(prefs.getString('potionshop.v2')!);
    expect(reopened.residents['sage']!.storyIndex, 1);
    expect(reopened.diary.where((e) => e.id == 'completed:${beat.id}'), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Nari can finish the scent-free invitation without a sale or fabricated review', () {
    final game = Game()..day = 4;
    final nari = content.residentById('nari');
    final invitation = nari.story[2];
    game.residents['nari']!.storyIndex = 2;
    game.residents['nari']!.completedBeatIds.addAll(nari.story.take(2).map((b) => b.id));
    game.visitQueue = [
      VisitPlan(visitId: '4:0:nari', day: 4, residentId: 'nari', name: nari.name,
          text: invitation.request, potionId: invitation.potionId, storyBeatId: invitation.id),
      const VisitPlan(visitId: '4:1:robin', day: 4, residentId: 'robin', name: '로빈', text: '숙면 물약 부탁해요.', potionId: 'sleep'),
      const VisitPlan(visitId: '4:2:mina', day: 4, residentId: 'mina', name: '미나', text: '숙면 물약 부탁해요.', potionId: 'sleep'),
    ];
    final gold = game.gold, stock = Map<String, int>.from(game.stock);
    expect(game.knows('calm_scent'), isFalse);
    game.recordArrival();
    expect(game.resolveStory(chooseAlternative: true, visitId: '4:0:nari'), isNull);
    expect(game.gold, gold); expect(game.stock, stock); expect(game.served, 0);
    expect(game.residents['nari']!.storyIndex, 3);
    expect(game.residents['nari']!.pendingReview, isNull);
    expect(game.residents['nari']!.successfulServices['calm_scent'], isNull);
    expect(game.claimedEvents, contains('alternative:${invitation.id}'));
    final saved = game.encode();
    expect(game.resolveStory(chooseAlternative: true, visitId: '4:0:nari'), isNotNull);
    expect(game.encode(), saved);
    expect(Game.decode(saved).residents['nari']!.storyIndex, 3);
  });
}
