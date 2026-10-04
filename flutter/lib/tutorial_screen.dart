import 'package:flutter/material.dart';
import 'tutorial_session.dart';

class TutorialScreen extends StatefulWidget {
  final TutorialSession session;
  final Future<void> Function(Map<String, dynamic>) onChanged;
  final bool replay;
  const TutorialScreen({super.key, required this.session, required this.onChanged, this.replay = false});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool saving = false;
  String? error;
  Future<void> act(int revision, TutorialAction action, {String? ingredient}) async {
    if (saving || error != null || !widget.session.apply(revision, action, ingredient: ingredient)) return;
    await persist();
  }
  Future<void> persist() async {
    if (saving) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.onChanged(widget.session.toJson());
    } catch (_) {
      if (mounted) setState(() => error = '연습 기록을 저장하지 못했어요. 현재 단계는 유지됩니다. 저장을 다시 시도해 주세요.');
    }
    if (!mounted) return;
    setState(() => saving = false);
    if (error == null && widget.session.satisfied) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session, step = session.current;
    final revision = session.revision;
    final instruction = widget.replay && {'return_shop', 'completed'}.contains(step.id)
        ? '연습을 마쳤어요. 기존 영업 기록은 바뀌지 않아요. 다이어리로 돌아가세요.' : step.text;
    return PopScope(canPop: !saving && error == null, child: Scaffold(
      appBar: AppBar(title: const Text('스승의 숙면 연습')),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('교육용 샘플 · 재료 소모 없음 · 보상 없음'),
            const SizedBox(height: 16),
            if ({'explain_1', 'explain_2', 'result_screen'}.contains(step.id))
              Text('완벽 ${session.attempts.last.strikes} · 불안정 ${session.attempts.last.balls}',
                key: const ValueKey('tutorial-result'), style: const TextStyle(fontSize: 20)),
            Text(instruction, key: const ValueKey('tutorial-instruction'), style: const TextStyle(fontSize: 18, height: 1.6)),
            const SizedBox(height: 16),
            Text('실험 ${step.experiment + 1} / 3'),
            const SizedBox(height: 8),
            Text(List.generate(3, (i) => i < session.slots.length
                ? '${i + 1}. ${tutorialSamples[session.slots[i]]}' : '${i + 1}. 빈 칸').join('  →  '),
                key: const ValueKey('tutorial-slots')),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final entry in tutorialSamples.entries)
                OutlinedButton(key: ValueKey('tutorial-sample-${entry.key}'),
                  onPressed: !saving && error == null && step.action == TutorialAction.select && step.ingredient == entry.key
                    ? () => act(revision, TutorialAction.select, ingredient: entry.key) : null,
                  child: Text(entry.value)),
            ]),
            const SizedBox(height: 20),
            if (step.action == TutorialAction.next)
              FilledButton(key: const ValueKey('tutorial-next'), onPressed: saving || error != null ? null : () => act(revision, TutorialAction.next),
                child: Text(step.id == 'return_shop'
                    ? widget.replay ? '연습 마치기' : '연습 마치고 로빈에게 건네기'
                    : '설명 읽고 계속')),
            if (step.action == TutorialAction.submit)
              FilledButton(key: const ValueKey('tutorial-submit'), onPressed: saving || error != null ? null : () => act(revision, TutorialAction.submit),
                child: const Text('샘플 조합 실험하기')),
            if (error != null) ...[
              Text(error!),
              TextButton(onPressed: saving ? null : persist, child: const Text('연습 기록 저장 다시 시도')),
            ],
            const SizedBox(height: 20),
            const Text('연습 기록', style: TextStyle(fontSize: 18)),
            for (var i = 0; i < session.attempts.length; i++)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(
                '${i + 1}. ${session.attempts[i].guess.map((id) => tutorialSamples[id]).join(' → ')}\n'
                '완벽 ${session.attempts[i].strikes} · 불안정 ${session.attempts[i].balls}',
                key: ValueKey('tutorial-attempt-$i'))),
          ]),
        )),
      )),
    ));
  }
}
