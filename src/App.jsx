import React, { useState, useEffect, useRef } from 'react';
import { 
  RotateCcw, FlaskConical, Sparkles, AlertCircle, Flame, 
  Store, Coins, Star, Users, ArrowRight, BookOpen,
  Search, Eye, ShoppingBag, X, PackageOpen, Target,
  ScrollText, CheckCircle2, XCircle, Info, Save, Lock,
  Volume2, VolumeX
} from 'lucide-react';

// --- 오디오 유틸리티 (웹 오디오 API 기반 8비트 사운드) ---
let audioCtx = null;
const playSound = (type) => {
  try {
    if (!window.AudioContext && !window.webkitAudioContext) return;
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    const now = audioCtx.currentTime;

    if (type === 'click') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, now);
      osc.frequency.exponentialRampToValueAtTime(300, now + 0.1);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.1);
      osc.start(now);
      osc.stop(now + 0.1);
    } else if (type === 'pop') {
      osc.type = 'square';
      osc.frequency.setValueAtTime(400, now);
      osc.frequency.exponentialRampToValueAtTime(600, now + 0.05);
      gain.gain.setValueAtTime(0.05, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.05);
      osc.start(now);
      osc.stop(now + 0.05);
    } else if (type === 'coin') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1000, now);
      osc.frequency.setValueAtTime(1500, now + 0.05);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.linearRampToValueAtTime(0.01, now + 0.2);
      osc.start(now);
      osc.stop(now + 0.2);
    } else if (type === 'success') {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(400, now);
      osc.frequency.setValueAtTime(500, now + 0.1);
      osc.frequency.setValueAtTime(600, now + 0.2);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.linearRampToValueAtTime(0.01, now + 0.5);
      osc.start(now);
      osc.stop(now + 0.5);
    } else if (type === 'fail') {
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(300, now);
      osc.frequency.linearRampToValueAtTime(150, now + 0.3);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.linearRampToValueAtTime(0.01, now + 0.4);
      osc.start(now);
      osc.stop(now + 0.4);
    } else if (type === 'bubble') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.linearRampToValueAtTime(300, now + 0.1);
      osc.frequency.linearRampToValueAtTime(200, now + 0.2);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.linearRampToValueAtTime(0.01, now + 0.3);
      osc.start(now);
      osc.stop(now + 0.3);
    } else if (type === 'magic') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.linearRampToValueAtTime(1200, now + 0.1);
      osc.frequency.linearRampToValueAtTime(1600, now + 0.2);
      gain.gain.setValueAtTime(0.05, now);
      gain.gain.linearRampToValueAtTime(0.01, now + 0.4);
      osc.start(now);
      osc.stop(now + 0.4);
    } else if (type === 'brew_good') {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.setValueAtTime(587.33, now + 0.1);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);
      osc.start(now);
      osc.stop(now + 0.3);
    } else if (type === 'brew_bad') {
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(150, now);
      osc.frequency.exponentialRampToValueAtTime(80, now + 0.2);
      gain.gain.setValueAtTime(0.1, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);
      osc.start(now);
      osc.stop(now + 0.3);
    } else if (type === 'fanfare') {
      [261.63, 329.63, 392.00, 523.25].forEach((freq, i) => {
        const o = audioCtx.createOscillator();
        o.type = 'triangle';
        o.frequency.value = freq;
        const g = audioCtx.createGain();
        o.connect(g);
        g.connect(audioCtx.destination);
        g.gain.setValueAtTime(0, now + i * 0.15);
        g.gain.linearRampToValueAtTime(0.1, now + i * 0.15 + 0.05);
        g.gain.exponentialRampToValueAtTime(0.01, now + i * 0.15 + 0.6);
        o.start(now + i * 0.15);
        o.stop(now + i * 0.15 + 0.6);
      });
      return;
    } else if (type === 'explosion') {
      osc.type = 'square';
      osc.frequency.setValueAtTime(100, now);
      osc.frequency.exponentialRampToValueAtTime(10, now + 0.5);
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.8);
      osc.start(now);
      osc.stop(now + 0.8);
      
      const osc2 = audioCtx.createOscillator();
      osc2.type = 'sawtooth';
      osc2.frequency.setValueAtTime(120, now);
      osc2.frequency.exponentialRampToValueAtTime(15, now + 0.5);
      osc2.connect(gain);
      osc2.start(now);
      osc2.stop(now + 0.8);
      return;
    }
  } catch(e) {}
};

// --- 다채널 시퀀서 BGM 정의 ---
const midiToFreq = (m) => 440 * Math.pow(2, (m - 69) / 12);

// 메인 멜로디 (신비로운 리드)
const BGM_MELODY = [
  76, -1, 72, -1, 69, -1, 72, 76, 81, -1, 79, -1, 76, -1, -1, -1,
  74, -1, 69, -1, 65, -1, 69, 74, 79, -1, 77, -1, 74, -1, -1, -1,
  72, -1, 69, -1, 65, -1, 69, 72, 77, -1, 76, -1, 72, -1, -1, -1,
  71, -1, 68, -1, 64, -1, 68, 71, 76, -1, 74, -1, 71, -1, 72, 74
];

// 베이스 라인 (무거운 저음)
const BGM_BASS = [
  45, -1, -1, -1, 45, -1, -1, -1, 45, -1, 52, -1, 45, -1, 40, -1,
  38, -1, -1, -1, 38, -1, -1, -1, 38, -1, 45, -1, 38, -1, 33, -1,
  41, -1, -1, -1, 41, -1, -1, -1, 41, -1, 48, -1, 41, -1, 36, -1,
  40, -1, -1, -1, 40, -1, -1, -1, 40, -1, 47, -1, 40, -1, 52, -1
];

// 아르페지오 화음 (배경에 깔리는 반짝이는 소리)
const BGM_ARP = [
  57, 60, 64, 60, 57, 60, 64, 60, 57, 60, 64, 60, 57, 60, 64, 60,
  53, 57, 62, 57, 53, 57, 62, 57, 53, 57, 62, 57, 53, 57, 62, 57,
  53, 57, 60, 57, 53, 57, 60, 57, 53, 57, 60, 57, 53, 57, 60, 57,
  52, 56, 59, 56, 52, 56, 59, 56, 52, 56, 59, 56, 52, 56, 59, 56
];

// 간단한 드럼 비트 (0: 킥, 1: 하이햇, 2: 마법 스네어)
const BGM_DRUMS = [
  0, 1, 1, 1, 2, 1, 1, 1, 0, 1, 0, 1, 2, 1, 1, 1,
  0, 1, 1, 1, 2, 1, 1, 1, 0, 1, 0, 1, 2, 1, 1, 1,
  0, 1, 1, 1, 2, 1, 1, 1, 0, 1, 0, 1, 2, 1, 1, 1,
  0, 1, 1, 1, 2, 1, 1, 1, 0, 1, 0, 1, 2, 1, 1, 1
];

// --- 데이터 정의 ---
const INGREDIENTS = [
  { id: '1', emoji: '🌺', name: '적염화', color: 'bg-red-100 border-red-300 text-red-700', cost: 4 },
  { id: '2', emoji: '💧', name: '정령의 눈물', color: 'bg-blue-100 border-blue-300 text-blue-700', cost: 3 },
  { id: '3', emoji: '🐉', name: '용의 비늘', color: 'bg-emerald-100 border-emerald-300 text-emerald-700', cost: 8 },
  { id: '4', emoji: '🧚', name: '요정 가루', color: 'bg-pink-100 border-pink-300 text-pink-700', cost: 5 },
  { id: '5', emoji: '🌊', name: '심해 소금', color: 'bg-cyan-100 border-cyan-300 text-cyan-700', cost: 3 },
  { id: '6', emoji: '🦄', name: '유니콘 뿔', color: 'bg-purple-100 border-purple-300 text-purple-700', cost: 10 },
  { id: '7', emoji: '🌱', name: '맨드레이크', color: 'bg-green-100 border-green-300 text-green-700', cost: 4 },
  { id: '8', emoji: '🕸️', name: '밤의 거미줄', color: 'bg-gray-100 border-gray-400 text-gray-700', cost: 2 },
  { id: '9', emoji: '🌙', name: '달빛 결정', color: 'bg-yellow-100 border-yellow-400 text-yellow-700', cost: 6 },
  { id: '10', emoji: '🍄', name: '별빛 버섯', color: 'bg-orange-100 border-orange-300 text-orange-700', cost: 5 }
];

const POTION_DB = {
  "깊은 밤의 숙면 물약": { slots: 3, maxAttempts: 8, baseReward: 35, reqRep: 0, recipe: ['8', '2', '9'] },
  "올빼미의 시야 물약": { slots: 3, maxAttempts: 8, baseReward: 35, reqRep: 0, recipe: ['9', '5', '10'] },
  "행운의 네잎클로버 물약": { slots: 3, maxAttempts: 8, baseReward: 40, reqRep: 0, recipe: ['7', '4', '2'] },
  "천상의 목소리 영약": { slots: 3, maxAttempts: 8, baseReward: 40, reqRep: 20, recipe: ['4', '7', '2'] },
  "거짓말 탐지 영약": { slots: 3, maxAttempts: 8, baseReward: 45, reqRep: 30, recipe: ['2', '9', '5'] },
  "광속의 깃털 물약": { slots: 3, maxAttempts: 8, baseReward: 45, reqRep: 40, recipe: ['4', '3', '1'] },
  "신속의 치유 물약": { slots: 4, maxAttempts: 10, baseReward: 50, reqRep: 60, recipe: ['6', '7', '2', '4'] },
  "맹독성 가스 물약": { slots: 4, maxAttempts: 10, baseReward: 55, reqRep: 70, recipe: ['7', '3', '5', '8'] },
  "물갈퀴 변이 물약": { slots: 4, maxAttempts: 10, baseReward: 60, reqRep: 80, recipe: ['5', '3', '7', '2'] },
  "마력 폭주 영약": { slots: 4, maxAttempts: 10, baseReward: 60, reqRep: 90, recipe: ['10', '6', '3', '1'] },
  "거인의 힘 물약": { slots: 4, maxAttempts: 10, baseReward: 65, reqRep: 100, recipe: ['3', '1', '7', '5'] },
  "사랑의 묘약": { slots: 4, maxAttempts: 10, baseReward: 70, reqRep: 110, recipe: ['1', '4', '2', '10'] },
  "그림자 걸음 물약": { slots: 4, maxAttempts: 10, baseReward: 75, reqRep: 120, recipe: ['8', '9', '5', '10'] },
  "투명화 영약": { slots: 4, maxAttempts: 10, baseReward: 80, reqRep: 140, recipe: ['8', '9', '4', '5'] },
  "눈부신 오로라 물약": { slots: 5, maxAttempts: 12, baseReward: 85, reqRep: 180, recipe: ['9', '10', '4', '6', '2'] },
  "기억 소거 물약": { slots: 5, maxAttempts: 12, baseReward: 90, reqRep: 200, recipe: ['8', '5', '9', '2', '4'] },
  "용의 숨결 물약": { slots: 5, maxAttempts: 12, baseReward: 95, reqRep: 230, recipe: ['3', '1', '7', '8', '2'] },
  "시간 역행의 영약": { slots: 5, maxAttempts: 12, baseReward: 100, reqRep: 260, recipe: ['9', '6', '10', '4', '5'] },
  "태양 극복의 영약": { slots: 5, maxAttempts: 12, baseReward: 110, reqRep: 300, recipe: ['5', '9', '8', '1', '6'] },
  "만병통치약": { slots: 5, maxAttempts: 12, baseReward: 130, reqRep: 350, recipe: ['1', '2', '3', '4', '6'] }
};

const POTION_CATALOG = Object.keys(POTION_DB).sort((a, b) => POTION_DB[a].reqRep - POTION_DB[b].reqRep);

