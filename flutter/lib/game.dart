import 'dart:convert';

class Ingredient {
  final String id, name, lore;
  final int price;
  final bool rare;
  const Ingredient(this.id, this.name, this.lore, this.price, {this.rare = false});
}
const ingredients = [
  Ingredient('web', '밤의 거미줄', '고요하게 감싸고 움직임을 느리게 해요.', 2),
  Ingredient('tear', '정령의 눈물', '마음의 불안을 가라앉히는 물방울이에요.', 2),
  Ingredient('moon', '달빛 결정', '달빛을 머금은 돌. 감각을 예민하게 만들어요.', 2),
  Ingredient('salt', '심해 소금', '깊은 바다에서 얻은 소금. 흐릿한 감각을 맑게 해요.', 2),
  Ingredient('mushroom', '별빛 버섯', '어두운 숲에서 은은하게 빛나는 버섯이에요.', 2),
  Ingredient('petal', '황혼 꽃잎', '따뜻한 체온과 붉은 기운을 되찾아줘요.', 2),
  Ingredient('root', '맨드레이크', '잠든 씨앗의 생명력을 깨워요.', 5, rare: true),
  Ingredient('fairy', '요정 가루', '우연을 살짝 비틀어 작은 행운을 가져와요.', 5, rare: true),
];
String ingredientName(String id) => ingredients.firstWhere((i) => i.id == id).name;
class Potion {
  final String id, name, description;
  final List<String> recipe;
  final int price;
  const Potion(this.id, this.name, this.description, this.recipe, this.price);
  String get ingredientText => recipe.map(ingredientName).join(' → ');
}
const potions = [
  Potion('sleep', '깊은 밤의 숙면 물약', '달빛처럼 고요한 잠을 선물해요.', ['web', 'tear', 'moon'], 35),
  Potion('sight', '올빼미의 시야 물약', '어두운 숲에서도 길을 잃지 않아요.', ['moon', 'salt', 'mushroom'], 38),
];
typedef CustomerOrder = (String, String, String);
const firstDayOrders = <CustomerOrder>[
  ('약초 상인 로빈', '요즘 잠을 통 못 자겠어요.\n편안히 잠들 수 있는 약이 있을까요?', 'sleep'),
  ('제빵사 미나', '내일 새벽에 빵을 구워야 해요.\n오늘은 푹 자고 싶어요.', 'sleep'),
  ('숲길 안내인 엘리', '횃불 없이도 밤 숲길을 보고 싶어요.\n그런 물약이 생기면 내일 다시 올게요.', 'sight'),
];
const secondDayOrders = <CustomerOrder>[
  ('숲길 안내인 엘리', '어제 부탁드린 밤눈 물약, 찾으셨나요?\n덕분에 길을 잃는 사람이 줄어들 거예요.', 'sight'),
  ('약초 상인 로빈', '지난번 물약 덕분에 잘 잤어요!\n오늘도 숙면 물약 한 병 부탁해요.', 'sleep'),
  ('견습 우편배달부 준', '저도 밤 배달을 시작해요.\n엘리가 이 가게를 소개해 줬어요.', 'sight'),
];
const laterOrders = <CustomerOrder>[
  ('제빵사 미나', '요즘 손님이 많아 바빠요.\n숙면 물약을 한 병 더 주세요.', 'sleep'),
  ('숲길 안내인 엘리', '우리 길잡이 조합의 주문서가 도착했어요.\n제 물약은 따로 한 병 살게요!', 'sight'),
  ('약초 상인 로빈', '상점이 제법 북적이네요.\n오늘도 잘 부탁해요.', 'sleep'),
];
class ResearchAttempt {
  final List<String> guess;
  final int strikes, balls;
  ResearchAttempt(List<String> guess, this.strikes, this.balls) : guess = List.unmodifiable(guess);
  Map<String, dynamic> toJson() => {'guess': guess, 'strikes': strikes, 'balls': balls};
}
// Distinct ingredients are the digits; their order is the mixing order.
ResearchAttempt scoreRecipe(List<String> guess, List<String> answer) {
  final strikes = List.generate(answer.length, (i) => guess[i] == answer[i]).where((v) => v).length;
  return ResearchAttempt(guess, strikes, guess.where(answer.contains).length - strikes);
}
class Game {
  int day = 1, gold = 128, customer = 0, served = 0, revenue = 0, spending = 0, investment = 0, level = 1;
  String phase = 'shop';
  bool researchRequested = false, supplierUnlocked = false;
  Set<String> discovered = {'sleep'};
  Map<String, int> stock = {'sleep': 3, 'sight': 0};
  Map<String, int> materials = {for (final i in ingredients) i.id: i.rare ? 0 : 6};
  List<ResearchAttempt> attempts = [];
  String? researchNotebook;
  Set<int> aidDays = {};
  List<CustomerOrder> get orders => day == 1 ? firstDayOrders : day == 2 ? secondDayOrders : laterOrders;
  bool get night => phase == 'night';
  bool get serviceFinished => customer >= orders.length;
  bool get closed => night || serviceFinished;
  bool get completed => supplierUnlocked;
  int get upgradeCost => 90 * level;
  String get objective => completed ? '특별 주문 완료 · 희귀 재료 상인과 거래가 열렸어요!'
      : day >= 3 ? '길잡이 조합에 시야 물약 3병 납품하기'
      : knows('sight') ? (!night && !serviceFinished
          ? '${orders[customer].$1}에게 ${potions.firstWhere((p) => p.id == orders[customer].$3).name} 건네기'
          : '내일 팔 물약을 생산하고 다음 영업 준비하기')
      : researchRequested ? '밤 연구실에서 어둠을 밝힐 물약 발견하기'
      : '숙면 물약을 팔고 마을 사람들의 이야기를 듣기';
  bool knows(String id) => discovered.contains(id);
  bool canBrew(Potion p) => knows(p.id) && p.recipe.every((id) => materials[id]! >= level);
  void _advance() {
    customer++;
    if (!serviceFinished && orders[customer].$3 == 'sight') researchRequested = true;
  }
  String? sell(String id) {
    if (closed || completed) return '지금은 손님에게 판매할 수 없어요.';
    if (!knows(id)) return '아직 발견하지 못한 레시피예요. 밤에 연구해 주세요.';
    if (id != orders[customer].$3) return '손님이 원하는 효능을 다시 살펴보세요.';
    if ((stock[id] ?? 0) == 0) return '재고가 없어요. 레시피북에서 생산해 주세요.';
    final potion = potions.firstWhere((p) => p.id == id);
    stock[id] = stock[id]! - 1;
    gold += potion.price; revenue += potion.price; served++;
    _advance();
    return null;
  }
  bool skipCustomer() {
    if (closed || completed) return false;
    if (orders[customer].$3 == 'sight') researchRequested = true;
    _advance(); return true;
  }
  String? brew(String id) {
    final matches = potions.where((p) => p.id == id);
    if (matches.isEmpty || !knows(id)) return '레시피를 먼저 발견해 주세요.';
    final p = matches.single;
    if (!canBrew(p)) return '재료가 부족해요. 재료 상인에게 구입해 주세요.';
    for (final material in p.recipe) { materials[material] = materials[material]! - level; }
    stock[id] = stock[id]! + level;
    return null;
  }
  bool buy(String id, {int quantity = 3}) {
    final matches = ingredients.where((i) => i.id == id);
    if (quantity <= 0 || quantity > 100 || matches.isEmpty) return false;
    final i = matches.single;
    if ((i.rare && !supplierUnlocked) || gold < i.price * quantity) return false;
    gold -= i.price * quantity; spending += i.price * quantity;
    materials[id] = materials[id]! + quantity; return true;
  }
  bool upgrade() {
    if (level >= 3 || gold < upgradeCost || completed) return false;
    investment += upgradeCost; gold -= upgradeCost; level++; return true;
  }
  bool startNight() {
    if (night || !serviceFinished || completed) return false;
    phase = 'night'; return true;
  }
  String? research(List<String> guess) {
    if (!night || completed || !researchRequested || knows('sight')) return '지금은 진행할 연구가 없어요.';
    final ids = ingredients.where((i) => !i.rare).map((i) => i.id).toSet();
    if (guess.length != 3 || guess.toSet().length != 3 || !guess.every(ids.contains)) return '서로 다른 재료 세 가지를 순서대로 골라 주세요.';
    final result = scoreRecipe(guess, potions[1].recipe);
    attempts.add(result);
    if (result.strikes == 3) { discovered.add('sight'); stock['sight'] = stock['sight']! + 1; }
    return null;
  }
  bool requestAid() {
    if (!night || aidDays.contains(day) || gold >= 18 || completed) return false;
    for (final i in ingredients.where((i) => !i.rare)) { materials[i.id] = materials[i.id]! + 1; }
    stock['sleep'] = stock['sleep']! + 1; aidDays.add(day); return true;
  }
  bool deliver() {
    if (day < 3 || !knows('sight') || stock['sight']! < 3 || completed) return false;
    stock['sight'] = stock['sight']! - 3; gold += 120; revenue += 120;
    supplierUnlocked = true; return true;
  }
  bool nextDay() {
    if (!night || completed) return false;
    day++; phase = 'shop'; customer = served = revenue = spending = investment = 0; return true;
  }
  String encode() => jsonEncode({'version': 2, 'day': day, 'gold': gold, 'customer': customer,
    'served': served, 'revenue': revenue, 'spending': spending, 'investment': investment, 'level': level, 'phase': phase,
    'stock': stock, 'materials': materials, 'discovered': discovered.toList(),
    'researchRequested': researchRequested, 'supplierUnlocked': supplierUnlocked,
    'attempts': attempts.map((a) => a.toJson()).toList(), 'aidDays': aidDays.toList(), 'researchNotebook': researchNotebook});
  static Game decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 2) throw const FormatException('Unsupported save');
    int read(String key, int min, int max) {
      final v = data[key];
      if (v is! int || v < min || v > max) throw const FormatException('Invalid save');
      return v;
    }
    final g = Game()
      ..day = read('day', 1, 1000000)..gold = read('gold', 0, 100000000)
      ..customer = read('customer', 0, 3)..served = read('served', 0, 3)
      ..revenue = read('revenue', 0, 1000000)..spending = read('spending', 0, 100000000)
      ..investment = read('investment', 0, 100000000)..level = read('level', 1, 3);
    Map<String, int> inventory(String key, Iterable<String> ids) {
      final m = data[key] as Map<String, dynamic>;
      return {for (final id in ids) id: (() {
        final v = m[id];
        if (v is! int || v < 0 || v > 1000000) throw const FormatException('Invalid inventory');
        return v;
      })()};
    }
    g.phase = data['phase'] as String;
    g.researchNotebook = data['researchNotebook'] as String?;
    g.researchRequested = data['researchRequested'] as bool;
    g.supplierUnlocked = data['supplierUnlocked'] as bool;
    g.discovered = (data['discovered'] as List).cast<String>().toSet();
    if (!{'shop', 'night'}.contains(g.phase) || (g.night && !g.serviceFinished) ||
        !g.discovered.contains('sleep') || !g.discovered.every((id) => potions.any((p) => p.id == id)) ||
        g.served > g.customer || (g.completed && (g.day < 3 || !g.knows('sight')))) {
      throw const FormatException('Invalid progress');
    }
    g.stock = inventory('stock', potions.map((p) => p.id));
    g.materials = inventory('materials', ingredients.map((i) => i.id));
    for (final raw in data['attempts'] as List) {
      final guess = (raw['guess'] as List).cast<String>();
      if (guess.length != 3 || guess.toSet().length != 3 ||
          !guess.every((id) => ingredients.any((i) => !i.rare && i.id == id))) throw const FormatException('Invalid guess');
      final a = scoreRecipe(guess, potions[1].recipe);
      if (a.strikes != raw['strikes'] || a.balls != raw['balls']) throw const FormatException('Invalid result');
      g.attempts.add(a);
    }
    g.aidDays = (data['aidDays'] as List).cast<int>().toSet();
    if (g.aidDays.any((day) => day < 1 || day > g.day)) throw const FormatException('Invalid aid');
    return g;
  }
}
