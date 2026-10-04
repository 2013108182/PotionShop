import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';

void main() {
  test('Wrong potion never consumes stock or rewards money', () {
    final g = Game();
    expect(g.sell('sight'), isNotNull);
    expect(g.gold, 128); expect(g.stock['sight'], 2); expect(g.customer, 0);
  });
  test('Sale, production, upgrade and restore preserve economy', () {
    final g = Game();
    expect(g.sell('sleep'), isNull); expect(g.gold, 163); expect(g.stock['sleep'], 2);
    expect(g.upgrade(), isTrue); expect(g.gold, 73); expect(g.level, 2);
    expect(g.brew('sleep'), isNull); expect(g.gold, 51); expect(g.stock['sleep'], 4);
    final restored = Game.decode(g.encode());
    expect(restored.encode(), g.encode());
  });
  test('Insufficient funds and missing stock never mutate economy', () {
    final g = Game()..gold = 0;
    expect(g.brew('sleep'), isNotNull); expect(g.upgrade(), isFalse);
    g.stock['sleep'] = 0;
    expect(g.sell('sleep'), isNotNull); expect(g.gold, 0); expect(g.customer, 0);
  });
  test('Day advance requires closing and preserves inventory', () {
    final g = Game();
    expect(g.nextDay(), isFalse);
    for (final order in orders) { expect(g.sell(order.$3), isNull); }
    expect(g.closed, isTrue); expect(g.sell('luck'), isNotNull);
    final stock = Map<String, int>.from(g.stock);
    expect(g.nextDay(), isTrue); expect(g.day, 4); expect(g.revenue, 0); expect(g.stock, stock);
  });
}
