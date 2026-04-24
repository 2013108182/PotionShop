/**
 * 위대한 마법약 상점 (The Great Potion Shop)
 *
 * 플레이어는 마법약 상점의 주인으로서 매일 방문하는 손님들의 대화를 듣고
 * 적절한 물약을 처방(진단)한 뒤, 워들(Wordle) 방식의 재료 조합 미니게임으로
 * 정해진 비밀 레시피를 추리하여 물약을 조제한다.
 *
 * 게임 흐름:
 *   start → shop(처방전 작성) → minigame(재료 조합) → day_end(일일 정산) → 반복
 *   명성(reputation)이 0 이하가 되면 game_over(파산)
 *
 * 주요 시스템:
 *   - 명성 기반 물약 해금: 명성이 높아질수록 더 복잡한 물약이 해금됨
 *   - 힌트 아이템: 골드로 '재료 감별 돋보기'(특정 재료 포함 여부 확인)와
 *                  '슬롯 투시 구슬'(특정 슬롯의 정답 재료 확인)을 구매 가능
 *   - 튜토리얼: 첫 플레이 시 단계별 안내 제공
 *   - 자동 저장: localStorage를 통해 진행 상황 자동 저장/불러오기
 */
import React, { useState, useEffect } from 'react';
import {
  RotateCcw, FlaskConical, Sparkles, AlertCircle, Flame,
  Store, Coins, Star, Users, ArrowRight, BookOpen,
  Search, Eye, ShoppingBag, X, PackageOpen, Target,
  ScrollText, CheckCircle2, XCircle, Info, Save, Lock
} from 'lucide-react';

// ─────────────────────────────────────────────
// 재료 데이터: 게임에서 사용할 수 있는 모든 재료 목록
//   id: 재료 고유 식별자 (레시피 비교에 사용)
//   emoji/name: 화면 표시용
//   color: 재료 버튼 테마 색상 (Tailwind 클래스)
//   cost: 조합 시도 1회당 차감되는 골드 비용
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// 물약 데이터베이스: 게임 내 모든 물약의 스펙 정의
//   slots: 조합에 필요한 재료 칸 수 (3~5칸)
//   maxAttempts: 최대 조합 시도 횟수
//   baseReward: 조제 성공 시 기본 보수 (골드)
//   reqRep: 이 물약을 처방/조제하기 위해 필요한 최소 명성치
//   recipe: 정답 재료 배열 (순서 포함) — 워들처럼 위치가 중요함
//
// 명성이 오를수록 더 많은 칸수(복잡도)의 물약이 해금되는 구조:
//   reqRep 0~50 → 3칸, 60~140 → 4칸, 180~350 → 5칸
// ─────────────────────────────────────────────
const POTION_DB = {
  // 3칸 물약 (시작~초반)
  "깊은 밤의 숙면 물약": { slots: 3, maxAttempts: 8, baseReward: 35, reqRep: 0, recipe: ['8', '2', '9'] },
  "올빼미의 시야 물약": { slots: 3, maxAttempts: 8, baseReward: 35, reqRep: 0, recipe: ['9', '5', '10'] },
  "행운의 네잎클로버 물약": { slots: 3, maxAttempts: 8, baseReward: 40, reqRep: 0, recipe: ['7', '4', '2'] },
  "천상의 목소리 영약": { slots: 3, maxAttempts: 8, baseReward: 40, reqRep: 20, recipe: ['4', '7', '2'] },
  "거짓말 탐지 영약": { slots: 3, maxAttempts: 8, baseReward: 45, reqRep: 30, recipe: ['2', '9', '5'] },
  "광속의 깃털 물약": { slots: 3, maxAttempts: 8, baseReward: 45, reqRep: 40, recipe: ['4', '3', '1'] },
  
  // 4칸 물약 (중반부 해금)
  "신속의 치유 물약": { slots: 4, maxAttempts: 10, baseReward: 50, reqRep: 60, recipe: ['6', '7', '2', '4'] },
  "맹독성 가스 물약": { slots: 4, maxAttempts: 10, baseReward: 55, reqRep: 70, recipe: ['7', '3', '5', '8'] },
  "물갈퀴 변이 물약": { slots: 4, maxAttempts: 10, baseReward: 60, reqRep: 80, recipe: ['5', '3', '7', '2'] },
  "마력 폭주 영약": { slots: 4, maxAttempts: 10, baseReward: 60, reqRep: 90, recipe: ['10', '6', '3', '1'] },
  "거인의 힘 물약": { slots: 4, maxAttempts: 10, baseReward: 65, reqRep: 100, recipe: ['3', '1', '7', '5'] },
  "사랑의 묘약": { slots: 4, maxAttempts: 10, baseReward: 70, reqRep: 110, recipe: ['1', '4', '2', '10'] },
  "그림자 걸음 물약": { slots: 4, maxAttempts: 10, baseReward: 75, reqRep: 120, recipe: ['8', '9', '5', '10'] },
  "투명화 영약": { slots: 4, maxAttempts: 10, baseReward: 80, reqRep: 140, recipe: ['8', '9', '4', '5'] },
  
  // 5칸 물약 (후반부 해금)
  "눈부신 오로라 물약": { slots: 5, maxAttempts: 12, baseReward: 85, reqRep: 180, recipe: ['9', '10', '4', '6', '2'] },
  "기억 소거 물약": { slots: 5, maxAttempts: 12, baseReward: 90, reqRep: 200, recipe: ['8', '5', '9', '2', '4'] },
  "용의 숨결 물약": { slots: 5, maxAttempts: 12, baseReward: 95, reqRep: 230, recipe: ['3', '1', '7', '8', '2'] },
  "시간 역행의 영약": { slots: 5, maxAttempts: 12, baseReward: 100, reqRep: 260, recipe: ['9', '6', '10', '4', '5'] },
  "태양 극복의 영약": { slots: 5, maxAttempts: 12, baseReward: 110, reqRep: 300, recipe: ['5', '9', '8', '1', '6'] },
  "만병통치약": { slots: 5, maxAttempts: 12, baseReward: 130, reqRep: 350, recipe: ['1', '2', '3', '4', '6'] }
};

