import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/main.dart';

void main() {
  testWidgets('Small screen supports first-day sales, demand and the night transition', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'potionshop.v1': 'old prototype save'});
    await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    expect(find.text('1일째 · 낮 영업'), findsOneWidget);
    expect(find.text('128 G'), findsOneWidget);
    expect(find.textContaining('이전 상점 저장'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      final sale = find.widgetWithText(OutlinedButton, '깊은 밤의 숙면 물약');
      await tester.ensureVisible(sale); await tester.tap(sale); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
      final give = find.widgetWithText(FilledButton, '물약 건네기');
      await tester.ensureVisible(give); await tester.tap(give); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    }
    final skip = find.text('아직 없어요 · 요청 기록하기');
    await tester.ensureVisible(skip); await tester.tap(skip); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    final night = find.text('밤 연구실로 가기');
    await tester.ensureVisible(night); await tester.tap(night); await tester.pump(const Duration(milliseconds: 700)); await tester.pumpAndSettle();
    expect(find.text('1일째 · 밤 연구와 준비'), findsOneWidget);
    expect(find.text('연구실 · 어둠 속 시야'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(Game.decode(prefs.getString('potionshop.v2')!).night, isTrue);
    expect(prefs.getString('potionshop.v1'), 'old prototype save');
    expect(tester.takeException(), isNull);
  });
}



