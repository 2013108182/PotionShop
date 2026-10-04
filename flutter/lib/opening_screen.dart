import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'research_screen.dart';
import 'shop_world.dart';
import 'game_skin.dart';
import 'shop_tasks.dart';
import 'tutorial_session.dart';
import 'tutorial_screen.dart';

const openingSaveKey = 'potionshop.opening.v1';
const storySaveKey = 'potionshop.story.v1';
const _cream = Color(0xffffe7bb), _gold = Color(0xffe9b568);

typedef _Beat = ({String title, String speaker, String text, String hint, String action});
const _beats = <_Beat>[
  (title: '당신의 작은 물약 상점', speaker: '스승이 남긴 편지',
    text: '오늘부터 이 가게의 주인은 너란다.\n\n진열대에 숙면 물약 세 병을 준비해 두었어. 먼저 문을 열고, 손님 한 명의 이야기를 들어보렴.',
    hint: '당신은 이 상점을 물려받은 새 약사입니다.', action: '상점 문 열기'),
  (title: '첫 손님이 들어왔어요', speaker: '약초 상인 로빈',
    text: '새 주인분이시군요!\n요즘 잠을 통 못 자겠어요. 오늘은 푹 잘 수 있는 약이 있을까요?',
    hint: '진열대의 숙면 물약 한 병을 건네보세요.', action: '숙면 물약 한 병 건네기 · 35 G'),
  (title: '첫 물약을 팔았어요', speaker: '약초 상인 로빈',
    text: '고마워요. 오늘 밤은 편안히 잘 수 있겠네요.\n다음에는 제가 재료도 가져올게요!',
    hint: '물약 한 병이 손님에게 가고, 35 G가 들어왔어요.', action: '다음 손님 맞이하기'),
  (title: '또 다른 손님의 부탁', speaker: '제빵사 미나',
    text: '내일 새벽에 빵을 구워야 해요.\n남은 숙면 물약이 있다면 저도 한 병 주세요.',
    hint: '손님의 부탁을 듣고 어울리는 약을 건네는 것이 영업이에요.', action: '숙면 물약 한 병 건네기 · 35 G'),
  (title: '조금 익숙해진 첫 영업', speaker: '제빵사 미나',
    text: '덕분에 내일도 따끈한 빵을 구울 수 있겠어요.\n새 가게가 생겨서 기뻐요!',
    hint: '숙면 물약은 한 병 남았어요. 문밖에 누군가 기다리고 있어요.', action: '문밖의 손님 맞이하기'),
  (title: '진열대에 없는 물약', speaker: '숲길 안내인 엘리',
    text: '밤마다 숲길을 안내하는데, 횃불이 꺼지면 길이 보이지 않아요.\n\n어둠 속에서도 볼 수 있는 물약은 없나요?',
    hint: '숙면 물약은 잠을 돕는 약이에요. 엘리에게는 새로운 약이 필요해요.', action: '새 물약을 만들어 보기로 약속하기'),
  (title: '오늘 밤 연구할 이유', speaker: '숲길 안내인 엘리',
    text: '정말 만들어 주실 수 있나요?\n그럼 내일 다시 들를게요. 그 약이 있으면 혼자 밤길을 걷는 사람도 도울 수 있어요.',
    hint: '오늘의 목표가 생겼어요: 엘리를 위한 시야 물약 만들기.', action: '문을 닫고 촛불 켜기'),
  (title: '손님의 부탁을 연구로', speaker: '당신의 연구 수첩',
    text: '가게가 조용해졌습니다.\n\n완성된 약을 파는 일에서, 아직 없는 약을 만드는 일로. 오늘 밤에는 엘리의 부탁을 풀어봅니다.',
    hint: '연구실에는 실험용 재료와 작은 가마솥이 있어요.', action: '낡은 연구 메모 읽기'),
  (title: '첫 실험을 위한 단서', speaker: '스승의 연구 메모',
    text: '재료의 성질을 읽고, 물약에 어울리는 세 가지를 골라보렴.\n\n어두운 길을 보려면 빛과 감각에 관련된 성질을 살펴보면 좋겠구나. 넣는 순서는 네 실험 기록에서 찾아보렴.',
    hint: '이번에는 자유 연구예요. 첫 시도에 발견해도 좋고, 무료로 다시 실험해도 좋아요.', action: '엘리의 시야 물약 연구 시작'),
  (title: '이어지는 밤의 연구', speaker: '엘리의 부탁',
    text: '횃불 없이도 밤 숲길을 볼 수 있는 물약.\n\n작업대의 조합과 실험 노트는 남아 있어요. 기록을 비교하며 다음 순서를 찾아보세요.',
    hint: '완벽은 재료와 순서 일치, 불안정은 재료만 일치한 개수예요.', action: '하던 연구 이어가기'),
  (title: '처음 만든 새로운 물약', speaker: '당신의 연구 수첩',
    text: '올빼미의 시야 물약을 발견했습니다.\n\n레시피를 기록하고, 방금 만든 한 병은 엘리를 위해 남겨두었습니다.',
    hint: '내일은 이 물약을 부탁한 사람에게 직접 건네보세요.', action: '다음 날, 엘리 맞이하기'),
  (title: '약속을 지킬 시간', speaker: '숲길 안내인 엘리',
    text: '좋은 아침이에요!\n어제 부탁한 밤눈 물약, 혹시 만드셨나요?',
    hint: '어젯밤 만든 물약 한 병이 준비되어 있어요.', action: '시야 물약 한 병 건네기 · 38 G'),
  (title: '당신의 약이 바꾸는 하루', speaker: '숲길 안내인 엘리',
    text: '작은 글씨까지 훨씬 또렷하게 보여요!\n오늘 밤은 횃불이 꺼져도 길을 찾을 수 있겠어요.\n\n밤 배달을 시작한 친구에게도 이 가게를 알려줄게요.',
    hint: '새 레시피가 생겼고, 다시 찾아올 손님도 생겼어요.', action: '상점 영업 이어가기'),
];

