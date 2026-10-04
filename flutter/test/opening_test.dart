import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/opening_screen.dart';
import 'package:potionshop/research_session.dart';

Finder dialogueContaining(String text) => find.byWidgetPredicate((widget) => widget is Text && (widget.semanticsLabel ?? widget.data ?? '').replaceAll('\u2060', '').contains(text));

void main() {
  for (final size in [const Size(1280, 720), const Size(360, 800)]) {
    testWidgets('Opening at $size explains ownership, sale, request, research and reunion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final oldGame = (Game()..gold = 999).encode();
      SharedPreferences.setMockInitialValues({'potionshop.v2': oldGame});
      await tester.pumpWidget(const PotionShop()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      expect(dialogueContaining('오늘부터 이 가게의 주인은 너란다'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('설비 개선'), findsNothing); expect(find.text('달빛 연구실'), findsNothing);
      Future<void> action(String text) async {
        if (text.contains('한 병 건네기')) {
          if (find.text('물약 고르기').evaluate().isEmpty) {
            await tester.tap(find.byTooltip('손님 대화')); await tester.pumpAndSettle();
          }
          await tester.tap(find.text('물약 고르기')); await tester.pumpAndSettle();
          final choice = find.widgetWithText(OutlinedButton, text.startsWith('시야') ? '올빼미의 시야 물약' : '깊은 밤의 숙면 물약');
          await tester.ensureVisible(choice); await tester.tap(choice); await tester.pumpAndSettle();
        }
        final button = find.widgetWithText(FilledButton, text.contains('한 병 건네기') ? '물약 건네기' : text);
        await tester.ensureVisible(button); await tester.tap(button); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      }
      await action('상점 문 열기');
      await tester.tap(find.byTooltip('손님 대화')); await tester.pumpAndSettle();
      expect(dialogueContaining('요즘 잠을 통 못 자겠어요'), findsOneWidget);
      await action('숙면 물약 한 병 건네기 · 35 G');
      expect(find.text('163 G'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final firstSale = jsonDecode(prefs.getString(openingSaveKey)!) as Map<String, dynamic>;
      expect(Game.decode(firstSale['game'] as String).stock['sleep'], 2);
      expect(prefs.getString('potionshop.v2'), oldGame);
      // Resume the thank-you scene instead of charging for the first sale again.
      await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.pumpWidget(const PotionShop()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('손님 대화')); await tester.pumpAndSettle();
      expect(dialogueContaining('오늘 밤은 편안히 잘 수 있겠네요'), findsOneWidget); expect(find.text('163 G'), findsOneWidget);
      await action('다음 손님 맞이하기'); await action('숙면 물약 한 병 건네기 · 35 G');
      await action('문밖의 손님 맞이하기');
      await tester.tap(find.byTooltip('손님 대화')); await tester.pumpAndSettle();
      expect(dialogueContaining('어둠 속에서도 볼 수 있는 물약'), findsOneWidget);
      await action('새 물약을 만들어 보기로 약속하기');
      await action('문을 닫고 촛불 켜기'); await action('낡은 연구 메모 읽기');
      await action('엘리의 시야 물약 연구 시작');
      expect(find.text('달빛 연구실'), findsOneWidget);
      if (find.text('재료').evaluate().isNotEmpty) { await tester.tap(find.text('재료')); await tester.pumpAndSettle(); }
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, '달빛 결정'));
      await tester.tap(find.widgetWithText(OutlinedButton, '달빛 결정')); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      final saved = jsonDecode(prefs.getString(openingSaveKey)!) as Map<String, dynamic>;
      final night = Game.decode(saved['game'] as String);
      expect(night.night, isTrue);
      expect(ResearchSession.decode(night.researchNotebook!).slots, ['moon', null, null]);
      await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.pumpWidget(const PotionShop()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await action('하던 연구 이어가기');
      for (final name in ['심해 소금', '별빛 버섯']) {
        if (find.text('재료').evaluate().isNotEmpty) { await tester.tap(find.text('재료')); await tester.pumpAndSettle(); }
        final choice = find.widgetWithText(OutlinedButton, name);
        await tester.ensureVisible(choice); await tester.tap(choice); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      }
      await action('조합 실험하기');
      await tester.ensureVisible(find.text('상점으로 돌아가기'));
      await tester.tap(find.text('상점으로 돌아가기')); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      expect(find.text('다음 날, 엘리 맞이하기'), findsOneWidget);
      await action('다음 날, 엘리 맞이하기'); await action('시야 물약 한 병 건네기 · 38 G');
      expect(dialogueContaining('밤 배달을 시작한 친구'), findsOneWidget);
      await action('상점 영업 이어가기');
      expect(find.text('2일째 · 낮 영업'), findsOneWidget);
      expect(find.text('물약 건네기'), findsNothing);
      var shop = Game.decode(prefs.getString(storySaveKey)!);
      expect(shop.gold, 236); expect(shop.customer, 1); expect(shop.stock['sight'], 0);
      expect(shop.stock['sleep'], 1); expect(shop.knows('sight'), isTrue);
      await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      await tester.pumpWidget(const PotionShop()); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      expect(find.text('2일째 · 낮 영업'), findsOneWidget);
      expect(prefs.getString('potionshop.v2'), oldGame);
      expect(tester.takeException(), isNull);
    });
  }
}





