import 'dart:convert';
import 'catalog.dart';
import 'resident_catalog.dart' as story;
import 'resident_progress.dart';
export 'catalog.dart';
export 'resident_catalog.dart';
export 'resident_progress.dart';

typedef CustomerOrder = (String, String, String);
const firstDayOrders = <CustomerOrder>[
  ('약초 상인 로빈', '요즘 잠을 통 못 자겠어요.\n편안히 잠들 수 있는 약이 있을까요?', 'sleep'),
  ('제빵사 미나', '내일 새벽에 빵을 구워야 해요.\n오늘은 푹 자고 싶어요.', 'sleep'),
  ('숲길 안내인 엘리', '횃불 없이도 밤 숲길을 보고 싶어요.\n그런 물약이 생기면 내일 다시 올게요.', 'sight'),
];
const secondDayOrders = <CustomerOrder>[
  ('숲길 안내인 엘리', '어제 부탁드린 밤눈 물약, 찾으셨나요?\n덕분에 길을 잃는 사람이 줄어들 거예요.', 'sight'),
  ('약초 상인 로빈', '지난번 물약 덕분에 잘 잤어요!\n오늘도 숙면 물약 한 병 부탁해요.', 'sleep'),
  ('견습 우편배달부 준', '밤 배달을 시작했는데 길이 너무 어두워요.\n어둠 속을 볼 수 있는 약 한 병 주세요.', 'sight'),
];
const laterOrders = <CustomerOrder>[
  ('제빵사 미나', '요즘 손님이 많아 바빠요.\n숙면 물약을 한 병 더 주세요.', 'sleep'),
  ('숲길 안내인 엘리', '길잡이 조합의 대량 주문도 확인해 주세요.\n저는 밤길을 밝힐 시야 물약 한 병을 따로 살게요!', 'sight'),
  ('약초 상인 로빈', '상점이 제법 북적이네요.\n요즘 잠을 설쳐서, 숙면 물약 한 병 부탁해요.', 'sleep'),
];
class ResearchAttempt {
  final List<String> guess;
  final int strikes, balls;
  ResearchAttempt(List<String> guess, this.strikes, this.balls) : guess = List.unmodifiable(guess);
  Map<String, dynamic> toJson() => {'guess': guess, 'strikes': strikes, 'balls': balls};
}
// Distinct ingredients are the digits; their order is the mixing order.
ResearchAttempt scoreRecipe(List<String> guess, List<String> answer) {
  if (guess.length != answer.length) throw const FormatException('Invalid recipe length');
  final strikes = List.generate(answer.length, (i) => guess[i] == answer[i]).where((v) => v).length;
  return ResearchAttempt(guess, strikes, guess.where(answer.contains).length - strikes);
}
class Game {
  int day = 1, gold = 128, customer = 0, served = 0, revenue = 0,
      spending = 0, investment = 0, level = 1;
  int salesRevenue = 0, guildRewards = 0, unclassifiedRevenue = 0;
  int wrongOffers = 0, lostSales = 0, researchPendingOrders = 0;
  final Map<String, int> missedOrders = {}, receivedMaterials = {};
  String phase = 'shop';
  bool researchRequested = false, supplierUnlocked = false;
  Set<String> discovered = {'sleep'};
  Map<String, int> stock = {for (final p in potions) p.id: p.id == 'sleep' ? 3 : 0};
  Map<String, int> materials = {
    for (final i in ingredients) i.id: i.rare || i.expansion ? 0 : 6};
  List<ResearchAttempt> attempts = [];
  String? researchNotebook;
  final Map<String, String> researchNotebooks = {};
  final Set<String> requestedResearch = {}, unlockedIngredients = {};
  Set<int> aidDays = {};
  Map<String, dynamic>? tutorialProgress;
  final Map<String, ResidentProgress> residents = {
    for (final r in story.residents) r.id: ResidentProgress()};
  final List<DiaryEntry> diary = [];
  final Set<String> claimedEvents = {}, arrivedVisits = {};
  List<VisitPlan>? visitQueue, nextDayPlan;
  String? lastServiceReaction;

