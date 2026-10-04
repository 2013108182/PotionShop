import 'dart:convert';
import 'game.dart';

// These are practice samples, never inventory or shop catalogue entries.
const tutorialSamples = <String, String>{
  'web': '밤의 거미줄', 'moon': '달빛 결정', 'tear': '정령의 눈물',
  'fairy': '요정 가루', 'salt': '심해 소금', 'tutorial_unicorn': '유니콘 뿔',
};
const tutorialGuesses = <List<String>>[
  ['web', 'moon', 'tear'],
  ['fairy', 'salt', 'tutorial_unicorn'],
  ['web', 'tear', 'moon'],
];

enum TutorialAction { next, select, submit, done }

class TutorialStep {
  final String id, text;
  final TutorialAction action;
  final int experiment;
  final String? ingredient;
  const TutorialStep(this.id, this.text, this.action,
      {this.experiment = 0, this.ingredient});
}

const tutorialSteps = <TutorialStep>[
  TutorialStep('guess_intro', '스승에게 배운 숙면 제조법으로 실험 기록 읽는 법을 연습해 볼까요?\n이미 배운 약의 연습이므로 새 물약이나 보상을 받지는 않아요.', TutorialAction.next),
  TutorialStep('free_cost_warning', '연습과 연구는 돈과 창고 재료를 쓰지 않아요. 실패해도 편하게 다시 시도할 수 있어요.', TutorialAction.next),
  TutorialStep('free_cost_warning_2', '판매할 물약을 제조할 때만 창고 재료를 사용해요. 지금은 교육용 샘플로 세 번 연습합니다.', TutorialAction.next),
  TutorialStep('guess_1_1', '먼저 밤의 거미줄을 넣어 보세요.', TutorialAction.select, ingredient: 'web'),
  TutorialStep('guess_1_2', '두 번째 칸에는 달빛 결정을 넣어 보세요.', TutorialAction.select, ingredient: 'moon'),
  TutorialStep('guess_1_3', '세 번째 칸에는 정령의 눈물을 넣어 보세요.', TutorialAction.select, ingredient: 'tear'),
  TutorialStep('brew_1', '세 샘플을 조합하고 결과를 읽어 봅시다.', TutorialAction.submit),
  TutorialStep('explain_1', '세 재료가 모두 들어맞아요. 완벽은 재료와 자리가 모두 맞은 개수예요.', TutorialAction.next),
  TutorialStep('explain_1_continue', '불안정은 재료는 맞지만 자리가 다른 개수예요. 어느 칸이 맞았는지는 기록이 직접 알려주지 않아요.', TutorialAction.next),
  TutorialStep('guess_2_1', '이번에는 교육용 요정 가루를 넣어 보세요.', TutorialAction.select, experiment: 1, ingredient: 'fairy'),
  TutorialStep('guess_2_2', '두 번째 칸에는 심해 소금을 넣어 보세요.', TutorialAction.select, experiment: 1, ingredient: 'salt'),
  TutorialStep('guess_2_3', '세 번째 칸에는 교육용 유니콘 뿔을 넣어 보세요.', TutorialAction.select, experiment: 1, ingredient: 'tutorial_unicorn'),
  TutorialStep('brew_2', '다른 세 샘플의 결과도 비교해 봅시다.', TutorialAction.submit, experiment: 1),
  TutorialStep('explain_2', '이 세 재료는 이번 숙면 제조법에 쓰이지 않아요. 다른 물약에도 쓸모없다는 뜻은 아니에요.', TutorialAction.next, experiment: 1),
  TutorialStep('guess_3_1', '마지막으로 밤의 거미줄을 넣어 보세요.', TutorialAction.select, experiment: 2, ingredient: 'web'),
  TutorialStep('guess_3_2', '두 번째 칸에는 정령의 눈물을 넣어 보세요.', TutorialAction.select, experiment: 2, ingredient: 'tear'),
  TutorialStep('guess_3_3', '세 번째 칸에는 달빛 결정을 넣어 보세요.', TutorialAction.select, experiment: 2, ingredient: 'moon'),
  TutorialStep('brew_3', '순서를 바꾼 마지막 조합을 실험해 보세요.', TutorialAction.submit, experiment: 2),
  TutorialStep('result_screen', '재료와 순서가 모두 맞았어요. 기록을 비교하는 법을 익혔네요.', TutorialAction.next, experiment: 2),
  TutorialStep('return_shop', '숙면 연습을 마쳤어요. 진열대에 있던 숙면 물약 한 병을 로빈에게 건네면 첫 판매가 됩니다.\n엘리의 부탁은 밤에 자유롭게 연구할 거예요.', TutorialAction.next, experiment: 2),
  TutorialStep('completed', '숙면 연습 완료', TutorialAction.done, experiment: 2),
];

class TutorialSession {
  int _step = 0;
  bool _legacy = false;
  int get revision => _step;
  TutorialStep get current => tutorialSteps[_step];
  bool get satisfied => _legacy || _step == tutorialSteps.length - 1;
  String get status => _legacy ? 'legacySatisfied' : satisfied ? 'completed'
      : _step == 0 ? 'notStarted' : 'inProgress';

  List<String> get slots {
    final start = [3, 9, 14][current.experiment];
    final count = (_step - start).clamp(0, 3).toInt();
    return List.unmodifiable(tutorialGuesses[current.experiment].take(count));
  }
  List<ResearchAttempt> get attempts => List.unmodifiable([
    for (var i = 0; i < 3; i++)
      if (_step > [6, 12, 17][i])
        scoreRecipe(tutorialGuesses[i], potions.firstWhere((p) => p.id == 'sleep').recipe),
  ]);

  // Stale/double callbacks and all off-script input are rejected in the model.
  bool apply(int expectedRevision, TutorialAction action, {String? ingredient}) {
    if (satisfied || expectedRevision != _step || action != current.action ||
        action == TutorialAction.done ||
        (action == TutorialAction.select && ingredient != current.ingredient) ||
        (action != TutorialAction.select && ingredient != null)) return false;
    _step++;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'version': 1, 'definitionId': 'legacy_sleep_v1', 'step': _step,
    'stepId': current.id, 'status': status, 'slots': slots,
    'attempts': attempts.map((a) => a.toJson()).toList(),
  };

  static TutorialSession fromJson(Map<String, dynamic>? data) {
    final session = TutorialSession();
    if (data == null) return session;
    if (data['status'] == 'legacySatisfied') {
      if (data['version'] != 1 || data['step'] != 0) {
        throw const FormatException('Invalid legacy tutorial progress');
      }
      session._legacy = true;
      return session;
    }
    final step = data['step'];
    if (data['version'] != 1 || data['definitionId'] != 'legacy_sleep_v1' ||
        step is! int || step < 0 || step >= tutorialSteps.length) {
      throw const FormatException('Invalid tutorial progress');
    }
    session._step = step;
    final expected = session.toJson();
    for (final key in ['status', 'stepId', 'slots', 'attempts']) {
      if (jsonEncode(data[key]) != jsonEncode(expected[key])) {
        throw const FormatException('Inconsistent tutorial progress');
      }
    }
    return session;
  }
}
