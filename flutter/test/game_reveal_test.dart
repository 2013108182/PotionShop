import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game_skin.dart';

void main() {
  testWidgets('Closing blocks input immediately and preserves contents until exit finishes', (tester) async {
    var taps = 0;
    Widget screen(bool visible, {bool reduced = false, String label = 'panel'}) => MaterialApp(
      home: MediaQuery(data: MediaQueryData(disableAnimations: reduced),
        child: GameReveal(visible: visible, child: Center(child: GestureDetector(
          onTap: () => taps++, child: Text(label))))));
    await tester.pumpWidget(screen(true));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('panel'));
    expect(taps, 1);
    await tester.pumpWidget(screen(false, label: 'next screen'));
    expect(find.text('next screen'), findsNothing);
    expect(find.text('panel'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.text('panel')));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('panel'), findsNothing);
    expect(find.text('panel', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(screen(true, reduced: true));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pumpWidget(screen(false, reduced: true));
    expect(find.text('panel'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