  List<CustomerOrder> _legacyOrders(int forDay) => forDay == 1 ? firstDayOrders
      : forDay == 2 ? [secondDayOrders[0],
        (residents['robin']!.successfulServices['sleep'] ?? 0) > 0 ? secondDayOrders[1]
          : ('약초 상인 로빈', '새벽에 약초를 돌보려면 푹 쉬고 싶어요.\n오늘은 숙면 물약 한 병을 살 수 있을까요?', 'sleep'),
        secondDayOrders[2]] : !completed ? laterOrders
      : [laterOrders[0], ('숲길 안내인 엘리', '조합에 보내 주신 물약, 잘 받았어요!\n저도 밤길을 밝힐 시야 물약 한 병을 살게요.', 'sight'), laterOrders[2]];
  List<CustomerOrder> get orders {
    final queue = visitQueue;
    if (queue == null || queue.isEmpty || queue.first.day != day) return _legacyOrders(day);
    return queue.map((v) => (v.name, v.text, v.potionId ?? '')).toList();
  }
  bool get night => phase == 'night';
  bool get serviceFinished => customer >= orders.length;
  bool get closed => night || serviceFinished;
  bool get completed => supplierUnlocked;
  int get upgradeCost => 90 * level;
  String get objective {
    if (pendingResearchIds.isNotEmpty) return '밤에 ${potionById(pendingResearchIds.first).name} 연구하기';
    if (day >= 3 && !completed) return '길잡이 조합에 시야 물약 3병 납품하기';
    if (currentStory != null) return '${currentStory!.title} · 이웃의 이야기 이어가기';
    if (completed) return '이웃의 부탁과 희귀 재료의 새 쓰임을 살펴보세요';
    return knows('sight') ? '내일 팔 물약을 생산하고 다음 영업 준비하기' : '숙면 물약을 팔고 마을 사람들의 이야기를 듣기';
  }
  bool knows(String id) => discovered.contains(id);
  List<String> get pendingResearchIds => potions.where((p) => !knows(p.id) &&
      (requestedResearch.contains(p.id) || (p.id == 'sight' && researchRequested))).map((p) => p.id).toList();
  bool canResearchPotion(String id) => night && pendingResearchIds.contains(id);
  bool requestResearch(String id) {
    final p = potions.where((p) => p.id == id).firstOrNull;
    if (p == null || knows(id)) return false;
    if (id == 'sight') researchRequested = true;
    final changed = requestedResearch.add(id);
    for (final ingredient in p.recipe) {
      if (!ingredients.firstWhere((i) => i.id == ingredient).rare) unlockedIngredients.add(ingredient);
    }
    return changed;
  }
  String? notebookFor(String id) => id == 'sight' ? researchNotebook ?? researchNotebooks[id] : researchNotebooks[id];
  void setNotebook(String id, String encoded) {
    if (!potions.any((p) => p.id == id)) throw ArgumentError.value(id, 'id');
    researchNotebooks[id] = encoded;
    if (id == 'sight') researchNotebook = encoded;
  }
  bool discoverRecipe(String id) {
    if (!potions.any((p) => p.id == id) || knows(id)) return false;
    discovered.add(id);
    stock[id] = (stock[id] ?? 0) + 1;
    claimedEvents.add('discovery:$id');
    for (final ingredient in potionById(id).recipe) {
      if (!ingredients.firstWhere((i) => i.id == ingredient).rare) unlockedIngredients.add(ingredient);
    }
    return true;
  }
  bool isIngredientUnlocked(String id) {
    final i = ingredients.where((i) => i.id == id).firstOrNull;
    return i != null && (i.rare ? supplierUnlocked : !i.expansion || unlockedIngredients.contains(id));
  }
  bool canBuyIngredient(String id) => isIngredientUnlocked(id);
  bool canBrew(Potion p) => knows(p.id) && p.recipe.every((id) => (materials[id] ?? 0) >= 1);
  int setsFor(int quantity) => (quantity / level).ceil();
  int prepareCost(Potion p, int quantity) => p.recipe.fold(0, (sum, id) {
    final missing = setsFor(quantity) - (materials[id] ?? 0);
    return sum + (missing > 0 ? missing * ingredients.firstWhere((i) => i.id == id).price : 0);
  });
  String? prepare(String id, int quantity) {
    final p = potions.where((p) => p.id == id).firstOrNull;
    if (p == null || !knows(id) || quantity < 1 || quantity > 30) return '제조할 물약과 수량을 확인해 주세요.';
    final cost = prepareCost(p, quantity), sets = setsFor(quantity);
    if (p.recipe.any((i) => (materials[i] ?? 0) < sets && !isIngredientUnlocked(i))) return '부탁을 확인해 재료 거래를 먼저 열어 주세요.';
    if (gold < cost) return '부족한 재료를 구매할 돈이 모자라요.';
    for (final ingredient in p.recipe) {
      materials[ingredient] = ((materials[ingredient] ?? 0) - sets).clamp(0, 1000000);
    }
    gold -= cost; spending += cost;
    stock[id] = (stock[id] ?? 0) + sets * level;
    return null;
  }
  String? brew(String id) {
    final p = potions.where((p) => p.id == id).firstOrNull;
    if (p == null || !knows(id)) return '레시피를 먼저 발견해 주세요.';
    if (!canBrew(p)) return '재료가 부족해요. 재료 상인에게 구입해 주세요.';
    for (final material in p.recipe) { materials[material] = materials[material]! - 1; }
    stock[id] = (stock[id] ?? 0) + level;
    return null;
  }
  bool buy(String id, {int quantity = 3}) {
    final i = ingredients.where((i) => i.id == id).firstOrNull;
    if (quantity <= 0 || quantity > 100 || i == null || !isIngredientUnlocked(id) || gold < i.price * quantity) return false;
    gold -= i.price * quantity; spending += i.price * quantity;
    materials[id] = (materials[id] ?? 0) + quantity;
    return true;
  }
  bool upgrade() {
    if (level >= 3 || gold < upgradeCost) return false;
    investment += upgradeCost; gold -= upgradeCost; level++; return true;
  }

