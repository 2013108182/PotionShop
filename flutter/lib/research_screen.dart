import 'ui_art.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'research_session.dart';
import 'research_art.dart';
import 'game_skin.dart';

const _ink = Color(0xff21162e), _panel = Color(0xff30213f), _line = Color(0xff77558d);
const _cream = Color(0xffffe8bb), _gold = Color(0xffddb776), _muted = Color(0xffb9a7cb);
const _green = Color(0xff9adbb6);
const _shortNames = {'web': '거미줄', 'tear': '눈물', 'moon': '달빛', 'salt': '소금', 'mushroom': '버섯', 'petal': '꽃잎'};
class ResearchStudio extends StatefulWidget {
  final Game? game;
  final String potionId;
  final ValueChanged<String>? onGameChanged;
  final Future<bool> Function(String)? persistGame;
  const ResearchStudio({super.key, this.game, this.onGameChanged, this.potionId = 'sight', this.persistGame});
  @override
  State<ResearchStudio> createState() => _ResearchStudioState();
}
class _ResearchStudioState extends State<ResearchStudio> {
  late ResearchSession session;
  final memoController = TextEditingController();
  @override
  void dispose() { memoController.dispose(); super.dispose(); }
  String get storageKey => widget.potionId == 'sight' ? 'potionshop.research.v1' : 'potionshop.research.${widget.potionId}.v2';
  Potion get target => session.target;
  String get completion => widget.potionId == 'sight' ? '시야 물약 완성!' : '${target.name} 완성!';
  SharedPreferences? prefs;
  bool loaded = false, brewing = false, saving = false, saveFailed = false, loadFailed = false;
  bool get blocked => brewing || saving || saveFailed || loadFailed;
  int mobilePanel = 0;
  int reactionPhase = 0;
  int revealed = 0;
  ResearchAttempt? pendingResult;
  static const reactionWords = ['재료가 녹아들고 있어요…', '마법이 서로 반응해요…', '조금만 더… 빛이 모이고 있어요.', '반응을 확인하고 있어요…'];
  String inspecting = '';
  String feedback = '재료의 성질로 후보를 좁히고, 실험으로 순서를 찾아보세요.';
  @override
  void initState() { super.initState(); session = ResearchSession(potionId: widget.potionId); unawaited(load()); }
  Future<void> load() async {
    try {
      if (widget.game != null) {
        final notebook = widget.game!.notebookFor(widget.potionId);
        if (notebook != null) {
          session = ResearchSession.decode(notebook);
        } else if (widget.potionId == 'sight') {
          session.attempts = [...widget.game!.attempts];
          if (session.attempts.isNotEmpty) session.slots = [...session.attempts.last.guess];
        }
      } else {
        prefs = await SharedPreferences.getInstance();
        final saved = prefs!.getString(storageKey);
        if (saved != null) {
          session = ResearchSession.decode(saved);
          if (prefs!.getString('$storageKey.backup') == null &&
              !await prefs!.setString('$storageKey.backup', saved)) {
            throw const FormatException('Notebook backup failed');
          }
        }
      }
      if (session.potionId != widget.potionId) throw const FormatException('Notebook target mismatch');
      if (session.solved) feedback = '$completion 발견한 레시피를 보관하고 있어요.';
      else if (session.attempts.isNotEmpty) feedback = '지난 실험과 미완성 조합을 불러왔어요. 노트를 비교하고 이어서 연구해 보세요.';
    } catch (_) { session = ResearchSession(potionId: widget.potionId); loadFailed = true; feedback = '실험 노트를 불러오지 못했어요. 원본을 보존했어요. 상점으로 돌아가 다시 시도해 주세요.'; }
    if (mounted) setState(() => loaded = true);
  }
  Future<void> save() async {
    if (saving || loadFailed) return;
    final snapshot = session.encode();
    if (mounted) setState(() { saving = true; saveFailed = false; });
    bool success = false;
    try {
      if (widget.game != null) {
        widget.game!.setNotebook(widget.potionId, snapshot);
        if (widget.persistGame != null) {
          success = await widget.persistGame!(feedback);
        } else {
          widget.onGameChanged?.call(feedback);
          success = true;
        }
      } else {
        success = await prefs?.setString(storageKey, snapshot) == true;
      }
    } catch (_) { success = false; }
    if (mounted) setState(() { saving = false; saveFailed = !success; });
  }
  Future<void> editMemo() async {
    final controller = memoController;
    controller.text = session.memo;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, update) => AlertDialog(
        title: const Text('내 메모'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('내가 남긴 표시예요. 실험 결과를 자동으로 판정하지 않아요.'),
          for (final ingredient in ingredients) Row(children: [
            Expanded(child: Text(ingredient.name)),
            DropdownButton<String>(value: session.marks[ingredient.id] ?? '', items: const [
              DropdownMenuItem(value: '', child: Text('표시 없음')),
              DropdownMenuItem(value: 'candidate', child: Text('후보')),
              DropdownMenuItem(value: 'hold', child: Text('보류')),
              DropdownMenuItem(value: 'excluded', child: Text('제외')),
            ], onChanged: (value) => update(() => session.setMark(ingredient.id, value == '' ? null : value))),
          ]),
          TextField(controller: controller, maxLength: 200, minLines: 2, maxLines: 5,
            decoration: const InputDecoration(hintText: '다음에 비교해 볼 조합이나 궁금한 점을 적어보세요.'),
            onChanged: session.setMemo),
        ]))),
        actions: [TextButton(onPressed: () async {
          final accepted = await showDialog<bool>(context: dialogContext, builder: (confirmContext) => AlertDialog(
            title: const Text('내 메모를 지울까요?'), content: const Text('표시와 메모만 지워요. 슬롯과 실험 기록은 유지해요.'),
            actions: [TextButton(onPressed: () => Navigator.pop(confirmContext, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(confirmContext, true), child: const Text('지우기'))]));
          if (accepted == true && dialogContext.mounted) update(() { session.clearMemo(); controller.clear(); });
        }, child: const Text('내 메모 지우기')),
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('완료'))],
      )));
    if (mounted) { setState(() {}); await save(); }
  }
  Future<void> newNotebook() async {
    final restart = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('새 연구 노트를 펼칠까요?'),
      content: const Text('이 연습 노트의 조합과 실험 기록을 비우고 다시 연구합니다. 내 메모와 상점에 등록한 레시피, 물약은 유지돼요.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('새 노트 시작'))],
    ));
    if (restart == true && mounted) {
      setState(() { session = session.freshNotebook(); pendingResult = null; revealed = 0; feedback = '새 노트를 펼쳤어요. 재료의 성질로 후보를 좁혀보세요.'; });
      save();
    }
  }
  Future<void> place(String id, {int? at}) async {
    if (blocked || session.solved) return;
    if (session.marks[id] == 'excluded') {
      final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('제외 표시한 재료예요'), content: const Text('다시 시험해 볼까요?'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('돌아가기')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('넣기'))]));
      if (accepted != true || !mounted || blocked || session.solved) return;
    }
    setState(() { inspecting = id; session.place(id, at: at); mobilePanel = 0; }); save();
  }
  Future<void> experiment() async {
    if (!session.ready || blocked) return;
    final guess = session.slots.cast<String>();
    if (session.attempts.any((a) => List.generate(session.slotCount, (i) => a.guess[i] == guess[i]).every((v) => v))) {
      setState(() => feedback = '이미 실험한 조합이에요. 노트를 비교하고 재료나 순서를 바꿔보세요.'); return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() { brewing = true; reactionPhase = 0; revealed = 0; pendingResult = null; });
    // Delay the actual commit until the reaction has played; navigation cannot duplicate rewards.
    for (var phase = 0; phase < 3; phase++) {
      if (!mounted) return;
      setState(() => reactionPhase = phase);
      await Future<void>.delayed(Duration(milliseconds: reduce ? 10 : [700, 950, 800][phase]));
    }
    if (!mounted) return;
    // Preview aggregate clues only: a token must never identify a correct ingredient position.
    pendingResult = scoreRecipe(session.slots.cast<String>(), target.recipe);
    setState(() => reactionPhase = 3);
    for (var count = 1; count <= session.slotCount; count++) {
      await Future<void>.delayed(Duration(milliseconds: reduce ? 10 : 380));
      if (!mounted) return;
      setState(() => revealed = count);
    }
    if (!mounted) return;
    final result = session.submit();
    setState(() {
      brewing = false;
      feedback = result!.strikes == session.slotCount ? '$completion 이 조합을 레시피로 기록했어요.'
          : '${result.strikes} 완벽 · ${result.balls} 불안정. 조합을 남겨뒀어요. 한 칸씩 바꿔보세요.';
    });
    final game = widget.game;
    if (game != null) {
      if (widget.potionId == 'sight') game.attempts = [...session.attempts];
      if (session.solved) game.discoverRecipe(widget.potionId);
    }
    save();
  }
  Widget frame(Widget child, {bool paper = false}) => SkinPanel(skin: paper ? Skin.parchment : Skin.dialogue,
    child: Padding(padding: const EdgeInsets.all(18), child: child));
  Widget heading(String eyebrow, String title, {bool paper = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(eyebrow, style: TextStyle(color: paper ? const Color(0xff8b6745) : _muted, fontSize: 10, letterSpacing: 1.8)),
    Text(title, style: TextStyle(color: paper ? _ink : _cream, fontSize: 19, fontWeight: FontWeight.bold)),
  ]);
  Widget mark(String id, {double size = 28}) => researchIngredientOrder.contains(id) ? IngredientSprite(id: id, size: size) : GameIcon(GameGlyph.herbs, size: size);
  Widget shelf(bool compact) => frame(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (!compact) heading('재료의 성질', '재료 선반') else const Text('재료 선반 · 칸을 고른 뒤 재료를 눌러요', style: TextStyle(color: _cream, fontSize: 12)),
    const SizedBox(height: 8),
    GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,
      mainAxisSpacing: 7, crossAxisSpacing: 7, mainAxisExtent: compact ? 50 : 116, childAspectRatio: .95),
      children: [for (final i in ingredients) Draggable<String>(data: i.id,
        maxSimultaneousDrags: blocked || session.solved ? 0 : 1,
        feedback: Material(color: _panel, child: Padding(padding: const EdgeInsets.all(12), child: mark(i.id, size: 36))),
        child: Tooltip(message: i.lore, child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(4), foregroundColor: _cream,
            backgroundColor: session.slots.contains(i.id) ? const Color(0xff513767) : const Color(0xff261a35),
            shape: const RoundedRectangleBorder(), side: BorderSide(color: session.slots.contains(i.id) ? _gold : _line, width: 2)),
          onPressed: blocked || session.solved ? null : () => place(i.id),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            mark(i.id, size: compact ? 24 : 64), Text(i.name, style: TextStyle(fontSize: compact ? 11 : 14)),
            if (!compact) Text(session.slots.contains(i.id) ? '${session.slots.indexOf(i.id) + 1}번째 칸' : '선택', style: const TextStyle(color: _muted, fontSize: 10)),
          ])),
        )),
      ]),
    const SizedBox(height: 8),

    Text(inspecting.isEmpty ? '재료를 살펴보면 성질을 읽을 수 있어요.' : '${ingredientName(inspecting)} · ${ingredients.firstWhere((i) => i.id == inspecting).lore}',
      maxLines: compact ? 2 : 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: compact ? 12 : 15)),
    TextButton(onPressed: blocked ? null : editMemo, child: const Text('내 메모 · 후보 표시')),
    if (!compact) const Text('재료 성질로 후보를 좁혀보세요. 넣는 순서는 실험 결과로 알아내요.', style: TextStyle(color: _gold, fontSize: 12)),
  ]));
  Widget slot(int index, bool compact) {
    final id = session.slots[index];
    final selected = session.activeSlot == index;
    return Expanded(child: DragTarget<String>(onWillAcceptWithDetails: (_) => !blocked && !session.solved,
      onAcceptWithDetails: (detail) => place(detail.data, at: index),
      builder: (context, candidates, rejected) => Container(
        decoration: BoxDecoration(color: selected || candidates.isNotEmpty ? const Color(0xff54375f) : const Color(0xff24172f),
          border: Border.all(color: selected || candidates.isNotEmpty ? _gold : _line, width: 2)),
        child: Stack(children: [
          SizedBox(height: compact ? 76 : 110, width: double.infinity, child: TextButton(
            onPressed: blocked || session.solved ? null : () { setState(() { session.selectSlot(index); mobilePanel = 1; }); save(); },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${index + 1}번째 칸', style: const TextStyle(color: _muted, fontSize: 10)),
              if (id != null) mark(id, size: compact ? 26 : 50) else GameIcon(GameGlyph.herbs, size: compact ? 20 : 32),
              Text(id != null ? (_shortNames[id] ?? ingredientName(id)) : '선택하기', style: const TextStyle(color: _cream, fontSize: 11)),
            ]))),
          if (id != null && !session.solved) Positioned(top: 0, right: 0, child: SizedBox(width: 26, height: 26, child: IconButton(
            padding: EdgeInsets.zero, iconSize: 13, tooltip: '${index + 1}번째 칸 비우기',
            onPressed: blocked ? null : () { setState(() => session.clearSlot(index)); save(); }, icon: const GameIcon(GameGlyph.close, size: 20)))),
        ]))));
  }
  Widget bench(bool compact) => frame(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (!compact) ...[heading('넣는 순서', '조합 작업대'), const SizedBox(height: 14)],
    Row(children: [for (var i = 0; i < session.slotCount; i++) ...[if (i > 0) const SizedBox(width: 8), slot(i, compact)]]),
    const SizedBox(height: 6),
    Text(session.solved ? '발견한 순서를 레시피로 보관했어요.' : '${session.activeSlot + 1}번째 칸 선택 중 · 이미 넣은 재료를 누르면 두 칸이 바뀌어요.',
      textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: compact ? 9 : 11)),
    if (!compact) Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360, maxHeight: 300),
      child: ResearchCauldron(brewing: brewing, solved: session.solved, phase: reactionPhase))))
    else SizedBox(height: 82, child: ResearchCauldron(brewing: brewing, solved: session.solved, phase: reactionPhase)),
    const SizedBox(height: 6),
    Semantics(liveRegion: true, child: Text(brewing ? reactionWords[reactionPhase] : feedback,
      textAlign: TextAlign.center, maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis,
      style: TextStyle(color: session.solved ? _green : _cream, fontSize: compact ? 12 : 15))),
    const SizedBox(height: 8),
    if (brewing || pendingResult != null) ...[
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < session.slotCount; i++) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8), child: AnimatedSwitcher(duration: const Duration(milliseconds: 180),
          child: Text(i >= revealed ? '◇' : i < pendingResult!.strikes ? '✦' : i < pendingResult!.strikes + pendingResult!.balls ? '◐' : '—',
            key: ValueKey('$i-${i < revealed}'), style: TextStyle(fontSize: 26, color: i < revealed ? _gold : _muted))))]),
      const Text('반응 개수 · 각 재료의 정답 위치를 뜻하지 않아요', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10)),
    ],
    SizedBox(height: compact ? 38 : 48, child: FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _ink, shape: const RoundedRectangleBorder()),
      onPressed: session.ready && !blocked ? experiment : null,
      icon: GameIcon(session.solved ? GameGlyph.next : GameGlyph.flask, size: 24),
      label: Text(session.solved ? '레시피 발견 완료' : brewing ? '실험 중…' : '조합 실험하기', style: const TextStyle(fontWeight: FontWeight.bold)))),
    if (!session.solved) TextButton(onPressed: blocked ? null : () { setState(session.clearSlots); save(); }, child: const Text('슬롯 비우기')),
    if (session.solved) TextButton(onPressed: blocked ? null : () => widget.game != null ? Navigator.pop(context) : Navigator.pushNamed(context, '/shop'),
      child: const Text('상점으로 돌아가기', style: TextStyle(color: _gold))),
  ]));
  Widget notes(bool compact) => frame(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (!compact) heading('지난 실험', '실험 노트', paper: true)
    else Text('실험 노트 · ${session.attempts.length}회', style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.bold)),
    const SizedBox(height: 6),
    TextButton(onPressed: blocked ? null : editMemo, child: const Text('내 메모 · 후보 표시')),
    const Text('완벽: 재료·순서 일치\n불안정: 재료만 일치', style: TextStyle(color: Color(0xff77563f), fontSize: 11)),
    const SizedBox(height: 8),
    Expanded(child: session.attempts.isEmpty ? const Center(child: Text('첫 조합을 실험해 보세요.\n결과를 비교하며 다음 추측을 만들어요.', textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xff86684f), fontSize: 12))) : ListView.separated(
      itemCount: session.attempts.length, separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final number = session.attempts.length - index;
        final a = session.attempts[number - 1];
        return OutlinedButton(
          style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(9),
            foregroundColor: _ink, disabledForegroundColor: _ink, backgroundColor: const Color(0xfffff2d8),
            side: BorderSide(color: index == 0 ? const Color(0xffb48852) : const Color(0xffd9c5a2), width: index == 0 ? 2 : 1), shape: const RoundedRectangleBorder()),
          onPressed: session.solved || blocked ? null : () { setState(() { session.reuse(a); mobilePanel = 0; feedback = '$number회 조합을 작업대에 놓았어요. 칸을 골라 수정해 보세요.'; }); save(); },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Text('$number', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8),
              for (final id in a.guess) Expanded(child: Column(children: [mark(id, size: compact ? 18 : 23), Text((_shortNames[id] ?? ingredientName(id)), style: const TextStyle(fontSize: 10))])),
              if (!session.solved) const GameIcon(GameGlyph.back, size: 18),
            ]), const SizedBox(height: 6),
            Text('${a.strikes} 완벽 · ${a.balls} 불안정${session.solved ? '' : '  · 눌러서 다시 놓기'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ]));
      })),
  ]), paper: true);
  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(backgroundColor: _ink, body: Center(child: CircularProgressIndicator()));
    return PopScope(canPop: loadFailed || !blocked, child: CallbackShortcuts(bindings: {
      const SingleActivator(LogicalKeyboardKey.digit1): () { if (!blocked) { setState(() => session.selectSlot(0)); save(); } },
      const SingleActivator(LogicalKeyboardKey.digit2): () { if (!blocked) { setState(() => session.selectSlot(1)); save(); } },
      const SingleActivator(LogicalKeyboardKey.digit3): () { if (!blocked) { setState(() => session.selectSlot(2)); save(); } },
      const SingleActivator(LogicalKeyboardKey.enter): experiment,
    }, child: Focus(autofocus: true, child: Scaffold(backgroundColor: _ink, body: SafeArea(child: LayoutBuilder(builder: (context, size) {

      const padding = 10.0;
      final wide = size.maxWidth >= 1050;
      final mobileBenchHeight = 454.0;
      return Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xff281b38), Color(0xff171020)])), child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 1380 : 760, maxHeight: wide ? 820 : double.infinity),
        child: Padding(padding: EdgeInsets.all(padding), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (saveFailed) Row(children: [const Expanded(child: Text('저장하지 못했어요. 다시 저장한 뒤 계속해요.', style: TextStyle(color: _cream))), TextButton(onPressed: save, child: const Text('저장 다시 시도'))]),
          Row(children: [const GameIcon(GameGlyph.flask, size: 24), const SizedBox(width: 8),
            const Expanded(child: Text('달빛 연구실', style: TextStyle(color: _cream, fontSize: 20, fontWeight: FontWeight.bold))),
            if (widget.game == null && session.solved) TextButton(onPressed: blocked ? null : newNotebook,
              child: const Text('새 연구', style: TextStyle(color: _gold, fontSize: 12))),
            TextButton(onPressed: !loadFailed && blocked ? null : () => widget.game != null ? Navigator.pop(context) : Navigator.pushNamed(context, '/shop'),
              child: const Text('상점으로', style: TextStyle(color: _muted))),
          ]),
          Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), margin: const EdgeInsets.only(top: 6, bottom: 12),
            decoration: BoxDecoration(color: const Color(0xff3b2b4d), border: Border(left: BorderSide(color: _gold, width: 3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.potionId == 'sight' ? '엘리의 부탁 · 어둠 속 시야' : target.name, style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(widget.potionId == 'sight' ? '“횃불 없이도 밤 숲길을 보고 싶어요.”  서로 다른 재료 3개와 넣는 순서를 찾아주세요.' : '${target.description} 서로 다른 재료 3개와 순서를 찾아보세요.', style: TextStyle(color: _cream, fontSize: 11)),
              if (target.useLimit.isNotEmpty) Text(target.useLimit, style: const TextStyle(color: _muted, fontSize: 10)),
            ])),
          Expanded(child: LayoutBuilder(builder: (context, area) {
            if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: SingleChildScrollView(child: shelf(false))), const SizedBox(width: 14),
              Expanded(flex: 4, child: bench(false)), const SizedBox(width: 14),
              Expanded(flex: 3, child: notes(false)),
            ]);
            return Column(children: [Row(children: [for (var i = 0; i < 3; i++) Expanded(child: TextButton(
              onPressed: () => setState(() => mobilePanel = i), style: TextButton.styleFrom(minimumSize: const Size(0, 52),
                foregroundColor: mobilePanel == i ? _gold : _muted, backgroundColor: mobilePanel == i ? _panel : Colors.transparent),
              child: Text(['조합', '재료', '기록'][i])))]), const SizedBox(height: 8),
              Expanded(child: IndexedStack(index: mobilePanel, children: [
                SingleChildScrollView(child: SizedBox(height: mobileBenchHeight, child: bench(true))),
                SingleChildScrollView(child: shelf(true)),
                notes(true),
              ])),
            ]);
          })),
          Padding(padding: const EdgeInsets.only(top: 10), child: Text('자유 연구 · 재료 소모와 날짜 제한 없음',
            textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 10))),
        ])))));
    }))))));
  }
}
