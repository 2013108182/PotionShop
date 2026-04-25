/**
 * 위대한 마법약 상점 (The Great Potion Shop)
 *
 * 플레이어는 마법약 상점의 주인으로서 매일 방문하는 손님들의 대화를 듣고
 * 적절한 물약을 처방(진단)한 뒤, 워들(Wordle) 방식의 재료 조합 미니게임으로
 * 정해진 비밀 레시피를 추리하여 물약을 조제한다.
 *
 * 게임 흐름:
 * start → shop(처방전 작성) → minigame(재료 조합) → day_end(일일 정산) → 반복
 * 명성(reputation)이 0 이하가 되면 game_over(파산)
 *
 * 주요 시스템:
 * - 명성 기반 물약 해금: 명성이 높아질수록 더 복잡한 물약이 해금됨
 * - 힌트 아이템: 골드로 '재료 감별 돋보기'(특정 재료 포함 여부 확인)와
 * '슬롯 투시 구슬'(특정 슬롯의 정답 재료 확인)을 구매 가능
 * - 튜토리얼: 첫 플레이 시 단계별 안내 제공
 * - 자동 저장: localStorage를 통해 진행 상황 자동 저장/불러오기
 */

import React, { useState, useEffect } from 'react';
import {
  RotateCcw, FlaskConical, Sparkles, AlertCircle, Flame,
  Store, Coins, Star, Users, ArrowRight, BookOpen,
  Search, Eye, ShoppingBag, X, Target,
  ScrollText, CheckCircle2, XCircle, Info, Save, Lock, Newspaper, TrendingUp, TrendingDown, Ban, Skull
} from 'lucide-react';

/* =========================================================================
 * 재료 데이터
 * 게임에서 사용할 수 있는 모든 재료 목록
 * id: 재료 고유 식별자 (레시피 비교에 사용)
 * emoji/name: 화면 표시용
 * color: 재료 버튼 테마 색상 (Tailwind 클래스)
 * cost: 조합 시도 1회당 차감되는 골드 비용
 * ========================================================================= */
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

/* =========================================================================
 * 물약 데이터베이스
 * 게임 내 모든 물약의 스펙 정의
 * slots: 조합에 필요한 재료 칸 수 (3~5칸)
 * maxAttempts: 최대 조합 시도 횟수
 * baseReward: 조제 성공 시 기본 보수 (골드)
 * reqRep: 이 물약을 처방/조제하기 위해 필요한 최소 명성치
 * recipe: 정답 재료 배열 (순서 포함) — 워들처럼 위치가 중요함
 *
 * 명성이 오를수록 더 많은 칸수(복잡도)의 물약이 해금되는 구조:
 * reqRep 0~50 → 3칸, 60~140 → 4칸, 180~350 → 5칸
 * ========================================================================= */
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

// 재료 중 가장 저렴한 단가 (골드가 이 값 미만이면 파산 처리)
const MIN_INGREDIENT_COST = Math.min(...INGREDIENTS.map(i => i.cost));

/* =========================================================================
 * 손님 데이터
 * 각 손님 유형(type)별 퀘스트(요청) 목록
 * dialogue: 손님이 직접 증상/원하는 효과를 설명하는 대사 (물약 이름 언급 안 함)
 * potionName: dialogue에 대응하는 정답 물약 이름
 * ========================================================================= */
