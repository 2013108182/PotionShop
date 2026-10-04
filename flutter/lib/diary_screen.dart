import 'package:flutter/material.dart';
import 'game.dart';
import 'tutorial_screen.dart';
import 'tutorial_session.dart';

/// Only witnessed records are rendered; unread and future story state are separate.
class DiaryScreen extends StatefulWidget {
  final Game game;
  final VoidCallback onChanged;
  final Future<bool> Function()? onPersist;
  const DiaryScreen({super.key, required this.game, required this.onChanged, this.onPersist});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String? selected;
  bool saving = false, saveFailed = false;
  Future<void> markRead(String id) async {
    if (saving || saveFailed) return;
    setState(() { saving = true; saveFailed = false; });
    widget.game.markDiaryRead(id);
    widget.onChanged();
    var saved = true;
    try { saved = await (widget.onPersist?.call() ?? Future.value(true)); }
    catch (_) { saved = false; }
    if (mounted) setState(() { saving = false; saveFailed = !saved; });
  }
  Future<void> retry() async {
    if (saving || widget.onPersist == null) return;
    setState(() { saving = true; });
    var saved = false;
    try { saved = await widget.onPersist!(); } catch (_) {}
    if (mounted) setState(() { saving = false; saveFailed = !saved; });
  }
  @override
  Widget build(BuildContext context) {
    final known = widget.game.residents.entries.where((entry) => entry.value.met).toList();
    final id = (known.any((entry) => entry.key == selected) ? selected : known.firstOrNull?.key) ?? '';
    final progress = id.isEmpty ? null : widget.game.residents[id];
    final entries = widget.game.diary.where((entry) => entry.residentId == id).toList().reversed.toList();
    return PopScope(canPop: !saving && !saveFailed, child: Scaffold(
      appBar: AppBar(title: const Text('주민 다이어리')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('직접 듣고 함께한 이야기를 모았어요. 아직 만나지 않은 이웃의 사정은 빈칸으로 남겨 두어요.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(icon: const Icon(Icons.science_outlined),
          label: const Text('실험 기록 읽기 연습'),
          onPressed: saving || saveFailed ? null : () => Navigator.push<bool>(context,
            MaterialPageRoute<bool>(builder: (_) => TutorialScreen(
              session: TutorialSession(), onChanged: (_) async {}, replay: true)))),
        const Text('교육용 샘플로 다시 읽어 봐요. 상점 진행과 보상은 바뀌지 않아요.'),
        const SizedBox(height: 16),
        if (known.isEmpty) const Text('손님을 맞으면 첫 기록이 생겨요.'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final resident in known)
          ChoiceChip(label: Text(_name(resident.key)), selected: resident.key == id,
            onSelected: saving ? null : (_) => setState(() => selected = resident.key))]),
        if (progress != null) ...[
          const SizedBox(height: 20),
          Text('${residentById(id).occupation} ${_name(id)}', style: Theme.of(context).textTheme.headlineSmall),
          Text(progress.trustLabel, key: const ValueKey('resident-trust')),
          const SizedBox(height: 8),
          const Text('도움과 대화로 관계가 깊어져요. 같은 주문이나 기록을 반복해 열 필요는 없어요.'),
          if (progress.knownFactIds.isNotEmpty) ...[
            const SizedBox(height: 16), const Text('알게 된 사실'),
            for (final factId in progress.knownFactIds)
              if (residentById(id).facts[factId] != null) Padding(padding: const EdgeInsets.only(top: 6),
                child: Text(residentById(id).facts[factId]!)),
          ],
          if (progress.pendingReview != null) const Padding(padding: EdgeInsets.only(top: 12),
            child: Text('물약을 건넸어요. 다음 만남에서 사용 후기를 들어보세요.')),
          if (entries.isEmpty) const Padding(padding: EdgeInsets.only(top: 20), child: Text('아직 남긴 이야기가 없어요.')),
          for (final entry in entries) Card(child: Padding(padding: const EdgeInsets.all(16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${entry.day}일째 · ${_kind(entry.kind)}${entry.read ? '' : ' · 새 기록'}', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6), Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8), Text(entry.text),
              if (!entry.read) Align(alignment: Alignment.centerRight, child: TextButton(
                onPressed: saving || saveFailed ? null : () => markRead(entry.id), child: const Text('읽음 표시'))),
            ]))),
        ],
        if (saving) const Padding(padding: EdgeInsets.all(12), child: Text('기록을 저장하고 있어요.')),
        if (saveFailed) ...[
          const Text('읽음 표시를 아직 저장하지 못했어요. 기록 내용과 관계는 그대로예요.'),
          TextButton(onPressed: retry, child: const Text('저장 다시 시도')),
        ],
      ])),
    ));
  }
  String _name(String id) => residentById(id).name;
  String _kind(String kind) => const {'fact': '알게 된 사실', 'request': '부탁 기록', 'quest': '부탁 기록',
    'promise': '약속', 'review': '사용 후기', 'story': '함께한 이야기', 'gift': '받은 선물',
    'introduction': '새로운 이웃', 'completed': '끝낸 도움'}[kind] ?? '이웃의 기록';
}
