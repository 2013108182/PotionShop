import 'dart:convert';
import 'game.dart';

class ResearchSession {
  List<String?> slots = [null, null, null];
  int activeSlot = 0;
  List<ResearchAttempt> attempts = [];
  bool get solved => attempts.any((a) => a.strikes == 3);
  bool get ready => !solved && slots.every((s) => s != null);
  void selectSlot(int index) { activeSlot = index; }
  void place(String id, {int? at}) {
    if (solved || !ingredients.any((i) => !i.rare && i.id == id)) return;
    final index = at ?? activeSlot;
    final previous = slots.indexOf(id);
    if (previous >= 0 && previous != index) slots[previous] = slots[index];
    slots[index] = id;
    activeSlot = slots.indexOf(null) >= 0 ? slots.indexOf(null) : index;
  }
  void clearSlot(int index) { if (!solved) { slots[index] = null; activeSlot = index; } }
  void reuse(ResearchAttempt attempt) { if (!solved) { slots = [...attempt.guess]; activeSlot = 0; } }
  ResearchAttempt? submit() {
    if (!ready) return null;
    final result = scoreRecipe(slots.cast<String>(), potions[1].recipe);
    attempts.add(result);
    return result;
  }
  String encode() => jsonEncode({'version': 1, 'slots': slots, 'active': activeSlot,
    'attempts': attempts.map((a) => a.toJson()).toList()});
  static ResearchSession decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 1) throw const FormatException('Invalid research save');
    final s = ResearchSession();
    final ids = ingredients.where((i) => !i.rare).map((i) => i.id).toSet();
    final slots = (data['slots'] as List).cast<String?>();
    if (slots.length != 3 || !slots.whereType<String>().every(ids.contains) ||
        slots.whereType<String>().toSet().length != slots.whereType<String>().length) {
      throw const FormatException('Invalid draft');
    }
    final active = data['active'];
    if (active is! int || active < 0 || active > 2) throw const FormatException('Invalid active slot');
    s.slots = [...slots]; s.activeSlot = active;
    for (final row in data['attempts'] as List) {
      final guess = (row['guess'] as List).cast<String>();
      if (s.solved || guess.length != 3 || guess.toSet().length != 3 || !guess.every(ids.contains)) throw const FormatException('Invalid history');
      final result = scoreRecipe(guess, potions[1].recipe);
      if (result.strikes != row['strikes'] || result.balls != row['balls']) throw const FormatException('Invalid score');
      s.attempts.add(result);
    }
    return s;
  }
}