const CUSTOMER_DATA = [
  {
    type: 'villager', emoji: '👨‍🌾', name: '마을 농부',
    quests: [
      { dialogue: "요즘 통 눈을 붙일 수가 없소. 밤새 뒤척이다 보면 해가 중천이오.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "이놈의 통나무가 꿈쩍도 안 하네. 내 팔뚝이 며칠만이라도 바위처럼 단단해졌으면 좋겠구려.", potionName: "거인의 힘 물약" },
      { dialogue: "낫질하다가 그만 푹 베여버렸지 뭐요. 피가 멈추질 않아서 큰일이오.", potionName: "신속의 치유 물약" },
      { dialogue: "밭에 요상한 벌레들이 들끓고 있소. 근처에 얼씬도 못 하게 할 지독한 냄새가 필요하오.", potionName: "맹독성 가스 물약" },
      { dialogue: "올해는 어째 씨앗 뿌리는 족족 새들이 다 파먹는구려. 하늘이 좀 도와줬으면 좋겠는데...", potionName: "행운의 네잎클로버 물약" },
      { dialogue: "마을 사람들이 하나둘 시름시름 앓고 있소. 의원도 두 손 두 발 다 들었는데, 무슨 방법이 없겠소?", potionName: "만병통치약" }
    ]
  },
  {
    type: 'bard', emoji: '🧑‍🎤', name: '떠돌이 음유시인',
    quests: [
      { dialogue: "내일은 왕 앞에서의 독창이오. 꾀꼬리조차 울고 갈 만큼 맑은 소리가 나야 할 텐데.", potionName: "천상의 목소리 영약" },
      { dialogue: "사흘 밤낮으로 악상이 떠오르질 않소. 내 머릿속을 강렬하게 깨워줄 무언가가 절실하오.", potionName: "마력 폭주 영약" },
      { dialogue: "관객들의 시선을 단숨에 사로잡을 무대 효과가 필요하오. 내 주위가 화려해졌으면 좋겠는데.", potionName: "눈부신 오로라 물약" },
      { dialogue: "공연 시간에 늦어버렸소! 저 산 너머 마을까지 순식간에 도착할 방법이 없겠소?", potionName: "광속의 깃털 물약" },
      { dialogue: "저기 저 아가씨의 눈길을 한 번이라도 끌고 싶소. 내게 푹 빠지게 만들 방법이 없겠소?", potionName: "사랑의 묘약" }
    ]
  },
  {
    type: 'fairy', emoji: '🧚‍♀️', name: '장난꾸러기 요정',
    quests: [
      { dialogue: "인간들 머리카락을 묶어놓고 도망갈 거야! 슉! 하고 사라지게 해 줘!", potionName: "광속의 깃털 물약" },
      { dialogue: "살금살금 다가가서 귀에다 소리칠 거야! 내 발소리가 아무한테도 안 들렸으면 좋겠어.", potionName: "그림자 걸음 물약" },
      { dialogue: "친구 꽃밭에 꼬리구린내를 피워놓을 거야! 코를 쥐어막을 만큼 지독한 걸로 부탁해!", potionName: "맹독성 가스 물약" },
      { dialogue: "밤하늘의 별보다 내가 더 예쁘게 반짝였으면 좋겠어! 온몸이 화려해지는 걸로 줘!", potionName: "눈부신 오로라 물약" },
      { dialogue: "숨바꼭질에서 절대 안 들킬 거야! 아예 내 몸이 없는 것처럼 만들어줄 수 있어?", potionName: "투명화 영약" },
      { dialogue: "장난을 좀 심하게 쳤더니 고블린들이 화났어... 걔네들이 방금 일어난 일을 싹 잊게 해줘!", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'knight', emoji: '💂‍♂️', name: '성기사',
    quests: [
      { dialogue: "갑옷 틈새로 독 화살이 스쳤소. 상처 부위가 검게 변하고 있는데 어찌해야 하오?", potionName: "신속의 치유 물약" },
      { dialogue: "적의 보초들이 깨어있소. 금속 갑옷 소리가 밖으로 새어나가지 않게 해야 하오.", potionName: "그림자 걸음 물약" },
      { dialogue: "달빛조차 닿지 않는 지하 던전을 수색해야 하오. 횃불 없이도 적의 움직임을 봐야겠소.", potionName: "올빼미의 시야 물약" },
      { dialogue: "성을 막고 있는 저 무거운 철문을 내 두 팔로 뜯어내야만 하오.", potionName: "거인의 힘 물약" },
      { dialogue: "잡혀 온 포로가 도통 입을 열지 않소. 혀끝에서 진실만이 흘러나오게 만들 방법이 있소?", potionName: "거짓말 탐지 영약" },
      { dialogue: "성물이 깊은 호수 밑바닥으로 떨어졌소. 숨을 참는 것만으로는 바닥에 닿을 수 없을 것 같소.", potionName: "물갈퀴 변이 물약" }
    ]
  },
  {
    type: 'wizard', emoji: '🧙‍♂️', name: '괴짜 마법사',
    quests: [
      { dialogue: "어제 실험을 무리했더니 몸속의 기운이 텅 비어버렸네. 단숨에 끌어올릴 심장이 뛸 만한 약이 필요해.", potionName: "마력 폭주 영약" },
      { dialogue: "두꺼운 고서를 너무 오래 들여다봤더니 글자가 두 개로 겹쳐 보이네. 흐릿한 시야를 맑게 해 주게.", potionName: "올빼미의 시야 물약" },
      { dialogue: "방금 폭발 실험으로 내 소중한 연구 노트를 태워먹었네! 조금 전으로 되돌릴 수만 있다면...", potionName: "시간 역행의 영약" },
      { dialogue: "내 연구실에 자꾸 불청객이 꼬이는군. 문을 열자마자 숨을 턱 막히게 할 함정을 파야겠어.", potionName: "맹독성 가스 물약" },
      { dialogue: "어제 내 수제자에게 절대 말해선 안 될 비밀 주문을 발설해 버렸네. 그 녀석의 머릿속을 비워야 해!", potionName: "기억 소거 물약" },
      { dialogue: "누군가 내 희귀 재료를 훔쳐 갔어! 용의자들을 심문할 텐데, 본심을 숨기지 못하게 해주게.", potionName: "거짓말 탐지 영약" }
    ]
  },
  {
    type: 'witch', emoji: '🧙‍♀️', name: '늪지대 마녀',
    quests: [
      { dialogue: "히히히... 가마솥에 넣을 마지막 재료가 필요해. 냄새만 맡아도 풀이 시들어버리는 걸로 줘.", potionName: "맹독성 가스 물약" },
      { dialogue: "이 칙칙한 피부 좀 봐. 백설공주보다 더 화사하고 아름답게 변하고 싶은데.", potionName: "눈부신 오로라 물약" },
      { dialogue: "내 낡은 빗자루가 부러졌어! 당장 내일 마녀 집회가 있는데, 날아가는 것보다 빨리 갈 방법이 필요해.", potionName: "광속의 깃털 물약" },
      { dialogue: "달이 뜨지 않는 캄캄한 밤에도 도마뱀 꼬리를 찾아내야 해. 어둠이 무의미해지게 만들어 줘.", potionName: "올빼미의 시야 물약" },
      { dialogue: "나를 무시하던 마법사 놈들의 탑을 잿더미로 만들어버릴 거야! 입술 사이로 불꽃이 일게 해 줘.", potionName: "용의 숨결 물약" },
      { dialogue: "내 숲에 길을 잃고 들어온 꼬마 녀석이 있어. 집으로 가는 길은 물론이고 자기 이름도 잊게 만들어야지.", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'thief', emoji: '🥷', name: '의심스러운 도적',
    quests: [
      { dialogue: "바닥에 깔린 마른 나뭇잎을 밟아도 아무 소리가 나지 않아야 해. 가능하겠어?", potionName: "그림자 걸음 물약" },
      { dialogue: "경비병이 눈치챘어! 화살이 날아오기 전에 내 등 뒤로 바람이 불게 해 줘.", potionName: "광속의 깃털 물약" },
      { dialogue: "이 금고는 쇠지렛대로도 안 열리네. 내 양팔에 황소 수십 마리의 힘을 담아줄 수 있나?", potionName: "거인의 힘 물약" },
      { dialogue: "저택을 지키는 맹견이 너무 사나워. 고기 조각에 섞어 먹일, 아주 고요해지는 가루가 필요해.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "조직 내에 돈을 빼돌리는 쥐새끼가 있어. 변명 따윈 못하게 혀를 묶어버릴 약이 필요해.", potionName: "거짓말 탐지 영약" },
      { dialogue: "벽을 넘는 것조차 귀찮군. 아예 경비병의 눈동자에 내 모습이 맺히지 않게 해 줘.", potionName: "투명화 영약" }
    ]
  },
  {
    type: 'noble', emoji: '🤴', name: '허영심 많은 귀족',
    quests: [
      { dialogue: "내일 황실 무도회에서 내가 가장 돋보여야 해요. 피부에서 자체적으로 빛이 나게 할 순 없나요?", potionName: "눈부신 오로라 물약" },
      { dialogue: "요즘 침대가 가시방석 같아요. 눈을 감으면 아침까지 단 한 번도 깨지 않게 해주세요.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "이 무거운 드레스를 입고도 춤을 출 때 깃털처럼 가볍고 사뿐하게 움직이고 싶어요.", potionName: "광속의 깃털 물약" },
      { dialogue: "연회에서 축사를 낭독해야 하는데 목이 잠겼군요. 은쟁반에 옥구슬 굴러가는 소리가 나야 해요.", potionName: "천상의 목소리 영약" },
      { dialogue: "그 분의 시선이 자꾸 다른 영애를 향하네요. 그 분의 심장이 나만 보면 미친 듯이 뛰게 만들어주세요.", potionName: "사랑의 묘약" },
      { dialogue: "어제 와인에 취해 백작님께 큰 실수를 저질렀어요... 연회장에 있던 사람들의 머릿속을 세탁해야 해요!", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'vampire', emoji: '🧛‍♂️', name: '창백한 뱀파이어',
    quests: [
      { dialogue: "아침 이슬을 직접 눈으로 보고 싶군. 내 창백한 피부가 타들어 가지 않을 비책이 있나?", potionName: "태양 극복의 영약" },
      { dialogue: "수백 년을 관 속에 누워 있었더니 뼈마디가 쑤시는군. 다시 예전처럼 묘비석을 한 손으로 뽑아낼 기력이 필요해.", potionName: "거인의 힘 물약" },
      { dialogue: "불쾌한 사냥꾼 놈들의 은장도에 긁혔어. 살점이 다시 빠르게 차오르게 해 줘.", potionName: "신속의 치유 물약" },
      { dialogue: "그녀가 미소 짓던 수백 년 전의 그날 밤이 도무지 기억나지 않아. 내 흐릿한 옛 기억을 선명하게 돌려놔.", potionName: "시간 역행의 영약" },
      { dialogue: "거울에 안 비치는 것만으론 부족해. 녀석들의 등 뒤에 설 때까지 내 존재 자체가 사라진 것처럼 해 줘.", potionName: "투명화 영약" }
    ]
  },
  {
    type: 'merchant', emoji: '🤑', name: '수상한 상인',
    quests: [
      { dialogue: "손님들이 내 물건의 작은 흠집들을 문제 삼으려고 하네. 방금 본 걸 금세 잊어버리게 할 방법 없나?", potionName: "기억 소거 물약" },
      { dialogue: "산적 떼를 만났네! 짐 마차는 버리더라도 내 목숨은 건져야 해. 번개처럼 도망칠 수 있게 해 주게.", potionName: "광속의 깃털 물약" },
      { dialogue: "저 상단 놈들이 제시한 장부가 영 수상해. 그놈들 입술이 덜덜 떨리며 바른말만 하게 해 주게.", potionName: "거짓말 탐지 영약" },
      { dialogue: "요즘 배가 암초에 걸리고 창고에 불이 나고 난리도 아니야. 나쁜 기운을 몰아낼 부적이 필요해.", potionName: "행운의 네잎클로버 물약" },
      { dialogue: "이 무거운 비단 상자들을 나를 인부가 부족해. 내가 직접 낙타 열 마리 몫을 거뜬히 옮기게 해 주게.", potionName: "거인의 힘 물약" }
    ]
  },
  {
    type: 'explorer', emoji: '🤠', name: '열혈 탐험가',
    quests: [
      { dialogue: "내일은 전설의 해저 도시를 탐험할 거요. 폐에 물이 차지 않고 자유롭게 헤엄쳐야만 하오.", potionName: "물갈퀴 변이 물약" },
      { dialogue: "저 깊은 동굴 끝에는 빛이 한 줌도 닿지 않소. 칠흑 같은 어둠도 대낮처럼 보일 방법이 필요하오.", potionName: "올빼미의 시야 물약" },
      { dialogue: "오지에선 모기 한 번 물려도 목숨이 위태롭지. 어떤 열병이나 독도 한 번에 씻어낼 구급약이 필요하오.", potionName: "만병통치약" },
      { dialogue: "유적의 고대 석문이 단단히 닫혀 있소이다. 폭약 없이도 문을 통째로 밀어버릴 괴력을 주시오.", potionName: "거인의 힘 물약" },
      { dialogue: "가시덩굴에 긁힌 상처가 곪아가고 있소. 흉터 하나 남기지 않고 순식간에 살이 붙게 해 주시오.", potionName: "신속의 치유 물약" }
    ]
  },
  {
    type: 'ghost', emoji: '👻', name: '원한 맺힌 유령',
    quests: [
      { dialogue: "복수를 해야 하는데... 물건을 통과해버리는 내 손으로 탁자를 엎어버릴 수 있게 해 줘...", potionName: "거인의 힘 물약" },
      { dialogue: "내가 어쩌다 이렇게 죽었는지 그 마지막 순간이 비어있어... 잃어버린 그날 밤의 진실을 보고 싶어...", potionName: "시간 역행의 영약" },
      { dialogue: "이승에 남은 억울함과 슬픔 때문에 떠나질 못하겠어... 이 괴로운 감정들을 다 비워낼 수 있다면...", potionName: "기억 소거 물약" },
      { dialogue: "그 사람이 내 외침을 듣지 못하고 그냥 지나쳐 가... 내 목소리가 공기를 진동시킬 수 있게 해 줘...", potionName: "천상의 목소리 영약" },
      { dialogue: "내 모습이 너무 흐릿해... 마지막으로 그 사람 앞에 가장 찬란하고 또렷한 모습으로 서고 싶어...", potionName: "눈부신 오로라 물약" }
    ]
  },
  {
    type: 'mermaid', emoji: '🧜‍♀️', name: '호기심 많은 인어',
    quests: [
      { dialogue: "육지의 왕자님을 구해주었어. 그가 눈을 떴을 때 나를 운명으로 느끼게 만들고 싶어.", potionName: "사랑의 묘약" },
      { dialogue: "이 다리로는 모래사장을 걷는 게 너무 서툴고 무거워. 땅 위에서도 물결을 타듯 가볍게 움직이게 해 줘.", potionName: "광속의 깃털 물약" },
      { dialogue: "다리를 얻는 대신 내 고운 목소리를 빼앗겼어... 다시 예전처럼 아름답게 노래할 수 있게 해 줘.", potionName: "천상의 목소리 영약" },
      { dialogue: "육지의 한낮은 너무 건조하고 뜨거워. 내 비늘이 바싹 마르지 않고 촉촉하게 유지되게 해 줘.", potionName: "태양 극복의 영약" },
      { dialogue: "해변에 모인 인간들을 가까이서 구경하고 싶어! 그들 눈에 내 모습이 파도처럼 흩어져 보이게 해 줘.", potionName: "투명화 영약" }
    ]
  }
];

const ALL_QUESTS = [];
CUSTOMER_DATA.forEach(customer => {
  customer.quests.forEach(quest => {
    ALL_QUESTS.push({
      type: customer.type,
      emoji: customer.emoji,
      name: customer.name,
      dialogue: quest.dialogue,
      potionName: quest.potionName
    });
  });
});

const ITEM_COSTS = { hintIngredient: 10, hintSlot: 25 }; // 골드 가격
const DAILY_RENT = 20; // 하루 임대료
const SAVE_KEY = 'potionShopSave';
const TUTORIAL_KEY = 'potionShopTutorialV4';

export default function App() {
  const [appState, setAppState] = useState('start');
  const [hasSaveData, setHasSaveData] = useState(false);
  const [saveIndicator, setSaveIndicator] = useState(false);

  const [tutorial, setTutorial] = useState({ isActive: false, step: '' });
  const [hasSeenTutorial, setHasSeenTutorial] = useState(false);

  const [day, setDay] = useState(1);
  const [money, setMoney] = useState(0);
  const [reputation, setReputation] = useState(50);
  const [inventory, setInventory] = useState({ hintIngredient: 0, hintSlot: 0 });
  
  const [dailySalesRevenue, setDailySalesRevenue] = useState(0);
  const [dailyIngredientCost, setDailyIngredientCost] = useState(0);
  
  const [showShopModal, setShowShopModal] = useState(false);
  const [activeItemMode, setActiveItemMode] = useState(null);
  const [knownIngredients, setKnownIngredients] = useState({});
  const [knownSlots, setKnownSlots] = useState([]);

  const [dailyCustomers, setDailyCustomers] = useState([]);
  const [currentCustomerIndex, setCurrentCustomerIndex] = useState(0);
  
  const [isDiagnosing, setIsDiagnosing] = useState(false);
  const [diagnosisFeedback, setDiagnosisFeedback] = useState(null);

  const [secretRecipe, setSecretRecipe] = useState([]);
  const [currentGuess, setCurrentGuess] = useState([]);
  const [history, setHistory] = useState([]);
  const [brewPhase, setBrewPhase] = useState('idle'); 
  const [effectText, setEffectText] = useState('');
  const [minigameResult, setMinigameResult] = useState(null);
  const [selectedSlotIndex, setSelectedSlotIndex] = useState(null);

  const [bgmEnabled, setBgmEnabled] = useState(false);
  const bgmTimerRef = useRef(null);
  const nextNoteTimeRef = useRef(0);
  const currentStepRef = useRef(0);

  // 정교한 스케줄러 기반 다채널 BGM 루프 제어
  useEffect(() => {
    if (bgmEnabled) {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      if (audioCtx.state === 'suspended') audioCtx.resume();

      nextNoteTimeRef.current = audioCtx.currentTime + 0.1;
      currentStepRef.current = 0;

      const scheduleNote = (step, time) => {
        // 음계 재생 헬퍼 함수
        const playTone = (note, type, vol, dur) => {
          if (note === -1) return;
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          osc.type = type;
          osc.frequency.value = midiToFreq(note);
          
          gain.gain.setValueAtTime(0, time);
          gain.gain.linearRampToValueAtTime(vol, time + 0.02);
          gain.gain.exponentialRampToValueAtTime(0.001, time + dur);
          
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start(time);
          osc.stop(time + dur);
        };

        // 드럼 재생 헬퍼 함수
        const playDrum = (type) => {
          if (type === -1) return;
          const gain = audioCtx.createGain();
          gain.connect(audioCtx.destination);
          
          if (type === 0) { // 묵직한 킥 드럼
            const osc = audioCtx.createOscillator();
            osc.connect(gain);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(120, time);
            osc.frequency.exponentialRampToValueAtTime(0.01, time + 0.2);
            gain.gain.setValueAtTime(0.2, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.2);
            osc.start(time);
            osc.stop(time + 0.2);
          } else if (type === 1) { // 가벼운 하이햇 소리
            const osc = audioCtx.createOscillator();
            osc.connect(gain);
            osc.type = 'square';
            osc.frequency.setValueAtTime(8000, time);
            gain.gain.setValueAtTime(0.01, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.05);
            osc.start(time);
            osc.stop(time + 0.05);
          } else if (type === 2) { // 마법 스네어 / 팝 사운드
            const osc = audioCtx.createOscillator();
            osc.connect(gain);
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(400, time);
            osc.frequency.linearRampToValueAtTime(600, time + 0.1);
            gain.gain.setValueAtTime(0.03, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.15);
            osc.start(time);
            osc.stop(time + 0.15);
          }
        };

        // 각 트랙 동시 재생 (볼륨 및 악기 설정)
        playTone(BGM_MELODY[step], 'square', 0.03, 0.25);
        playTone(BGM_BASS[step], 'sawtooth', 0.03, 0.2);
        playTone(BGM_ARP[step], 'sine', 0.02, 0.15);
        playDrum(BGM_DRUMS[step]);
      };

      const scheduler = () => {
        // 타이머가 조금 늦게 돌더라도, 시간 내에 있는 모든 음표를 예약함
        while (nextNoteTimeRef.current < audioCtx.currentTime + 0.1) {
          scheduleNote(currentStepRef.current, nextNoteTimeRef.current);
          
          // 110 BPM 속도로 진행 (16분 음표)
          const secondsPerBeat = 60.0 / 110; 
          nextNoteTimeRef.current += 0.25 * secondsPerBeat;
          
          currentStepRef.current++;
          if (currentStepRef.current >= 64) {
            currentStepRef.current = 0; // 루프 반복
          }
        }
        bgmTimerRef.current = setTimeout(scheduler, 25);
      };

      scheduler(); // 스케줄러 시작
    } else {
      if (bgmTimerRef.current) {
        clearTimeout(bgmTimerRef.current);
      }
    }

    return () => {
      if (bgmTimerRef.current) clearTimeout(bgmTimerRef.current);
    };
  }, [bgmEnabled]);

  useEffect(() => {
    const saved = localStorage.getItem(SAVE_KEY);
    if (saved) setHasSaveData(true);
    const tut = localStorage.getItem(TUTORIAL_KEY);
    if (tut === 'true') setHasSeenTutorial(true);
  }, []);

  useEffect(() => {
    if (appState === 'shop' || appState === 'day_end') {
      const saveData = { day, money, reputation, inventory, dailyCustomers, currentCustomerIndex };
      localStorage.setItem(SAVE_KEY, JSON.stringify(saveData));
      setHasSaveData(true);
      
      setSaveIndicator(true);
      const timer = setTimeout(() => setSaveIndicator(false), 2000);
      return () => clearTimeout(timer);
    }
  }, [appState, day, money, reputation, inventory, dailyCustomers, currentCustomerIndex]);

  const loadGame = () => {
    playSound('click');
    setBgmEnabled(true);
    const saved = localStorage.getItem(SAVE_KEY);
    if (saved) {
      const data = JSON.parse(saved);
      setDay(data.day);
      setMoney(data.money);
      setReputation(data.reputation);
      setInventory(data.inventory);
      setDailyCustomers(data.dailyCustomers || []);
      setCurrentCustomerIndex(data.currentCustomerIndex || 0);
      setAppState('shop');
    }
  };

  const startGame = () => {
    playSound('click');
    setBgmEnabled(true);
    if (hasSaveData && !window.confirm('기존 저장 데이터가 지워집니다. 정말 새로 시작하시겠습니까?')) return;
    setDay(1);
    setMoney(50);
    setReputation(50);
    setInventory({ hintIngredient: 0, hintSlot: 0 });
    startNewDay(1, null);
  };

  const startNewDay = (currentDay, lastDayFinalCustomerType) => {
    const customersCount = 2 + Math.floor(currentDay / 3);
    const queue = [];
    let lastType = lastDayFinalCustomerType;

    let maxSlotsAllowed = 3;
    if (currentDay >= 3) maxSlotsAllowed = 4;
    if (currentDay >= 5) maxSlotsAllowed = 5;

    if (currentDay === 1) {
      if (!hasSeenTutorial) {
        setTutorial({ isActive: true, step: 'intro_1' });
      }
      const villagerQuest = ALL_QUESTS.find(q => q.potionName === '깊은 밤의 숙면 물약');
      queue.push({
        id: 0,
        type: villagerQuest.type,
        emoji: villagerQuest.emoji,
        name: villagerQuest.name,
        dialogue: villagerQuest.dialogue,
        potionName: villagerQuest.potionName,
        slots: 3,
        maxAttempts: 8,
        baseReward: 35,
        prescriptionCode: '#TUT0'
      });
    } else {
      let availableQuests = ALL_QUESTS.filter(q => POTION_DB[q.potionName].slots <= maxSlotsAllowed && POTION_DB[q.potionName].reqRep <= reputation)
                                      .sort(() => Math.random() - 0.5);
      
      const usedTypes = new Set([lastType]);
      const usedPotions = new Set();

      for(let i=0; i < (customersCount > 5 ? 5 : customersCount); i++) {
        let quest = availableQuests.find(q => !usedTypes.has(q.type) && !usedPotions.has(q.potionName));
        if (!quest) quest = availableQuests.find(q => !usedPotions.has(q.potionName));
        if (!quest) quest = availableQuests[0]; 

        if (quest) {
          usedTypes.add(quest.type);
          usedPotions.add(quest.potionName);
          availableQuests = availableQuests.filter(q => q !== quest);

          const potionInfo = POTION_DB[quest.potionName];
          queue.push({
            id: i,
            type: quest.type,
            emoji: quest.emoji,
            name: quest.name,
            dialogue: quest.dialogue,
            potionName: quest.potionName,
            slots: potionInfo.slots,
            maxAttempts: potionInfo.maxAttempts,
            baseReward: potionInfo.baseReward,
            prescriptionCode: '#' + Math.random().toString(36).substring(2, 6).toUpperCase()
          });
        }
      }
    }

    setDailyCustomers(queue);
    setCurrentCustomerIndex(0);
    setDay(currentDay);
    setAppState('shop');
    setIsDiagnosing(false);
    setDiagnosisFeedback(null);
    setDailySalesRevenue(0);
    setDailyIngredientCost(0);
  };

  const currentCustomer = dailyCustomers[currentCustomerIndex];

  const buyItem = (type) => {
    const cost = ITEM_COSTS[type];
    if (money < cost) {
      playSound('fail');
      return;
    }
    playSound('coin');
    setMoney(prev => prev - cost);
    setInventory(prev => ({ ...prev, [type]: prev[type] + 1 }));
  };

  const moveToNextCustomer = () => {
    playSound('click');
    const nextIndex = currentCustomerIndex + 1;
    if (nextIndex >= dailyCustomers.length) {
      setAppState('day_end');
    } else {
      setCurrentCustomerIndex(nextIndex);
      setIsDiagnosing(false);
      setDiagnosisFeedback(null);
      setAppState('shop');
    }
  };

  const handleDiagnose = (selectedPotion) => {
    playSound('click');
    if (selectedPotion === currentCustomer.potionName) {
      setDiagnosisFeedback('success');
      playSound('success');
      setTimeout(() => { acceptOrder(); }, 1200);
    } else {
      setDiagnosisFeedback('fail');
      playSound('fail');
      const penalty = 10;
      setReputation(prev => prev - penalty);
      setTimeout(() => {
        if (reputation - penalty <= 0) {
          setAppState('game_over');
          localStorage.removeItem(SAVE_KEY);
          setHasSaveData(false);
        } else {
          moveToNextCustomer();
        }
      }, 1500);
    }
  };

  const acceptOrder = () => {
    playSound('click');
    const slotsCount = currentCustomer.slots;
    
    if (tutorial.isActive) {
      setSecretRecipe(['8', '2', '9']); // 튜토리얼 고정 레시피
      setTutorial(p => ({...p, step: 'guess_intro'}));
    } else {
      const fixedRecipe = POTION_DB[currentCustomer.potionName].recipe;
      setSecretRecipe([...fixedRecipe]);
    }
    
    setCurrentGuess(Array(slotsCount).fill(null));
    setHistory([]);
    setBrewPhase('idle');
    setEffectText('');
    setMinigameResult(null);
    setSelectedSlotIndex(null);
    setActiveItemMode(null);
    setKnownIngredients({});
    setKnownSlots(Array(slotsCount).fill(null));
    setAppState('minigame');
  };

  const getTutorialAllowedIngredient = () => {
    if (!tutorial.isActive) return null;
    switch (tutorial.step) {
      case 'guess_1_1': return '8';
      case 'guess_1_2': return '9';
      case 'guess_1_3': return '2';
      case 'guess_2_1': return '4';
      case 'guess_2_2': return '5';
      case 'guess_2_3': return '6';
      case 'guess_3_1': return '8';
      case 'guess_3_2': return '2';
      case 'guess_3_3': return '9';
      default: return null;
    }
  };

  const handleIngredientClick = (id) => {
    if (minigameResult || brewPhase !== 'idle') return;
    playSound('pop');

    if (tutorial.isActive) {
      const allowed = getTutorialAllowedIngredient();
      if (allowed && id !== allowed) return; 
      if (currentGuess.includes(id)) return; 

      if (tutorial.step === 'guess_1_1') setTutorial(p => ({...p, step: 'guess_1_2'}));
      if (tutorial.step === 'guess_1_2') setTutorial(p => ({...p, step: 'guess_1_3'}));
      if (tutorial.step === 'guess_1_3') setTutorial(p => ({...p, step: 'free_cost_warning'}));
      
      if (tutorial.step === 'guess_2_1') setTutorial(p => ({...p, step: 'guess_2_2'}));
      if (tutorial.step === 'guess_2_2') setTutorial(p => ({...p, step: 'guess_2_3'}));
      if (tutorial.step === 'guess_2_3') setTutorial(p => ({...p, step: 'brew_2'}));
      
      if (tutorial.step === 'guess_3_1') setTutorial(p => ({...p, step: 'guess_3_2'}));
      if (tutorial.step === 'guess_3_2') setTutorial(p => ({...p, step: 'guess_3_3'}));
      if (tutorial.step === 'guess_3_3') setTutorial(p => ({...p, step: 'brew_3'}));
    }

    if (activeItemMode === 'hintIngredient') {
      if (knownIngredients[id] !== undefined) return;
      setKnownIngredients(prev => ({ ...prev, [id]: secretRecipe.includes(id) }));
      setInventory(prev => ({ ...prev, hintIngredient: prev.hintIngredient - 1 }));
      setActiveItemMode(null);
      return;
    }

    if (currentGuess.includes(id)) {
      setCurrentGuess(currentGuess.map(itemId => itemId === id ? null : itemId));
    } else if (currentGuess.includes(null)) {
      const newGuess = [...currentGuess];
      if (selectedSlotIndex !== null && newGuess[selectedSlotIndex] === null) {
        newGuess[selectedSlotIndex] = id;
        setSelectedSlotIndex(null);
      } else {
        const emptyIndex = newGuess.indexOf(null);
        newGuess[emptyIndex] = id;
      }
      setCurrentGuess(newGuess);
    }
  };

  const handleSlotClick = (index, guessId) => {
    if (minigameResult || brewPhase !== 'idle' || tutorial.isActive) return;
    playSound('pop');

    if (activeItemMode === 'hintSlot') {
      if (knownSlots[index]) return;
      setKnownSlots(prev => {
        const next = [...prev];
        next[index] = secretRecipe[index];
        return next;
      });
      setInventory(prev => ({ ...prev, hintSlot: prev.hintSlot - 1 }));
      setActiveItemMode(null);
      return;
    }

    if (guessId) {
      handleIngredientClick(guessId);
      if (selectedSlotIndex === index) setSelectedSlotIndex(null);
    } else {
      setSelectedSlotIndex(selectedSlotIndex === index ? null : index);
    }
  };

  const handleBrew = () => {
    if (currentGuess.includes(null) || brewPhase !== 'idle') return;
    playSound('bubble');
    setActiveItemMode(null);
    setSelectedSlotIndex(null);

    const brewCost = currentGuess.reduce((total, id) => {
      const ingredient = INGREDIENTS.find(ing => ing.id === id);
      return total + (ingredient ? ingredient.cost : 0);
    }, 0);

    if (!tutorial.isActive) {
      setMoney(prev => prev - brewCost);
      setDailyIngredientCost(prev => prev + brewCost);
    }

    setBrewPhase('heating');
    setEffectText('🔥 끓이는 중...');

    setTimeout(() => {
      playSound('magic');
      setBrewPhase('mixing');
      setEffectText('✨ 마법 융합!');

      setTimeout(() => {
        let perfect = 0;
        let unstable = 0;

        currentGuess.forEach((guessId, index) => {
          if (guessId === secretRecipe[index]) perfect++;
          else if (secretRecipe.includes(guessId)) unstable++;
        });

        const newHistoryItem = { guess: currentGuess, perfect, unstable, attempt: history.length + 1 };
        const newHistory = [newHistoryItem, ...history];
        
        setHistory(newHistory);
        setCurrentGuess(Array(currentCustomer.slots).fill(null));
        setBrewPhase('idle');
        setEffectText('');

        const isWin = perfect === currentCustomer.slots;
        const isGameOver = newHistory.length >= currentCustomer.maxAttempts;

        if (tutorial.isActive) {
          if (tutorial.step === 'brew_1') {
            playSound(perfect > 0 || unstable > 0 ? 'brew_good' : 'brew_bad');
            setTutorial(p => ({...p, step: 'explain_1'}));
          }
          else if (tutorial.step === 'brew_2') {
            playSound(perfect > 0 || unstable > 0 ? 'brew_good' : 'brew_bad');
            setTutorial(p => ({...p, step: 'explain_2'}));
          }
          else if (tutorial.step === 'brew_3') {
            finishOrder(true, newHistory.length);
            setTutorial(p => ({...p, step: 'result_screen'}));
          }
        }

        if (!tutorial.isActive) {
          if (isWin) {
            finishOrder(true, newHistory.length);
          } else if (isGameOver) {
            finishOrder(false, newHistory.length);
          } else {
            playSound(perfect > 0 || unstable > 0 ? 'brew_good' : 'brew_bad');
          }
        }

      }, 1500);
    }, 1200);
  };

  const finishOrder = (isWin, attempts) => {
    playSound(isWin ? 'fanfare' : 'explosion');
    let earnedMoney = 0;
    let earnedRep = 0;
    let tip = 0;
    const base = currentCustomer.baseReward;

    if (isWin) {
      const remainingAttempts = currentCustomer.maxAttempts - attempts;
      tip = Math.floor(base * (remainingAttempts * 0.15));
      earnedMoney = base + tip;
      earnedRep = 10;
    } else {
      earnedMoney = 0;
      earnedRep = -15;
    }

    setMinigameResult({ status: isWin ? 'win' : 'lose', baseReward: base, tip, earnedMoney, earnedRep, attempts });
  };

  const returnToShop = () => {
    playSound('coin');
    if (tutorial.isActive) {
      setTutorial({ isActive: true, step: 'day_end_1' });
    }
    
    const newReputation = reputation + minigameResult.earnedRep;
    setMoney(prev => prev + minigameResult.earnedMoney);
    setReputation(newReputation);
    if (minigameResult.earnedMoney > 0) {
      setDailySalesRevenue(prev => prev + minigameResult.earnedMoney);
    }

    if (newReputation <= 0) {
      setAppState('game_over');
      localStorage.removeItem(SAVE_KEY);
      setHasSaveData(false);
    } else {
      moveToNextCustomer();
    }
  };

  const getIngredientDetails = (id) => INGREDIENTS.find(item => item.id === id);

  const getTutorialMessage = () => {
    switch (tutorial.step) {
      case 'intro_1': return "마법약 상점의 새 주인이 된 것을 환영합니다!\n오늘 첫 영업을 시작해볼까요?";
      case 'intro_2': return "첫 손님이 기다리고 있네요.\n손님의 이야기를 잘 듣고 아래의\n[처방전 작성하기] 버튼을 누르세요.";
      case 'pick_potion': return "밤새 뒤척여서 잠을 잘 수 없다고 하네요.\n목록에서 [깊은 밤의 숙면 물약]을 선택하세요.";
      
      case 'guess_intro': return "조제실에 오신 것을 환영합니다!\n이곳에서 3가지 재료를 조합하여\n손님이 주문한 약을 만들어야 합니다.";
      case 'guess_1_1': return "이 물약의 정답 레시피는 아직 모릅니다.\n튜토리얼을 위해 제가 지시하는 재료를 넣어보세요.\n먼저 [밤의 거미줄(🕸️)]을 클릭하세요.";
      case 'guess_1_2': return "좋습니다. 다음으로 [달빛 결정(🌙)]을 클릭하세요.";
      case 'guess_1_3': return "마지막으로 [정령의 눈물(💧)]을 클릭하세요.";
      
      case 'free_cost_warning': return "재료를 모두 넣었군요!\n원래대로라면 우측 상단에 표시된\n재료비(11G)가 차감되지만...";
      case 'free_cost_warning_2': return "이번 첫 조합은 특별히 재료비를 면제해 드리겠습니다!\n앞으로는 재료를 낭비하지 않도록\n신중하게 조합하세요.";
      case 'brew_1': return "이제 가마솥 아래의\n[조합하기] 버튼을 눌러 결과를 확인해보세요!";
      
      case 'explain_1': return "결과가 나왔습니다! [완벽 1, 불안정 2]군요.";
      case 'explain_1_continue': return "✨ 완벽: 재료의 종류와 위치가 모두 일치\n⚠️ 불안정: 재료의 종류는 맞지만 위치가 틀림\n\n방금 넣은 세 가지 재료가 모두 정답에 포함된다는 뜻입니다!";
      
      case 'guess_2_1': return "이번엔 확실한 오답을 걸러내기 위해\n전혀 다른 재료를 넣어볼까요?\n[요정 가루(🧚)]를 클릭하세요.";
      case 'guess_2_2': return "[심해 소금(🌊)]을 클릭하세요.";
      case 'guess_2_3': return "[유니콘 뿔(🦄)]을 클릭하세요.";
      case 'brew_2': return "다시 [조합하기] 버튼을 눌러보세요.\n(이번에도 무료입니다!)";
      
      case 'explain_2': return "결과 [완벽 0, 불안정 0]이 나왔습니다!\n\n이건 방금 넣은 재료들이 정답에 전혀 쓰이지 않는다는 뜻입니다.\n확실한 오답을 걸러내는 것도 중요합니다!";
      
      case 'guess_3_1': return "이제 정답을 맞혀봅시다!\n처음에 넣었던 3가지 재료(🕸️,🌙,💧)가 정답임을 알아냈죠?\n위치를 바꿔서 [밤의 거미줄(🕸️)]을 클릭하세요.";
      case 'guess_3_2': return "[정령의 눈물(💧)]을 클릭하세요.";
      case 'guess_3_3': return "[달빛 결정(🌙)]을 클릭하세요.";
      case 'brew_3': return "완벽합니다! 마지막으로\n[조합하기] 버튼을 누르세요!";
      
      case 'result_screen': return "완벽하게 조제했습니다!\n성공 보수와 남은 기회에 따른 추가 팁을 획득했습니다.";
      case 'return_shop': return "이제 [상점으로 돌아가기] 버튼을 누르세요.";
      
      case 'day_end_1': return "하루 영업이 끝났습니다!\n정산서를 확인해볼까요?";
      case 'day_end_2': return "오늘 번 [판매 수익]에서\n[사용한 재료비]와 상점 [유지비]를 빼서\n순이익을 계산합니다.";
      case 'day_end_3': return "튜토리얼이 모두 끝났습니다!\n이제 [다음 날 시작하기]를 눌러\n본격적인 상점 운영을 시작하세요!";
      
      default: return "";
    }
  };

  const handleTutorialNext = () => {
    playSound('click');
    const step = tutorial.step;
    if (step === 'intro_1') setTutorial({ ...tutorial, step: 'intro_2' });
    else if (step === 'guess_intro') setTutorial({ ...tutorial, step: 'guess_1_1' });
    else if (step === 'free_cost_warning') setTutorial({ ...tutorial, step: 'free_cost_warning_2' });
    else if (step === 'free_cost_warning_2') setTutorial({ ...tutorial, step: 'brew_1' });
    else if (step === 'explain_1') setTutorial({ ...tutorial, step: 'explain_1_continue' });
    else if (step === 'explain_1_continue') setTutorial({ ...tutorial, step: 'guess_2_1' });
    else if (step === 'explain_2') setTutorial({ ...tutorial, step: 'guess_3_1' });
    else if (step === 'result_screen') setTutorial({ ...tutorial, step: 'return_shop' });
    else if (step === 'day_end_1') setTutorial({ ...tutorial, step: 'day_end_2' });
    else if (step === 'day_end_2') setTutorial({ ...tutorial, step: 'day_end_3' });
  };

  const isInfoStep = ['intro_1', 'guess_intro', 'free_cost_warning', 'free_cost_warning_2', 'explain_1', 'explain_1_continue', 'explain_2', 'result_screen', 'day_end_1', 'day_end_2'].includes(tutorial.step);

  const toggleBgm = () => {
    playSound('click');
    setBgmEnabled(!bgmEnabled);
  };

  const renderTopBar = () => (
    <div className="flex items-center justify-between bg-slate-800 p-3 sm:p-4 rounded-xl border border-slate-700 shadow-md mb-4 sm:mb-6 relative z-20">
      <div className="flex items-center gap-2 text-purple-300 font-bold text-lg sm:text-xl relative">
        <Store className="w-5 h-5 sm:w-6 sm:h-6" />
        <span>Day {day}</span>
        <button onClick={toggleBgm} className="ml-2 text-slate-400 hover:text-white bg-slate-700 hover:bg-slate-600 p-1 sm:p-1.5 rounded-lg transition-colors flex items-center justify-center" title="BGM 켜기/끄기">
          {bgmEnabled ? <Volume2 className="w-4 h-4 sm:w-5 sm:h-5 text-green-400"/> : <VolumeX className="w-4 h-4 sm:w-5 sm:h-5 text-slate-500"/>}
        </button>
        {saveIndicator && (
          <div className="absolute -top-3 left-0 bg-green-900/80 text-green-300 text-[10px] px-2 py-0.5 rounded-full flex items-center gap-1 animate-pulse border border-green-500 whitespace-nowrap">
            <Save className="w-3 h-3"/> 자동 저장됨
          </div>
        )}
      </div>
      <div className="flex gap-3 sm:gap-6 text-sm sm:text-base">
        <div className="flex items-center gap-1 sm:gap-2 text-yellow-400 font-bold">
          <Coins className="w-4 h-4 sm:w-5 sm:h-5" />
          <span>{money} G</span>
        </div>
        <div className={`flex items-center gap-1 sm:gap-2 font-bold ${reputation > 30 ? 'text-blue-400' : 'text-red-400 animate-pulse'}`}>
          <Star className="w-4 h-4 sm:w-5 sm:h-5" />
          <span>명성 {reputation}</span>
        </div>
      </div>
    </div>
  );

  if (appState === 'start') {
    return (
      <div className="min-h-[100dvh] bg-slate-900 flex flex-col items-center justify-center p-4">
        <div className="text-center space-y-4 sm:space-y-6 max-w-md w-full">
          <div className="flex justify-center mb-4 sm:mb-8">
            <div className="relative">
              <FlaskConical className="w-24 h-24 sm:w-32 sm:h-32 text-purple-500 animate-pulse" />
              <Sparkles className="w-8 h-8 sm:w-12 sm:h-12 text-yellow-400 absolute -top-2 -right-2 sm:-top-4 sm:-right-4 animate-bounce" />
            </div>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-500 drop-shadow-lg">
            위대한 마법약 상점
          </h1>
          <p className="text-slate-400 leading-relaxed bg-slate-800 p-3 sm:p-4 rounded-lg border border-slate-700 text-xs sm:text-sm mb-6">
            손님들의 증상을 듣고 올바른 마법약을 처방한 뒤,<br/>
            <span className="text-purple-300 font-bold">고정된 마법약 레시피</span>를 추리하여 완벽하게 조제하세요!<br/><br/>
            조제에 성공하여 <span className="text-yellow-400 font-bold">명성이 오르면 새로운 물약이 해금</span>됩니다.<br/>
            오진하거나 조제에 실패하면 명성이 깎이며, 0이 되면 파산합니다.
          </p>
          
          <div className="space-y-3">
            {hasSaveData && (
              <button 
                onClick={loadGame}
                className="w-full py-3 sm:py-4 bg-indigo-600 hover:bg-indigo-500 text-white text-lg sm:text-xl font-bold rounded-xl shadow-[0_0_20px_rgba(79,70,229,0.4)] transition-all transform hover:scale-105 flex items-center justify-center gap-2"
              >
                <Save className="w-5 h-5"/> 이어서 하기
              </button>
            )}
            <button 
              onClick={startGame}
              className={`w-full py-3 sm:py-4 text-lg sm:text-xl font-bold rounded-xl transition-all transform hover:scale-105 ${hasSaveData ? 'bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-600' : 'bg-purple-600 hover:bg-purple-500 text-white shadow-[0_0_20px_rgba(168,85,247,0.4)]'}`}
            >
              새로 시작하기
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (appState === 'game_over') {
    return (
      <div className="min-h-[100dvh] bg-red-950 flex flex-col items-center justify-center p-4 text-center">
        <AlertCircle className="w-20 h-20 sm:w-24 sm:h-24 text-red-500 mb-4 sm:mb-6 animate-bounce" />
        <h1 className="text-3xl sm:text-4xl font-black text-red-400 mb-2 sm:mb-4">파산했습니다!</h1>
        <p className="text-red-200 mb-6 sm:mb-8 text-sm sm:text-lg">명성이 바닥에 떨어져 상점을 닫습니다...</p>
        <div className="bg-slate-900 p-4 sm:p-6 rounded-xl border border-slate-700 mb-6 sm:mb-8 w-56 sm:w-64">
          <p className="text-slate-400 mb-1 sm:mb-2 text-sm sm:text-base">최종 기록</p>
          <p className="text-xl sm:text-2xl font-bold text-white">Day {day}</p>
          <p className="text-lg sm:text-xl font-bold text-yellow-400 mt-1 sm:mt-2">{money} G</p>
        </div>
        <button onClick={startGame} className="px-6 py-3 sm:px-8 sm:py-3 bg-red-600 hover:bg-red-500 text-white font-bold rounded-lg flex items-center gap-2 text-sm sm:text-base">
          <RotateCcw className="w-4 h-4 sm:w-5 sm:h-5"/> 처음부터 다시 시작
        </button>
      </div>
    );
  }

  const netProfit = dailySalesRevenue - dailyIngredientCost - DAILY_RENT;

  return (
    <div className="min-h-[100dvh] bg-slate-900 text-slate-100 p-2 sm:p-4 font-sans selection:bg-purple-500/30 flex flex-col">
      <style>{`
        @keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-4px); } 50% { transform: translateX(4px); } 75% { transform: translateX(-4px); } }
        .animate-shake { animation: shake 0.3s ease-in-out infinite; }
        @keyframes pulse-fast { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.8; transform: scale(1.02); } }
        .animate-pulse-fast { animation: pulse-fast 0.4s ease-in-out infinite; }
        @keyframes walkIn { 0% { transform: translateX(100%); opacity: 0; } 100% { transform: translateX(0); opacity: 1; } }
        .animate-walk-in { animation: walkIn 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
        @keyframes popUp { 0% { transform: scale(0.8); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
        .animate-pop-up { animation: popUp 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; animation-delay: 0.6s; opacity: 0; }
        .animate-fade-in-btn { animation: popUp 0.3s ease-in forwards; animation-delay: 1.0s; opacity: 0; }
        @keyframes pulse-glow { 0%, 100% { box-shadow: 0 0 15px rgba(59,130,246,0.5); border-color: rgba(59,130,246,0.8); } 50% { box-shadow: 0 0 25px rgba(59,130,246,0.8); border-color: rgba(96,165,250,1); } }
        .animate-pulse-glow { animation: pulse-glow 1.5s ease-in-out infinite; }
        @keyframes slideUp { 0% { transform: translateY(100%); opacity: 0; } 100% { transform: translateY(0); opacity: 1; } }
        .animate-slide-up { animation: slideUp 0.4s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
        .custom-scrollbar::-webkit-scrollbar { width: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: #475569; border-radius: 10px; }
      `}</style>

      {tutorial.isActive && (
        <div className="fixed top-4 sm:top-10 left-1/2 -translate-x-1/2 w-[95%] max-w-md bg-indigo-950/95 border-2 border-indigo-400 p-4 sm:p-6 rounded-2xl z-[120] shadow-[0_0_30px_rgba(99,102,241,0.5)] animate-in slide-in-from-top-4 backdrop-blur-sm">
          <h3 className="text-indigo-300 font-black mb-2 flex items-center gap-2 text-sm sm:text-base"><Info className="w-5 h-5"/> 튜토리얼 안내</h3>
          <p className="text-white text-sm sm:text-base leading-relaxed whitespace-pre-wrap">{getTutorialMessage()}</p>
          {isInfoStep && (
            <button 
              onClick={handleTutorialNext}
              className="mt-4 w-full py-3 bg-indigo-600 hover:bg-indigo-500 rounded-xl font-bold text-white transition-all shadow-lg animate-pulse"
            >
              다음
            </button>
          )}
        </div>
      )}

      <div className="max-w-2xl mx-auto w-full relative overflow-hidden pb-2 sm:pb-4 flex-1 flex flex-col">
        {renderTopBar()}

        {showShopModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
            <div className="bg-slate-800 border-2 border-blue-500 rounded-2xl p-4 sm:p-6 max-w-sm w-full shadow-[0_0_40px_rgba(59,130,246,0.3)]">
              <div className="flex justify-between items-center mb-4 sm:mb-6">
                <h2 className="text-xl sm:text-2xl font-bold text-blue-300 flex items-center gap-2">
                  <ShoppingBag className="w-5 h-5 sm:w-6 sm:h-6" /> 도구 상점
                </h2>
                <button onClick={() => { playSound('click'); setShowShopModal(false); }} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5 sm:w-6 sm:h-6" />
                </button>
              </div>
              
              <div className="space-y-3 sm:space-y-4">
                <div className="bg-slate-900 p-3 sm:p-4 rounded-xl border border-slate-700 flex justify-between items-center">
                  <div>
                    <h3 className="font-bold text-white flex items-center gap-1 text-sm sm:text-base"><Search className="w-3 h-3 sm:w-4 sm:h-4 text-indigo-400"/> 재료 감별 돋보기</h3>
                    <p className="text-[10px] sm:text-xs text-slate-400 mt-1">특정 재료가 레시피에 쓰이는지 O/X.</p>
                  </div>
                  <button 
                    onClick={() => buyItem('hintIngredient')}
                    disabled={money < ITEM_COSTS.hintIngredient}
                    className={`ml-2 px-2 py-1.5 sm:px-3 sm:py-2 rounded-lg text-xs sm:text-sm font-bold flex flex-col items-center min-w-[60px] sm:min-w-[70px] transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${money < ITEM_COSTS.hintIngredient ? 'bg-slate-800 text-slate-500 border-slate-700' : 'bg-slate-800 hover:bg-yellow-900 border border-yellow-500 text-yellow-300'}`}
                  >
                    <span>{ITEM_COSTS.hintIngredient} G</span>
                    <span className="text-[10px] sm:text-xs text-slate-400">보유: {inventory.hintIngredient}</span>
                  </button>
                </div>

                <div className="bg-slate-900 p-3 sm:p-4 rounded-xl border border-slate-700 flex justify-between items-center">
                  <div>
                    <h3 className="font-bold text-white flex items-center gap-1 text-sm sm:text-base"><Eye className="w-3 h-3 sm:w-4 sm:h-4 text-purple-400"/> 슬롯 투시 구슬</h3>
                    <p className="text-[10px] sm:text-xs text-slate-400 mt-1">가마솥의 칸에 들어갈 재료를 확인.</p>
                  </div>
                  <button 
                    onClick={() => buyItem('hintSlot')}
                    disabled={money < ITEM_COSTS.hintSlot}
                    className={`ml-2 px-2 py-1.5 sm:px-3 sm:py-2 rounded-lg text-xs sm:text-sm font-bold flex flex-col items-center min-w-[60px] sm:min-w-[70px] transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${money < ITEM_COSTS.hintSlot ? 'bg-slate-800 text-slate-500 border-slate-700' : 'bg-slate-800 hover:bg-yellow-900 border border-yellow-500 text-yellow-300'}`}
                  >
                    <span>{ITEM_COSTS.hintSlot} G</span>
                    <span className="text-[10px] sm:text-xs text-slate-400">보유: {inventory.hintSlot}</span>
                  </button>
                </div>
              </div>

              <div className="mt-4 sm:mt-6 text-center text-xs sm:text-sm text-slate-500">
                아이템은 조제실(미니게임)에서 사용할 수 있습니다.
              </div>
            </div>
          </div>
        )}

        {appState === 'shop' && currentCustomer && (
          <div className="bg-slate-900 rounded-t-3xl border-4 border-slate-700 flex-1 overflow-hidden relative shadow-2xl flex flex-col justify-end animate-in fade-in duration-500 min-h-[450px]">
            <div className="absolute inset-0 bg-slate-800/50 flex justify-around p-4">
              <div className="w-1/4 h-24 sm:h-32 bg-slate-700 rounded-lg border-b-4 border-slate-800 mt-6 sm:mt-10 opacity-50"></div>
              <div className="w-1/4 h-24 sm:h-32 bg-slate-700 rounded-lg border-b-4 border-slate-800 mt-12 sm:mt-20 opacity-50"></div>
              <div className="w-1/4 h-24 sm:h-32 bg-slate-700 rounded-lg border-b-4 border-slate-800 mt-6 sm:mt-10 opacity-50"></div>
            </div>

            <div className="absolute top-3 left-3 sm:top-4 sm:left-4 bg-slate-900/80 px-2 py-1 sm:px-3 sm:py-1 rounded-full text-xs sm:text-sm font-semibold text-slate-300 flex items-center gap-1 sm:gap-2 z-10 border border-slate-700">
              <Users className="w-3 h-3 sm:w-4 sm:h-4" /> 
              대기표: {currentCustomerIndex + 1} / {dailyCustomers.length}
            </div>

            <div className="relative z-10 flex flex-col items-center animate-walk-in pt-12 sm:pt-0">
              <div className="bg-white text-slate-900 p-3 sm:p-5 rounded-2xl rounded-br-none mb-2 sm:mb-4 shadow-xl w-[90%] sm:max-w-sm relative mx-auto animate-pop-up">
                <h3 className="text-base sm:text-lg font-black text-slate-800 mb-1">{currentCustomer.name}</h3>
                <p className="text-xs sm:text-base text-slate-700 italic font-medium leading-relaxed break-keep">"{currentCustomer.dialogue}"</p>
                
                <div className="mt-2 sm:mt-4 pt-2 sm:pt-3 border-t border-slate-200 flex justify-between items-end gap-1 sm:gap-2">
                  <div className="flex flex-col flex-1">
                    <span className="text-[10px] sm:text-xs text-slate-500 font-bold mb-0.5 sm:mb-1">상태</span>
                    <span className="bg-slate-100 text-slate-600 px-2 py-1 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-bold flex items-center gap-1 w-fit">
                      <Search className="w-3 h-3" /> 대기중...
                    </span>
                  </div>
                  <div className="flex flex-col items-end">
                    <span className="text-[10px] sm:text-xs text-slate-500 font-bold mb-0.5 sm:mb-1">예상 보수</span>
                    <span className="text-amber-600 font-black flex items-center gap-1 text-sm sm:text-base">
                      {currentCustomer.baseReward} G
                    </span>
                  </div>
                </div>
                <div className="absolute -bottom-3 right-6 sm:-bottom-4 sm:right-10 w-0 h-0 border-l-[12px] sm:border-l-[16px] border-l-transparent border-t-[12px] sm:border-t-[16px] border-t-white border-r-[12px] sm:border-r-[16px] border-r-transparent"></div>
              </div>

              {diagnosisFeedback && (
                <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 text-2xl sm:text-4xl font-black px-4 sm:px-6 py-3 sm:py-4 rounded-2xl shadow-2xl animate-bounce border-4 whitespace-nowrap flex items-center gap-1 sm:gap-2 ${diagnosisFeedback === 'success' ? 'bg-green-100 text-green-600 border-green-500' : 'bg-red-100 text-red-600 border-red-500'}`}>
                  {diagnosisFeedback === 'success' ? <><CheckCircle2 className="w-6 h-6 sm:w-10 sm:h-10"/> 성공!</> : <><XCircle className="w-6 h-6 sm:w-10 sm:h-10"/> 오진!</>}
                </div>
              )}

              <div className={`text-[80px] sm:text-[120px] leading-none filter drop-shadow-[0_10px_10px_rgba(0,0,0,0.5)] translate-y-2 transition-all ${diagnosisFeedback === 'fail' ? 'grayscale opacity-50' : ''}`}>
                {currentCustomer.emoji}
              </div>
            </div>

            <div className="bg-amber-900 w-full border-t-[8px] sm:border-t-[12px] border-amber-800 shadow-[0_-10px_30px_rgba(0,0,0,0.5)] z-20 relative shrink-0">
              <div className="absolute top-0 w-full h-1 sm:h-2 bg-white/10"></div>
              
              {!isDiagnosing ? (
                <div className="h-20 sm:h-32 flex items-center justify-center px-4">
                  <button 
                    onClick={() => {
                      playSound('click');
                      setIsDiagnosing(true);
                      if (tutorial.isActive && tutorial.step === 'intro_2') {
                        setTutorial(p => ({ ...p, step: 'pick_potion' }));
                      }
                    }}
                    disabled={diagnosisFeedback !== null || (tutorial.isActive && tutorial.step !== 'intro_2')}
                    className={`w-full sm:w-auto px-4 py-3 sm:px-8 sm:py-4 hover:bg-indigo-500 text-white font-black text-sm sm:text-xl rounded-xl shadow-[0_6px_0_rgba(67,56,202,1)] sm:shadow-[0_8px_0_rgba(67,56,202,1)] hover:translate-y-[2px] transition-all flex items-center justify-center gap-2 sm:gap-3 animate-fade-in-btn disabled:opacity-50 disabled:cursor-not-allowed ${tutorial.isActive && tutorial.step === 'intro_2' ? 'bg-indigo-500 animate-pulse ring-4 ring-indigo-400' : 'bg-indigo-600'}`}
                  >
                    <ScrollText className="w-4 h-4 sm:w-6 sm:h-6" /> 처방전 작성하기
                  </button>
                </div>
              ) : (
                <div className="bg-slate-800 border-t-4 border-slate-600 p-3 sm:p-5 animate-slide-up rounded-t-3xl max-h-[60vh] sm:max-h-[400px] overflow-y-auto custom-scrollbar shadow-[0_-10px_20px_rgba(0,0,0,0.3)]">
                  <div className="flex justify-between items-center mb-3 sm:mb-4 sticky top-0 bg-slate-800 py-2 z-20">
                    <h3 className="text-white font-bold flex items-center gap-1 sm:gap-2 text-sm sm:text-lg"><ScrollText className="w-4 h-4 sm:w-5 sm:h-5 text-indigo-400"/> 알맞은 약을 고르세요</h3>
                    <button onClick={() => { playSound('click'); setIsDiagnosing(false); }} className="text-slate-400 hover:text-white bg-slate-700 p-1.5 rounded-lg transition-colors">
                      <X className="w-4 h-4 sm:w-5 sm:h-5"/>
                    </button>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3">
                    {POTION_CATALOG.filter(potionName => POTION_DB[potionName].reqRep <= reputation || (tutorial.isActive && potionName === '깊은 밤의 숙면 물약')).map((potionName, idx) => {
                      const isTutorialTarget = tutorial.isActive && potionName === '깊은 밤의 숙면 물약';
                      const isTutorialDisabled = tutorial.isActive && potionName !== '깊은 밤의 숙면 물약';
                      return (
                        <button
                          key={idx}
                          onClick={() => handleDiagnose(potionName)}
                          disabled={diagnosisFeedback !== null || (tutorial.isActive && tutorial.step !== 'pick_potion') || isTutorialDisabled}
                          className={`p-2 sm:p-3 text-left rounded-lg sm:rounded-xl text-[11px] sm:text-sm font-semibold transition-colors flex items-center gap-2 border ${
                            isTutorialTarget && tutorial.step === 'pick_potion' ? 'bg-indigo-600 text-white border-indigo-400 animate-pulse ring-2 ring-indigo-500' : 
                            isTutorialDisabled ? 'bg-slate-800 text-slate-600 border-slate-700 cursor-not-allowed' :
                            'bg-slate-700 hover:bg-indigo-600 text-slate-200 hover:text-white border-slate-600 hover:border-indigo-400'
                          }`}
                        >
                          <FlaskConical className="w-3 h-3 sm:w-4 sm:h-4 opacity-70 shrink-0" />
                          <span className="truncate">{potionName}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {appState === 'minigame' && (
          <div className="flex flex-col flex-1 gap-3 sm:gap-5 h-full relative overflow-hidden pb-1">
            
            {minigameResult && (
              <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
                <div className={`bg-slate-800 border-2 rounded-2xl p-6 sm:p-8 max-w-sm w-full text-center space-y-4 sm:space-y-6 animate-in zoom-in-95 ${minigameResult.status === 'win' ? 'border-green-500 shadow-[0_0_40px_rgba(34,197,94,0.3)]' : 'border-red-500 shadow-[0_0_40px_rgba(239,68,68,0.3)]'}`}>
                  <div className="text-5xl sm:text-6xl mb-2">{minigameResult.status === 'win' ? '🎇' : '💥'}</div>
                  <h2 className={`text-xl sm:text-2xl font-bold ${minigameResult.status === 'win' ? 'text-green-400' : 'text-red-400'}`}>
                    {minigameResult.status === 'win' ? '완벽한 조제!' : '조제 실패...'}
                  </h2>
                  
                  {tutorial.isActive && minigameResult.status === 'win' ? (
                    <div className="bg-indigo-900/50 border border-indigo-500 p-3 rounded-lg mt-2 text-indigo-200 text-sm break-keep">
                      튜토리얼 모드라서 특별히<br/>재료 소모 없이 보수를 획득했습니다!
                    </div>
                  ) : (
                    <>
                      {minigameResult.status === 'win' && (
                        <p className="text-sm sm:text-base text-slate-300">남은 기회에 비례하여<br/>추가 팁을 받았습니다!</p>
                      )}
                      {minigameResult.status === 'lose' && (
                        <p className="text-sm sm:text-base text-slate-300">가마솥이 폭발하여 손님이 화를 내며 나갔습니다.</p>
                      )}
                    </>
                  )}

                  <div className="flex justify-center gap-4 sm:gap-6 py-3 sm:py-4 bg-slate-900 rounded-xl">
                    <div className="text-center flex flex-col justify-end">
                      <p className="text-xs sm:text-sm text-slate-400 mb-1">획득 골드</p>
                      <p className={`font-bold text-base sm:text-lg flex flex-col items-center justify-center ${minigameResult.earnedMoney > 0 ? 'text-yellow-400' : 'text-slate-500'}`}>
                        <span className="flex items-center gap-1">{minigameResult.earnedMoney > 0 ? '+' : ''}{minigameResult.earnedMoney} <Coins className="w-3 h-3 sm:w-4 sm:h-4"/></span>
                        {minigameResult.tip > 0 && <span className="text-[10px] sm:text-xs text-yellow-600/80 mt-1">(기본 {minigameResult.baseReward} + 팁 {minigameResult.tip})</span>}
                      </p>
                    </div>
                    <div className="text-center flex flex-col justify-start border-l border-slate-700 pl-4 sm:pl-6">
                      <p className="text-xs sm:text-sm text-slate-400 mb-1">명성 변화</p>
                      <p className={`font-bold text-base sm:text-lg flex items-center justify-center gap-1 ${minigameResult.earnedRep > 0 ? 'text-blue-400' : 'text-red-400'}`}>
                        {minigameResult.earnedRep > 0 ? '+' : ''}{minigameResult.earnedRep} <Star className="w-3 h-3 sm:w-4 sm:h-4"/>
                      </p>
                    </div>
                  </div>

                  <button 
                    onClick={returnToShop}
                    disabled={tutorial.isActive && tutorial.step !== 'return_shop'}
                    className={`w-full py-3 sm:py-4 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl transition-all shadow-lg text-sm sm:text-base disabled:opacity-50 disabled:cursor-not-allowed ${tutorial.isActive && tutorial.step === 'return_shop' ? 'ring-4 ring-indigo-400 animate-pulse' : ''}`}
                  >
                    상점으로 돌아가기
                  </button>
                </div>
              </div>
            )}

            <div className="bg-slate-800 p-2 sm:p-4 rounded-2xl border border-slate-700 flex flex-wrap gap-2 sm:gap-4 items-center shrink-0 shadow-sm">
              <span className="hidden sm:flex text-sm text-slate-400 font-bold items-center gap-1.5"><PackageOpen className="w-4 h-4"/> 도구함</span>
              
              {activeItemMode && (
                <span className="w-full sm:w-auto text-center sm:text-left text-[11px] sm:text-sm text-blue-300 animate-pulse font-bold bg-blue-900/40 px-3 py-1.5 rounded-lg mr-auto border border-blue-800/50">
                  {activeItemMode === 'hintIngredient' ? '감별할 재료 클릭!' : '투시할 칸 클릭!'}
                </span>
              )}

              <div className="flex gap-2 w-full sm:w-auto ml-auto">
                <button 
                  onClick={() => { playSound('click'); setActiveItemMode(activeItemMode === 'hintIngredient' ? null : 'hintIngredient'); }}
                  disabled={inventory.hintIngredient <= 0 || brewPhase !== 'idle' || tutorial.isActive}
                  className={`flex-1 sm:flex-none flex items-center justify-center gap-1.5 sm:gap-2 px-2 py-2 sm:px-4 sm:py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                    activeItemMode === 'hintIngredient' 
                      ? 'bg-indigo-600 text-white shadow-[0_0_15px_rgba(79,70,229,0.8)]' 
                      : inventory.hintIngredient > 0 && !tutorial.isActive ? 'bg-slate-700 hover:bg-slate-600 text-indigo-300' : 'bg-slate-900 text-slate-600 cursor-not-allowed'
                  }`}
                >
                  <Search className="w-3 h-3 sm:w-4 sm:h-4" /> 돋보기 ({inventory.hintIngredient})
                </button>

                <button 
                  onClick={() => { playSound('click'); setActiveItemMode(activeItemMode === 'hintSlot' ? null : 'hintSlot'); }}
                  disabled={inventory.hintSlot <= 0 || brewPhase !== 'idle' || tutorial.isActive}
                  className={`flex-1 sm:flex-none flex items-center justify-center gap-1.5 sm:gap-2 px-2 py-2 sm:px-4 sm:py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                    activeItemMode === 'hintSlot' 
                      ? 'bg-purple-600 text-white shadow-[0_0_15px_rgba(147,51,234,0.8)]' 
                      : inventory.hintSlot > 0 && !tutorial.isActive ? 'bg-slate-700 hover:bg-slate-600 text-purple-300' : 'bg-slate-900 text-slate-600 cursor-not-allowed'
                  }`}
                >
                  <Eye className="w-3 h-3 sm:w-4 sm:h-4" /> 구슬 ({inventory.hintSlot})
                </button>

                <button 
                  onClick={() => { playSound('click'); setShowShopModal(true); }}
                  disabled={tutorial.isActive}
                  className={`flex-1 sm:flex-none flex items-center justify-center gap-1 px-2 py-2 sm:px-4 sm:py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-colors whitespace-nowrap ${tutorial.isActive ? 'bg-slate-900 text-slate-600 cursor-not-allowed' : 'bg-yellow-900/80 hover:bg-yellow-800 text-yellow-200 border border-yellow-500 shadow-lg'}`}
                >
                  <ShoppingBag className="w-3 h-3 sm:w-4 sm:h-4" /> 상점
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2 sm:gap-6 shrink-0">
              <div className={`bg-slate-800 p-3 sm:p-4 rounded-xl border transition-all ${activeItemMode === 'hintIngredient' ? 'animate-pulse-glow' : 'border-slate-700'}`}>
                <div className="flex justify-between items-center mb-2 sm:mb-4">
                  <h3 className="text-sm sm:text-lg font-semibold text-slate-200">재료 선반</h3>
                </div>
                <div className="grid grid-cols-5 md:grid-cols-5 gap-1 sm:gap-2">
                  {INGREDIENTS.map(item => {
                    const isSelected = currentGuess.includes(item.id);
                    const isKnown = knownIngredients[item.id] !== undefined;
                    const isItemTarget = activeItemMode === 'hintIngredient' && !isKnown;
                    const tutAllowedId = getTutorialAllowedIngredient();
                    const isTutTarget = tutorial.isActive && tutAllowedId === item.id;
                    const isTutDisabled = tutorial.isActive && tutAllowedId !== item.id;

                    return (
                      <button
                        key={item.id}
                        onClick={() => handleIngredientClick(item.id)}
                        disabled={minigameResult !== null || brewPhase !== 'idle' || (!isItemTarget && !isSelected && !currentGuess.includes(null)) || (activeItemMode === 'hintIngredient' && isKnown) || isTutDisabled}
                        className={`
                          relative p-2 sm:p-3 min-h-[64px] sm:min-h-[80px] rounded-xl flex flex-col items-center justify-center transition-all duration-300 border-2
                          ${isSelected && !activeItemMode ? 'bg-slate-700 border-purple-500 shadow-[0_0_12px_rgba(168,85,247,0.5)] transform scale-105 z-10' : 'bg-slate-900 border-slate-700'}
                          ${isItemTarget ? 'hover:border-indigo-400 hover:shadow-[0_0_12px_rgba(99,102,241,0.5)] cursor-crosshair z-10' : ''}
                          ${(!activeItemMode && !isSelected && !currentGuess.includes(null)) || isTutDisabled ? 'opacity-40 cursor-not-allowed' : 'hover:-translate-y-1'}
                          ${isTutTarget ? 'ring-4 ring-indigo-400 animate-pulse border-indigo-400 bg-indigo-900/30 z-20' : ''}
                        `}
                      >
                        <span className="text-2xl sm:text-3xl mb-1 drop-shadow-md">{item.emoji}</span>
                        <span className="text-[9px] sm:text-[11px] text-center text-slate-300 leading-tight break-keep font-medium">{item.name}</span>
                        <span className="text-[8px] sm:text-[10px] text-yellow-500 font-black mt-0.5">{item.cost}G</span>
                        
                        {isKnown && (
                          <div className="absolute -top-1.5 -right-1.5 sm:-top-2 sm:-right-2 bg-slate-800 rounded-full w-5 h-5 sm:w-6 sm:h-6 flex items-center justify-center border-2 border-slate-600 shadow-xl text-[10px] sm:text-xs z-20">
                            {knownIngredients[item.id] ? '✅' : '❌'}
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className={`
                bg-slate-800 p-3 sm:p-6 rounded-xl border flex flex-col relative overflow-hidden transition-all duration-500
                ${brewPhase === 'heating' ? 'border-orange-500 shadow-[0_0_30px_rgba(249,115,22,0.3)] animate-shake' : ''}
                ${brewPhase === 'mixing' ? 'border-purple-500 shadow-[0_0_40px_rgba(168,85,247,0.5)] animate-pulse-fast bg-slate-700' : ''}
                ${activeItemMode === 'hintSlot' ? 'animate-pulse-glow' : (!brewPhase || brewPhase === 'idle' ? 'border-slate-700' : '')}
              `}>
                
                {brewPhase !== 'idle' && (
                  <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/40 backdrop-blur-[2px] rounded-xl">
                    <span className="text-lg sm:text-2xl font-black text-white drop-shadow-[0_4px_4px_rgba(0,0,0,0.8)] animate-bounce">
                      {effectText}
                    </span>
                  </div>
                )}

                <h3 className="text-sm sm:text-lg font-semibold text-slate-200 mb-2 sm:mb-4 text-center z-10 relative">투입된 재료 ({currentCustomer.slots}칸)
                  {currentGuess.some(id => id !== null) && (
                    <span className="ml-2 text-xs text-red-400 font-normal">
                      {tutorial.isActive ? (
                        <span className="line-through opacity-60">재료비: {currentGuess.reduce((sum, id) => {
                          const ing = id ? INGREDIENTS.find(i => i.id === id) : null;
                          return sum + (ing ? ing.cost : 0);
                        }, 0)}G</span>
                      ) : (
                        <span>재료비: {currentGuess.reduce((sum, id) => {
                          const ing = id ? INGREDIENTS.find(i => i.id === id) : null;
                          return sum + (ing ? ing.cost : 0);
                        }, 0)}G</span>
                      )}
                      {tutorial.isActive && <span className="ml-2 text-green-400 font-black text-sm">무료!</span>}
                    </span>
                  )}
                </h3>
                
                <div className="flex justify-center gap-2 sm:gap-4 mb-4 sm:mb-8 z-10 relative flex-1 items-center w-full">
                  {Array.from({ length: currentCustomer?.slots || 3 }).map((_, index) => {
                    const guessId = currentGuess[index];
                    const item = guessId ? getIngredientDetails(guessId) : null;
                    const isKnownSlot = knownSlots[index] !== null;
                    const correctItem = isKnownSlot ? getIngredientDetails(knownSlots[index]) : null;
                    const isItemTarget = activeItemMode === 'hintSlot' && !isKnownSlot;
                    const isSelectedEmptySlot = selectedSlotIndex === index && !item && !activeItemMode;

                    return (
                      <div 
                        key={index} 
                        onClick={() => handleSlotClick(index, guessId)}
                        className={`
                          relative w-12 h-12 sm:w-16 sm:h-16 md:w-20 md:h-20 shrink-0 rounded-full border-2 flex items-center justify-center text-2xl sm:text-4xl transition-all duration-300
                          ${item ? 'bg-slate-800 border-purple-400 shadow-[inset_0_0_15px_rgba(168,85,247,0.5)]' : 'bg-slate-900 border-slate-700 border-dashed'}
                          ${isItemTarget ? 'cursor-crosshair hover:border-purple-400 hover:shadow-[0_0_12px_rgba(168,85,247,0.5)]' : (item && !activeItemMode && !tutorial.isActive ? 'cursor-pointer hover:scale-105' : '')}
                          ${isSelectedEmptySlot && !tutorial.isActive ? 'border-blue-400 shadow-[0_0_12px_rgba(96,165,250,0.6)] animate-pulse cursor-pointer bg-blue-900/20' : (!item && !activeItemMode && !tutorial.isActive ? 'cursor-pointer hover:border-slate-500 hover:bg-slate-800/50' : '')}
                          ${brewPhase === 'heating' ? 'animate-bounce shadow-[inset_0_0_20px_rgba(249,115,22,0.8)] border-orange-400' : ''}
                        `}
                        style={{ animationDelay: `${index * 0.15}s` }}
                      >
                        {item ? item.emoji : <span className="text-slate-600 text-[11px] sm:text-base z-10 font-black">{index + 1}</span>}
                        {!item && isKnownSlot && (
                          <div className="absolute inset-0 flex items-center justify-center opacity-30 text-2xl sm:text-4xl">
                            {correctItem.emoji}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
                
                <button
                  onClick={handleBrew}
                  disabled={currentGuess.includes(null) || minigameResult !== null || brewPhase !== 'idle' || activeItemMode !== null || (tutorial.isActive && !tutorial.step.startsWith('brew_'))}
                  className={`
                    w-full py-3 sm:py-4 font-extrabold rounded-xl transition-all shadow-lg flex items-center justify-center gap-2 sm:gap-3 text-sm sm:text-lg z-10 relative
                    ${(brewPhase !== 'idle' || activeItemMode || (tutorial.isActive && !tutorial.step.startsWith('brew_'))) ? 'bg-slate-600 text-slate-400 cursor-not-allowed' : 'bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white hover:shadow-[0_0_15px_rgba(168,85,247,0.4)]'}
                    ${tutorial.isActive && tutorial.step.startsWith('brew_') ? 'ring-4 ring-indigo-400 animate-pulse' : ''}
                  `}
                >
                  {brewPhase === 'idle' ? (
                    <><Flame className="w-4 h-4 sm:w-6 sm:h-6 text-orange-400" /> 조합하기</>
                  ) : (
                    <><FlaskConical className="w-4 h-4 sm:w-6 sm:h-6 animate-spin" /> 연성 중...</>
                  )}
                </button>
              </div>
            </div>

            <div className="bg-slate-800 rounded-xl border border-slate-700 shadow-inner flex flex-col flex-1 min-h-[160px] overflow-hidden shrink-0 mt-1">
              <div className="bg-slate-800/80 border-b border-slate-700 p-2 text-[10px] sm:text-xs text-slate-300 flex items-center gap-3 justify-center z-10 shrink-0">
                <Info className="w-3 h-3 text-slate-400 shrink-0"/>
                <span className="flex items-center gap-1">
                  <Sparkles className="w-3 h-3 text-green-400"/> 
                  <span className="text-green-400 font-bold whitespace-nowrap">완벽:</span> 종류/위치 일치
                </span>
                <span className="text-slate-600">|</span>
                <span className="flex items-center gap-1">
                  <AlertCircle className="w-3 h-3 text-yellow-400"/> 
                  <span className="text-yellow-400 font-bold whitespace-nowrap">불안정:</span> 위치 다름
                </span>
              </div>

              {history.length > 0 ? (
                <div className="flex-1 overflow-y-auto custom-scrollbar relative pb-10">
                  <div className="p-3 sm:p-5 space-y-2 sm:space-y-3">
                    {history.map((record, idx) => (
                      <div key={idx} className={`flex items-center justify-between p-3 sm:p-4 rounded-lg border transition-all ${idx === 0 ? 'bg-slate-700 border-purple-500 shadow-md' : 'bg-slate-900 border-slate-700 opacity-80'}`}>
                        <div className="flex items-center gap-3 sm:gap-4">
                          <span className="text-slate-400 w-4 sm:w-5 text-xs sm:text-base font-mono text-center font-bold">{record.attempt}.</span>
                          <div className="flex flex-wrap gap-1 sm:gap-2">
                            {record.guess.map((id, i) => (
                              <div key={i} className="text-base sm:text-xl" title={getIngredientDetails(id).name}>
                                {getIngredientDetails(id).emoji}
                              </div>
                            ))}
                          </div>
                        </div>
                        <div className="flex gap-1.5 sm:gap-2 text-[10px] sm:text-sm font-bold shrink-0">
                          <div className={`flex items-center gap-0.5 sm:gap-1 px-2 py-1.5 sm:px-3 sm:py-2 rounded-md ${record.perfect > 0 ? 'bg-green-900/60 text-green-400' : 'bg-slate-800 text-slate-500'}`}>
                            <Sparkles className="w-3 h-3 sm:w-4 sm:h-4" /> {record.perfect}
                          </div>
                          <div className={`flex items-center gap-0.5 sm:gap-1 px-2 py-1.5 sm:px-3 sm:py-2 rounded-md ${record.unstable > 0 ? 'bg-yellow-900/60 text-yellow-400' : 'bg-slate-800 text-slate-500'}`}>
                            <AlertCircle className="w-3 h-3 sm:w-4 sm:h-4" /> {record.unstable}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="flex-1 flex items-center justify-center text-slate-500 text-xs sm:text-sm p-4 text-center">
                  조합을 시작하면 여기에 기록이 표시됩니다.
                </div>
              )}
            </div>
            
          </div>
        )}

        {appState === 'day_end' && (
          <div className="flex flex-col flex-1 gap-4 sm:gap-6 justify-center max-w-md mx-auto w-full animate-slide-up pb-6 px-2">
            <div className="bg-slate-800 rounded-3xl border border-slate-700 shadow-2xl p-6 sm:p-8 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-indigo-500 to-purple-500"></div>

              <div className="text-center mb-8 mt-2">
                <ScrollText className="w-12 h-12 text-indigo-400 mx-auto mb-3" />
                <h2 className="text-2xl font-black text-white mb-1">Day {day} 마감</h2>
                <p className="text-slate-400 text-sm">오늘 하루의 영업 기록</p>
              </div>

              <div className="space-y-3 mb-8">
                <div className="flex justify-between items-center bg-slate-900/50 p-3 sm:p-4 rounded-xl border border-slate-700/50">
                  <span className="text-slate-300 font-semibold flex items-center gap-2 text-sm sm:text-base"><Coins className="w-4 h-4 text-yellow-400"/> 판매 수익</span>
                  <span className="text-yellow-400 font-bold text-base sm:text-lg">+{dailySalesRevenue} G</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-3 sm:p-4 rounded-xl border border-slate-700/50">
                  <span className="text-slate-300 font-semibold flex items-center gap-2 text-sm sm:text-base"><FlaskConical className="w-4 h-4 text-red-400"/> 재료비</span>
                  <span className="text-red-400 font-bold text-base sm:text-lg">-{dailyIngredientCost} G</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-3 sm:p-4 rounded-xl border border-slate-700/50">
                  <span className="text-slate-300 font-semibold flex items-center gap-2 text-sm sm:text-base"><Store className="w-4 h-4 text-orange-400"/> 상점 유지비</span>
                  <span className="text-orange-400 font-bold text-base sm:text-lg">-{DAILY_RENT} G</span>
                </div>
              </div>

              <div className={`flex justify-between items-center p-4 sm:p-5 rounded-xl border-2 mb-8 ${netProfit >= 0 ? 'bg-green-900/20 border-green-500/50' : 'bg-red-900/20 border-red-500/50'}`}>
                <span className={`font-bold ${netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>{netProfit >= 0 ? '순이익' : '순손실'}</span>
                <span className={`font-black text-2xl ${netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>{netProfit > 0 ? '+' : ''}{netProfit} G</span>
              </div>

              <div className="flex justify-between items-center px-2 mb-8">
                <span className="text-slate-400 font-medium text-sm sm:text-base">최종 보유 자금</span>
                <span className="text-white font-bold flex items-center gap-1.5 text-lg sm:text-xl"><Coins className="w-5 h-5 text-yellow-400"/> {money} G</span>
              </div>

              <button
                onClick={() => {
                  playSound('coin');
                  if (tutorial.isActive) {
                    setTutorial({ isActive: false, step: '' });
                    setHasSeenTutorial(true);
                    localStorage.setItem(TUTORIAL_KEY, 'true');
                  }
                  setMoney(prev => prev - DAILY_RENT);
                  startNewDay(day + 1, dailyCustomers[dailyCustomers.length - 1].type);
                }}
                disabled={tutorial.isActive && tutorial.step !== 'day_end_3'}
                className={`w-full py-4 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl transition-all shadow-[0_4px_0_rgba(67,56,202,1)] hover:translate-y-[2px] hover:shadow-[0_2px_0_rgba(67,56,202,1)] flex items-center justify-center gap-2 text-base sm:text-lg disabled:opacity-50 disabled:cursor-not-allowed ${tutorial.isActive && tutorial.step === 'day_end_3' ? 'ring-4 ring-indigo-400 animate-pulse' : ''}`}
              >
                다음 날 시작하기 <ArrowRight className="w-5 h-5"/>
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
