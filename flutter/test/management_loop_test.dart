import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';

void main() {
  test('Preparation buys only shortages and changes inventory atomically', () {
    final g = Game()..gold = 20;
    g.materials['web'] = 0; g.materials['tear'] = 1;
    expect(g.prepareCost(potions.first, 3), 10);
    expect(g.prepare('sleep', 3), isNull);
    expect(g.gold, 10); expect(g.spending, 10); expect(g.stock['sleep'], 6);
    expect(g.materials['web'], 0); expect(g.materials['tear'], 0); expect(g.materials['moon'], 3);
    final before = g.encode();
    expect(g.prepare('sleep', 30), isNotNull);
    expect(g.prepare('sleep', 0), isNotNull);
    expect(g.prepare('unknown', 1), isNotNull);
    expect(g.encode(), before);
  });
  test('Upgraded cauldron actually saves materials and reports whole batches', () {
    final g = Game()..level = 2;
    expect(g.prepare('sleep', 3), isNull);
    expect(g.stock['sleep'], 7); // Two sets, four bottles.
    expect(g.materials['web'], 4);
    expect(g.gold, 128);
    g.level = 3;
    expect(g.brew('sleep'), isNull);
    expect(g.stock['sleep'], 10); expect(g.materials['web'], 3);
  });
  test('Wrong potion gets one explanation, then loses the customer without revenue', () {
    var g = Game()..discovered.add('sight'); g.stock['sight'] = 2;
    expect(g.sell('sight'), contains('숙면'));
    expect(g.customer, 0); expect(g.gold, 128); expect(g.stock['sight'], 2);
    g = Game.decode(g.encode());
    expect(g.wrongOffers, 1);
    expect(g.sell('sight'), contains('다른 가게'));
    expect(g.customer, 1); expect(g.lostSales, 1); expect(g.wrongOffers, 0);
    expect(g.revenue, 0); expect(g.stock['sight'], 2);
    expect(g.sell('sleep'), isNull); expect(g.served, 1);
  });
  test('Guild delivery unlocks trade without ending ongoing business', () {
    final g = Game()..day = 3..discovered.add('sight'); g.stock['sight'] = 4;
    expect(g.deliver(), isTrue); expect(g.stock['sight'], 1);
    expect(g.sell('sleep'), isNull); expect(g.sell('sight'), isNull); expect(g.sell('sleep'), isNull);
    expect(g.startNight(), isTrue); expect(g.nextDay(), isTrue);
    expect(g.day, 4); expect(g.completed, isTrue); expect(g.deliver(), isFalse);
    expect(Game.decode(g.encode()).day, 4);
  });
  test('Previous saves retain inventory and default new service counters', () {
    final raw = jsonDecode(Game().encode()) as Map<String, dynamic>;
    raw.remove('wrongOffers'); raw.remove('lostSales');
    final g = Game.decode(jsonEncode(raw));
    expect(g.gold, 128); expect(g.wrongOffers, 0); expect(g.lostSales, 0);
  });
}
