import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/shop_motion.dart';

void main() {
  test('All visitor routes avoid solid furniture and move one grid edge at a time', () {
    for (final shelf in ShopMap.shelfStops) {
      for (final trip in [(ShopMap.door, shelf), (shelf, ShopMap.counter), (ShopMap.counter, ShopMap.door)]) {
        final route = ShopMap.route(trip.$1, trip.$2);
        expect(route, isNotEmpty); expect(route.last, trip.$2);
        var previous = trip.$1;
        for (final cell in route) {
          expect(ShopMap.walkable(cell), isTrue);
          expect((previous.x - cell.x).abs() + (previous.y - cell.y).abs(), 1);
          previous = cell;
        }
      }
    }
    expect(ShopMap.route(ShopMap.door, (x: 9, y: 7)), isEmpty);
  });
  test('Customer browses before ordering and physically leaves through the door', () {
    final visitor = CustomerVisit('robin', 1);
    final phases = <VisitPhase>{};
    for (var i = 0; i < 200; i++) {
      visitor.update(.1); phases.add(visitor.phase);
      expect(ShopMap.blocked.contains((x: visitor.x.round(), y: visitor.y.round())), isFalse);
    }
    expect(phases, containsAll([VisitPhase.entering, VisitPhase.browsing, VisitPhase.approaching, VisitPhase.waiting]));
    expect(visitor.ready, isTrue); expect(visitor.facing, Facing.up);
    visitor.leave(); expect(visitor.ready, isFalse);
    visitor.update(10);
    expect(visitor.phase, VisitPhase.gone);
    expect(visitor.x, ShopMap.door.x); expect(visitor.y, ShopMap.door.y);
  });
  test('New customer waits for the previous customer to leave', () {
    final traffic = ShopTraffic()..request('robin', 1);
    traffic.update(20); expect(traffic.ready, isTrue);
    traffic.request('mina', 2);
    expect(traffic.visitor!.id, 'robin'); expect(traffic.ready, isFalse);
    traffic.update(10);
    expect(traffic.visitor!.id, 'mina'); expect(traffic.visitor!.phase, VisitPhase.entering);
    traffic.update(20); expect(traffic.ready, isTrue);
    traffic.request(null, 1); traffic.update(10);
    expect(traffic.visitor, isNull); expect(traffic.ready, isFalse);
  });
  test('Changing a visitor while walking does not create diagonal movement', () {
    final traffic = ShopTraffic()..request('robin', 1);
    traffic.update(.17);
    traffic.request('ellie', 3);
    for (var i = 0; i < 300; i++) {
      final actor = traffic.visitor!;
      final x = actor.x, y = actor.y;
      traffic.update(.01);
      if (identical(actor, traffic.visitor)) {
        expect((actor.x - actor.x.round()).abs() < .00001 ||
            (actor.y - actor.y.round()).abs() < .00001, isTrue);
        expect((actor.x - x).abs() + (actor.y - y).abs(), lessThanOrEqualTo(CustomerVisit.speed * .01 + .00001));
      }
    }
  });
  test('Reduced motion preserves serving state without animation', () {
    final traffic = ShopTraffic()..request('ellie', 3, reducedMotion: true);
    expect(traffic.ready, isTrue);
    traffic.request(null, 1, reducedMotion: true);
    expect(traffic.visitor, isNull);
  });
}