  String? get currentResidentId {
    if (serviceFinished) return null;
    if (visitQueue != null && visitQueue!.isNotEmpty && visitQueue!.first.day == day) return visitQueue![customer].residentId;
    return _residentForName(orders[customer].$1);
  }
  static String _residentForName(String name) => name.contains('로빈') ? 'robin'
      : name.contains('미나') ? 'mina' : name.contains('엘리') ? 'ellie' : name.contains('준') ? 'jun'
      : story.residents.firstWhere((r) => name == r.name || name.endsWith(r.name)).id;
  String? get currentVisitId => serviceFinished ? null : visitQueue != null && visitQueue!.isNotEmpty && visitQueue!.first.day == day
      ? visitQueue![customer].visitId : '$day:$customer:${currentResidentId!}';
  story.ResidentStoryBeat? get currentStory {
    if (serviceFinished || visitQueue == null || visitQueue!.isEmpty || visitQueue!.first.day != day) return null;
    final id = visitQueue![customer].storyBeatId;
    if (id == null) return null;
    return story.residentById(currentResidentId!).story.where((b) => b.id == id).firstOrNull;
  }
  bool get currentStoryNeedsReview => currentStory != null && residents[currentResidentId]!.pendingReview == currentStory!.id;
  String get orderClarification {
    if (serviceFinished) return '';
    final id = orders[customer].$3;
    if (id.isEmpty) return '오늘은 이야기를 나누러 왔어요.';
    if (id == 'sleep') return '푹 잠들 수 있는 숙면 물약 한 병이 필요해요.';
    if (id == 'sight') return '어둠 속을 볼 수 있는 시야 물약 한 병이 필요해요.';
    final p = potionById(id);
    return '${p.description} ${p.useLimit}';
  }
  void _diary(String id, String residentId, String kind, String title, String text) {
    if (diary.any((e) => e.id == id)) return;
    diary.add(DiaryEntry(id: id, residentId: residentId, kind: kind, title: title, text: text, day: day));
  }
  void markDiaryRead(String id) {
    final entry = diary.where((e) => e.id == id).firstOrNull;
    if (entry != null) entry.read = true;
  }
  void _revealFacts(String id, Iterable<String> facts) {
    final definition = story.residentById(id), progress = residents[id]!;
    for (final fact in facts) {
      final text = definition.facts[fact];
      if (text != null && progress.knownFactIds.add(fact)) _diary('fact:$id:$fact', id, 'fact', '알게 된 이야기', text);
    }
  }
  String? recordArrival() {
    final id = currentResidentId, visit = currentVisitId;
    if (id == null || visit == null || night || !arrivedVisits.add(visit)) return null;
    final progress = residents[id]!, definition = story.residentById(id);
    progress.met = true;
    progress.lastOfferedDay = day;
    _diary('met:$id', id, 'profile', definition.name, '${definition.occupation} · ${definition.personality}');
    final beat = currentStory;
    if (beat != null) {
      if (!currentStoryNeedsReview) {
        _revealFacts(id, beat.revealedFactIds);
        _diary('request:${beat.id}', id, 'request', beat.title, beat.request);
        if (beat.potionId != null) requestResearch(beat.potionId!);
      }
    } else if (orders[customer].$3 == 'sight') {
      requestResearch('sight');
    }
    // The first three authored days also witness real follow-up visits. Do not
    // invent these reviews when a migrated save has no customer history.
    if (beat == null && progress.pendingReview != null &&
        progress.deliveredDay != null && progress.deliveredDay! < day) {
      final reviewed = definition.story.firstWhere((b) => b.id == progress.pendingReview);
      progress.completedBeatIds.add(reviewed.id);
      progress.storyIndex = (progress.storyIndex + 1).clamp(0, definition.story.length);
      progress.pendingReview = null; progress.deliveredDay = null;
      _diary('completed:${reviewed.id}', id, 'feedback', reviewed.title, reviewed.success);
      for (final introduced in reviewed.introducedResidentIds) claimedEvents.add('introduced:$introduced');
    }
    if (id == 'robin' && claimedEvents.contains('robin:promise') &&
        !claimedEvents.contains('robin:gift') && !claimedEvents.contains('robin:promise:$visit')) {
      claimedEvents.add('robin:gift');
      progress.fulfilledPromiseIds.add('robin:materials');
      for (final ingredient in ['web', 'tear']) {
        materials[ingredient] = materials[ingredient]! + 1;
        receivedMaterials[ingredient] = (receivedMaterials[ingredient] ?? 0) + 1;
      }
      const text = '로빈의 선물 · 밤의 거미줄 +1 · 정령의 눈물 +1';
      _diary('robin:gift', id, 'promise', '약속한 재료', text);
      return text;
    }
    return null;
  }
  /// A question reveals only its authored fact and cannot farm relationship points.
  bool askResidentQuestion() {
    if (closed || currentResidentId == null) return false;
    recordArrival();
    final beat = currentStory, id = currentResidentId!;
    if (beat == null || beat.revealedFactIds.isEmpty) return false;
    final before = residents[id]!.knownFactIds.length;
    _revealFacts(id, beat.revealedFactIds);
    return residents[id]!.knownFactIds.length != before;
  }
  void _recordSuccess(String residentId, String potionId, String visit) {
    final progress = residents[residentId]!;
    progress.met = true;
    progress.successfulServices[potionId] = (progress.successfulServices[potionId] ?? 0) + 1;
    final definition = story.residentById(residentId);
    if (definition.facts.isNotEmpty) _revealFacts(residentId, [definition.facts.keys.first]);
    _diary('first-help:$residentId:$potionId', residentId, 'help', '물약을 건넸어요', '${potionById(potionId).name}을 건넸어요. 후기는 다음 방문에 들을 수 있어요.');
    if (residentId == 'robin' && potionId == 'sleep' && claimedEvents.add('robin:promise')) {
      claimedEvents.add('robin:promise:$visit');
      _diary('robin:promise', residentId, 'promise', '로빈의 약속', '다음에는 재료를 가져오겠다고 했어요.');
    }
    if (currentStory == null && progress.storyIndex == 0 && progress.pendingReview == null &&
        definition.story.first.potionId == potionId) {
      progress.pendingReview = definition.story.first.id;
      progress.deliveredDay = day;
    }
    lastServiceReaction = residentId == 'robin' && potionId == 'sleep' ? '고마워요. 오늘은 푹 쉬고 새벽에 약초를 돌볼게요.'
        : residentId == 'mina' && potionId == 'sleep' ? '덕분에 내일 따끈한 빵을 준비할 수 있겠어요.'
        : residentId == 'ellie' && potionId == 'sight' ? '오늘 밤길에서 표지판이 잘 보이는지 살펴볼게요.'
        : residentId == 'jun' && potionId == 'sight' ? '맡겨 주신 편지를 안전하게 전하고 올게요.'
        : '${definition.name} · ${potionById(potionId).name}을 써 보고 다음에 이야기해 드릴게요.';
  }
  void _advance() {
    wrongOffers = 0; customer++;
    if (!serviceFinished && orders[customer].$3 == 'sight') researchRequested = true;
  }
  void _miss(String reason) {
    lostSales++;
    missedOrders[reason] = (missedOrders[reason] ?? 0) + 1;
  }
  String? sell(String id, {String? visitId}) {
    if (closed || (visitId != null && visitId != currentVisitId)) return '지금은 손님에게 판매할 수 없어요.';
    if (currentStory != null) {
      if (currentStoryNeedsReview || currentStory!.potionId == null) return '오늘은 이웃의 이야기를 먼저 들어 주세요.';
    }
    if (!knows(id)) return '아직 발견하지 못한 레시피예요. 밤에 연구해 주세요.';
    if ((stock[id] ?? 0) == 0) return '재고가 없어요. 레시피북에서 생산해 주세요.';
    if (id != orders[customer].$3) {
      wrongOffers++;
      if (wrongOffers == 1) return '이 약은 제가 찾던 게 아니에요. $orderClarification 한 번만 다시 골라 주시겠어요?';
      _miss('wrongPotion'); _advance();
      return '이번에도 다른 약이네요… 오늘은 다른 가게에 가 볼게요.';
    }
    if (currentStory != null) return resolveStory();
    recordArrival();
    final resident = currentResidentId!, visit = currentVisitId!, potion = potionById(id);
    stock[id] = stock[id]! - 1;
    gold += potion.price; revenue += potion.price; salesRevenue += potion.price; served++;
    _recordSuccess(resident, id, visit);
    _advance();
    return null;
  }
  bool skipCustomer() {
    if (closed) return false;
    recordArrival();
    final wanted = orders[customer].$3;
    if (wanted.isNotEmpty && !knows(wanted)) { requestResearch(wanted); researchPendingOrders++; }
    else if (wanted.isNotEmpty) { _miss((stock[wanted] ?? 0) == 0 ? 'outOfStock' : 'declined'); }
    _advance(); return true;
  }
  String? resolveStory({bool chooseAlternative = false, String? visitId}) {
    final beat = currentStory, id = currentResidentId, visit = currentVisitId;
    if (closed || beat == null || id == null || visit == null || (visitId != null && visitId != visit)) return '지금 이어갈 이야기가 없어요.';
    final progress = residents[id]!;
    if (progress.completedBeatIds.contains(beat.id)) return '이미 마친 이야기예요.';
    if (chooseAlternative && !beat.optional) return '이 부탁에는 다른 준비 방법이 없어요.';
    final isReview = currentStoryNeedsReview;
    if (isReview && (progress.deliveredDay ?? day) >= day) return '사용 후기는 다음 방문에 들을 수 있어요.';
    if (!isReview && !chooseAlternative && beat.potionId != null) {
      final potionId = beat.potionId!;
      if (!knows(potionId)) return '밤에 이 부탁의 물약을 먼저 연구해 주세요.';
      if ((stock[potionId] ?? 0) < 1) return '물약 한 병을 준비해 주세요.';
      recordArrival();
      final p = potionById(potionId);
      stock[potionId] = stock[potionId]! - 1;
      gold += p.price; revenue += p.price; salesRevenue += p.price; served++;
      _recordSuccess(id, potionId, visit);
      progress.pendingReview = beat.id; progress.deliveredDay = day;
      _diary('delivered:${beat.id}', id, 'help', beat.title, '${p.name}을 전했어요. 다음 방문에 후기를 들어 보세요.');
      _advance();
      return null;
    }
    recordArrival();
    progress.completedBeatIds.add(beat.id);
    progress.pendingReview = null; progress.deliveredDay = null;
    progress.storyIndex = (progress.storyIndex + 1).clamp(0, story.residentById(id).story.length);
    _revealFacts(id, beat.revealedFactIds);
    if (chooseAlternative) {
      claimedEvents.add('alternative:${beat.id}');
      lastServiceReaction = beat.alternativeText ?? '향 없이 준비해도 같은 마음이 전해졌어요.';
    } else { lastServiceReaction = beat.success; }
    _diary('completed:${beat.id}', id, isReview ? 'feedback' : 'story', beat.title, lastServiceReaction!);
    for (final introduced in beat.introducedResidentIds) {
      claimedEvents.add('introduced:$introduced');
      _diary('intro:${beat.id}:$introduced', id, 'connection', '이웃을 소개받았어요', '${story.residentById(introduced).name}에게도 가게 이야기를 전했어요.');
    }
    if (beat.id.endsWith('.ending')) progress.fulfilledPromiseIds.add(beat.id);
    _advance();
    return null;
  }

