import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';

void closeFirstDay(Game g) {
  expect(g.sell('sleep'), isNull);
  expect(g.sell('sleep'), isNull);
  expect(g.researchRequested, isTrue);
  expect(g.skipCustomer(), isTrue);
  expect(g.startNight(), isTrue);
}
void main() {
  test('Locked recipes, wrong orders and invalid research never spend resources', () {
    final g = Game();
    final before = g.encode();
    expect(g.sell('sight'), isNotNull);
    expect(g.brew('sight'), isNotNull);
    expect(g.research(['moon', 'salt', 'mushroom']), isNotNull);
    expect(g.nextDay(), isFalse);
    expect(g.startNight(), isFalse);
    expect(g.encode(), before);
    closeFirstDay(g);
    final night = g.encode();
    expect(g.research(['moon', 'moon', 'salt']), isNotNull);
    expect(g.research(['moon', 'salt']), isNotNull);
    expect(g.research(['unknown', 'fairy', 'tear']), isNotNull);
    expect(g.encode(), night);
  });
  test('All distinct guesses score the right ingredients and positions', () {
    const answer = ['moon', 'salt', 'mushroom'];
    // Preserve the original six-ingredient scoring regression as the catalog grows.
    const ids = ['web', 'tear', 'moon', 'salt', 'mushroom', 'petal'];
    var count = 0;
    for (final a in ids) {
      for (final b in ids.where((id) => id != a)) {
        for (final c in ids.where((id) => id != a && id != b)) {
          final guess = [a, b, c];
          final result = scoreRecipe(guess, answer);
          final exact = [0, 1, 2].where((i) => guess[i] == answer[i]).length;
          final present = guess.toSet().intersection(answer.toSet()).length;
          expect(result.strikes, exact); expect(result.balls, present - exact);
          count++;
        }
      }
    }
    expect(count, 120);
  });
  test('Free research preserves inventory; notes survive the next day', () {
    final g = Game(); closeFirstDay(g);
    expect(g.research(['salt', 'moon', 'mushroom']), isNull);
    expect(g.attempts.single.strikes, 1); expect(g.attempts.single.balls, 2);
    expect(g.materials['salt'], 6); expect(g.materials['web'], 6);
    expect(g.knows('sight'), isFalse); expect(g.stock['sight'], 0);
    expect(g.nextDay(), isTrue);
    final restored = Game.decode(g.encode());
    expect(restored.day, 2); expect(restored.attempts.single.guess, ['salt', 'moon', 'mushroom']);
    expect(restored.encode(), g.encode());
  });
  test('Three-day story from unmet demand to discovery, sales and supplier unlock', () {
    final g = Game(); closeFirstDay(g);
    expect(g.research(['moon', 'salt', 'mushroom']), isNull);
    expect(g.knows('sight'), isTrue); expect(g.stock['sight'], 1);
    final resolved = g.encode();
    expect(g.research(['moon', 'salt', 'mushroom']), isNotNull);
    expect(g.encode(), resolved);
    expect(g.brew('sight'), isNull); // Two bottles for tomorrow's customers.
    expect(g.upgrade(), isTrue); expect(g.level, 2); expect(g.investment, 90);
    expect(g.nextDay(), isTrue);
    expect(g.sell('sight'), isNull); expect(g.sell('sleep'), isNull); expect(g.sell('sight'), isNull);
    expect(g.startNight(), isTrue);
    expect(g.brew('sight'), isNull); expect(g.brew('sight'), isNull);
    expect(g.stock['sight'], 4);
    expect(g.deliver(), isFalse); // Not before day three.
    expect(g.buy('root'), isFalse);
    expect(g.nextDay(), isTrue);
    final gold = g.gold;
    expect(g.deliver(), isTrue); expect(g.stock['sight'], 1); expect(g.gold, gold + 120);
    expect(g.completed, isTrue); expect(g.buy('root'), isTrue); expect(g.materials['root'], 3);
    final finished = g.encode();
    expect(g.deliver(), isFalse); expect(g.nextDay(), isFalse);
    expect(g.encode(), finished);
    expect(Game.decode(finished).encode(), finished);
  });
  test('Production and buying share real inventory and never overdraw', () {
    final g = Game()..gold = 0;
    g.materials['web'] = 0;
    final before = g.encode();
    expect(g.brew('sleep'), isNotNull); expect(g.buy('web'), isFalse);
    expect(g.buy('unknown'), isFalse); expect(g.buy('web', quantity: -1), isFalse);
    expect(g.upgrade(), isFalse); expect(g.encode(), before);
    g.gold = 20;
    expect(g.buy('web'), isTrue); expect(g.gold, 14); expect(g.spending, 6);
    expect(g.brew('sleep'), isNull); expect(g.materials['web'], 2); expect(g.stock['sleep'], 4);
  });
  test('Supply aid and postponed deadline let an exhausted player recover', () {
    final g = Game();
    while (!g.serviceFinished) { g.skipCustomer(); }
    expect(g.startNight(), isTrue);
    g.gold = 0; g.stock['sleep'] = 0;
    g.materials.updateAll((key, value) => 0);
    expect(g.attempts, isEmpty);
    expect(g.requestAid(), isTrue); expect(g.requestAid(), isFalse);
    expect(g.stock['sleep'], 1);
    expect(g.research(['moon', 'salt', 'mushroom']), isNull);
    expect(g.nextDay(), isTrue);
    expect(g.sell('sight'), isNull); expect(g.sell('sleep'), isNull); expect(g.gold, 73);
    while (!g.serviceFinished) { g.skipCustomer(); }
    g.startNight(); g.nextDay();
    expect(g.deliver(), isFalse);
    while (!g.serviceFinished) { g.skipCustomer(); }
    g.startNight();
    expect(g.nextDay(), isTrue); expect(g.day, 4); // No game over for a missed deadline.
  });
  test('Corrupt or inconsistent saves are rejected', () {
    final saved = jsonDecode(Game().encode()) as Map<String, dynamic>;
    saved['materials']['moon'] = -1;
    expect(() => Game.decode(jsonEncode(saved)), throwsA(anything));
    saved['materials']['moon'] = 6; saved['phase'] = 'night';
    expect(() => Game.decode(jsonEncode(saved)), throwsA(anything));
    saved['phase'] = 'shop'; saved['supplierUnlocked'] = true;
    expect(() => Game.decode(jsonEncode(saved)), throwsA(anything));
  });
}
