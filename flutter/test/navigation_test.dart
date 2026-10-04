import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/shop_world.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(1280, 720)]) {
    testWidgets('Tabs preserve selected potion and selection alone does not sell at $size', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async { await tester.ensureVisible(finder); await tester.tap(finder); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle(); }
      final give = find.widgetWithText(FilledButton, '물약 건네기');
      expect(tester.widget<FilledButton>(give).onPressed, isNull);
      await tap(find.widgetWithText(OutlinedButton, '깊은 밤의 숙면 물약'));
      expect(find.text('128 G'), findsOneWidget);
      final world = find.byType(ShopWorld);
      expect(world, findsOneWidget);
      expect(tester.getSize(world).height, greaterThan(150));
      final mapHeight = tester.getSize(world).height;
      await tap(find.byTooltip('패널 닫기'));
      expect(tester.getSize(world).height, greaterThan(mapHeight));
      await tap(find.widgetWithText(TextButton, '손님 응대'));
      expect(tester.widget<FilledButton>(give).onPressed, isNotNull);
      await tap(find.widgetWithText(TextButton, '작업대'));
      expect(find.text('레시피로 제조'), findsOneWidget);
      await tap(find.widgetWithText(TextButton, '상점 관리'));
      expect(find.text('재료 구매'), findsOneWidget);
      await tap(find.widgetWithText(TextButton, '손님 응대'));
      expect(tester.widget<FilledButton>(give).onPressed, isNotNull);
      await tap(give);
      final saved = Game.decode((await SharedPreferences.getInstance()).getString('potionshop.v2')!);
      expect(saved.gold, 163); expect(saved.stock['sleep'], 2); expect(saved.customer, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