// reqRep 오름차순으로 정렬된 물약 이름 목록 (처방전 UI에 표시)
const POTION_CATALOG = Object.keys(POTION_DB).sort((a, b) => POTION_DB[a].reqRep - POTION_DB[b].reqRep);

// ─────────────────────────────────────────────
// 손님 데이터: 각 손님 유형(type)별 퀘스트(요청) 목록
//   dialogue: 손님이 직접 증상/원하는 효과를 설명하는 대사 (물약 이름을 직접 언급하지 않음)
//   potionName: dialogue에 대응하는 정답 물약 이름
// 손님 대사는 의도적으로 모호하게 작성되어 플레이어가 추론해야 함
// ─────────────────────────────────────────────
const CUSTOMER_DATA = [
  {
    type: 'villager', emoji: '👨‍🌾', name: '마을 농부',
    quests: [
      { dialogue: "눈꺼풀은 천근만근인데, 누우면 정신이 말똥말똥하니 환장할 노릇이오. 깊은 밤속으로 푹 잠기고 싶구려.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "장정 넷이 붙어도 안 움직이는 바윗덩이가 밭 한복판에 박혔소. 내 팔에 무쇠 같은 힘이라도 솟으면 좋으련만.", potionName: "거인의 힘 물약" },
      { dialogue: "낫질 한 번 잘못했다가 발등을 크게 찍었소. 상처가 아물 기미가 안 보이니, 이거 큰일 아니오?", potionName: "신속의 치유 물약" },
      { dialogue: "밭에 지독한 해충들이 꼬여서 농사를 다 망치게 생겼소. 놈들이 기절할 만큼 독한 냄새를 좀 풍겨야겠소.", potionName: "맹독성 가스 물약" },
      { dialogue: "올해는 어째 씨를 뿌려도 흉조만 찾아드니... 지푸라기라도 잡는 심정으로 하늘의 운이라도 빌려보고 싶소.", potionName: "행운의 네잎클로버 물약" },
      { dialogue: "마을에 원인 모를 역병이 돌아 사람들이 죽어 나가고 있소. 어떤 병마도 씻어낼 전설의 약이라도 필요하오.", potionName: "만병통치약" }
    ]
  },
  {
    type: 'bard', emoji: '🧑‍🎤', name: '떠돌이 음유시인',
    quests: [
      { dialogue: "내일은 왕실의 축제라오. 내 목소리가 숲속의 요정처럼 맑고 감미롭게 울려 퍼져야 할 텐데.", potionName: "천상의 목소리 영약" },
      { dialogue: "영감이 메말라 손끝조차 움직이지 않는구려. 내 영혼을 불태워줄 뜨거운 마력의 폭발이 필요하오.", potionName: "마력 폭주 영약" },
      { dialogue: "단조로운 무대는 지루한 법이지요. 밤하늘의 오로라를 그대로 옮겨온 듯한 화려한 연출을 원하오.", potionName: "눈부신 오로라 물약" },
      { dialogue: "이런, 공연 시간이 코앞인데 발이 묶였소! 구름 위를 달리는 바람처럼 순식간에 이동할 방법이 없겠소?", potionName: "광속의 깃털 물약" },
      { dialogue: "저기 저 아가씨의 차가운 눈빛을 녹이고 싶소. 내 노래 한 자락에 그녀의 심장이 뛰게 만들 수만 있다면...", potionName: "사랑의 묘약" }
    ]
  },
  {
    type: 'fairy', emoji: '🧚‍♀️', name: '장난꾸러기 요정',
    quests: [
      { dialogue: "인간들 머리카락을 다 엉키게 하고 도망갈 거야! 내 날개가 눈에 보이지 않을 만큼 빨라지게 해 줘!", potionName: "광속의 깃털 물약" },
      { dialogue: "살금살금 다가가서 깜짝 놀라게 해 줄래! 공기를 밟는 듯이 발소리가 아예 안 났으면 좋겠어.", potionName: "그림자 걸음 물약" },
      { dialogue: "욕심쟁이 고블린 굴에 코를 찌르는 악취를 가득 채워주고 싶어! 평생 못 잊을 지독한 걸로 줘!", potionName: "맹독성 가스 물약" },
      { dialogue: "오늘 밤 연회에서 내가 주인공이 될 거야! 온몸에서 눈부신 빛이 쏟아져 나오게 해 줄래?", potionName: "눈부신 오로라 물약" },
      { dialogue: "완벽한 숨바꼭질을 하고 싶어! 공기처럼 투명해져서 아무도 나를 찾지 못하게 만들어 줘.", potionName: "투명화 영약" },
      { dialogue: "히히, 장난이 좀 과했나 봐. 무서운 아저씨들이 방금 있었던 일을 통째로 잊어버렸으면 좋겠어!", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'knight', emoji: '💂‍♂️', name: '성기사',
    quests: [
      { dialogue: "전투 중에 묻은 마물의 피가 갑옷을 뚫고 살을 파고드는군. 이 불길한 상처를 즉시 치료해야 하네.", potionName: "신속의 치유 물약" },
      { dialogue: "적진 깊숙이 잠입해야 하네. 철갑의 마찰음조차 어둠 속에 묻어버릴 은밀함이 필요하군.", potionName: "그림자 걸음 물약" },
      { dialogue: "빛조차 삼켜버린 심연의 던전이군. 횃불 없이도 적의 숨결까지 읽어낼 눈이 필요하네.", potionName: "올빼미의 시야 물약" },
      { dialogue: "앞길을 가로막는 성문을 부숴야 하네. 내 검과 방패에 거신(巨神)의 위력을 담아줄 수 있겠나?", potionName: "거인의 힘 물약" },
      { dialogue: "간첩을 잡았으나 입을 굳게 닫고 있군. 거짓을 뱉을 수 없도록 혀를 정화할 비책이 필요하네.", potionName: "거짓말 탐지 영약" },
      { dialogue: "국왕의 보물이 깊은 호수에 잠겼네. 인간의 숨을 포기하고 물결 속에서 자유로워져야 하네.", potionName: "물갈퀴 변이 물약" }
    ]
  },
  {
    type: 'wizard', emoji: '🧙‍♂️', name: '괴짜 마법사',
    quests: [
      { dialogue: "금단의 주문을 읊었더니 마력이 바닥나버렸어! 심장이 터질 듯한 에너지를 주입해야겠네.", potionName: "마력 폭주 영약" },
      { dialogue: "수백 년 된 마법서를 읽었더니 앞이 침침해. 미세한 마력의 흐름까지 꿰뚫어 볼 시야가 필요하네.", potionName: "올빼미의 시야 물약" },
      { dialogue: "실패다! 실험실을 통째로 날려버렸군! 방금 전의 그 어리석은 순간을 되돌릴 방법은 없는 건가?", potionName: "시간 역행의 영약" },
      { dialogue: "연구실 근처에 자꾸 좀도둑이 꼬이는군. 문을 여는 순간 숨이 막혀 쓰러질 함정용 액체가 필요해.", potionName: "맹독성 가스 물약" },
      { dialogue: "제자가 내 비상금 위치를 알아버렸어! 그 녀석의 기억 속에서 어제의 일을 깨끗이 지워주게.", potionName: "기억 소거 물약" },
      { dialogue: "이자가 내 보석을 훔친 게 분명해. 속임수가 통하지 않게 본심만 털어놓게 할 수 있겠나?", potionName: "거짓말 탐지 영약" }
    ]
  },
  {
    type: 'witch', emoji: '🧙‍♀️', name: '늪지대 마녀',
    quests: [
      { dialogue: "히히히... 숨만 쉬어도 나무가 말라 죽고 꽃이 시드는... 그런 지독한 안개를 만들 거야.", potionName: "맹독성 가스 물약" },
      { dialogue: "이 지긋지긋한 늪의 냄새는 싫어. 오늘만큼은 이 세상에서 가장 아름답고 눈부신 존재가 되고 싶군.", potionName: "눈부신 오로라 물약" },
      { dialogue: "빗자루가 부러져서 제시간에 도착할 수가 없어! 빛보다 빠르게 공간을 가로지르는 비책을 내놔.", potionName: "광속의 깃털 물약" },
      { dialogue: "달빛 한 줌 없는 칠흑 같은 밤에도 도마뱀 꼬리를 정확히 골라내야 해. 어둠 따위는 장애물이 아니지.", potionName: "올빼미의 시야 물약" },
      { dialogue: "감히 나를 모욕한 녀석들을 잿더미로 만들 테다! 내 숨결에 화룡의 분노를 담아주겠니?", potionName: "용의 숨결 물약" },
      { dialogue: "늪으로 들어온 꼬마 녀석을 돌려보낼 거야. 대신 자기가 누군지도 잊은 채 숲을 헤매게 되겠지.", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'thief', emoji: '🥷', name: '의심스러운 도적',
    quests: [
      { dialogue: "유리 조각 위를 걸어도 쥐죽은 듯 조용해야 해. 그림자조차 소리를 내지 않는 비결을 원하네.", potionName: "그림자 걸음 물약" },
      { dialogue: "추격대가 따라붙었군! 화살이 내 몸을 꿰뚫기 전에 바람처럼 저 언덕을 넘어야 하네.", potionName: "광속의 깃털 물약" },
      { dialogue: "이 육중한 금고는 정교한 기술로도 안 풀려. 차라리 문짝을 맨손으로 뜯어낼 괴력을 주게.", potionName: "거인의 힘 물약" },
      { dialogue: "경비견들이 너무 짖어대는군. 저 녀석들이 꿈나라에서 영영 깨어나고 싶지 않게 할 수 있나?", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "우리 중 밀고자가 있어. 입만 열면 맹세가 아닌 진실만 쏟아내도록 입술을 묶어버려야겠어.", potionName: "거짓말 탐지 영약" },
      { dialogue: "그냥 투명해지고 싶어. 경비병의 눈앞을 지나가도 아예 존재하지 않는 것처럼 말이야.", potionName: "투명화 영약" }
    ]
  },
  {
    type: 'noble', emoji: '🤴', name: '허영심 많은 귀족',
    quests: [
      { dialogue: "무도회에서 제가 가장 빛나야 해요. 장신구 따위가 아니라 제 피부에서 영롱한 광채가 뿜어져 나와야 한다고요!", potionName: "눈부신 오로라 물약" },
      { dialogue: "최고급 침구도 이젠 지루하군요. 세상의 모든 근심을 잊고 깊은 잠속으로 빠져들게 해주세요.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "이 무거운 보석 드레스를 입고도 깃털처럼 가볍게 춤추고 싶어요. 발걸음이 구름 위를 걷는 듯하게 말이죠.", potionName: "광속의 깃털 물약" },
      { dialogue: "중요한 연설을 앞두고 목소리가 탁해졌어요. 세상에서 가장 우아하고 아름다운 선율을 담아주세요.", potionName: "천상의 목소리 영약" },
      { dialogue: "공작님이 절 보며 한눈을 팔다니요! 그분이 저를 보는 순간 심장이 멎을 듯한 사랑에 빠지게 하세요.", potionName: "사랑의 묘약" },
      { dialogue: "어젯밤 만취해서 끔찍한 실수를 저질렀어요! 연회에 있던 모든 이의 머릿속을 깨끗이 세탁해야 해요!", potionName: "기억 소거 물약" }
    ]
  },
  {
    type: 'vampire', emoji: '🧛‍♂️', name: '창백한 뱀파이어',
    quests: [
      { dialogue: "수백 년간 커튼 뒤에만 숨어 살았지. 단 한 번이라도 저 찬란한 태양 아래 당당히 서보고 싶군.", potionName: "태양 극복의 영약" },
      { dialogue: "나약해진 손끝으로는 관 뚜껑조차 무겁군. 전설 속 태고의 힘을 다시 일깨울 수 있겠나?", potionName: "거인의 힘 물약" },
      { dialogue: "은 화살에 스친 상처가 타들어 가는군. 내 불멸의 육신이 다시 빠르게 재생되게 해주게.", potionName: "신속의 치유 물약" },
      { dialogue: "그녀와 함께했던 그 소중한 기억이 흐릿해져 가네... 잃어버린 시간을 거슬러 그때로 돌아가고 싶군.", potionName: "시간 역행의 영약" },
      { dialogue: "어둠 그 자체가 되고 싶네. 사냥꾼들이 내 숨소리조차 느끼지 못하도록 존재를 지워주게.", potionName: "투명화 영약" }
    ]
  },
  {
    type: 'merchant', emoji: '🤑', name: '수상한 상인',
    quests: [
      { dialogue: "물건에 하자가 있는 걸 들켰지 뭔가! 손님들이 방금 본 걸 싹 잊게 할 수 있나? 금전은 충분히 주지.", potionName: "기억 소거 물약" },
      { dialogue: "도적 떼가 습격했어! 이 짐들은 버리더라도, 내 목숨 하나는 번개보다 빨리 피신시켜야겠네.", potionName: "광속의 깃털 물약" },
      { dialogue: "거래처 녀석들이 장난을 치는 것 같아. 놈들이 헛소리를 못 하도록 진심만 털어놓게 만들어주게.", potionName: "거짓말 탐지 영약" },
      { dialogue: "요즘 운수가 지독히도 없군. 엎어지면 코가 깨지니, 하늘이 내려주는 행운이라도 사야겠어.", potionName: "행운의 네잎클로버 물약" },
      { dialogue: "짐꾼들이 파업을 했네! 내가 직접 낙타 백 마리 몫의 짐을 가볍게 옮길 수 있는 비법을 내놓게.", potionName: "거인의 힘 물약" }
    ]
  },
  {
    type: 'explorer', emoji: '🤠', name: '열혈 탐험가',
    quests: [
      { dialogue: "고대 해저 도시의 입구를 찾았소. 물속에서도 물고기처럼 자유롭게 숨 쉬고 헤엄칠 수 있겠소?", potionName: "물갈퀴 변이 물약" },
      { dialogue: "이 동굴은 빛이 한 점도 없군. 칠흑 같은 어둠 속에서도 바늘 하나까지 찾아낼 시야를 원하오.", potionName: "올빼미의 시야 물약" },
      { dialogue: "정글의 독충들에게 시달려 몸이 엉망이오. 어떤 독기나 질병도 한순간에 정화할 수 있는 구급약이 필요하오.", potionName: "만병통치약" },
      { dialogue: "유적의 거대한 석문이 길을 막고 있소. 기계의 힘 없이 순수한 완력으로 문을 밀어버리고 싶소.", potionName: "거인의 힘 물약" },
      { dialogue: "가시덩굴에 찢긴 상처가 깊구려. 흉터 하나 없이 새살이 돋아나게 할 비약이 필요하오.", potionName: "신속의 치유 물약" }
    ]
  },
  {
    type: 'ghost', emoji: '👻', name: '원한 맺힌 유령',
    quests: [
      { dialogue: "억울해서 떠날 수가 없어... 물건을 통과하는 이 허망한 손에 세상을 뒤엎을 원한의 힘을 담아 줘.", potionName: "거인의 힘 물약" },
      { dialogue: "내가 어떻게 죽었는지 기억나지 않아... 끊어진 내 마지막 운명의 조각을 되찾아 보여 줘.", potionName: "시간 역행의 영약" },
      { dialogue: "이승의 고통이 너무 길어... 내 영혼에 맺힌 모든 슬픔과 기억을 깨끗이 비워버리고 싶어.", potionName: "기억 소거 물약" },
      { dialogue: "그에게 내 마지막 인사를 전하고 싶지만 닿지 않아. 내 목소리가 공기를 울려 그에게 들리게 해 줘.", potionName: "천상의 목소리 영약" },
      { dialogue: "내 마지막 모습은 너무나 초라했지... 떠나기 전, 그 사람 앞에 가장 눈부시고 아름다웠던 빛으로 서고 싶어.", potionName: "눈부신 오로라 물약" }
    ]
  },
  {
    type: 'mermaid', emoji: '🧜‍♀️', name: '호기심 많은 인어',
    quests: [
      { dialogue: "바다 밖에서 만난 그 소년이 자꾸 생각나요. 그가 저를 보자마자 거부할 수 없는 이끌림을 느끼길 바라요.", potionName: "사랑의 묘약" },
      { dialogue: "땅 위에서는 다리가 너무 무거워요. 육지에서도 물거품 사이를 노닐 듯 사뿐사뿐 가볍게 걷고 싶어요.", potionName: "광속의 깃털 물약" },
      { dialogue: "심해의 마녀에게 목소리를 빼앗겼어요... 다시 바다를 울리던 제 고운 노래를 되찾아 주세요.", potionName: "천상의 목소리 영약" },
      { dialogue: "태양 아래의 공기는 너무 뜨겁고 따가워요. 제 몸이 바닷속에 있는 것처럼 촉촉하고 시원하게 유지되길 원해요.", potionName: "태양 극복의 영약" },
      { dialogue: "사람들 틈에서 그들을 구경하고 싶어요. 하지만 그들이 저를 알아채지 못하게, 물안개처럼 존재를 감춰주세요.", potionName: "투명화 영약" }
    ]
  }
];

// 모든 손님 유형의 퀘스트를 단일 배열로 합친 것 (하루 손님 큐 생성 시 참조)
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

const ITEM_COSTS = { hintIngredient: 10, hintSlot: 25 }; // 힌트 아이템 구매 비용 (골드)
const DAILY_RENT = 20; // 하루 영업 종료 시 차감되는 상점 유지비
const SAVE_KEY = 'potionShopSave';       // localStorage 저장 키
const TUTORIAL_KEY = 'potionShopTutorialV4'; // 튜토리얼 완료 여부 저장 키

export default function App() {
  // ── 화면 상태 머신 ──────────────────────────────────────────────────
  // appState 가능한 값:
  //   'start'    : 타이틀/메인 메뉴
  //   'shop'     : 손님 응대 화면 (처방전 작성)
  //   'minigame' : 재료 조합 미니게임 (워들 방식 레시피 추리)
  //   'day_end'  : 하루 마감 정산 화면
  //   'game_over': 파산(명성 0 이하) 화면
  const [appState, setAppState] = useState('start');
  const [hasSaveData, setHasSaveData] = useState(false); // localStorage에 저장 데이터 존재 여부
  const [saveIndicator, setSaveIndicator] = useState(false); // "자동 저장됨" 알림 표시 여부

  // ── 튜토리얼 상태 ──────────────────────────────────────────────────
  // tutorial.step: 튜토리얼 진행 단계 ('intro_1', 'guess_1_1', 'brew_1' 등)
  const [tutorial, setTutorial] = useState({ isActive: false, step: '' });
  const [hasSeenTutorial, setHasSeenTutorial] = useState(false); // 이미 튜토리얼을 완료했는지 여부

  // ── 플레이어 자원 ──────────────────────────────────────────────────
  const [day, setDay] = useState(1);          // 현재 날짜
  const [money, setMoney] = useState(0);       // 보유 골드
  const [reputation, setReputation] = useState(50); // 명성치 (0이 되면 파산)
  const [inventory, setInventory] = useState({ hintIngredient: 0, hintSlot: 0 }); // 힌트 아이템 보유 수량

  // ── 하루 영업 집계 (day_end 정산에 사용) ───────────────────────────
  const [dailySalesRevenue, setDailySalesRevenue] = useState(0);    // 당일 총 판매 수익
  const [dailyIngredientCost, setDailyIngredientCost] = useState(0); // 당일 사용된 재료 비용 합계

  // ── 도구 상점 및 힌트 아이템 모드 ──────────────────────────────────
  const [showShopModal, setShowShopModal] = useState(false);   // 도구 상점 모달 표시 여부
  const [activeItemMode, setActiveItemMode] = useState(null);  // 활성 힌트 모드: null | 'hintIngredient' | 'hintSlot'
  const [knownIngredients, setKnownIngredients] = useState({}); // { 재료id: true/false } — 돋보기로 확인된 재료 정보
  const [knownSlots, setKnownSlots] = useState([]);             // [재료id | null] — 구슬로 확인된 슬롯별 정답 재료

  // ── 하루 손님 큐 ───────────────────────────────────────────────────
  const [dailyCustomers, setDailyCustomers] = useState([]);     // 오늘 방문할 손님 목록
  const [currentCustomerIndex, setCurrentCustomerIndex] = useState(0); // 현재 응대 중인 손님 인덱스

  // ── 처방전 작성(진단) 상태 ─────────────────────────────────────────
  const [isDiagnosing, setIsDiagnosing] = useState(false);       // 처방전 목록 펼침 여부
  const [diagnosisFeedback, setDiagnosisFeedback] = useState(null); // 처방 결과: null | 'success' | 'fail'

  // ── 미니게임(레시피 추리) 상태 ──────────────────────────────────────
  const [secretRecipe, setSecretRecipe] = useState([]);         // 이번 손님의 정답 레시피 배열
  const [currentGuess, setCurrentGuess] = useState([]);         // 현재 입력 중인 재료 배열
  const [history, setHistory] = useState([]);                   // 이전 조합 시도 기록 (결과 포함)
  const [brewPhase, setBrewPhase] = useState('idle');           // 조합 애니메이션 단계: 'idle' | 'heating' | 'mixing'
  const [effectText, setEffectText] = useState('');             // 조합 중 표시할 이펙트 텍스트
  const [minigameResult, setMinigameResult] = useState(null);   // 미니게임 최종 결과 (승리/패배, 보상 등)
  const [selectedSlotIndex, setSelectedSlotIndex] = useState(null); // 재료 배치를 위해 선택된 슬롯 인덱스

  // 최초 마운트 시: 로컬 저장 데이터와 튜토리얼 완료 여부를 확인해 상태 초기화
  useEffect(() => {
    const saved = localStorage.getItem(SAVE_KEY);
    if (saved) setHasSaveData(true);
    const tut = localStorage.getItem(TUTORIAL_KEY);
    if (tut === 'true') setHasSeenTutorial(true);
  }, []);

  // shop 또는 day_end 상태 진입 시마다 현재 진행 상황을 자동 저장하고 2초간 알림 표시
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

  // localStorage에 저장된 이전 게임 상태를 불러와 shop 화면으로 진입
  const loadGame = () => {
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

  // 새 게임 시작: 기존 저장 데이터를 지우고 초기 자원(골드 50, 명성 50)으로 1일차를 시작
  const startGame = () => {
    if (hasSaveData && !window.confirm('기존 저장 데이터가 지워집니다. 정말 새로 시작하시겠습니까?')) return;
    setDay(1);
    setMoney(50);
    setReputation(50);
    setInventory({ hintIngredient: 0, hintSlot: 0 });
    startNewDay(1, null);
  };

  /**
   * 새로운 하루를 시작: 당일 손님 큐를 생성하고 관련 상태를 초기화한다.
   * @param {number} currentDay - 시작할 날짜
   * @param {string|null} lastDayFinalCustomerType - 직전 날 마지막 손님 유형 (연속 동일 유형 방지용)
   *
   * 손님 수: 2 + floor(날짜/3) 명 (최대 5명)
   * 날짜별 허용 최대 칸수: 1~2일차 3칸, 3~4일차 4칸, 5일차+ 5칸
   * 1일차는 튜토리얼 퀘스트(깊은 밤의 숙면 물약)로 고정
   */
  const startNewDay = (currentDay, lastDayFinalCustomerType) => {
    const customersCount = 2 + Math.floor(currentDay / 3);
    const queue = [];
    let lastType = lastDayFinalCustomerType;

    // 날짜에 따라 등장할 수 있는 물약의 최대 칸수 제한 (난이도 점진적 증가)
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
      // 현재 명성과 칸수 제한에 맞는 퀘스트만 추려서 무작위 셔플
      let availableQuests = ALL_QUESTS.filter(q => POTION_DB[q.potionName].slots <= maxSlotsAllowed && POTION_DB[q.potionName].reqRep <= reputation)
                                      .sort(() => Math.random() - 0.5);

      const usedTypes = new Set([lastType]); // 같은 유형 손님이 연속 등장하지 않도록 추적
      const usedPotions = new Set();         // 같은 물약이 중복 등장하지 않도록 추적

      for(let i=0; i < (customersCount > 5 ? 5 : customersCount); i++) {
        // 우선순위: 유형 중복 없고 물약 중복 없는 것 → 물약 중복만 없는 것 → 나머지 아무거나
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

  // 현재 응대 중인 손님 객체 (편의 참조)
  const currentCustomer = dailyCustomers[currentCustomerIndex];

  // 도구 상점에서 힌트 아이템 구매: 골드를 차감하고 인벤토리에 1개 추가
  const buyItem = (type) => {
    const cost = ITEM_COSTS[type];
    if (money < cost) return;
    setMoney(prev => prev - cost);
    setInventory(prev => ({ ...prev, [type]: prev[type] + 1 }));
  };

  // 현재 손님 처리를 완료하고 다음 손님으로 이동 (마지막 손님이면 day_end로 전환)
  const moveToNextCustomer = () => {
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

  /**
   * 처방전 작성: 플레이어가 선택한 물약이 정답인지 판정한다.
   * - 정답: 'success' 피드백 표시 후 1.2초 뒤 조합 미니게임으로 진입
   * - 오답: 'fail' 피드백 + 명성 -10 처리, 명성이 0 이하가 되면 게임 오버
   */
  const handleDiagnose = (selectedPotion) => {
    if (selectedPotion === currentCustomer.potionName) {
      setDiagnosisFeedback('success');
      setTimeout(() => { acceptOrder(); }, 1200);
    } else {
      setDiagnosisFeedback('fail');
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

  /**
   * 처방 확정 후 미니게임 초기화: secretRecipe를 설정하고 minigame 화면으로 전환한다.
   * 튜토리얼 중에는 레시피를 ['8','2','9']로 고정하여 안내대로 진행되게 한다.
   */
  const acceptOrder = () => {
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

  // 튜토리얼 단계별로 클릭 가능한 재료 id를 반환 (해당 재료만 활성화, 나머지는 비활성)
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

  /**
   * 재료 선반에서 재료 클릭 처리 (미니게임 메인 입력 로직):
   *   1. 힌트 아이템 모드(hintIngredient) 활성화 상태면 해당 재료가 레시피에 포함되는지 확인
   *   2. 이미 선택된 재료 클릭 시 제거 (토글)
   *   3. 빈 슬롯에 재료 배치 (selectedSlotIndex 우선, 없으면 첫 번째 빈 슬롯)
   */
  const handleIngredientClick = (id) => {
    if (minigameResult || brewPhase !== 'idle') return;

    if (tutorial.isActive) {
      const allowed = getTutorialAllowedIngredient();
      if (allowed && id !== allowed) return; // 튜토리얼: 지정된 재료만 클릭 허용
      if (currentGuess.includes(id)) return; // 이미 배치된 재료는 무시

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

  /**
   * 가마솥 슬롯 클릭 처리:
   *   - hintSlot 모드: 해당 슬롯의 정답 재료를 공개 (구슬 1개 소비)
   *   - 재료가 이미 배치된 슬롯 클릭: 재료 제거
   *   - 빈 슬롯 클릭: selectedSlotIndex로 지정하여 다음 재료 배치 위치 고정
   */
  const handleSlotClick = (index, guessId) => {
    if (minigameResult || brewPhase !== 'idle' || tutorial.isActive) return;

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
      handleIngredientClick(guessId); // 배치된 재료를 클릭 → 제거
      if (selectedSlotIndex === index) setSelectedSlotIndex(null);
    } else {
      setSelectedSlotIndex(selectedSlotIndex === index ? null : index); // 빈 슬롯 선택/해제 토글
    }
  };

  /**
   * 조합(brew) 실행: 현재 배치된 재료로 한 번의 조합 시도를 수행한다.
   *
   * 결과 판정 (워들 방식):
   *   perfect  - 재료 종류와 위치가 모두 정답과 일치
   *   unstable - 재료 종류는 정답에 포함되지만 위치가 다름
   *
   * 1.2초 heating → 1.5초 mixing 애니메이션 후 결과를 history에 추가한다.
   * 모든 칸이 perfect이면 성공(finishOrder), maxAttempts 소진 시 실패(finishOrder).
   */
  const handleBrew = () => {
    if (currentGuess.includes(null) || brewPhase !== 'idle') return;
    setActiveItemMode(null);
    setSelectedSlotIndex(null);

    // 이번 시도에 사용된 재료들의 골드 비용 합산
    const brewCost = currentGuess.reduce((total, id) => {
      const ingredient = INGREDIENTS.find(ing => ing.id === id);
      return total + (ingredient ? ingredient.cost : 0);
    }, 0);

    // 튜토리얼 중에는 골드 차감 면제
    if (!tutorial.isActive) {
      setMoney(prev => prev - brewCost);
      setDailyIngredientCost(prev => prev + brewCost);
    }

    setBrewPhase('heating');
    setEffectText('🔥 끓이는 중...');

    setTimeout(() => {
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

        if (tutorial.isActive) {
          if (tutorial.step === 'brew_1') setTutorial(p => ({...p, step: 'explain_1'}));
          else if (tutorial.step === 'brew_2') setTutorial(p => ({...p, step: 'explain_2'}));
          else if (tutorial.step === 'brew_3') {
            finishOrder(true, newHistory.length);
            setTutorial(p => ({...p, step: 'result_screen'}));
          }
        }

        if (!tutorial.isActive) {
          if (perfect === currentCustomer.slots) {
            finishOrder(true, newHistory.length);
          } else if (newHistory.length >= currentCustomer.maxAttempts) {
            finishOrder(false, newHistory.length);
          }
        }

      }, 1500);
    }, 1200);
  };

  /**
   * 미니게임 종료 처리 및 보상 계산:
   *   성공: 기본 보수 + 팁(남은 기회 × 기본보수 × 15%) + 명성 +10
   *   실패: 보수 없음 + 명성 -15
   * 결과는 minigameResult에 저장되어 결과 팝업에 표시된다.
   */
  const finishOrder = (isWin, attempts) => {
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

  /**
   * 미니게임 결과를 반영하고 상점 화면으로 돌아간다:
   * 골드·명성 업데이트 → 명성이 0 이하면 game_over, 아니면 moveToNextCustomer 호출
   */
  const returnToShop = () => {
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

  // 재료 id로 INGREDIENTS 배열에서 해당 재료 객체 조회 (이모지, 이름, 비용 등)
  const getIngredientDetails = (id) => INGREDIENTS.find(item => item.id === id);

  // 현재 튜토리얼 단계(tutorial.step)에 맞는 안내 문구 반환 (튜토리얼 말풍선에 표시)
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

  // 튜토리얼 "다음" 버튼 클릭 시 현재 step에서 다음 step으로 순서대로 전환
  const handleTutorialNext = () => {
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

  // "다음" 버튼을 표시해야 하는 튜토리얼 단계 목록 (정보 전달만 하는 단계 → 버튼으로 넘어감)
  const isInfoStep = ['intro_1', 'guess_intro', 'free_cost_warning', 'free_cost_warning_2', 'explain_1', 'explain_1_continue', 'explain_2', 'result_screen', 'day_end_1', 'day_end_2'].includes(tutorial.step);

  // 상단 상태 바: 현재 날짜·골드·명성 표시 및 자동저장 알림 (모든 화면에서 공통 렌더)
  const renderTopBar = () => (
    <div className="flex items-center justify-between bg-slate-800 p-3 sm:p-4 rounded-xl border border-slate-700 shadow-md mb-4 sm:mb-6 relative z-20">
      <div className="flex items-center gap-2 text-purple-300 font-bold text-lg sm:text-xl relative">
        <Store className="w-5 h-5 sm:w-6 sm:h-6" />
        <span>Day {day}</span>
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

  // ── 렌더링 ───────────────────────────────────────────────────────────
  // appState 별로 각각 독립된 화면을 반환한다.

  // [start] 타이틀 화면: 게임 설명, 이어하기/새로 시작 버튼
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

  // [game_over] 파산 화면: 최종 날짜·골드 표시 및 재시작 버튼
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

  // 하루 순이익 = 판매 수익 - 재료비 - 상점 유지비 (day_end 화면에 표시)
  const netProfit = dailySalesRevenue - dailyIngredientCost - DAILY_RENT;

  // [shop / minigame / day_end] 공통 레이아웃 래퍼
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
                <button onClick={() => setShowShopModal(false)} className="text-slate-400 hover:text-white">
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

        {/* [shop] 손님 응대 화면: 손님 입장 애니메이션, 대사 말풍선, 처방전 작성 패널 */}
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
                    <button onClick={() => setIsDiagnosing(false)} className="text-slate-400 hover:text-white bg-slate-700 p-1.5 rounded-lg transition-colors">
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

        {/* [minigame] 재료 조합 화면: 도구함, 재료 선반, 가마솥 슬롯, 조합하기 버튼, 시도 기록 */}
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
                  onClick={() => setActiveItemMode(activeItemMode === 'hintIngredient' ? null : 'hintIngredient')}
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
                  onClick={() => setActiveItemMode(activeItemMode === 'hintSlot' ? null : 'hintSlot')}
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
                  onClick={() => setShowShopModal(true)}
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

        {/* [day_end] 하루 마감 화면: 판매 수익/재료비/유지비 정산 후 다음 날로 진행 */}
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
