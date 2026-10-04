import 'package:flutter_test/flutter_test.dart';
import 'package:potionshop/catalog.dart';
import 'package:potionshop/resident_catalog.dart';

void main() {
  test('All production recipes use three distinct purchasable ingredients', () {
    expect(ingredients.length, 12);
    expect(potions.length, 12);
    final ids = ingredients.map((i) => i.id).toSet();
    expect(ids.length, ingredients.length);
    expect(potions.map((p) => p.id).toSet().length, potions.length);
    expect(ids.contains('tutorial_unicorn'), isFalse);
    expect(ingredients.where((i) => i.expansion).length, 4);
    for (final potion in potions) {
      expect(potion.recipe.length, 3, reason: potion.id);
      expect(potion.recipe.toSet().length, 3, reason: potion.id);
      expect(potion.recipe.every(ids.contains), isTrue, reason: potion.id);
      expect(potion.materialCost, greaterThan(0));
      expect(potion.price, greaterThan(potion.materialCost));
      expect(potion.useLimit, isNotEmpty);
      expect(potion.description, isNotEmpty);
    }
    expect(potionById('sleep').recipe, ['web', 'tear', 'moon']);
    expect(potionById('sleep').price, 35);
    expect(potionById('sight').recipe, ['moon', 'salt', 'mushroom']);
    expect(potionById('sight').price, 38);
    expect(potionById('sprout').materialCost, 9);
    expect(potionById('raincoat').materialCost, 7);
  });

  test('Resident stories have reachable independent entries and valid references', () {
    expect(residents.length, 8);
    final residentIds = residents.map((r) => r.id).toSet();
    final potionIds = potions.map((p) => p.id).toSet();
    expect(residentIds.length, residents.length);
    const conditions = {'always', 'sightFeedback', 'guildCompleted', 'junFeedbackOrGuild'};
    final beatIds = <String>{};
    final requestedPotions = <String>{};
    for (final resident in residents) {
      expect(conditions.contains(resident.entryCondition), isTrue);
      expect(resident.story.length, 4, reason: resident.id);
      expect(resident.facts.length, greaterThanOrEqualTo(3));
      expect(resident.personality, isNotEmpty);
      expect(resident.speech, isNotEmpty);
      expect(resident.want, isNotEmpty);
      final revealed = <String>{};
      for (final beat in resident.story) {
        expect(beatIds.add(beat.id), isTrue, reason: 'Duplicate ${beat.id}');
        expect(beat.title, isNotEmpty);
        expect(beat.request, isNotEmpty);
        expect(beat.success, isNotEmpty);
        expect(beat.revealedFactIds.every(resident.facts.containsKey), isTrue,
            reason: 'Unknown fact in ${beat.id}');
        expect(beat.introducedResidentIds.every(residentIds.contains), isTrue,
            reason: 'Unknown introduction in ${beat.id}');
        revealed.addAll(beat.revealedFactIds);
        if (beat.potionId != null) {
          expect(potionIds.contains(beat.potionId), isTrue);
          requestedPotions.add(beat.potionId!);
        }
        if (beat.optional) {
          expect(beat.alternativeText, isNotNull);
          expect(beat.alternativeText, isNotEmpty);
        }
      }
      expect(revealed, resident.facts.keys.toSet(), reason: 'Unreachable facts for ${resident.id}');
      expect(resident.story.last.potionId, isNull, reason: 'Epilogue must not demand another purchase');
    }
    expect(requestedPotions, potionIds, reason: 'Every potion needs a concrete authored request');
    for (final potion in potions.where((p) => p.unlockResidentId != null)) {
      expect(residentIds.contains(potion.unlockResidentId), isTrue);
      final owner = residentById(potion.unlockResidentId!);
      expect(owner.story.any((b) => b.potionId == potion.id), isTrue);
    }
  });

  test('Scent stories support an equally valid non-purchase choice', () {
    for (final residentId in ['mina', 'nari']) {
      final choice = residentById(residentId).story.singleWhere((b) => b.potionId == 'calm_scent');
      expect(choice.optional, isTrue);
      expect(choice.alternativeText, contains('향 없이'));
      expect(choice.success, contains('있'));
    }
  });
}
