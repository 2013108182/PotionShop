import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/game.dart';

void finishDay(Game g) {
  while (!g.serviceFinished) { g.skipCustomer(); }
  expect(g.startNight(), isTrue);
}

VisitPlan storyVisit(String resident, int index, int day) {
  final r = residentById(resident), beat = r.story[index];
  return VisitPlan(visitId: '$day:0:$resident', day: day, residentId: resident,
    name: r.name, text: beat.request, potionId: beat.potionId, storyBeatId: beat.id);
}

void putStory(Game g, String resident, int index, int day, {bool review = false}) {
  g.day = day; g.customer = 0; g.phase = 'shop'; g.served = 0;
  g.lostSales = 0; g.missedOrders.clear(); g.researchPendingOrders = 0;
  final v = storyVisit(resident, index, day);
  g.visitQueue = [VisitPlan(visitId: v.visitId, day: day, residentId: resident,
    name: v.name, text: v.text, potionId: review ? null : v.potionId, storyBeatId: v.storyBeatId),
    VisitPlan(visitId: '$day:1:mina', day: day, residentId: 'mina', name: '미나', text: '숙면 한 병', potionId: 'sleep'),
    VisitPlan(visitId: '$day:2:ellie', day: day, residentId: 'ellie', name: '엘리', text: '시야 한 병', potionId: 'sight')];
}

void main() {
  test('Research discovery is per recipe and never duplicates its sample bottle', () {
    final g = Game(); finishDay(g);
    expect(g.requestResearch('hush'), isTrue);
    expect(g.canResearchPotion('hush'), isTrue);
    expect(g.isIngredientUnlocked('reed'), isTrue);
    final money = g.gold, materials = Map<String, int>.from(g.materials);
    expect(g.research(potionById('hush').recipe, potionId: 'hush'), isNull);
    expect(g.stock['hush'], 1);
    expect(g.discoverRecipe('hush'), isFalse);
    expect(g.gold, money); expect(g.materials, materials);
    expect(g.pendingResearchIds, isNot(contains('hush')));
    expect(g.research(potionById('hush').recipe, potionId: 'hush'), isNotNull);
    expect(g.stock['hush'], 1);
  });

  test('Promised Robin gift is one-time, persisted and independent of today purchase', () {
    var g = Game();
    expect(g.sell('sleep'), isNull);
    expect(g.claimedEvents, contains('robin:promise'));
    finishDay(g); g.nextDay();
    g.skipCustomer(); // Ellie, Robin now arrives.
    final web = g.materials['web']!, tears = g.materials['tear']!;
    expect(g.recordArrival(), contains('로빈의 선물'));
    expect(g.materials['web'], web + 1); expect(g.materials['tear'], tears + 1);
    expect(g.recordArrival(), isNull);
    g = Game.decode(g.encode());
    expect(g.recordArrival(), isNull);
    expect(g.skipCustomer(), isTrue);
    expect(g.materials['web'], web + 1);
    expect(g.diary.where((e) => e.id == 'robin:gift'), hasLength(1));
    expect(g.residents['robin']!.fulfilledPromiseIds, contains('robin:materials'));
  });

  test('Income sources and final lost-demand reasons stay distinct', () {
    final g = Game()..day = 3;
    g.discovered.add('sight'); g.stock['sight'] = 4;
    expect(g.sell('sleep'), isNull); expect(g.sell('sight'), isNull); expect(g.sell('sleep'), isNull);
    expect(g.deliver(), isTrue);
    expect(g.salesRevenue, 108); expect(g.guildRewards, 120); expect(g.revenue, 228);
    expect(g.deliver(), isFalse);
    expect(Game.decode(g.encode()).guildRewards, 120);

    final missed = Game()..discovered.add('sight'); missed.stock['sight'] = 2;
    expect(missed.sell('sight'), isNotNull); expect(missed.lostSales, 0);
    expect(missed.sell('sight'), isNotNull); expect(missed.missedOrders['wrongPotion'], 1);
    missed.stock['sleep'] = 0;
    expect(missed.sell('sleep'), isNotNull); expect(missed.lostSales, 1);
    missed.skipCustomer(); expect(missed.missedOrders['outOfStock'], 1);
    missed.skipCustomer(); expect(missed.missedOrders['declined'], 1);
    expect(Game.decode(missed.encode()).lostSales, 3);
  });

  test('Frozen night plan survives unlocks and reload without rerolling visits', () {
    final g = Game()..day = 3;
    g.discovered.add('sight'); g.stock['sight'] = 3;
    finishDay(g);
    final ids = g.ensureNextDayPlan().map((v) => v.visitId).toList();
    expect(g.deliver(), isTrue); // New residents wait until a later plan.
    expect(g.ensureNextDayPlan().map((v) => v.visitId).toList(), ids);
    final restored = Game.decode(g.encode()); restored.nextDay();
    expect(restored.visitQueue!.map((v) => v.visitId).toList(), ids);
    expect(restored.guildRewards, 0); expect(restored.salesRevenue, 0);
  });

  test('Story delivery, later feedback and stale commands cannot duplicate outcomes', () {
    var g = Game(); putStory(g, 'nari', 0, 4);
    final visit = g.currentVisitId!;
    g.recordArrival();
    expect(g.pendingResearchIds, contains('hush'));
    expect(g.resolveStory(), isNotNull); expect(g.customer, 0);
    g.discoverRecipe('hush');
    final money = g.gold;
    expect(g.resolveStory(visitId: visit), isNull);
    expect(g.gold, money + potionById('hush').price); expect(g.stock['hush'], 0);
    expect(g.residents['nari']!.pendingReview, 'nari.hush');
    expect(g.resolveStory(visitId: visit), isNotNull);
    g = Game.decode(g.encode());
    putStory(g, 'nari', 0, 5, review: true);
    expect(g.currentStoryNeedsReview, isTrue);
    expect(g.resolveStory(), isNull);
    expect(g.residents['nari']!.storyIndex, 1);
    expect(g.diary.where((e) => e.id == 'completed:nari.hush'), hasLength(1));
    expect(g.gold, money + potionById('hush').price);
  });

  test('No-scent alternative advances equally without inventory, cash or repeat farming', () {
    final g = Game(); putStory(g, 'nari', 2, 5);
    g.residents['nari']!.storyIndex = 2;
    final gold = g.gold;
    final stock = Map<String, int>.from(g.stock);
    final visit = g.currentVisitId!;
    expect(g.resolveStory(chooseAlternative: true, visitId: visit), isNull);
    expect(g.residents['nari']!.storyIndex, 3);
    expect(g.gold, gold); expect(g.stock, stock);
    expect(g.claimedEvents, contains('alternative:nari.invitation'));
    expect(g.resolveStory(chooseAlternative: true, visitId: visit), isNotNull);
    putStory(g, 'nari', 3, 6);
    expect(g.resolveStory(), isNull);
    expect(g.residents['nari']!.trustStage, 2);
    expect(g.residents['nari']!.storyIndex, 4);
  });
}
