import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/game.dart';

void main() {
  testWidgets('Incorrect service explains, allows retry, then releases the next customer', (tester) async {
    tester.view.physicalSize = const Size(1280, 720); tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final g = Game()..day = 3..discovered.add('sight'); g.stock['sight'] = 4;
    SharedPreferences.setMockInitialValues({'potionshop.v2': g.encode()});
    await tester.pumpWidget(const PotionShop(researchFirst: false)); await tester.pumpAndSettle();
    Future<void> tap(Finder f) async { await tester.ensureVisible(f); await tester.tap(f); await tester.pumpAndSettle(); }
    await tap(find.byTooltip('손님 대화')); await tap(find.text('물약 고르기'));
    await tap(find.widgetWithText(OutlinedButton, '올빼미의\n시야 물약'));
    await tap(find.text('물약 건네기'));
    expect(find.byWidgetPredicate((w) => w is Text && (w.semanticsLabel ?? '').contains('한 번만 다시')), findsOneWidget);
    await tap(find.text('물약 고르기'));
    await tap(find.widgetWithText(OutlinedButton, '올빼미의\n시야 물약')); await tap(find.text('물약 건네기'));
    expect(find.byWidgetPredicate((w) => w is Text && (w.semanticsLabel ?? '').contains('다른 가게')), findsOneWidget);
    await tap(find.text('대화 마치기'));
    await tap(find.byTooltip('손님 대화')); await tap(find.text('물약 고르기'));
    await tap(find.widgetWithText(OutlinedButton, '올빼미의\n시야 물약')); await tap(find.text('물약 건네기'));
    final saved = Game.decode((await SharedPreferences.getInstance()).getString('potionshop.v2')!);
    expect(saved.customer, 2); expect(saved.lostSales, 1); expect(saved.gold, 166);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