const CUSTOMER_DATA = [
  {
    type: 'villager', emoji: '👨‍🌾', name: '마을 농부',
    quests: [
      { dialogue: "눈꺼풀은 천근만근인데, 누우면 정신이 말똥말똥하니 환장할 노릇이오. 깊은 밤속으로 푹 잠기고 싶구려.", potionName: "깊은 밤의 숙면 물약" },
      { dialogue: "장정 넷이 붙어도 안 움직이는 바윗덩이가 밭 한복판에 박혔소. 내 팔에 무쇠 같은 힘이라도 솟으면 좋으련만.", potionName: "거인의 힘 물약" },
      { dialogue: "낫질 한 번 잘못했다가 발등을 크게 찍었소. 상처가 아물 기미가 안 보이니, 이거 큰일 아니오?", potionName: "신속의 치유 물약" },
      { dialogue: "밭에 지독한 해충들이 꼬여서 농사를 다 망치게 생겼소. 놈들이 기절할 만큼 독한 냄새를 좀 풍겨야겠소.", potionName: "맹독성 가스 물약" },
      { dialogue: "올해는 어째 씨를 뿌려도 흉조만 찾아드니... 지푸라기라도 잡는 심정으로 하늘의 운이라도 빌려보고 싶소.", potionName: "행운의 네잎클로버 물약" },
      { dialogue: "마 마을에 원인 모를 역병이 돌아 사람들이 죽어 나가고 있소. 어떤 병마도 씻어낼 전설의 약이라도 필요하오.", potionName: "만병통치약" }
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
      { dialogue: "짐꾼들이 파업을 했네! 내가 직접 낙타 백 마리 몫의 일들을 가볍게 옮길 수 있는 비법을 내놓게.", potionName: "거인의 힘 물약" }
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

/* =========================================================================
 * 거절 시 손님 반응 대사
 * ========================================================================= */
const REJECT_DIALOGUES = {
  villager: "아쉽구려. 할 수 없이 다른 곳을 찾아보겠소.",
  bard: "아아... 내 영감이 식기 전에 서둘러 다른 곳으로 가야겠군요.",
  fairy: "치, 재미없어! 구두쇠 상인 같으니라고!",
  knight: "알겠네. 임무가 시급하니 이만 실례하지.",
  wizard: "쯧쯧, 이래서야 위대한 상점이라 할 수 있겠나.",
  witch: "흥, 역시 허접한 상점이었네. 내 발로 나가주마.",
  thief: "흠... 알겠소. 없는 사람 치시오.",
  noble: "정말 격 떨어지는 상점이군요. 다시는 안 오겠어요!",
  vampire: "시간 낭비였군... 어둠 속으로 돌아가겠다.",
  merchant: "장사의 기본이 안 되어 있구만! 내 갈 길 가겠네.",
  explorer: "아쉽군! 다음 탐험을 위해 지체할 시간이 없소!",
  ghost: "으으음... 허무하도다... 다시 구천을 떠돌아야겠군...",
  mermaid: "아쉽네요... 그럼 다시 바다로 돌아갈게요."
};

const ITEM_COSTS = { hintIngredient: 10, hintSlot: 25 }; 
const DAILY_RENT_BASE = 20; 
const SAVE_KEY = 'potionShopSave';       
const TUTORIAL_KEY = 'potionShopTutorialV4'; 

/* =========================================================================
 * 다채로운 일일 이벤트 풀 생성기
 * 환경, 경제, 사회적 변동을 시뮬레이션하여 
 * 매일 아침 플레이어에게 전략적 선택을 강요합니다.
 * ========================================================================= */
const generateDailyEvent = (day, reputation) => {
  if (day === 1) return null; // 1일차는 튜토리얼을 위해 이벤트 없음

  // 이벤트 풀 및 가중치 정의
  const events = [
    { weight: 8, type: 'viral_potion', targetId: 'random_unlocked', title: '💥 틱톡(?) 대유행!', message: `마을 전체에 챌린지가 유행입니다! 오늘 모든 손님이 약속이나 한 듯 [특정 물약]만을 찾습니다.` },
    { weight: 8, type: 'global_tip', multiplier: 2.0, title: '🎉 마을 대축제', message: `축제로 마을 사람들이 들떠있습니다. 오늘 획득하는 모든 팁이 2배가 됩니다!` },
    { weight: 8, type: 'expensive_ingredients_cost', multiplier: 2.0, title: '📜 왕실 규제령', message: `사치품 통제로 인해 단가가 높은(6G 이상) 고급 재료들의 가격이 2배로 폭등합니다.` },
    { weight: 8, type: 'potion_group_reward', targets: ['거인의 힘 물약', '용의 숨결 물약', '신속의 치유 물약', '올빼미의 시야 물약'], multiplier: 2.0, title: '⚔️ 전쟁의 전조', message: `군수 물자 확보를 위해 기사단에서 [전투 및 버프 관련 물약]들을 2배의 가격에 매입합니다.` },
    { weight: 8, type: 'potion_group_reward', targets: ['깊은 밤의 숙면 물약', '신속의 치유 물약', '만병통치약'], multiplier: 1.5, title: '🤧 지독한 독감 유행', message: `마 마을에 독감이 돌고 있습니다. [치유 및 수면 관련 물약]의 수요가 급증하여 보수가 1.5배가 됩니다.` },
    { weight: 8, type: 'smuggler', costMultiplier: 0.5, repMultiplier: 0.5, title: '🏴‍☠️ 밀수업자의 방문', message: `출처를 알 수 없는 저렴한 재료가 들어왔습니다. 오늘 재료비는 반값이지만, 질이 떨어져 획득 명성도 반토막 납니다.` },
    { weight: 8, type: 'critic_day', repMultiplier: 2.0, repPenaltyMultiplier: 2.0, title: '🧐 비평가의 순회일', message: `깐깐하기로 소문난 비평가들이 방문합니다. 조제 성공 시 명성을 2배로 얻지만, 실수(거절/오진/실패) 시 명성도 2배로 깎입니다!` },
    { weight: 8, type: 'free_hints', title: '🌠 유성우 내리는 밤', message: `충만한 마력 덕분에 도구 상점의 힌트 아이템(돋보기, 구슬) 가격이 오늘 하루 전면 무료(0G)가 됩니다!` },
    { weight: 6, type: 'rent_override', rent: 50, title: '💸 임대료 폭등', message: `악덕 건물주가 지붕 수리비를 핑계로 오늘 하루 상점 유지비를 50G로 뜯어갑니다. (파산 주의)` },
    { weight: 10, type: 'ingredient_cost', targetId: 'random', multiplier: 2.0, title: '📈 재료 시세 폭등', message: `품귀 현상으로 인해 [특정 재료]의 가격이 오늘 하루 2배 올랐습니다.` },
    { weight: 10, type: 'ingredient_cost', targetId: 'random', multiplier: 0.5, title: '📉 재료 대풍년', message: `공급량이 너무 넘쳐흘러 [특정 재료]의 가격이 반값으로 떨어졌습니다.` },
    { weight: 15, type: 'none', title: '🕊️ 평화로운 하루', message: '오늘은 특별한 소식이 없습니다. 묵묵히 마법약을 끓이세요.' }
  ];

  // 가중치 랜덤 뽑기
  const totalWeight = events.reduce((sum, e) => sum + e.weight, 0);
  let rand = Math.random() * totalWeight;
  let selectedEvent = events[0];
  for (const e of events) {
    if (rand < e.weight) { selectedEvent = e; break; }
    rand -= e.weight;
  }

  const resultEvent = { ...selectedEvent };

  // 'random' 타겟을 실제 게임 데이터로 치환
  if (resultEvent.targetId === 'random') {
    const ing = INGREDIENTS[Math.floor(Math.random() * INGREDIENTS.length)];
    resultEvent.targetId = ing.id;
    resultEvent.message = resultEvent.message.replace('특정 재료', ing.name);
  } else if (resultEvent.targetId === 'random_unlocked') {
     const unlockedPotions = Object.keys(POTION_DB).filter(p => POTION_DB[p].reqRep <= reputation);
     const potionName = unlockedPotions[Math.floor(Math.random() * unlockedPotions.length)];
     resultEvent.targetId = potionName;
     resultEvent.message = resultEvent.message.replace('특정 물약', potionName);
  }

  return resultEvent;
};

// 재료비 계산 헬퍼 (이벤트 적용)
const getCurrentIngredientCost = (baseCost, id, currentEvent) => {
  if (!currentEvent) return baseCost;
  if (currentEvent.type === 'ingredient_cost' && currentEvent.targetId === id) {
    return Math.max(1, Math.floor(baseCost * currentEvent.multiplier));
  }
  if (currentEvent.type === 'expensive_ingredients_cost' && baseCost >= 6) {
    return Math.floor(baseCost * currentEvent.multiplier);
  }
  if (currentEvent.type === 'smuggler') {
    return Math.max(1, Math.floor(baseCost * currentEvent.costMultiplier));
  }
  return baseCost;
};

// 물약 보상 계산 헬퍼 (이벤트 적용)
const getCurrentPotionReward = (baseReward, potionName, currentEvent) => {
  if (!currentEvent) return baseReward;
  if (currentEvent.type === 'potion_reward' && currentEvent.targetId === potionName) {
    return Math.floor(baseReward * currentEvent.multiplier);
  }
  if (currentEvent.type === 'potion_group_reward' && currentEvent.targets.includes(potionName)) {
    return Math.floor(baseReward * currentEvent.multiplier);
  }
  return baseReward;
};

// 상점 아이템 가격 계산 헬퍼 (이벤트 적용)
const getCurrentItemCost = (type, currentEvent) => {
  if (currentEvent?.type === 'free_hints') return 0;
  return ITEM_COSTS[type];
};

export default function App() {
  /* =========================================================================
   * 화면 및 게임 상태 관리
   * ========================================================================= */
  const [appState, setAppState] = useState('start');
  const [hasSaveData, setHasSaveData] = useState(false);
  const [saveIndicator, setSaveIndicator] = useState(false);
  const [hasUsedLoan, setHasUsedLoan] = useState(false);
  const [pendingRoute, setPendingRoute] = useState(null);
  const [currentEvent, setCurrentEvent] = useState(null);

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

  // 이벤트에 따른 변동형 임대료
  const currentRent = currentEvent?.type === 'rent_override' ? currentEvent.rent : DAILY_RENT_BASE;

  // [수정사항 2] 기기 뒤로가기 버튼 이벤트 감지 및 종료 팝업 처리
  useEffect(() => {
    const handlePopState = (e) => {
      // 뒤로가기 동작을 막기 위해 현재 상태를 다시 history에 푸시
      window.history.pushState(null, null, window.location.pathname);
      
      const isConfirmed = window.confirm("게임을 종료하시겠습니까?\n진행사항은 자동 저장됩니다.");
      if (isConfirmed) {
        // Capacitor, Cordova, 일반 웹뷰 등 환경에 맞는 앱 종료 처리
        if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.App) {
          window.Capacitor.Plugins.App.exitApp();
        } else if (window.navigator && window.navigator.app && window.navigator.app.exitApp) {
          window.navigator.app.exitApp();
        } else {
          window.close();
        }
      }
    };

    // 초기 history state 삽입
    window.history.pushState(null, null, window.location.pathname);
    window.addEventListener('popstate', handlePopState);

    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem(SAVE_KEY);
    if (saved) setHasSaveData(true);
    const tut = localStorage.getItem(TUTORIAL_KEY);
    if (tut === 'true') setHasSeenTutorial(true);
  }, []);

  useEffect(() => {
    if (appState === 'shop' || appState === 'day_end') {
      const saveData = { day, money, reputation, inventory, dailyCustomers, currentCustomerIndex, hasUsedLoan, currentEvent };
      localStorage.setItem(SAVE_KEY, JSON.stringify(saveData));
      setHasSaveData(true);

      setSaveIndicator(true);
      const timer = setTimeout(() => setSaveIndicator(false), 2000);
      return () => clearTimeout(timer);
    }
  }, [appState, day, money, reputation, inventory, dailyCustomers, currentCustomerIndex, hasUsedLoan, currentEvent]);

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
      setHasUsedLoan(data.hasUsedLoan || false);
      setCurrentEvent(data.currentEvent || null);
      setAppState('shop');
    }
  };

  const startGame = () => {
    if (hasSaveData && !window.confirm('기존 저장 데이터가 지워집니다. 정말 새로 시작하시겠습니까?')) return;
    setDay(1);
    setMoney(50);
    setReputation(50);
    setInventory({ hintIngredient: 0, hintSlot: 0 });
    setHasUsedLoan(false);
    setCurrentEvent(null);
    
    setHasSeenTutorial(false);
    localStorage.removeItem(TUTORIAL_KEY);
    
    startNewDay(1, null, true); 
  };

  /**
   * 새로운 하루 큐 및 이벤트 생성
   */
  const startNewDay = (currentDay, lastDayFinalCustomerType, isNewGame = false) => {
    const customersCount = 2 + Math.floor(currentDay / 3);
    const queue = [];
    
    // 이벤트 생성
    const newEvent = generateDailyEvent(currentDay, reputation);
    
    if (currentDay === 1) {
      if (!hasSeenTutorial || isNewGame) {
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
    } 
    // 대유행(Viral) 이벤트인 경우 큐를 전부 같은 물약 퀘스트로 채움
    else if (newEvent?.type === 'viral_potion') {
      const viralPotionName = newEvent.targetId;
      const potionInfo = POTION_DB[viralPotionName];
      const matchingQuests = ALL_QUESTS.filter(q => q.potionName === viralPotionName);
      
      for(let i=0; i < (customersCount > 5 ? 5 : customersCount); i++) {
        const quest = matchingQuests[Math.floor(Math.random() * matchingQuests.length)];
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
    // 일반 큐 생성
    else {
      let maxSlotsAllowed = 3;
      if (currentDay >= 3) maxSlotsAllowed = 4;
      if (currentDay >= 5) maxSlotsAllowed = 5;

      let availableQuests = ALL_QUESTS.filter(q => POTION_DB[q.potionName].slots <= maxSlotsAllowed && POTION_DB[q.potionName].reqRep <= reputation)
                                      .sort(() => Math.random() - 0.5);

      const usedTypes = new Set([lastDayFinalCustomerType]);
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

    setCurrentEvent(newEvent);
    setDailyCustomers(queue);
    setCurrentCustomerIndex(0);
    setDay(currentDay);
    setAppState(newEvent ? 'daily_event' : 'shop');
    setIsDiagnosing(false);
    setDiagnosisFeedback(null);
    setDailySalesRevenue(0);
    setDailyIngredientCost(0);
  };

  const currentCustomer = dailyCustomers[currentCustomerIndex];

  // 상점 아이템 구매
  const buyItem = (type) => {
    const cost = getCurrentItemCost(type, currentEvent);
    if (money < cost) return;
    setMoney(prev => prev - cost);
    setInventory(prev => ({ ...prev, [type]: prev[type] + 1 }));
  };

  // 다음 손님으로
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
   * 진단(처방) 핸들러 (오진 시 이벤트에 따른 명성 패널티 조절)
   */
  const handleDiagnose = (selectedPotion) => {
    if (selectedPotion === currentCustomer.potionName) {
      setDiagnosisFeedback('success');
      setTimeout(() => { acceptOrder(); }, 1200);
    } else {
      setDiagnosisFeedback('fail');
      let penalty = 10;
      if (currentEvent?.type === 'critic_day') penalty *= currentEvent.repPenaltyMultiplier; // 비평가 2배 패널티
      
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
   * 정중히 거절 핸들러 (이벤트에 따른 거절 패널티 조절)
   */
  const handleReject = () => {
    setDiagnosisFeedback('reject');
    let penalty = 2;
    if (currentEvent?.type === 'critic_day') penalty *= currentEvent.repPenaltyMultiplier; // 비평가 2배 패널티

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
  };

  // 미니게임 초기화
  const acceptOrder = () => {
    const slotsCount = currentCustomer.slots;

    if (tutorial.isActive) {
      setSecretRecipe(['8', '2', '9']);
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

  // 재료 클릭 (워들 입력)
  const handleIngredientClick = (id) => {
    if (minigameResult || brewPhase !== 'idle') return;

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

  // 가마솥 슬롯 클릭
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
      handleIngredientClick(guessId);
      if (selectedSlotIndex === index) setSelectedSlotIndex(null);
    } else {
      setSelectedSlotIndex(selectedSlotIndex === index ? null : index);
    }
  };

  // 조합 (미니게임 제출)
  const handleBrew = () => {
    if (currentGuess.includes(null) || brewPhase !== 'idle') return;

    const brewCost = currentGuess.reduce((total, id) => {
      const ingredient = INGREDIENTS.find(ing => ing.id === id);
      return total + (ingredient ? getCurrentIngredientCost(ingredient.cost, id, currentEvent) : 0);
    }, 0);

    // [수정사항 1] 조합 시 비용이 부족할 때 대출 이벤트 발생
    if (!tutorial.isActive && money < brewCost) {
      if (!hasUsedLoan) {
        setActiveItemMode(null);
        setSelectedSlotIndex(null);
        setPendingRoute('minigame'); // 대출 후 미니게임으로 복귀하도록 경로 설정
        setAppState('loan_event');
      } else {
        alert("자금이 부족합니다! 더 저렴한 재료를 조합하거나 상점 아이템을 활용하세요.");
      }
      return;
    }

    setActiveItemMode(null);
    setSelectedSlotIndex(null);

    const newMoney = tutorial.isActive ? money : money - brewCost;
    if (!tutorial.isActive) {
      setMoney(newMoney);
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
          } else if (newMoney < MIN_INGREDIENT_COST) {
            finishOrder(false, newHistory.length);
          }
        }
      }, 1500);
    }, 1200);
  };

  /**
   * 주문 완료 계산 (이벤트 기반 보상 보정)
   */
  const finishOrder = (isWin, attempts) => {
    let earnedMoney = 0;
    let earnedRep = 0;
    let tip = 0;
    const base = getCurrentPotionReward(currentCustomer.baseReward, currentCustomer.potionName, currentEvent);

    if (isWin) {
      const remainingAttempts = currentCustomer.maxAttempts - attempts;
      let tipCalc = Math.floor(base * (remainingAttempts * 0.15));
      if (currentEvent?.type === 'global_tip') tipCalc = Math.floor(tipCalc * currentEvent.multiplier); // 축제 팁 2배

      tip = tipCalc;
      earnedMoney = base + tip;
      
      earnedRep = 10;
      if (currentEvent?.type === 'critic_day') earnedRep *= currentEvent.repMultiplier; // 비평가 명성 2배
      if (currentEvent?.type === 'smuggler') earnedRep *= currentEvent.repMultiplier; // 밀수업자 명성 반토막

    } else {
      earnedMoney = 0;
      earnedRep = -15;
      if (currentEvent?.type === 'critic_day') earnedRep *= currentEvent.repPenaltyMultiplier; // 비평가 실패 패널티 2배
    }

    setMinigameResult({ status: isWin ? 'win' : 'lose', baseReward: base, tip, earnedMoney, earnedRep, attempts });
  };

  // 상점 복귀 후 반영
  const returnToShop = () => {
    if (tutorial.isActive) {
      setTutorial({ isActive: true, step: 'day_end_1' });
    }

    const newReputation = reputation + minigameResult.earnedRep;
    const newMoney = money + minigameResult.earnedMoney;
    setMoney(newMoney);
    setReputation(newReputation);
    if (minigameResult.earnedMoney > 0) {
      setDailySalesRevenue(prev => prev + minigameResult.earnedMoney);
    }

    if (newReputation <= 0) {
      setAppState('game_over');
      localStorage.removeItem(SAVE_KEY);
      setHasSaveData(false);
    } else if (newMoney < MIN_INGREDIENT_COST) {
      if (!hasUsedLoan) {
        setPendingRoute('next_customer');
        setAppState('loan_event');
      } else {
        setAppState('game_over');
        localStorage.removeItem(SAVE_KEY);
        setHasSaveData(false);
      }
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

  /* =========================================================================
   * 상단 상태 바 UI
   * ========================================================================= */
  const renderTopBar = () => (
    <div className="flex items-center justify-between bg-slate-800 p-3 sm:p-4 rounded-xl border border-slate-700 shadow-md mb-2 sm:mb-4 relative z-20 shrink-0">
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

  const isIntro1 = tutorial.isActive && tutorial.step === 'intro_1';

  /* =========================================================================
   * 메인 렌더링
   * ========================================================================= */

  // [start] 타이틀 화면
  if (appState === 'start') {
    return (
      <div className="h-[100svh] bg-slate-900 flex flex-col items-center justify-center p-4 overflow-y-auto">
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
            <span className="text-purple-300 font-bold">마법약 레시피</span>를 추리하여 완벽하게 조제하세요!<br/><br/>
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

  // [daily_event] 매일 아침 뉴스/이벤트 표시
  if (appState === 'daily_event' && currentEvent) {
    const isBadEvent = ['expensive_ingredients_cost', 'rent_override'].includes(currentEvent.type) || (currentEvent.type === 'ingredient_cost' && currentEvent.multiplier > 1);
    const isGoodEvent = ['global_tip', 'potion_group_reward', 'free_hints', 'viral_potion'].includes(currentEvent.type) || currentEvent.type === 'potion_reward' || (currentEvent.type === 'ingredient_cost' && currentEvent.multiplier < 1);
    
    return (
      <div className="h-[100svh] bg-slate-900 flex flex-col items-center justify-center p-4 text-center overflow-y-auto">
        <div className={`bg-slate-800 border-2 rounded-3xl p-8 sm:p-10 max-w-md w-full relative overflow-hidden animate-in zoom-in duration-500 shadow-2xl ${
          isBadEvent ? 'border-red-500/50 shadow-[0_0_40px_rgba(239,68,68,0.2)]' :
          isGoodEvent ? 'border-yellow-500/50 shadow-[0_0_40px_rgba(234,179,8,0.2)]' :
          'border-slate-500/50'
        }`}>
          <div className={`absolute top-0 left-0 w-full h-2 bg-gradient-to-r ${isBadEvent ? 'from-red-600 to-red-400' : isGoodEvent ? 'from-yellow-500 to-green-500' : 'from-blue-500 to-purple-500'}`}></div>
          
          <div className="flex justify-center mb-4 sm:mb-6">
            <div className="bg-slate-900 p-4 rounded-full border border-slate-700 shadow-inner relative">
              {currentEvent.type === 'viral_potion' && <Flame className="w-12 h-12 sm:w-16 sm:h-16 text-orange-500 animate-bounce" />}
              {currentEvent.type === 'smuggler' && <Skull className="w-12 h-12 sm:w-16 sm:h-16 text-slate-400" />}
              {currentEvent.type === 'critic_day' && <Eye className="w-12 h-12 sm:w-16 sm:h-16 text-blue-400" />}
              {currentEvent.type === 'rent_override' && <TrendingUp className="w-12 h-12 sm:w-16 sm:h-16 text-red-500" />}
              {!['viral_potion', 'smuggler', 'critic_day', 'rent_override'].includes(currentEvent.type) && <Newspaper className={`w-12 h-12 sm:w-16 sm:h-16 ${isBadEvent ? 'text-red-400' : 'text-blue-400'}`} />}
            </div>
          </div>
          
          <div className="bg-blue-900/30 text-blue-300 text-xs sm:text-sm font-bold px-3 py-1 rounded-full inline-block mb-3 sm:mb-4 border border-blue-500/30">
            Day {day} 오늘의 특종
          </div>
          
          <h1 className={`text-2xl sm:text-3xl font-black mb-4 ${isBadEvent ? 'text-red-400' : isGoodEvent ? 'text-yellow-400' : 'text-white'}`}>{currentEvent.title}</h1>
          <p className="text-slate-300 text-sm sm:text-base bg-slate-900/60 p-4 sm:p-5 rounded-xl border border-slate-700/50 leading-relaxed mb-8 break-keep">
            {currentEvent.message}
          </p>
          
          <button 
            onClick={() => setAppState('shop')}
            className="w-full py-4 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl shadow-[0_0_20px_rgba(79,70,229,0.4)] transition-all transform hover:scale-[1.02] flex items-center justify-center gap-2 text-base sm:text-lg"
          >
            영업 시작하기 <ArrowRight className="w-5 h-5"/>
          </button>
        </div>
      </div>
    );
  }

  // [game_over] 파산 화면
  if (appState === 'game_over') {
    let gameOverMessage = "명성이 바닥에 떨어져 상점 문을 닫습니다...";
    if (money < 0) {
      gameOverMessage = "상점 유지비를 내지 못해 쫓겨났습니다...";
    } else if (reputation > 0 && money < MIN_INGREDIENT_COST) {
      gameOverMessage = "재료를 살 돈조차 남아있지 않아 파산했습니다...";
    }

    return (
      <div className="h-[100svh] bg-slate-900 flex flex-col items-center justify-center p-4 text-center overflow-y-auto">
        <div className="bg-slate-800 border-2 border-red-500/50 rounded-3xl p-8 sm:p-10 max-w-md w-full shadow-[0_0_50px_rgba(239,68,68,0.2)] relative overflow-hidden animate-in zoom-in duration-500">
          <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-red-600 to-red-400"></div>
          
          <div className="flex justify-center mb-6">
            <div className="relative">
              <AlertCircle className="w-20 h-20 sm:w-24 sm:h-24 text-red-500 animate-pulse" />
            </div>
          </div>
          
          <h1 className="text-3xl sm:text-4xl font-black text-white mb-3 tracking-tight">파산했습니다</h1>
          <p className="text-slate-400 mb-8 text-sm sm:text-base bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
            {gameOverMessage}
          </p>
          
          <div className="grid grid-cols-2 gap-4 mb-8">
            <div className="bg-slate-900 p-4 rounded-2xl border border-slate-700 flex flex-col items-center justify-center">
              <span className="text-slate-500 text-xs sm:text-sm font-bold mb-1">최종 생존</span>
              <span className="text-2xl sm:text-3xl font-black text-white">Day {day}</span>
            </div>
            <div className="bg-slate-900 p-4 rounded-2xl border border-slate-700 flex flex-col items-center justify-center">
              <span className="text-slate-500 text-xs sm:text-sm font-bold mb-1">남은 자금</span>
              <span className="text-2xl sm:text-3xl font-black text-yellow-400 flex items-center gap-1">
                {money} <Coins className="w-4 h-4 sm:w-5 sm:h-5"/>
              </span>
            </div>
          </div>
          
          <button 
            onClick={startGame} 
            className="w-full py-4 bg-red-600 hover:bg-red-500 text-white font-bold rounded-xl shadow-[0_0_20px_rgba(220,38,38,0.4)] transition-all transform hover:scale-[1.02] flex items-center justify-center gap-2 text-base sm:text-lg"
          >
            <RotateCcw className="w-5 h-5 sm:w-6 sm:h-6"/> 처음부터 다시 시작
          </button>
        </div>
      </div>
    );
  }

  // [loan_event] 긴급 구제 금융 화면
  if (appState === 'loan_event') {
    return (
      <div className="h-[100svh] bg-slate-900 flex flex-col items-center justify-center p-4 text-center overflow-y-auto">
        <div className="bg-slate-800 border-2 border-amber-500/50 rounded-3xl p-8 sm:p-10 max-w-md w-full shadow-[0_0_50px_rgba(245,158,11,0.2)] relative overflow-hidden animate-in zoom-in duration-500">
          <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-amber-600 to-yellow-400"></div>
          <div className="flex justify-center mb-6">
            <div className="relative">
              <Coins className="w-20 h-20 sm:w-24 sm:h-24 text-amber-500 animate-bounce" />
            </div>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-white mb-3 tracking-tight">상인 길드의 구제 금융</h1>
          <p className="text-slate-300 mb-6 text-sm sm:text-base leading-relaxed bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
            자금이 바닥났군요! 하지만 상점의 잠재력을 본 길드에서 <span className="text-yellow-400 font-bold">마지막으로 50G</span>를 대출해 주기로 했습니다.
          </p>
          <div className="bg-slate-900 p-4 rounded-xl border border-slate-700 flex justify-between items-center mb-8">
            <span className="text-slate-400 font-bold">대출 후 보유 자금</span>
            <span className="text-2xl font-black text-yellow-400 flex items-center gap-1">
              {money + 50} <Coins className="w-5 h-5"/>
            </span>
          </div>
          <button
            onClick={() => {
              setHasUsedLoan(true);
              setMoney(prev => prev + 50);
              if (pendingRoute === 'next_customer') moveToNextCustomer();
              else if (pendingRoute === 'next_day') startNewDay(day + 1, dailyCustomers[dailyCustomers.length - 1].type);
              else if (pendingRoute === 'minigame') setAppState('minigame'); // [수정사항 1] 미니게임으로 복귀 처리 추가
            }}
            className="w-full py-4 bg-amber-600 hover:bg-amber-500 text-white font-bold rounded-xl shadow-[0_0_20px_rgba(217,119,6,0.4)] transition-all transform hover:scale-[1.02] flex items-center justify-center gap-2 text-base sm:text-lg"
          >
            50G 받고 재도전하기
          </button>
        </div>
      </div>
    );
  }

  const netProfit = dailySalesRevenue - dailyIngredientCost - currentRent;

  // 공통 레이아웃 구조 반환
  return (
    <div className="h-[100svh] bg-slate-900 text-slate-100 p-2 sm:p-4 font-sans selection:bg-purple-500/30 flex flex-col overflow-hidden">
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
        @keyframes pulse-slow { 0%, 100% { opacity: 0.3; transform: scale(1); } 50% { opacity: 0.6; transform: scale(1.1); } }
        .animate-pulse-slow { animation: pulse-slow 3s ease-in-out infinite; }
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

      <div className="max-w-2xl mx-auto w-full relative flex-1 flex flex-col min-h-0">
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
                    disabled={money < getCurrentItemCost('hintIngredient', currentEvent)}
                    className={`ml-2 px-2 py-1.5 sm:px-3 sm:py-2 rounded-lg text-xs sm:text-sm font-bold flex flex-col items-center min-w-[60px] sm:min-w-[70px] transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${money < getCurrentItemCost('hintIngredient', currentEvent) ? 'bg-slate-800 text-slate-500 border-slate-700' : 'bg-slate-800 hover:bg-yellow-900 border border-yellow-500 text-yellow-300'}`}
                  >
                    <span>{getCurrentItemCost('hintIngredient', currentEvent) === 0 ? '무료!' : `${getCurrentItemCost('hintIngredient', currentEvent)} G`}</span>
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
                    disabled={money < getCurrentItemCost('hintSlot', currentEvent)}
                    className={`ml-2 px-2 py-1.5 sm:px-3 sm:py-2 rounded-lg text-xs sm:text-sm font-bold flex flex-col items-center min-w-[60px] sm:min-w-[70px] transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${money < getCurrentItemCost('hintSlot', currentEvent) ? 'bg-slate-800 text-slate-500 border-slate-700' : 'bg-slate-800 hover:bg-yellow-900 border border-yellow-500 text-yellow-300'}`}
                  >
                    <span>{getCurrentItemCost('hintSlot', currentEvent) === 0 ? '무료!' : `${getCurrentItemCost('hintSlot', currentEvent)} G`}</span>
                    <span className="text-[10px] sm:text-xs text-slate-400">보유: {inventory.hintSlot}</span>
                  </button>
                </div>
              </div>

              <div className="mt-4 sm:mt-6 text-center text-xs sm:text-sm text-slate-500">
                {currentEvent?.type === 'free_hints' ? '유성우의 기운으로 오늘 하루 무료입니다!' : '아이템은 조제실(미니게임)에서 사용할 수 있습니다.'}
              </div>
            </div>
          </div>
        )}

        {/* [shop] 손님 응대 화면 */}
        {appState === 'shop' && currentCustomer && (
          <div className="bg-slate-900 rounded-t-3xl border-4 border-slate-700 flex-1 min-h-0 overflow-hidden relative shadow-2xl flex flex-col justify-end animate-in fade-in duration-500">
            
            {/* 배경: 마법 물약 상점 */}
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-indigo-900/60 via-slate-900 to-black overflow-hidden">
              <div className="absolute top-[10%] right-[15%] text-yellow-500/20 animate-pulse-slow"><Sparkles className="w-24 h-24" /></div>
              <div className="absolute top-[40%] left-[10%] text-purple-500/20 animate-pulse-slow" style={{animationDelay: '1.5s'}}><Sparkles className="w-16 h-16" /></div>

              {/* 선반 1 */}
              <div className="absolute top-[25%] w-full h-3 sm:h-4 bg-amber-900/40 border-t border-amber-800/50 shadow-[0_5px_15px_rgba(0,0,0,0.6)]">
                <div className="absolute bottom-full left-[10%] flex items-end gap-2 sm:gap-4 mb-[-2px]">
                  <div className="w-4 h-6 sm:w-6 sm:h-8 bg-red-500/80 rounded-t-xl rounded-b-sm shadow-[0_0_15px_rgba(239,68,68,0.4)] border border-red-400/40 relative">
                    <div className="absolute top-1 left-1 w-1 h-2 bg-white/30 rounded-full"></div>
                  </div>
                  <div className="w-6 h-5 sm:w-8 sm:h-6 bg-blue-500/80 rounded-full shadow-[0_0_15px_rgba(59,130,246,0.4)] border border-blue-400/40 mb-0.5 relative">
                    <div className="absolute top-1 left-2 w-2 h-1 bg-white/30 rounded-full"></div>
                  </div>
                  <div className="w-8 h-10 sm:w-10 sm:h-12 bg-purple-900 border-l-4 border-purple-700/80 shadow-lg -rotate-12 transform origin-bottom-left"></div>
                </div>
                <div className="absolute bottom-full right-[15%] flex items-end gap-2 mb-[-2px]">
                   <div className="w-3 h-8 sm:w-4 sm:h-10 bg-green-500/80 rounded-t-sm shadow-[0_0_15px_rgba(34,197,94,0.4)] border border-green-400/40"></div>
                   <div className="w-5 h-7 sm:w-6 sm:h-9 bg-yellow-500/80 rounded-t-3xl shadow-[0_0_15px_rgba(234,179,8,0.4)] border border-yellow-400/40"></div>
                </div>
              </div>

              {/* 선반 2 */}
              <div className="absolute top-[55%] w-full h-3 sm:h-4 bg-amber-900/40 border-t border-amber-800/50 shadow-[0_5px_15px_rgba(0,0,0,0.6)]">
                <div className="absolute bottom-full left-[25%] flex items-end gap-1 mb-[-2px]">
                   <div className="w-5 h-5 sm:w-7 sm:h-7 bg-purple-500/80 rounded-sm shadow-[0_0_15px_rgba(168,85,247,0.4)] border border-purple-400/40 transform rotate-6"></div>
                   <div className="w-4 h-7 sm:w-5 sm:h-9 bg-cyan-500/80 rounded-t-lg shadow-[0_0_15px_rgba(6,182,212,0.4)] border border-cyan-400/40"></div>
                </div>
                <div className="absolute bottom-full right-[25%] flex items-end mb-[-2px]">
                   <div className="w-12 h-10 sm:w-16 sm:h-12 bg-slate-800 rounded-b-3xl rounded-t-md shadow-lg border-t-2 border-slate-600 relative overflow-hidden">
                     <div className="absolute top-0 w-full h-2 bg-green-500/50 animate-pulse"></div>
                   </div>
                </div>
              </div>
            </div>

            {!isIntro1 && (
              <div className="absolute top-3 left-3 sm:top-4 sm:left-4 bg-slate-900/80 px-2 py-1 sm:px-3 sm:py-1 rounded-full text-xs sm:text-sm font-semibold text-slate-300 flex items-center gap-1 sm:gap-2 z-10 border border-slate-700">
                <Users className="w-3 h-3 sm:w-4 sm:h-4" /> 
                대기표: {currentCustomerIndex + 1} / {dailyCustomers.length}
              </div>
            )}

            {!isIntro1 && (
              <div className="relative z-10 flex flex-col items-center animate-walk-in pt-12 sm:pt-0">
                <div className="bg-white text-slate-900 p-3 sm:p-5 rounded-2xl rounded-br-none mb-2 sm:mb-4 shadow-xl w-[90%] sm:max-w-sm relative mx-auto animate-pop-up">
                  <h3 className="text-base sm:text-lg font-black text-slate-800 mb-1">{currentCustomer.name}</h3>
                  <p className={`text-xs sm:text-base italic font-medium leading-relaxed break-keep transition-colors ${diagnosisFeedback === 'reject' ? 'text-slate-500 font-bold' : 'text-slate-700'}`}>
                    "{diagnosisFeedback === 'reject' ? REJECT_DIALOGUES[currentCustomer.type] : currentCustomer.dialogue}"
                  </p>
                  
                  <div className="mt-2 sm:mt-4 pt-2 sm:pt-3 border-t border-slate-200 flex justify-between items-end gap-1 sm:gap-2">
                    <div className="flex flex-col flex-1">
                      <span className="text-[10px] sm:text-xs text-slate-500 font-bold mb-0.5 sm:mb-1">상태</span>
                      <span className="bg-slate-100 text-slate-600 px-2 py-1 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-bold flex items-center gap-1 w-fit">
                        <Search className="w-3 h-3" /> 대기중...
                      </span>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[10px] sm:text-xs text-slate-500 font-bold mb-0.5 sm:mb-1">예상 보수</span>
                      <span className={`font-black flex items-center gap-1 text-sm sm:text-base ${['potion_reward', 'potion_group_reward'].includes(currentEvent?.type) && (currentEvent.targetId === currentCustomer.potionName || currentEvent.targets?.includes(currentCustomer.potionName)) ? 'text-green-600 animate-pulse' : 'text-amber-600'}`}>
                        {getCurrentPotionReward(currentCustomer.baseReward, currentCustomer.potionName, currentEvent)} G
                        {['potion_reward', 'potion_group_reward'].includes(currentEvent?.type) && (currentEvent.targetId === currentCustomer.potionName || currentEvent.targets?.includes(currentCustomer.potionName)) && (
                          <TrendingUp className="w-4 h-4 ml-0.5" />
                        )}
                      </span>
                    </div>
                  </div>
                  <div className="absolute -bottom-3 right-6 sm:-bottom-4 sm:right-10 w-0 h-0 border-l-[12px] sm:border-l-[16px] border-l-transparent border-t-[12px] sm:border-t-[16px] border-t-white border-r-[12px] sm:border-r-[16px] border-r-transparent"></div>
                </div>

                {diagnosisFeedback && (
                  <div className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 text-2xl sm:text-4xl font-black px-4 sm:px-6 py-3 sm:py-4 rounded-2xl shadow-2xl animate-bounce border-4 whitespace-nowrap flex items-center gap-1 sm:gap-2 ${diagnosisFeedback === 'success' ? 'bg-green-100 text-green-600 border-green-500' : diagnosisFeedback === 'fail' ? 'bg-red-100 text-red-600 border-red-500' : 'bg-slate-100 text-slate-600 border-slate-500'}`}>
                    {diagnosisFeedback === 'success' ? <><CheckCircle2 className="w-6 h-6 sm:w-10 sm:h-10"/> 성공!</> : diagnosisFeedback === 'fail' ? <><XCircle className="w-6 h-6 sm:w-10 sm:h-10"/> 오진!</> : <><Ban className="w-6 h-6 sm:w-10 sm:h-10"/> 거절함</>}
                  </div>
                )}

                <div className={`text-[80px] sm:text-[120px] leading-none filter drop-shadow-[0_10px_10px_rgba(0,0,0,0.5)] translate-y-2 transition-all ${diagnosisFeedback === 'fail' || diagnosisFeedback === 'reject' ? 'grayscale opacity-50' : ''}`}>
                  {currentCustomer.emoji}
                </div>
              </div>
            )}

            <div className="bg-amber-900 w-full border-t-[8px] sm:border-t-[12px] border-amber-800 shadow-[0_-10px_30px_rgba(0,0,0,0.5)] z-20 relative shrink-0">
              <div className="absolute top-0 w-full h-1 sm:h-2 bg-white/10"></div>
              
              {!isIntro1 ? (
                !isDiagnosing ? (
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
                  <div className="bg-slate-800 border-t-4 border-slate-600 p-3 sm:p-5 animate-slide-up rounded-t-3xl max-h-[42svh] sm:max-h-[380px] overflow-y-auto custom-scrollbar shadow-[0_-10px_20px_rgba(0,0,0,0.3)] flex flex-col">
                    <div className="flex justify-between items-center mb-3 sm:mb-4 sticky top-0 bg-slate-800 py-2 z-20">
                      <h3 className="text-white font-bold flex items-center gap-1 sm:gap-2 text-sm sm:text-lg"><ScrollText className="w-4 h-4 sm:w-5 sm:h-5 text-indigo-400"/> 알맞은 약을 고르세요</h3>
                      <div className="flex items-center gap-2">
                        <button 
                          onClick={handleReject} 
                          disabled={diagnosisFeedback !== null || tutorial.isActive}
                          className="text-xs sm:text-sm px-2 py-1 sm:px-3 sm:py-1.5 bg-slate-700 hover:bg-red-900/60 text-slate-300 hover:text-red-400 border border-slate-600 hover:border-red-500/50 rounded-lg transition-colors flex items-center gap-1 disabled:opacity-50"
                        >
                          <Ban className="w-3 h-3 sm:w-4 sm:h-4"/> 정중히 거절 (-{currentEvent?.type === 'critic_day' ? 4 : 2} 명성)
                        </button>
                        <button onClick={() => setIsDiagnosing(false)} className="text-slate-400 hover:text-white bg-slate-700 p-1.5 rounded-lg transition-colors ml-1">
                          <X className="w-4 h-4 sm:w-5 sm:h-5"/>
                        </button>
                      </div>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3 overflow-y-auto pr-1">
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
                )
              ) : (
                <div className="h-20 sm:h-32 flex items-center justify-center px-4"></div>
              )}
            </div>
          </div>
        )}

        {/* [minigame] 재료 조합 화면 */}
        {appState === 'minigame' && (
          <div className="flex flex-col flex-1 min-h-0 gap-2 sm:gap-3 overflow-y-auto pb-2">

            {/* 물약 이름 배너 */}
            <div className="bg-slate-800 px-3 py-2 sm:px-4 sm:py-2.5 rounded-xl border border-purple-700/60 flex items-center justify-between shrink-0 shadow-sm">
              <div className="flex items-center gap-2 min-w-0">
                <FlaskConical className="w-4 h-4 sm:w-5 sm:h-5 text-purple-400 shrink-0" />
                <span className="text-sm sm:text-base font-bold text-white truncate">{currentCustomer?.potionName}</span>
              </div>
              <span className="text-xs text-slate-400 shrink-0 ml-2">
                {history.length} / {currentCustomer?.maxAttempts} 시도
              </span>
            </div>

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
                      {currentEvent?.type === 'critic_day' && (
                        <span className="text-[10px] text-red-400 font-bold mt-1">비평가 2배 적용!</span>
                      )}
                      {currentEvent?.type === 'smuggler' && minigameResult.status === 'win' && (
                        <span className="text-[10px] text-slate-400 font-bold mt-1">밀수 소문 반토막</span>
                      )}
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

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2 sm:gap-3 shrink-0">
              <div className={`bg-slate-800 p-2 sm:p-4 rounded-xl border transition-all ${activeItemMode === 'hintIngredient' ? 'animate-pulse-glow' : 'border-slate-700'}`}>
                <div className="flex justify-between items-center mb-1 sm:mb-3">
                  <h3 className="text-sm sm:text-lg font-semibold text-slate-200">재료 선반</h3>
                  <div className="flex items-center gap-1">
                    {activeItemMode && (
                      <span className="text-[10px] text-blue-300 font-bold animate-pulse mr-0.5">
                        {activeItemMode === 'hintIngredient' ? '감별할 재료 클릭!' : '투시할 칸 클릭!'}
                      </span>
                    )}
                    <button
                      onClick={() => setActiveItemMode(activeItemMode === 'hintIngredient' ? null : 'hintIngredient')}
                      disabled={inventory.hintIngredient <= 0 || brewPhase !== 'idle' || tutorial.isActive}
                      title={`재료 감별 돋보기 (${inventory.hintIngredient}개)`}
                      className={`relative p-1.5 rounded-lg transition-all ${
                        activeItemMode === 'hintIngredient'
                          ? 'bg-indigo-600 text-white shadow-[0_0_10px_rgba(79,70,229,0.8)]'
                          : inventory.hintIngredient > 0 && !tutorial.isActive
                          ? 'bg-slate-700 hover:bg-slate-600 text-indigo-300'
                          : 'bg-slate-900 text-slate-600 cursor-not-allowed'
                      }`}
                    >
                      <Search className="w-3.5 h-3.5" />
                      {inventory.hintIngredient > 0 && (
                        <span className="absolute -top-1 -right-1 bg-indigo-500 text-white text-[8px] w-3.5 h-3.5 rounded-full flex items-center justify-center font-bold leading-none">{inventory.hintIngredient}</span>
                      )}
                    </button>
                    <button
                      onClick={() => setActiveItemMode(activeItemMode === 'hintSlot' ? null : 'hintSlot')}
                      disabled={inventory.hintSlot <= 0 || brewPhase !== 'idle' || tutorial.isActive}
                      title={`슬롯 투시 구슬 (${inventory.hintSlot}개)`}
                      className={`relative p-1.5 rounded-lg transition-all ${
                        activeItemMode === 'hintSlot'
                          ? 'bg-purple-600 text-white shadow-[0_0_10px_rgba(147,51,234,0.8)]'
                          : inventory.hintSlot > 0 && !tutorial.isActive
                          ? 'bg-slate-700 hover:bg-slate-600 text-purple-300'
                          : 'bg-slate-900 text-slate-600 cursor-not-allowed'
                      }`}
                    >
                      <Eye className="w-3.5 h-3.5" />
                      {inventory.hintSlot > 0 && (
                        <span className="absolute -top-1 -right-1 bg-purple-500 text-white text-[8px] w-3.5 h-3.5 rounded-full flex items-center justify-center font-bold leading-none">{inventory.hintSlot}</span>
                      )}
                    </button>
                    <button
                      onClick={() => setShowShopModal(true)}
                      disabled={tutorial.isActive}
                      title="도구 상점"
                      className={`p-1.5 rounded-lg transition-colors relative ${tutorial.isActive ? 'bg-slate-900 text-slate-600 cursor-not-allowed' : 'bg-yellow-900/60 hover:bg-yellow-800 text-yellow-300 border border-yellow-600/40'}`}
                    >
                      {currentEvent?.type === 'free_hints' && <div className="absolute -top-1 -right-1 flex h-2 w-2"><span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span><span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span></div>}
                      <ShoppingBag className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
                <div className="grid grid-cols-5 md:grid-cols-5 gap-1 sm:gap-2">
                  {INGREDIENTS.map(item => {
                    const isSelected = currentGuess.includes(item.id);
                    const isKnown = knownIngredients[item.id] !== undefined;
                    const isItemTarget = activeItemMode === 'hintIngredient' && !isKnown;
                    const tutAllowedId = getTutorialAllowedIngredient();
                    const isTutTarget = tutorial.isActive && tutAllowedId === item.id;
                    const isTutDisabled = tutorial.isActive && tutAllowedId !== item.id;
                    const currentCost = getCurrentIngredientCost(item.cost, item.id, currentEvent);
                    const isPriceChanged = currentCost !== item.cost;

                    return (
                      <button
                        key={item.id}
                        onClick={() => handleIngredientClick(item.id)}
                        disabled={minigameResult !== null || brewPhase !== 'idle' || (!isItemTarget && !isSelected && !currentGuess.includes(null)) || (activeItemMode === 'hintIngredient' && isKnown) || isTutDisabled}
                        className={`
                          relative p-1.5 sm:p-3 min-h-[52px] sm:minh-[72px] rounded-xl flex flex-col items-center justify-center transition-all duration-300 border-2
                          ${isSelected && !activeItemMode ? 'bg-slate-700 border-purple-500 shadow-[0_0_12px_rgba(168,85,247,0.5)] transform scale-105 z-10' : 'bg-slate-900 border-slate-700'}
                          ${isItemTarget ? 'hover:border-indigo-400 hover:shadow-[0_0_12px_rgba(99,102,241,0.5)] cursor-crosshair z-10' : ''}
                          ${(!activeItemMode && !isSelected && !currentGuess.includes(null)) || isTutDisabled ? 'opacity-40 cursor-not-allowed' : 'hover:-translate-y-1'}
                          ${isTutTarget ? 'ring-4 ring-indigo-400 animate-pulse border-indigo-400 bg-indigo-900/30 z-20' : ''}
                          ${isPriceChanged ? 'overflow-hidden' : ''}
                        `}
                      >
                        <span className="text-2xl sm:text-3xl mb-1 drop-shadow-md">{item.emoji}</span>
                        <span className="text-[9px] sm:text-[11px] text-center text-slate-300 leading-tight break-keep font-medium">{item.name}</span>
                        <span className={`text-[8px] sm:text-[10px] font-black mt-0.5 flex items-center gap-0.5 ${currentCost > item.cost ? 'text-red-400' : currentCost < item.cost ? 'text-green-400' : 'text-yellow-500'}`}>
                          {currentCost}G
                          {currentCost > item.cost && <TrendingUp className="w-2.5 h-2.5" />}
                          {currentCost < item.cost && <TrendingDown className="w-2.5 h-2.5" />}
                        </span>
                        
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
                bg-slate-800 p-2 sm:p-5 rounded-xl border flex flex-col relative overflow-hidden transition-all duration-500
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

                <h3 className="text-sm sm:text-lg font-semibold text-slate-200 mb-1 sm:mb-3 text-center z-10 relative">투입된 재료 ({currentCustomer.slots}칸)
                  {currentGuess.some(id => id !== null) && (
                    <span className="ml-2 text-xs text-red-400 font-normal">
                      {tutorial.isActive ? (
                        <span className="line-through opacity-60">재료비: {currentGuess.reduce((sum, id) => {
                          const ing = id ? INGREDIENTS.find(i => i.id === id) : null;
                          return sum + (ing ? getCurrentIngredientCost(ing.cost, id, currentEvent) : 0);
                        }, 0)}G</span>
                      ) : (
                        <span>재료비: {currentGuess.reduce((sum, id) => {
                          const ing = id ? INGREDIENTS.find(i => i.id === id) : null;
                          return sum + (ing ? getCurrentIngredientCost(ing.cost, id, currentEvent) : 0);
                        }, 0)}G</span>
                      )}
                      {tutorial.isActive && <span className="ml-2 text-green-400 font-black text-sm">무료!</span>}
                    </span>
                  )}
                </h3>
                
                <div className="flex justify-center gap-2 sm:gap-3 mb-2 sm:mb-5 z-10 relative flex-1 items-center w-full">
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
                          relative w-10 h-10 sm:w-14 sm:h-14 md:w-18 md:h-18 shrink-0 rounded-full border-2 flex items-center justify-center text-xl sm:text-3xl transition-all duration-300
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
                
                {/* [수정사항 1] 버튼의 disabled 조건에서 자금 부족 조건 삭제 */}
                <button
                  onClick={handleBrew}
                  disabled={currentGuess.includes(null) || minigameResult !== null || brewPhase !== 'idle' || activeItemMode !== null || (tutorial.isActive && !tutorial.step.startsWith('brew_'))}
                  className={`
                    w-full py-2.5 sm:py-4 font-extrabold rounded-xl transition-all shadow-lg flex items-center justify-center gap-2 sm:gap-3 text-sm sm:text-lg z-10 relative
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

            <div className="bg-slate-800 rounded-xl border border-slate-700 shadow-inner flex flex-col shrink-0 min-h-[100px] max-h-[28svh] overflow-hidden">
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

        {/* [day_end] 하루 마감 화면 */}
        {appState === 'day_end' && (
          <div className="flex flex-col flex-1 min-h-0 gap-3 sm:gap-5 overflow-y-auto max-w-md mx-auto w-full animate-slide-up pb-4 px-2 pt-2 justify-center">
            <div className="bg-slate-800 rounded-3xl border border-slate-700 shadow-[0_0_40px_rgba(0,0,0,0.5)] p-5 sm:p-8 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-full h-1.5 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500"></div>

              <div className="text-center mb-6 sm:mb-8 mt-2">
                <div className="inline-flex items-center justify-center w-16 h-16 sm:w-20 sm:h-20 bg-indigo-900/50 rounded-2xl border border-indigo-500/30 mb-4 transform rotate-3">
                  <ScrollText className="w-8 h-8 sm:w-10 sm:h-10 text-indigo-400 -rotate-3" />
                </div>
                <h2 className="text-2xl sm:text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-indigo-300 to-purple-300 mb-2">Day {day} 마감 정산</h2>
                <p className="text-slate-400 text-sm">오늘 하루의 상점 영업 기록입니다.</p>
              </div>

              <div className="space-y-3 mb-6 bg-slate-900/60 p-4 sm:p-5 rounded-2xl border border-slate-700/50 relative">
                {currentEvent?.type === 'rent_override' && (
                  <div className="absolute -top-3 -right-2 bg-red-600/90 text-white text-[10px] font-bold px-2 py-1 rounded-lg animate-pulse z-10 shadow-lg border border-red-400">
                    임대료 폭등!
                  </div>
                )}
                <div className="flex justify-between items-center">
                  <span className="text-slate-300 font-medium flex items-center gap-2 text-sm sm:text-base"><Coins className="w-4 h-4 sm:w-5 sm:h-5 text-yellow-400"/> 판매 수익</span>
                  <span className="text-yellow-400 font-bold text-base sm:text-lg">+{dailySalesRevenue} G</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-300 font-medium flex items-center gap-2 text-sm sm:text-base"><FlaskConical className="w-4 h-4 sm:w-5 sm:h-5 text-red-400"/> 재료 비용</span>
                  <span className="text-red-400 font-bold text-base sm:text-lg">-{dailyIngredientCost} G</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-300 font-medium flex items-center gap-2 text-sm sm:text-base"><Store className="w-4 h-4 sm:w-5 sm:h-5 text-orange-400"/> 상점 유지비</span>
                  <span className={`font-bold text-base sm:text-lg ${currentEvent?.type === 'rent_override' ? 'text-red-400 scale-110' : 'text-orange-400'}`}>-{currentRent} G</span>
                </div>
                
                <div className="w-full h-px bg-slate-700/50 my-3"></div>
                
                <div className="flex justify-between items-center">
                  <span className={`font-bold text-base sm:text-lg ${netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>{netProfit >= 0 ? '오늘의 순이익' : '오늘의 순손실'}</span>
                  <span className={`font-black text-xl sm:text-2xl ${netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {netProfit > 0 ? '+' : ''}{netProfit} G
                  </span>
                </div>
              </div>

              <div className="flex justify-between items-center bg-slate-700/30 p-4 rounded-xl border border-slate-600/50 mb-6">
                <span className="text-slate-300 font-medium">최종 보유 자금</span>
                <span className="text-white font-black flex items-center gap-2 text-xl sm:text-2xl">
                  {money} <Coins className="w-5 h-5 sm:w-6 sm:h-6 text-yellow-400"/>
                </span>
              </div>

              <button
                onClick={() => {
                  if (tutorial.isActive) {
                    setTutorial({ isActive: false, step: '' });
                    setHasSeenTutorial(true);
                    localStorage.setItem(TUTORIAL_KEY, 'true');
                  }
                  
                  const nextMoney = money - currentRent;
                  setMoney(nextMoney);
                  
                  if (nextMoney < 0 || (reputation > 0 && nextMoney < MIN_INGREDIENT_COST)) {
                    if (!hasUsedLoan && reputation > 0) {
                      setPendingRoute('next_day');
                      setAppState('loan_event');
                    } else {
                      setAppState('game_over');
                      localStorage.removeItem(SAVE_KEY);
                      setHasSaveData(false);
                    }
                  } else {
                    startNewDay(day + 1, dailyCustomers[dailyCustomers.length - 1].type);
                  }
                }}
                disabled={tutorial.isActive && tutorial.step !== 'day_end_3'}
                className={`w-full py-4 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl shadow-[0_0_20px_rgba(79,70,229,0.4)] transition-all transform hover:scale-[1.02] flex items-center justify-center gap-2 text-base sm:text-lg disabled:opacity-50 disabled:cursor-not-allowed ${tutorial.isActive && tutorial.step === 'day_end_3' ? 'ring-4 ring-indigo-400 animate-pulse' : ''}`}
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
