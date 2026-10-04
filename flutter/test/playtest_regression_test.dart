import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/main.dart';

Future<void> openSavedShop(WidgetTester tester, Game game) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  SharedPreferences.setMockInitialValues({'potionshop.v2': game.encode()});
  await tester.pumpWidget(const PotionShop(researchFirst: false));
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final section in ['설비', '영업 장부', '재료 상인']) {
    testWidgets('F08 guild shortcut opens the order after visiting $section',
        (tester) async {
      final game = Game()
        ..day = 3
        ..customer = 3
        ..supplierUnlocked = (section == '재료 상인');
      if (game.completed) game.discovered.add('sight');
      await openSavedShop(tester, game);
      final shortcut = find.widgetWithText(TextButton,
          game.completed ? '협회 납품 완료' : '협회 주문 · 0/3');
      await tapAndSettle(tester, shortcut);
      await tapAndSettle(tester, find.text(section));
      final heading = find.text(section == '설비'
          ? '가마솥 공방'
          : section == '영업 장부' ? '3일째 영업 장부' : '재료 구매');
      expect(heading, findsOneWidget);

      // Ordinary close/reopen preserves the current management subtab.
      await tapAndSettle(tester, find.byTooltip('패널 닫기'));
      await tapAndSettle(tester, find.widgetWithText(TextButton, '상점 관리'));
      expect(heading, findsOneWidget);

      // The named shortcut must override that remembered destination.
      await tapAndSettle(tester, shortcut);
      expect(find.text('길잡이 조합의 편지'), findsOneWidget);
      expect(heading, findsNothing);
      expect(find.text(game.completed ? '납품 완료' : '시야 물약 3병'),
          findsOneWidget);
      await tapAndSettle(tester, shortcut);
      expect(find.text('길잡이 조합의 편지'), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip('패널 닫기'));
      await tapAndSettle(tester, shortcut);
      expect(find.text('길잡이 조합의 편지'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scenario in ['pending', 'completed', 'no request']) {
    testWidgets('F09 closing offers the appropriate night activity: $scenario',
        (tester) async {
      final game = Game()
        ..day = 2
        ..customer = 3
        ..researchRequested = scenario != 'no request';
      if (scenario == 'completed') game.discovered.add('sight');
      await openSavedShop(tester, game);
      final pending = scenario == 'pending';
      final label = pending ? '밤 연구실로 가기' : '내일 영업 준비하기';
      expect(find.text(label), findsOneWidget);
      expect(find.text(pending ? '내일 영업 준비하기' : '밤 연구실로 가기'),
          findsNothing);
      await tapAndSettle(tester, find.text(label));
      expect(find.text('2일째 · 밤 연구와 준비'), findsOneWidget);
      expect(find.text('내일의 영업 준비'), findsOneWidget);
      expect(find.text('엘리의 물약 연구하기'),
          pending ? findsOneWidget : findsNothing);
      expect(find.text('준비를 마치고 3일째 시작'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(Game.decode(prefs.getString('potionshop.v2')!).night, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
