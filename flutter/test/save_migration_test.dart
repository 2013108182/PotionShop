import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';

// Frozen pre-expansion save: two potions, eight ingredients, mixed revenue.
const legacySave = '''{
 "version":2,"day":3,"gold":432,"customer":3,"served":3,
 "wrongOffers":0,"lostSales":0,"revenue":228,"spending":12,
 "investment":90,"level":2,"phase":"night",
 "stock":{"sleep":1,"sight":0},
 "materials":{"web":2,"tear":2,"moon":3,"salt":2,"mushroom":2,"petal":6,"root":0,"fairy":0},
 "discovered":["sleep","sight"],"researchRequested":true,"supplierUnlocked":true,
 "attempts":[{"guess":["moon","salt","mushroom"],"strikes":3,"balls":0}],
 "aidDays":[],"researchNotebook":null
}''';

void main() {
  test('Real v2 save migrates without inventing gifts, sales attribution or research rewards', () {
    final g = Game.decode(legacySave);
    expect(g.gold, 432); expect(g.day, 3); expect(g.customer, 3);
    expect(g.stock['sleep'], 1); expect(g.stock['sight'], 0);
    expect(g.stock['sprout'], 0); expect(g.materials['resin'], 0);
    expect(g.materials['moon'], 3); expect(g.level, 2);
    expect(g.revenue, 228); expect(g.unclassifiedRevenue, 228);
    expect(g.salesRevenue, 0); expect(g.guildRewards, 0);
    expect(g.tutorialProgress!['status'], 'legacySatisfied');
    expect(g.claimedEvents, contains('guild:first'));
    expect(g.claimedEvents, isNot(contains('robin:gift')));
    expect(g.claimedEvents, isNot(contains('robin:promise')));
    expect(g.residents.values.every((p) => p.successfulServices.isEmpty), isTrue);
    expect(g.discoverRecipe('sight'), isFalse);
    expect(g.deliver(), isFalse);
    expect(Game.decode(g.encode()).encode(), g.encode());
  });

  test('Mid-service v2 cursor survives and new villagers remain reachable', () {
    final raw = jsonDecode(legacySave) as Map<String, dynamic>;
    raw['phase'] = 'shop'; raw['customer'] = 1; raw['served'] = 1;
    final g = Game.decode(jsonEncode(raw));
    expect(g.currentResidentId, 'ellie');
    expect(g.currentVisitId, '3:1:ellie');
    expect(g.isResidentAvailable('sage'), isTrue);
    expect(g.isResidentAvailable('luna'), isTrue);
    expect(g.isResidentAvailable('nari'), isTrue);
    while (!g.serviceFinished) { g.skipCustomer(); }
    expect(g.startNight(), isTrue);
    final forecast = g.ensureNextDayPlan().map((v) => v.toJson()).toList();
    final restored = Game.decode(g.encode());
    expect(restored.nextDay(), isTrue);
    expect(restored.visitQueue!.map((v) => v.toJson()).toList(), forecast);
    expect(restored.tutorialProgress!['status'], 'legacySatisfied');
  });

  test('Expanded v3 experiments round trip while v2 keeps its six candidate validation', () {
    final g = Game()..customer = 3..phase = 'night'..researchRequested = true;
    final before = Map<String, int>.from(g.materials);
    expect(g.research(['fairy', 'root', 'resin']), isNull);
    expect(g.materials, before);
    expect(Game.decode(g.encode()).attempts.single.guess, ['fairy', 'root', 'resin']);
    final old = jsonDecode(legacySave) as Map<String, dynamic>;
    old['attempts'] = [{'guess': ['fairy', 'root', 'resin'], 'strikes': 0, 'balls': 0}];
    expect(() => Game.decode(jsonEncode(old)), throwsFormatException);
  });

  test('New target notebooks and tutorial payload survive v3 exactly', () {
    final g = Game();
    g.requestResearch('warmth');
    const notebook = '{"version":2,"potionId":"warmth","slots":[null,null,null]}';
    g.setNotebook('warmth', notebook);
    g.tutorialProgress = {'version': 1, 'status': 'inProgress', 'step': 3};
    final restored = Game.decode(g.encode());
    expect(restored.notebookFor('warmth'), notebook);
    expect(restored.pendingResearchIds, contains('warmth'));
    expect(restored.tutorialProgress, g.tutorialProgress);
    expect(restored.encode(), g.encode());
  });

  test('Malformed/future snapshots are rejected without changing their source string', () {
    final original = Game().encode();
    final raw = jsonDecode(original) as Map<String, dynamic>;
    raw['version'] = 99;
    expect(() => Game.decode(jsonEncode(raw)), throwsFormatException);
    raw['version'] = 3; raw['stock']['sleep'] = -1;
    expect(() => Game.decode(jsonEncode(raw)), throwsFormatException);
    raw['stock']['sleep'] = 3; raw['salesRevenue'] = 900;
    expect(() => Game.decode(jsonEncode(raw)), throwsFormatException);
    expect(Game.decode(original).gold, 128);
  });
}
