import 'dart:collection';
import 'dart:math';

typedef Cell = ({int x, int y});
enum VisitPhase { entering, browsing, approaching, waiting, leaving, gone }
enum Facing { down, left, up, right }

/// Walkability is shared by the tile renderer and the customer simulation.
class ShopMap {
  static const width = 26, height = 14, tileSize = 24.0;
  static const door = (x: 20, y: 13), counter = (x: 10, y: 8);
  static const shelfStops = [(x: 8, y: 10), (x: 14, y: 10)];
  static final blocked = <Cell>{
    for (var x = 7; x <= 13; x++) (x: x, y: 7),
    for (var x = 4; x <= 6; x++) (x: x, y: 6),
    for (var x = 16; x <= 22; x++) (x: x, y: 6),
    for (var x = 10; x <= 13; x++) (x: x, y: 10),
    for (var x = 2; x <= 3; x++) (x: x, y: 10),
  };
  static bool walkable(Cell c) => c.x >= 3 && c.x <= 23 &&
      c.y >= 6 && c.y <= 13 && !blocked.contains(c);
  static List<Cell> route(Cell from, Cell to) {
    if (!walkable(from) || !walkable(to)) return [];
    final queue = Queue<Cell>()..add(from);
    final previous = <Cell, Cell?>{from: null};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == to) {
        final result = <Cell>[];
        Cell? cursor = to;
        while (cursor != null && cursor != from) {
          result.add(cursor); cursor = previous[cursor];
        }
        return result.reversed.toList();
      }
      for (final delta in [(x: 0, y: -1), (x: -1, y: 0), (x: 1, y: 0), (x: 0, y: 1)]) {
        final next = (x: current.x + delta.x, y: current.y + delta.y);
        if (walkable(next) && !previous.containsKey(next)) {
          previous[next] = current; queue.add(next);
        }
      }
    }
    return [];
  }
}

class CustomerVisit {
  final String id;
  final int appearance;
  double x = ShopMap.door.x.toDouble(), y = ShopMap.door.y.toDouble();
  Facing facing = Facing.up;
  VisitPhase phase = VisitPhase.entering;
  double pause = 0;
  final Queue<Cell> _path = Queue<Cell>();
  static const speed = 4.2;
  CustomerVisit(this.id, this.appearance) {
    _path.addAll(ShopMap.route(ShopMap.door, ShopMap.shelfStops[appearance % 2]));
  }
  bool get moving => _path.isNotEmpty;
  bool get ready => phase == VisitPhase.waiting;
  void arriveImmediately() {
    _path.clear(); x = ShopMap.counter.x.toDouble(); y = ShopMap.counter.y.toDouble();
    phase = VisitPhase.waiting; facing = Facing.up;
  }
  void leave() {
    if (phase == VisitPhase.leaving || phase == VisitPhase.gone) return;
    // Finish the current grid edge first, rather than cutting diagonally through furniture.
    final anchor = _path.isNotEmpty ? _path.first : (x: x.round(), y: y.round());
    _path.clear();
    if ((x - anchor.x).abs() + (y - anchor.y).abs() > .001) _path.add(anchor);
    _path.addAll(ShopMap.route(anchor, ShopMap.door));
    phase = VisitPhase.leaving;
  }
  void update(double seconds) {
    var remaining = max(0.0, seconds);
    while (remaining > .00001 && phase != VisitPhase.waiting && phase != VisitPhase.gone) {
      if (phase == VisitPhase.browsing) {
        final spent = min(remaining, pause); pause -= spent; remaining -= spent;
        if (pause <= .00001) {
          phase = VisitPhase.approaching;
          _path.addAll(ShopMap.route((x: x.round(), y: y.round()), ShopMap.counter));
        }
        continue;
      }
      if (_path.isEmpty) {
        if (phase == VisitPhase.entering) {
          phase = VisitPhase.browsing; pause = 1.4; facing = Facing.up;
        } else if (phase == VisitPhase.approaching) {
          phase = VisitPhase.waiting; facing = Facing.up;
        } else if (phase == VisitPhase.leaving) { phase = VisitPhase.gone; }
        continue;
      }
      final next = _path.first;
      final dx = next.x - x, dy = next.y - y;
      final distance = dx.abs() + dy.abs();
      facing = dx.abs() > .001 ? (dx > 0 ? Facing.right : Facing.left)
          : (dy > 0 ? Facing.down : Facing.up);
      final step = min(distance, remaining * speed);
      if (distance > 0) { x += dx / distance * step; y += dy / distance * step; }
      remaining -= step / speed;
      if (distance - step < .00001) { x = next.x.toDouble(); y = next.y.toDouble(); _path.removeFirst(); }
    }
  }
}

/// A new visitor waits outside until the previous visitor has left through the door.
class ShopTraffic {
  CustomerVisit? visitor;
  String? desiredId;
  int desiredAppearance = 1;
  void request(String? id, int appearance, {bool reducedMotion = false}) {
    desiredId = id; desiredAppearance = appearance;
    if (visitor?.id != id) visitor?.leave();
    if (reducedMotion) {
      visitor = id == null ? null : (CustomerVisit(id, appearance)..arriveImmediately());
    } else { _admit(); }
  }
  void _admit() {
    if (visitor?.phase == VisitPhase.gone) visitor = null;
    if (visitor == null && desiredId != null) visitor = CustomerVisit(desiredId!, desiredAppearance);
  }
  void update(double seconds) { visitor?.update(seconds); _admit(); }
  bool get ready => desiredId != null && visitor?.id == desiredId && visitor!.ready;
}
