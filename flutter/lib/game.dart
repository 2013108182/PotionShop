import 'dart:convert';

class Potion {
  final String id, name, description, ingredients;
  final int price, cost;
  const Potion(this.id, this.name, this.description, this.ingredients, this.price, this.cost);
}

const potions = [
  Potion('sleep', '깊은 밤의 숙면 물약', '달빛처럼 고요한 잠을 선물해요.', '밤의 거미줄 · 정령의 눈물 · 달빛 결정', 35, 11),
  Potion('sight', '올빼미의 시야 물약', '어두운 숲에서도 길을 잃지 않아요.', '달빛 결정 · 심해 소금 · 별빛 버섯', 38, 14),
  Potion('luck', '행운의 네잎클로버 물약', '작은 행운이 필요한 하루에.', '맨드레이크 · 요정 가루 · 정령의 눈물', 40, 12),
];

const orders = [
  ('약초 상인 로빈', '요즘 잠을 통 못 자겠어요.\n편안히 잠들 수 있는 약이 있을까요?', 'sleep'),
  ('숲길 안내인 로빈', '오늘 밤 숲길을 지나야 해요.\n횃불 없이도 앞을 보고 싶어요.', 'sight'),
  ('마을 농부 로빈', '이번에는 씨앗이 잘 자랐으면 좋겠어요.\n조금의 행운을 빌려줄 수 있나요?', 'luck'),
];

class Game {
  int day = 3, gold = 128, customer = 0, served = 0, revenue = 0, spending = 0, level = 1;
  Map<String, int> stock = {'sleep': 3, 'sight': 2, 'luck': 1};
  bool get closed => customer >= orders.length;
  int get upgradeCost => 90 * level;
  String? sell(String id) {
    if (closed) return '오늘 영업은 끝났어요.';
    if (id != orders[customer].$3) return '손님이 원하는 효능을 다시 살펴보세요.';
    if ((stock[id] ?? 0) == 0) return '재고가 없어요. 레시피북에서 생산해 주세요.';
    final potion = potions.firstWhere((p) => p.id == id);
    stock[id] = stock[id]! - 1;
    gold += potion.price;
    revenue += potion.price;
    served++;
    customer++;
    return null;
  }

  String? brew(String id) {
    final potion = potions.firstWhere((p) => p.id == id);
    final quantity = level;
    if (gold < potion.cost * quantity) return '재료를 살 골드가 부족해요.';
    gold -= potion.cost * quantity;
    spending += potion.cost * quantity;
    stock[id] = (stock[id] ?? 0) + quantity;
    return null;
  }

  bool upgrade() {
    if (level >= 3 || gold < upgradeCost) return false;
    gold -= upgradeCost;
    level++;
    return true;
  }

  bool nextDay() {
    if (!closed) return false;
    day++;
    customer = served = revenue = spending = 0;
    return true;
  }

  String encode() => jsonEncode({'day': day, 'gold': gold, 'customer': customer, 'served': served, 'revenue': revenue, 'spending': spending, 'level': level, 'stock': stock});
  static Game decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    int read(String key, int min, int max) {
      final value = data[key];
      if (value is! int || value < min || value > max) throw const FormatException('Invalid save');
      return value;
    }
    final game = Game()
      ..day = read('day', 1, 1000000)
      ..gold = read('gold', 0, 100000000)
      ..customer = read('customer', 0, orders.length)
      ..served = read('served', 0, orders.length)
      ..revenue = read('revenue', 0, 1000000)
      ..spending = read('spending', 0, 100000000)
      ..level = read('level', 1, 3);
    final stock = data['stock'] as Map<String, dynamic>;
    game.stock = {for (final p in potions) p.id: stock[p.id] as int};
    if (game.stock.values.any((v) => v < 0 || v > 1000000)) throw const FormatException('Invalid stock');
    return game;
  }
}
