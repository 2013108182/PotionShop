import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/main.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/opening_screen.dart';
import 'package:potionshop/shop_world.dart';

Finder dialogueContaining(String text) => find.byWidgetPredicate((widget) => widget is Text && (widget.semanticsLabel ?? widget.data ?? '').replaceAll('\u2060', '').contains(text));

void main() {
  testWidgets('Arrival, conversation, selection and response reveal only their own UI', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({openingSaveKey: jsonEncode({'stage': 1, 'game': Game().encode()})});
    await tester.pumpWidget(const PotionShop());
    await tester.pump(); await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('이어하기')); await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('물약 건네기'), findsNothing);
    expect(find.byKey(const ValueKey('npc-speech')), findsNothing);
    expect(find.byTooltip('손님 대화'), findsNothing);
    expect(dialogueContaining('숙면 물약 한 병을 건네보세요'), findsNothing);
    for (var i = 0; i < 300; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    expect(find.byTooltip('손님 대화'), findsOneWidget);
    expect(find.text('물약 건네기'), findsNothing);
    final mapSize = tester.getSize(find.byType(ShopWorld));
    await tester.tap(find.byTooltip('손님 대화')); await tester.pump();
    expect(find.byKey(const ValueKey('npc-speech')), findsOneWidget);
    await tester.tap(find.text('물약 고르기')); await tester.pump();
    expect(find.byKey(const ValueKey('npc-speech')), findsNothing);
    expect(tester.getSize(find.byType(ShopWorld)), mapSize);
    await tester.tap(find.widgetWithText(OutlinedButton, '깊은 밤의\n숙면 물약')); await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '물약 건네기'));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('163 G'), findsOneWidget);
    expect(find.text('물약 건네기'), findsNothing);
    expect(dialogueContaining('오늘 밤은 편안히 잘 수 있겠네요'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape); await tester.pump(); await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('npc-speech')), findsNothing);
    await tester.tap(find.byTooltip('손님 대화')); await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '상점 관리')); await tester.pump(); await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('npc-speech')), findsNothing);
    expect(tester.getSize(find.byType(ShopWorld)), mapSize);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
