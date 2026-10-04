import 'dart:convert';
import 'game.dart';

/// A free experiment notebook. Ingredient samples are independent of shop stock.
class ResearchSession {
  final String potionId;
  final int recipeVersion;
  ResearchSession({this.potionId = 'sight', this.recipeVersion = 1}) {
    if (!potions.any((p) => p.id == potionId && p.recipeVersion == recipeVersion)) {
      throw const FormatException('Unknown research definition');
    }
    slots = List.filled(slotCount, null);
  }
  Potion get target => potions.firstWhere((p) => p.id == potionId);
  int get slotCount => target.slotCount;
  late List<String?> slots;
  int activeSlot = 0;
  List<ResearchAttempt> attempts = [];
  Map<String, String> marks = {};
  String memo = '';
  static const markValues = {'candidate', 'hold', 'excluded'};
  bool get solved => attempts.any((a) => a.strikes == slotCount);
  bool get ready => !solved && slots.length == slotCount && slots.every((s) => s != null);
  void selectSlot(int index) { if (index >= 0 && index < slotCount) activeSlot = index; }
  void setMark(String id, String? mark) {
    if (!ingredients.any((i) => i.id == id)) return;
    if (mark == null) { marks.remove(id); }
    else if (markValues.contains(mark)) { marks[id] = mark; }
  }
  void setMemo(String text) { memo = String.fromCharCodes(text.runes.take(200)); }
  void clearMemo() { marks.clear(); memo = ''; }
  void clearSlots() { if (!solved) { slots = List.filled(slotCount, null); activeSlot = 0; } }
  ResearchSession freshNotebook() => ResearchSession(potionId: potionId, recipeVersion: recipeVersion)
    ..marks = {...marks} ..memo = memo;
  void place(String id, {int? at}) {
    if (solved || !ingredients.any((i) => i.id == id)) return;
    final index = at ?? activeSlot;
    if (index < 0 || index >= slotCount) return;
    final previous = slots.indexOf(id);
    if (previous >= 0 && previous != index) slots[previous] = slots[index];
    slots[index] = id;
    activeSlot = slots.indexOf(null) >= 0 ? slots.indexOf(null) : index;
  }
  void clearSlot(int index) {
    if (!solved && index >= 0 && index < slotCount) { slots[index] = null; activeSlot = index; }
  }
  void reuse(ResearchAttempt attempt) {
    if (!solved && attempt.guess.length == slotCount && attempt.guess.toSet().length == slotCount &&
        attempt.guess.every((id) => ingredients.any((i) => i.id == id))) {
      slots = [...attempt.guess]; activeSlot = 0;
    }
  }
  ResearchAttempt? submit() {
    if (!ready) return null;
    final result = scoreRecipe(slots.cast<String>(), target.recipe);
    attempts.add(result);
    return result;
  }
  String encode() => jsonEncode({'version': 2, 'potionId': potionId, 'recipeVersion': recipeVersion,
    'slots': slots, 'active': activeSlot, 'marks': marks, 'memo': memo,
    'attempts': attempts.map((a) => a.toJson()).toList()});
  static ResearchSession decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 1 && data['version'] != 2) throw const FormatException('Invalid research save');
    final legacy = data['version'] == 1;
    final s = ResearchSession(potionId: legacy ? 'sight' : data['potionId'] as String,
      recipeVersion: legacy ? 1 : data['recipeVersion'] as int);
    final ids = ingredients.where((i) => !legacy || const {'web', 'tear', 'moon', 'salt', 'mushroom', 'petal'}.contains(i.id)).map((i) => i.id).toSet();
    final slots = (data['slots'] as List).cast<String?>();
    if (slots.length != s.slotCount || !slots.whereType<String>().every(ids.contains) ||
        slots.whereType<String>().toSet().length != slots.whereType<String>().length) {
      throw const FormatException('Invalid draft');
    }
    final active = data['active'];
    if (active is! int || active < 0 || active >= s.slotCount) throw const FormatException('Invalid active slot');
    s.slots = [...slots]; s.activeSlot = active;
    for (final row in data['attempts'] as List) {
      final guess = (row['guess'] as List).cast<String>();
      if (s.solved || guess.length != s.slotCount || guess.toSet().length != s.slotCount || !guess.every(ids.contains)) {
        throw const FormatException('Invalid history');
      }
      final result = scoreRecipe(guess, s.target.recipe);
      if (result.strikes != row['strikes'] || result.balls != row['balls']) throw const FormatException('Invalid score');
      s.attempts.add(result);
    }
    // Optional annotations may be repaired without discarding a valid experiment.
    final marks = data['marks'];
    if (marks is Map) {
      for (final entry in marks.entries) {
        if (entry.key is String && entry.value is String) s.setMark(entry.key as String, entry.value as String);
      }
    }
    if (data['memo'] is String) s.setMemo(data['memo'] as String);
    return s;
  }
}