  bool isResidentAvailable(String id) {
    final condition = story.residentById(id).entryCondition;
    bool sightFeedback() => residents['ellie']!.completedBeatIds.contains('ellie.sight') || completed;
    return switch (condition) {
      'always' => true,
      'sightFeedback' => sightFeedback(),
      'guildCompleted' => completed,
      'junFeedbackOrGuild' => residents['jun']!.completedBeatIds.contains('jun.address') || completed,
      _ => false,
    };
  }
  List<VisitPlan> _planFor(int planDay) {
    if (planDay <= 3) return [for (var n = 0; n < _legacyOrders(planDay).length; n++)
      VisitPlan(visitId: '$planDay:$n:${_residentForName(_legacyOrders(planDay)[n].$1)}', day: planDay,
        residentId: _residentForName(_legacyOrders(planDay)[n].$1), name: _legacyOrders(planDay)[n].$1,
        text: _legacyOrders(planDay)[n].$2, potionId: _legacyOrders(planDay)[n].$3)];
    final available = story.residents.where((r) => isResidentAvailable(r.id)).toList()
      ..sort((a, b) {
        final cmp = residents[a.id]!.lastOfferedDay.compareTo(residents[b.id]!.lastOfferedDay);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    final result = <VisitPlan>[];
    final used = <String>{};
    for (final r in available) {
      if (result.length >= 2) break;
      final progress = residents[r.id]!;
      if (progress.storyIndex >= r.story.length) continue;
      final beat = r.story[progress.storyIndex];
      if (beat.potionId != null && potionById(beat.potionId!).recipe.any((i) => ingredients.firstWhere((x) => x.id == i).rare) && !completed) continue;
      final review = progress.pendingReview == beat.id;
      result.add(VisitPlan(visitId: '$planDay:${result.length}:${r.id}', day: planDay,
        residentId: r.id, name: r.name, text: review ? beat.success : beat.request,
        potionId: review ? null : beat.potionId, storyBeatId: beat.id));
      used.add(r.id);
    }
    for (final r in available) {
      if (result.length >= 3) break;
      if (!used.add(r.id)) continue;
      final potionId = (r.id == 'ellie' || r.id == 'jun' || r.id == 'doran') && knows('sight') ? 'sight' : 'sleep';
      result.add(VisitPlan(visitId: '$planDay:${result.length}:${r.id}', day: planDay,
        residentId: r.id, name: r.name, text: '오늘은 ${potionById(potionId).name} 한 병 부탁해요.', potionId: potionId));
    }
    return result;
  }
  List<VisitPlan> ensureNextDayPlan() {
    if (nextDayPlan != null && nextDayPlan!.isNotEmpty && nextDayPlan!.first.day == day + 1) return nextDayPlan!;
    // Preview during service remains a read-only estimate. Freeze only at night.
    final plan = _planFor(day + 1);
    if (night) nextDayPlan = plan;
    return plan;
  }
  Map<String, int> get nextDayDemand {
    final demand = <String, int>{};
    for (final visit in ensureNextDayPlan()) {
      if (visit.potionId != null) demand[visit.potionId!] = (demand[visit.potionId!] ?? 0) + 1;
    }
    return demand;
  }
  bool startNight() {
    if (night || !serviceFinished) return false;
    phase = 'night'; ensureNextDayPlan(); return true;
  }
  String? research(List<String> guess, {String potionId = 'sight'}) {
    if (!canResearchPotion(potionId)) return '지금은 진행할 연구가 없어요.';
    final p = potionById(potionId);
    // Experiment samples are free and independent of purchasing unlocks.
    final ids = ingredients.map((i) => i.id).toSet();
    if (guess.length != p.recipe.length || guess.toSet().length != guess.length || !guess.every(ids.contains)) return '서로 다른 재료 세 가지를 순서대로 골라 주세요.';
    final result = scoreRecipe(guess, p.recipe);
    if (potionId == 'sight') attempts.add(result);
    if (result.strikes == p.recipe.length) discoverRecipe(potionId);
    return null;
  }
  bool requestAid() {
    if (!night || aidDays.contains(day) || gold >= 18) return false;
    for (final i in ingredients.where((i) => !i.rare && !i.expansion)) materials[i.id] = materials[i.id]! + 1;
    stock['sleep'] = stock['sleep']! + 1; aidDays.add(day); return true;
  }
  bool deliver() {
    if (day < 3 || !knows('sight') || stock['sight']! < 3 || completed) return false;
    stock['sight'] = stock['sight']! - 3; gold += 120; revenue += 120; guildRewards += 120;
    supplierUnlocked = true; claimedEvents.add('guild:first');
    _diary('guild:first', 'ellie', 'guild', '길잡이 조합 납품', '시야 물약 3병을 전했어요. 120 G와 희귀 재료 거래가 열렸어요.');
    return true;
  }
  bool nextDay() {
    if (!night) return false;
    final plan = ensureNextDayPlan();
    day++; phase = 'shop'; visitQueue = plan; nextDayPlan = null;
    customer = served = revenue = spending = investment = wrongOffers = lostSales = 0;
    salesRevenue = guildRewards = unclassifiedRevenue = researchPendingOrders = 0;
    missedOrders.clear(); receivedMaterials.clear(); arrivedVisits.clear();
    return true;
  }

  String encode() => jsonEncode({'version': 3, 'day': day, 'gold': gold, 'customer': customer,
    'served': served, 'wrongOffers': wrongOffers, 'lostSales': lostSales, 'revenue': revenue,
    'spending': spending, 'investment': investment, 'level': level, 'phase': phase,
    'salesRevenue': salesRevenue, 'guildRewards': guildRewards, 'unclassifiedRevenue': unclassifiedRevenue,
    'missedOrders': missedOrders, 'researchPendingOrders': researchPendingOrders, 'receivedMaterials': receivedMaterials,
    'stock': stock, 'materials': materials, 'discovered': discovered.toList(),
    'researchRequested': researchRequested, 'supplierUnlocked': supplierUnlocked,
    'attempts': attempts.map((a) => a.toJson()).toList(), 'aidDays': aidDays.toList(), 'researchNotebook': researchNotebook,
    'researchNotebooks': researchNotebooks, 'requestedResearch': requestedResearch.toList(),
    'unlockedIngredients': unlockedIngredients.toList(), 'tutorialProgress': tutorialProgress,
    'residents': {for (final entry in residents.entries) entry.key: entry.value.toJson()},
    'diary': diary.map((e) => e.toJson()).toList(), 'claimedEvents': claimedEvents.toList(),
    'arrivedVisits': arrivedVisits.toList(), 'visitQueue': visitQueue?.map((v) => v.toJson()).toList(),
    'nextDayPlan': nextDayPlan?.map((v) => v.toJson()).toList(), 'lastServiceReaction': lastServiceReaction});

  static Game decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final version = data['version'];
    if (version != 2 && version != 3) throw const FormatException('Unsupported save');
    int read(String key, int min, int max) => checkedInt(data[key], min, max);
    final g = Game()
      ..day = read('day', 1, 1000000)..gold = read('gold', 0, 100000000)
      ..customer = read('customer', 0, 3)..served = read('served', 0, 3)
      ..revenue = read('revenue', 0, 1000000)..spending = read('spending', 0, 100000000)
      ..investment = read('investment', 0, 100000000)..level = read('level', 1, 3);
    g.wrongOffers = data.containsKey('wrongOffers') ? read('wrongOffers', 0, 1) : 0;
    g.lostSales = data.containsKey('lostSales') ? read('lostSales', 0, 3) : 0;
    Map<String, int> inventory(String key, Iterable<String> ids, Set<String> legacyIds) {
      final m = data[key] as Map<String, dynamic>;
      return {for (final id in ids) id: m.containsKey(id) ? checkedInt(m[id], 0, 1000000)
        : version == 2 && !legacyIds.contains(id) ? 0 : throw const FormatException('Missing inventory')};
    }
    g.phase = data['phase'] as String;
    g.researchNotebook = data['researchNotebook'] as String?;
    g.researchRequested = data['researchRequested'] as bool;
    g.supplierUnlocked = data['supplierUnlocked'] as bool;
    g.discovered = (data['discovered'] as List).cast<String>().toSet();
    g.stock = inventory('stock', potions.map((p) => p.id), {'sleep', 'sight'});
    g.materials = inventory('materials', ingredients.map((i) => i.id),
      {'web', 'tear', 'moon', 'salt', 'mushroom', 'petal', 'root', 'fairy'});
    for (final raw in data['attempts'] as List) {
      final guess = (raw['guess'] as List).cast<String>();
      if (guess.length != 3 || guess.toSet().length != 3 || !guess.every((id) =>
          ingredients.any((i) => i.id == id && (version == 3 || (!i.rare && !i.expansion))))) throw const FormatException('Invalid guess');
      final a = scoreRecipe(guess, potionById('sight').recipe);
      if (a.strikes != raw['strikes'] || a.balls != raw['balls']) throw const FormatException('Invalid result');
      g.attempts.add(a);
    }
    g.aidDays = (data['aidDays'] as List).cast<int>().toSet();
    if (g.aidDays.any((d) => d < 1 || d > g.day)) throw const FormatException('Invalid aid');
    if (version == 2) {
      g.unclassifiedRevenue = g.revenue;
      if (g.lostSales > 0) g.missedOrders['unknown'] = g.lostSales;
      g.tutorialProgress = {'version': 1, 'status': 'legacySatisfied', 'step': 0};
      if (g.researchRequested) g.requestedResearch.add('sight');
      if (g.researchNotebook != null) g.researchNotebooks['sight'] = g.researchNotebook!;
      if (g.completed) g.claimedEvents.add('guild:first');
    } else {
      g.salesRevenue = read('salesRevenue', 0, 1000000);
      g.guildRewards = read('guildRewards', 0, 1000000);
      g.unclassifiedRevenue = read('unclassifiedRevenue', 0, 1000000);
      if (g.revenue != g.salesRevenue + g.guildRewards + g.unclassifiedRevenue) throw const FormatException('Invalid ledger');
      g.researchPendingOrders = read('researchPendingOrders', 0, 3);
      for (final entry in (data['missedOrders'] as Map<String, dynamic>).entries) {
        if (!{'wrongPotion', 'outOfStock', 'declined', 'unknown'}.contains(entry.key)) throw const FormatException('Invalid lost reason');
        g.missedOrders[entry.key] = checkedInt(entry.value, 0, 3);
      }
      if (g.lostSales != g.missedOrders.values.fold(0, (a, b) => a + b)) throw const FormatException('Invalid lost total');
      for (final entry in (data['receivedMaterials'] as Map<String, dynamic>).entries) {
        if (!g.materials.containsKey(entry.key)) throw const FormatException('Invalid gift material');
        g.receivedMaterials[entry.key] = checkedInt(entry.value, 0, 1000000);
      }
      g.researchNotebooks.addAll((data['researchNotebooks'] as Map<String, dynamic>).cast<String, String>());
      g.requestedResearch.addAll((data['requestedResearch'] as List).cast<String>());
      g.unlockedIngredients.addAll((data['unlockedIngredients'] as List).cast<String>());
      g.tutorialProgress = data['tutorialProgress'] == null ? null : Map<String, dynamic>.from(data['tutorialProgress'] as Map);
      final residentData = data['residents'] as Map<String, dynamic>;
      for (final definition in story.residents) {
        final progress = ResidentProgress.fromJson(residentData[definition.id] as Map<String, dynamic>);
        if (progress.storyIndex > definition.story.length || !progress.knownFactIds.every(definition.facts.containsKey) ||
            !progress.successfulServices.keys.every(g.stock.containsKey) ||
            !progress.completedBeatIds.every((id) => definition.story.any((b) => b.id == id)) ||
            (progress.pendingReview != null && !definition.story.any((b) => b.id == progress.pendingReview)) ||
            (progress.deliveredDay != null && progress.deliveredDay! > g.day) || progress.lastOfferedDay > g.day) {
          throw const FormatException('Invalid resident progress');
        }
        g.residents[definition.id] = progress;
      }
      for (final raw in data['diary'] as List) {
        final entry = DiaryEntry.fromJson(raw as Map<String, dynamic>);
        if (!g.residents.containsKey(entry.residentId) || entry.day > g.day || g.diary.any((e) => e.id == entry.id)) throw const FormatException('Invalid diary entry');
        g.diary.add(entry);
      }
      g.claimedEvents.addAll((data['claimedEvents'] as List).cast<String>());
      g.arrivedVisits.addAll((data['arrivedVisits'] as List).cast<String>());
      List<VisitPlan>? queue(String key, int expectedDay) {
        final raw = data[key];
        if (raw == null) return null;
        final items = (raw as List).map((d) => VisitPlan.fromJson(d as Map<String, dynamic>)).toList();
        if (items.length != 3 || items.map((v) => v.visitId).toSet().length != items.length ||
            items.any((v) => v.day != expectedDay || !g.residents.containsKey(v.residentId) ||
              (v.potionId != null && !g.stock.containsKey(v.potionId)) ||
              (v.storyBeatId != null && !story.residentById(v.residentId).story.any((b) => b.id == v.storyBeatId)))) {
          throw const FormatException('Invalid visit queue');
        }
        return items;
      }
      g.visitQueue = queue('visitQueue', g.day); g.nextDayPlan = queue('nextDayPlan', g.day + 1);
      g.lastServiceReaction = data['lastServiceReaction'] as String?;
    }
    if (!{'shop', 'night'}.contains(g.phase) || (g.night && !g.serviceFinished) ||
        !g.discovered.contains('sleep') || !g.discovered.every(g.stock.containsKey) ||
        !g.requestedResearch.every(g.stock.containsKey) || !g.researchNotebooks.keys.every(g.stock.containsKey) ||
        !g.unlockedIngredients.every(g.materials.containsKey) ||
        g.served > g.customer || g.served + g.lostSales + g.researchPendingOrders > g.customer ||
        (g.completed && (g.day < 3 || !g.knows('sight')))) throw const FormatException('Invalid progress');
    return g;
  }
}
