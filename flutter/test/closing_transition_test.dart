import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/shop_tasks.dart';

void main() {
  testWidgets('Opening door keeps the departing note and its size until fully closed', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PotionShop());
    await tester.pump(); await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('새로 시작'));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
    final panel = find.byKey(const ValueKey('shop-panel'));
    final original = tester.getRect(panel);
    expect(find.text('당신은 이 상점을 물려받은 새 약사입니다.'), findsNothing);
    await tester.tap(find.text('상점 문 열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getRect(panel), original);
    expect(find.text('상점 문 열기'), findsOneWidget);
    expect(find.byType(PotionSelection), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('상점 문 열기'), findsNothing);
    expect(find.byType(PotionSelection), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
