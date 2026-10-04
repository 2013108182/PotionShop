import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'game_skin.dart';
import 'opening_screen.dart';
import 'shop_world.dart';
import 'ui_art.dart';

class TitleScreen extends StatefulWidget {
  final Widget Function() opening;
  final Widget Function(String key) shop;
  const TitleScreen({super.key, required this.opening, required this.shop});
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool loading = true, busy = false;
  String? destination, error;
  Game? savedGame;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      String? target;
      Game? game;
      final opening = prefs.getString(openingSaveKey);
      if (opening != null) {
        final data = jsonDecode(opening) as Map<String, dynamic>;
        final stage = data['stage'];
        if (stage is! int || stage < 0 || stage > 13) throw const FormatException();
        if (stage < 13) { target = openingSaveKey; game = Game.decode(data['game'] as String); }
        else { target = storySaveKey; game = Game.decode(prefs.getString(storySaveKey)!); }
      } else {
        for (final key in [storySaveKey, 'potionshop.v2']) {
          final data = prefs.getString(key);
          if (data != null) { target = key; game = Game.decode(data); break; }
        }
      }
      if (mounted) setState(() { destination = target; savedGame = game; loading = false; error = null; });
    } catch (_) {
      if (mounted) setState(() { loading = false; destination = null; error = '저장 기록을 읽지 못했어요. 새로 시작할 수 있습니다.'; });
    }
  }
  Future<void> enter(String key) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => key == openingSaveKey ? widget.opening() : widget.shop(key)));
    if (mounted) { await load(); if (mounted) setState(() => busy = false); }
  }
  Future<void> startNew() async {
    if (busy) return;
    if (destination != null || error != null) {
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: SkinPanel(skin: Skin.dialogue,
          child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('새로운 이야기를 시작할까요?', style: TextStyle(color: worldGold, fontSize: 20)),
            const SizedBox(height: 16), const Text('현재 이어하기 기록을 새 이야기로 바꿉니다.'),
            const SizedBox(height: 24), GameAction(label: '새로 시작하기', onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 8), GameAction(label: '돌아가기', onPressed: () => Navigator.pop(ctx, false)),
          ]))))));
      if (confirmed != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(openingSaveKey, jsonEncode({'stage': 0, 'game': Game().encode()}));
      if (!ok) throw StateError('Save failed');
      if (mounted) await enter(openingSaveKey);
    } catch (_) {
      if (mounted) setState(() { busy = false; error = '새 기록을 저장하지 못했어요. 다시 시도해 주세요.'; });
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: worldInk, body: Stack(children: [
    Positioned.fill(child: ExcludeSemantics(child: IgnorePointer(child: ShopWorld(night: true, level: 2, bottles: 5)))),
    const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xd9160e24), Color(0x99160e24), Color(0xf0160e24)])))),
    SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const GameIcon(GameGlyph.moon, size: 44), const SizedBox(height: 18),
        const Text('달빛 물약 상점', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xffffdfab), fontSize: 34, height: 1.4, shadows: [Shadow(color: Color(0xff382037), offset: Offset(3, 4))])),
        const SizedBox(height: 12), const Text('작은 가게에서 피어나는 마법 같은 하루', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xffcab5cd), fontSize: 13)),
        const SizedBox(height: 44),
        SizedBox(width: 280, child: GameAction(label: '이어하기', onPressed: loading || busy || destination == null ? null : () {
          setState(() => busy = true); enter(destination!);
        })),
        const SizedBox(height: 10),
        Text(loading ? '기록을 확인하고 있어요…' : savedGame != null
          ? '${savedGame!.day}일째 · ${savedGame!.night ? '밤' : '낮'} · ${savedGame!.gold} G' : '아직 저장된 이야기가 없어요.',
          textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffcab5cd), fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(width: 280, child: GameAction(label: '새로 시작', onPressed: loading || busy ? null : startNew)),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, textAlign: TextAlign.center)),
      ]))))),
  ]));
}
