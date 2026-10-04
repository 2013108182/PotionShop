import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potionshop/game.dart';
import 'package:potionshop/opening_screen.dart';
import 'package:potionshop/title_screen.dart';

void main() {
  Future<void> mount(WidgetTester t, Map<String, Object> save) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(save);
    await t.pumpWidget(MaterialApp(home: TitleScreen(opening: () => const Scaffold(body: Text('opening')),
      shop: (key) => Scaffold(body: Text(key)))));
    await t.pumpAndSettle();
  }
  testWidgets('No save disables continue; new story is saved before entry', (t) async {
    await mount(t, {});
    expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, '이어하기')).onPressed, isNull);
    await t.tap(find.text('새로 시작')); await t.pumpAndSettle();
    expect(find.text('opening'), findsOneWidget);
    final data = jsonDecode((await SharedPreferences.getInstance()).getString(openingSaveKey)!);
    expect(data['stage'], 0);
  });
  testWidgets('Cancel retains save; confirmation starts fresh instead of old shop', (t) async {
    final saved = (Game()..day = 4..gold = 555).encode();
    await mount(t, {'potionshop.v2': saved});
    await t.tap(find.text('새로 시작')); await t.pumpAndSettle();
    await t.tap(find.text('돌아가기')); await t.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getString(openingSaveKey), isNull);
    await t.tap(find.text('새로 시작')); await t.pumpAndSettle();
    await t.tap(find.text('새로 시작하기')); await t.pumpAndSettle();
    final data = jsonDecode((await SharedPreferences.getInstance()).getString(openingSaveKey)!);
    expect(Game.decode(data['game']).gold, 128); expect(find.text('opening'), findsOneWidget);
  });
  testWidgets('Completed introduction continues the latest shop save', (t) async {
    await mount(t, {openingSaveKey: jsonEncode({'stage': 13, 'game': Game().encode()}),
      storySaveKey: (Game()..day = 6..gold = 777).encode()});
    expect(find.text('6일째 · 낮 · 777 G'), findsOneWidget);
    await t.tap(find.text('이어하기')); await t.pumpAndSettle();
    expect(find.text(storySaveKey), findsOneWidget);
  });
}