class OpeningJourney extends StatefulWidget {
  final Widget Function() onFinished;
  const OpeningJourney({super.key, required this.onFinished});
  @override
  State<OpeningJourney> createState() => _OpeningJourneyState();
}
class _OpeningJourneyState extends State<OpeningJourney> {
  Game game = Game();
  int stage = 0;
  bool loaded = false, busy = false, customerReady = false;
  bool loadFailed = false, dirty = false;
  int saveRevision = 0;
  SharedPreferences? prefs;
  Future<void> saveQueue = Future.value();
  String? error, customerReply;
  @override
  void initState() { super.initState(); unawaited(load()); }
  Future<void> load() async {
    try {
      prefs = await SharedPreferences.getInstance();
      await prefs!.reload();
      final saved = prefs!.getString(openingSaveKey);
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        final step = data['stage'];
        if (step is! int || step < 0 || step > 13) throw const FormatException('Invalid opening');
        final restored = Game.decode(data['game'] as String);
        TutorialSession.fromJson(restored.tutorialProgress);
        final version = (jsonDecode(data['game'] as String) as Map<String, dynamic>)['version'];
        if (version == 2 && !prefs!.containsKey('$openingSaveKey.backup.v2')) {
          if (!await prefs!.setString('$openingSaveKey.backup.v2', saved)) {
            throw StateError('Opening migration backup failed');
          }
        }
        game = restored; stage = step; customerReply = data['customerReply'] as String?;
      }
      if (stage == 9 && game.knows('sight')) stage = 10;
      loadFailed = false; error = null;
    } catch (_) {
      loadFailed = true;
      error = '도입부 기록을 읽지 못했어요. 원본 기록은 그대로 보관하고 있어요. 다시 불러와 주세요.';
    }
    if (mounted) setState(() => loaded = true);
  }
  Future<bool> save() {
    if (loadFailed) return Future.value(false);
    final snapshot = jsonEncode({'stage': stage, 'game': game.encode(), 'customerReply': customerReply});
    final revision = ++saveRevision;
    dirty = true;
    var stored = false;
    saveQueue = saveQueue.then((_) async {
      try {
        if (await prefs?.setString(openingSaveKey, snapshot) != true) {
          throw StateError('Save failed');
        }
        stored = true;
        if (mounted && revision == saveRevision) setState(() { dirty = false; error = null; });
      } catch (_) {
        if (mounted && revision == saveRevision) setState(() => error = '기록을 저장하지 못했어요. 현재 진행은 유지됩니다. 저장을 다시 시도해 주세요.');
      }
    });
    return saveQueue.then((_) => stored);
  }
  Future<bool> practiceBeforeSale() async {
    final session = TutorialSession.fromJson(game.tutorialProgress);
    if (session.satisfied) return true;
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TutorialScreen(
      session: session, onChanged: (snapshot) async {
        game.tutorialProgress = snapshot;
        if (!await save()) throw StateError('Tutorial save failed');
      })));
    if (!mounted) return false;
    return session.satisfied && !dirty;
  }
  Future<void> openResearch() async {
    if (loadFailed || dirty) return;
    setState(() { stage = 9; busy = true; });
    if (!await save()) {
      if (mounted) setState(() => busy = false);
      return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ResearchStudio(game: game, persistGame: (_) => save())));
    if (!mounted) return;
    setState(() { stage = game.knows('sight') ? 10 : 9; busy = false; }); await save();
  }
  Future<void> advance() async {
    if (loadFailed || dirty || busy || ({1, 3, 5, 11}.contains(stage) && !customerReady)) return;
    setState(() => busy = true);
    if (stage == 1 && !await practiceBeforeSale()) {
      if (mounted) setState(() => busy = false);
      return;
    }
    if (!mounted) return;
    if (stage == 8 || stage == 9) { await openResearch(); return; }
    if (stage == 1 || stage == 3) {
      final result = game.sell('sleep');
      if (result != null) { setState(() { error = result; busy = false; }); return; }
    } else if (stage == 5) { game.skipCustomer(); }
    else if (stage == 6) { game.startNight(); }
    else if (stage == 10) { game.nextDay(); }
    else if (stage == 11) { game.sell('sight'); }
    else if (stage == 12) {
      // The guided story has its own save; older shop and research saves remain usable.
      await saveQueue;
      try {
        if (await prefs?.setString(storySaveKey, game.encode()) != true) throw StateError('Save failed');
      } catch (_) {
        if (mounted) setState(() { error = '영업 기록을 저장하지 못했어요. 다시 시도해 주세요.'; busy = false; });
        return;
      }
    }
    if (!mounted) return;
    setState(() { stage++; error = null; customerReply = null; customerReady = false; }); await save();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) setState(() => busy = false);
  }
  bool get hasCustomer => {1, 2, 3, 4, 5, 6, 11, 12}.contains(stage);
  Widget savedActions(Widget child) => AbsorbPointer(absorbing: dirty || busy,
    child: ExcludeFocus(excluding: dirty || busy, child: child));
  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (loadFailed) return Scaffold(appBar: AppBar(title: const Text('기록 불러오기')),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error!), const SizedBox(height: 16),
        FilledButton(onPressed: () async {
          setState(() => loaded = false);
          await load();
        }, child: const Text('기록 다시 불러오기')),
      ]))));
    if (stage == 13) {
      if (!busy && !dirty) return widget.onFinished();
      return PopScope(canPop: false, child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('영업 기록 저장')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(busy ? '이야기의 마지막 기록을 저장하고 있어요.' : error ?? '기록 저장을 마쳐 주세요.'),
          const SizedBox(height: 16),
          if (busy) const CircularProgressIndicator()
          else FilledButton(onPressed: () async {
            setState(() => busy = true);
            await save();
            if (mounted) setState(() => busy = false);
          }, child: const Text('진행 기록 저장 다시 시도')),
        ]))),
      ));
    }
    final beat = _beats[stage];
    final waiting = {1, 3, 5, 11}.contains(stage) && !customerReady;
    return PopScope(canPop: !busy && !dirty, child: ShopViewport(systemMessage: error ?? (hasCustomer ? '' : beat.hint),
      dialogueAction: {1, 3, 11}.contains(stage) ? '물약 고르기' : beat.action,
      onDialogueAction: {1, 3, 11}.contains(stage) ? null : () { if (!busy) advance(); },
      waiting: waiting,
      workbench: savedActions(ShopTasks(game: game, management: false, canResearch: stage == 8 || stage == 9, onResearch: openResearch,
        onChanged: (message) { setState(() => error = message); unawaited(save()); })),
      management: savedActions(ShopTasks(game: game, management: true, canResearch: false, onResearch: openResearch,
        onChanged: (message) { setState(() => error = message); unawaited(save()); })),
      speakerName: {1, 2, 3, 4, 5, 6, 11, 12}.contains(stage) ? beat.speaker : null,
      dayLabel: '${game.day}일째 · ${game.night ? '밤 연구와 준비' : '낮 영업'}',
      goldLabel: '${game.gold} G',
      stockLabel: stage >= 10 ? '시야 물약 ${game.stock['sight']}병' : '숙면 물약 ${game.stock['sleep']}병',
      world: ShopWorld(customerId: hasCustomer ? 'opening-${{2: 1, 4: 3, 6: 5, 12: 11}[stage] ?? stage}' : null,
        speech: hasCustomer ? customerReply ?? beat.text.replaceAll('\n\n', ' ') : null,
        customerName: hasCustomer ? beat.speaker : '', night: game.night,
        bottles: game.stock['sleep']!,
        onReady: (value) { if (mounted) setState(() => customerReady = value); }),
      dialogue: LayoutBuilder(builder: (context, constraints) {

        final words = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (dirty) TextButton(onPressed: busy ? null : save, child: const Text('진행 기록 저장 다시 시도')),
          if (stage == 1 && !TutorialSession.fromJson(game.tutorialProgress).satisfied)
            const Text('첫 판매 전에 스승의 숙면 제조법으로 실험 기록 읽는 법을 연습해요.'),
          Text(hasCustomer ? beat.speaker : beat.title, style: const TextStyle(color: _gold, fontSize: 18)),
          const SizedBox(height: 12),
          GameParagraph(beat.text.replaceAll('\n\n', '\n'),
            style: const TextStyle(color: _cream, fontSize: 15, height: 1.5)),
        ]);
        final action = Tooltip(message: beat.action, child: GameAction(onPressed: busy || dirty || waiting ? null : advance,
          label: waiting ? '손님이 오는 중…' : beat.action.contains('한 병 건네기') ? '물약 건네기' : beat.action));
        if ({1, 3, 11}.contains(stage)) return PotionSelection(order: words, key: ValueKey(stage), game: game, enabled: !busy && !dirty && !waiting, onGive: (id) {
            if (busy || dirty) return;
            if (id != (stage == 11 ? 'sight' : 'sleep')) {
              final previous = game.customer;
              final reply = game.sell(id);
              setState(() {
                customerReply = reply;
                if (game.customer != previous) { stage++; error = '손님이 구매하지 않고 떠났어요 · 놓친 주문 +1'; }
              });
              unawaited(save()); return;
            }
            advance();
          });
        return Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [words, const SizedBox(height: 24), Align(alignment: Alignment.centerRight, child: action)]));
      }),
    ));
  }
}
