# v2 시스템 확장 명세 — 연구·주민 관계·다이어리

상태: 신규 기능 설계안이며 구현 결과가 아니다. 실제 Flutter 코드와 저장 형식은 변경하지 않았다. 기존 F08/F09 버그 수정은 유지한다. v2의 핵심은 React 방식 첫 연구 교육, 다양한 레시피·손님, 호감도와 반복 응대로 드러나는 정보·개인 이야기다. 주민 다이어리는 사용자 확정 필수 UI로 단정하지 않고 **도입 검토에 대한 채택 권고안**으로 제안한다. 아트는 후순위다.

## 요청 추적과 이전 문서 대체 범위

| 콘텐츠 인계 | 시스템 | 목적·선행 |
|---|---|---|
| RQv201 | SRv201 | React 숙면 안내 실험 재사용. 기존 CR01/SR01의 첫 연구 대체안은 이 결정으로 대체 |
| RQv202 | SRv202 | 최소 12종 레시피와 연구별 상태. SRv201의 연습 모드와 자유 연구 모드 분리 |
| RQv203 | SRv203 | 안정된 주민 8명 ID, 방문 일정과 3막+마무리 사건 그래프 |
| RQv204 | SRv204 | 호감/신뢰 단계, 반복 응대로 고유 정보와 개인 이야기 해금. SRv203 방문ID 필요 |
| RQv205 | SRv205 | 다이어리 도입 채택 권고안. 확인된 정보·부탁·약속·후기를 SRv203/204 사건에서 읽는 모델 |

콘텐츠의 구체 대사·12종 정의·주민 이야기는 [콘텐츠 확장안](content-expansion.ko.md)을 기준으로 한다. 여기의 SRv2 번호는 기존 SR01–SR08과 다른 v2 작업이다. 기존 연구 무료·재도전·낮 제조 유지 원칙은 계속 적용한다. 단, **교육용 숙면 연습의 두 오답은 사용자가 지정한 React 방식의 예외**다. 자유 연구에서 실패를 강제하거나 정답을 막는 규칙은 만들지 않는다.

## 실제 구현 근거와 Flutter 매핑

직접 읽은 React 근거는 `src/App.jsx`의 `INGREDIENTS/POTION_DB`, `startNewDay`, `acceptOrder`, `getTutorialAllowedIngredient`, `handleIngredientClick`, `handleBrew`, `getTutorialMessage`, `handleTutorialNext` 및 완료 버튼이다. 줄 번호는 후속 변경으로 이동할 수 있어 함수·데이터명을 함께 표기한다.

| React 근거 | 확인한 사실 | Flutter 대응/변경점 |
|---|---|---|
| `POTION_DB`, 185행 부근 | 숙면 정답 `8,2,9`; 시야 `9,5,10`; 3–5칸 물약20종 | 그대로 복사할 카탈로그가 아님. 이번 콘텐츠12종 registry와 실제 재료 성질을 사용 |
| `startNewDay`, 565행 부근 | 첫날 숙면 주문, tutorial 미완이면 intro_1 | `OpeningJourney` 첫 로빈 주문에서 기존 판매 전 연습 삽입 |
| `getTutorialAllowedIngredient`, 698행 부근 | 8,9,2 → 4,5,6 → 8,2,9만 차례로 허용 | 동일한 재료 의미·배열·입력 잠금·점수 설명 보존 |
| `getTutorialMessage`, 900행 부근 | 1/2·0/0 결과 의미를 설명하고 마지막 성공으로 마무리 | 한국어 설명 의미 유지, 단계별 입력과 기록 비교 유지 |
| `handleBrew`, 794행 부근 | tutorial은 모든 실험 비용 면제 | Flutter 연습/자유 연구 모두 무료. 제조 비용과 구분 |
| React 비용·결과·마감 설명 | 11G 비용, 남은 기회 팁, 평판, 유지비20G 전제 | Flutter에 없는 경제를 이식하지 않음. 문구를 실제 Flutter 무료 연구·35G 첫 판매·제조 재료 사용으로 명시적 치환 |
| React 저장, 506–523행 부근 | shop/day_end 상태에서 날짜·돈·평판·인벤토리·손님 큐 저장; tutorial 완료 별도 키. 진행 step/guess/history는 저장하지 않음 | 이 복원 제약은 이식하지 않음. Flutter 연습 도중 단계·결과도 저장하여 재시작 복구. React localStorage 저장 파일을 Flutter 세이브로 읽지는 않음 |
| Flutter `Game()` | 이미 sleep 발견, sleep 재고3 | 첫 연습은 “스승의 제조법을 익히는 연습”. 발견 보상·병·돈 중복 생성 없음 |
| Flutter `ResearchSession.submit/decode` | `potions[1]`, 기본재료6종,3칸 고정 | SRv202에서 targetId/allowedIngredients/slotCount 기반으로 변경 필요 |
| Flutter `ResearchStudio.experiment` | sight preview/해금 직접 처리; `Game.research` 별도 경로도 존재 | 하나의 연구 계산/발견 명령으로 합치되 기존 두 진입점 테스트 유지 |
| Flutter `Game.orders` | 1일·2일·이후 고정3명, 고객 이름 기반 레코드 | 첫 서사 유지 후 영속 방문큐와 주민ID 사용 |

이 문서는 소스 독해 결과이며 React/Flutter 화면을 실제 플레이하여 튜토리얼을 검증했다는 뜻이 아니다. 세부 원형 검토는 [튜토리얼 감사](legacy-tutorial-audit.ko.md)를 따른다. Library 재접근은 하지 않았다.

## SRv201 — 원형을 보존하는 첫 숙면 연습

### 교육 범위와 진입

새 게임: 첫 로빈 주문 확인 → 숙면 선택 → 조제실 설명 → 실험1 → 결과 읽기 → 실험2 → 제외 의미 읽기 → 실험3 → 성공 설명 → 기존 첫 판매35G → 기존 미나/엘리 이야기. 첫 밤의 시야 연구는 기존처럼 자유 연구다. 이미 알려진 sleep을 다시 “새로 발견했다”고 하지 않는다. 기존 시작 재고3병 중1병을 실제 판매할 때만 차감한다.

원형 ID 매핑은 `8→web`, `2→tear`, `9→moon`, `4→fairy`, `5→salt`, `6→tutorial_unicorn`이다. 유니콘 뿔은 Flutter 일반 재료에 없으므로 교육용 샘플로만 정의한다. fairy도 연습에서는 희귀 상인 해금과 무관하게 선택 가능하다. 연습 샘플은 일반 인벤토리·가격·상점 카탈로그·양산 recipe에 등록하지 않고 `TutorialIngredientDefinition` 레지스트리에 둔다. 샘플을 소유물처럼 표시하거나 일반 희귀 해금을 우회하지 않는다.

| 연습 | 강제 선택 순서 | 실제 scorer 결과 | 다음 정보 |
|---|---|---|---|
| 1 | web → moon → tear | 완벽1 / 불안정2 | 재료3개 모두 포함, 두 재료 위치가 다름 |
| 2 | fairy → salt → tutorial_unicorn | 완벽0 / 불안정0 | 이 세 재료는 숙면 정답에 쓰이지 않음 |
| 3 | web → tear → moon | 완벽3 / 불안정0 | 위치까지 맞음, 숙면 연습 완료 |

점수는 하드코딩된 표시값이 아니라 원형 정답으로 계산해 검증한다. 예시는 다른 물약의 정답을 배제한다는 뜻이 아니다. 실험2 설명에 “이 숙면 연습에서”를 붙여 salt/fairy가 영구 쓸모없는 재료라는 오해를 막는다.

### 단계와 명령 계약

`TutorialProgress {definitionId: legacy_sleep_v1, stepId, slots, attempts, status: notStarted|inProgress|completed|legacySatisfied}`를 Game 스냅샷에 보관한다. 가능한 stepId는 원형의 `intro_1/intro_2/pick_potion/guess_intro/guess_1_1..3/free_cost_warning/free_cost_warning_2/brew_1/explain_1/explain_1_continue/guess_2_1..3/brew_2/explain_2/guess_3_1..3/brew_3/result_screen/return_shop`를 유지한다. 비용 warning ID는 이식 추적용이며 실제 표시문은 “연습과 연구는 무료, 판매용 제조에는 재료 사용”으로 바뀐다. React의 day_end 단계는 Flutter 첫날 정산 시점에 안내만 연결하며, 숙면 한 건 뒤 즉시 하루를 끝내지 않는다.

`applyTutorialAction(expectedStepId, action)`은 현재 단계와 맞는 입력만 받는다. 설명 단계에서는 next, 재료 단계에서는 지정재료, brew 단계에서는 submit만 허용. 슬롯 교환·삭제·힌트아이템·실험재사용은 안내 중 잠근다. UI 버튼 비활성 외에도 모델에서 검증한다. 실험 완료 후 기록을 먼저 한 번 저장하고 다음 입력 단계 슬롯만 비운다. 결과 설명 완료 전 다음 실험으로 건너뛰지 않는다. 연습 완료는 `tutorialComplete:legacy_sleep_v1` 사건 하나이며 affinity·discovered·stock·gold·sales에 효과가 없다.

실제 판매는 `sale:visitId`에 의해 기존35G/재고1만 한 번 처리한다. 판매 UI 이중클릭·연습 결과 재진입이 중복 결제를 만들지 않는다. 연습에서 여러 번 맞추어도 가마솥 생산량을 곱하지 않는다. 기존 세이브 이어하기는 아래 마이그레이션 정책에 따라 기존 영업 도중 연습을 강제로 삽입하지 않는다.

### 재시작과 시험

결과 확정 전 애니메이션 중 종료하면 같은 draft+brew 대기에서 재개하며 보상은 없다. 결과 확정 후 종료하면 저장된 attemptId/다음 step에서 이어간다. 연습 기록은 자유 연구 노트와 분리해 `sight` 노트로 이관하지 않는다. 도움말에서 다시 연습하기는 별도 practice 세션으로 열어 완료상태·판매·호감도·다이어리에 추가 진전을 만들지 않는다.

수용: 모든 단계의 허용/금지 입력 표 테스트; 세 점수1/2·0/0·3/0; 연습 전후 일반재료·재고·돈 불변; 첫 판매 후 sleep2·+35G 정확히1회; 각 단계 저장 복원; reduced-motion/일반-motion에서 동일 결과; 첫밤 sight 정답 첫 시도 허용. 튜토리얼 문구에 없는 유지비·기회팁·일반연구 유료화 약속이 남지 않아야 한다.

## SRv202 — 12종 레시피와 연구별 진행

### 카탈로그 계약

`PotionDefinition {id, nameKey, effectKey, loreKeys, recipeVersion, recipe, slotCount, price, requestIds, unlockConditionId, useLimitTextKey}`. id는 저장에서 안정적이며 이름으로 찾지 않는다. 사용 한계는 세계관 효과 범위 설명이지 사용횟수/유통기한 규칙이 아니다. 제안12종 ID는 `sleep, sight, warmth, sprout, luck, hush, softfall, raincoat, echo, calm_scent, pathlight, clearvoice`이며 recipe/가격/효능의 정본은 콘텐츠 표다. 콘텐츠 담당과12종 정답순서·8주민ID를 대조했다. 기존 sleep/sight ID·조합·현재가격을 유지한다. 신규 가격범위는 실제 구현에서 한 고정값으로 승인해야 하며 매 방문 임의변동하지 않는다. 신규10종을 한꺼번에 발견 상태로 넣지 않는다.

재료는 기존8종에 `feather/resin/reed/aromaleaf`를 콘텐츠 정의에 따라 추가한다. 신규재료 제안가는 각3G, 기존 root/fairy는5G이며 구현 전 경제 검토 대상이다. 신규 카탈로그 재료가 모두 해금 전0개여도 무료 연구는 가능해야 한다. 판매용 제조 접근과 실험 샘플 접근은 별도 `isPurchasable`/`isResearchCandidate` 조회로 결정한다. 실험에 재료 구매를 입장료로 요구하지 않는다.

### 상태와 전이

`ResearchProgress {potionId, recipeVersion, status: locked|requested|discovered, requestedByQuestIds, session}`; `session`은 targetId, slots, activeSlot, attempts, marks, memo를 가진다. 기존 연구 주석 SR02 원칙을 유지한다. 초기 신규 slotCount는 콘텐츠12종 모두3이며, API·검증은 definition 길이를 읽는다. React의4·5칸을 레시피 개수 증가와 혼동해 이번 단계에 강제로 넣지 않는다.

`requestResearch(questId,potionId)`는 요청을 집합에 추가하고 locked→requested 한 번만 전이한다. 이미 발견했다면 즉시 제조/납품 단계로 보내며 재연구를 요구하지 않는다. 두 주민이 같은 물약을 부탁하면 한 연구를 공유하되 의뢰 이행 상태는 별개다. `submitExperiment(potionId,expectedSessionRevision,guess)`는 해당 연구의 후보ID/서로다름/칸수를 검증하고 순수 scorer를 호출한다. 첫 정답이면 발견 사건과 실험병1병만 한 번 지급한다. 튜토리얼 sleep 예외는 SRv201처럼 실험병0이다. 무료 실패는 금액·재료·날짜·신뢰를 바꾸지 않는다.

레시피의 정답 배열을 수정할 때는 recipeVersion을 올린다. 발견한 플레이어의 기존 상품 정의를 조용히 바꾸지 않는다. 미완성 노트의 과거 점수도 새 정답으로 재계산해 덮지 않는다. 출시 후 조합변경이 필요하면 이전 정의를 보존하고 새 연구를 따로 만들거나 명시적인 마이그레이션을 설계한다. 최초12종을 구현하기 전에 모든 정답ID 유효·중복없음·효능성질 일치·제조가능 여부를 데이터 검증한다.

### 코드 변경 접점과 시험

`Game.research`, `ResearchSession.submit/decode`, `ResearchStudio.experiment`의 sight/potions[1] 참조를 공통 ResearchService로 옮긴다. `Game.stock/materials` 초기화·decode는 registry 기준으로 채우고 신규ID 기본0을 허용한다. `canBrew/prepare/prepareCost`는 기존 배치수학 유지. `PotionSelection`의8개 페이지와 `shop_tasks.dart` recipe 목록을 12종으로 검증한다. 기존 sprite는 potionId별 신규 아트가 없어도 이름/효능/접근성 텍스트로 식별 가능해야 한다; 아트 구현을 기능 선행조건으로 두지 않는다.

수용:12종 registry 정합성; 각각 첫정답 발견1회; 연구A 중단→B→A 노트 불변; 두 의뢰 한 recipe 중복보상 없음; 미발견 제조차단; research용 후보 접근이 희귀 구매해금을 변경하지 않음; 새 재료0 상태 무료실험; 품절/부족돈 제조실패 원자성; 기존 sleep/sight 저장과 레시피 결과 보존.

## SRv203 — 주민8명과 방문/개인 이야기 그래프

### 안정된 주민·의뢰 정의

주민ID는 `robin, mina, ellie, jun, sage, luna, doran, nari`. Sage의 상인 UI를 열었다는 사실만으로 판매응대/관계 방문을 완료 처리하지 않는다. `ResidentDefinition`은 이름·직업·소개·초기 facts·storyGraphId만 가지며 스프라이트에 의존하지 않는다. 기존 고객 레코드는 `OrderDefinition {orderId,residentId,potionId?,dialogueKey,questId?}`로 바꾼다. 방문은 `Visit {visitId,day,residentId,orderId,storyBeatId?,stage,outcome?}`이며 visitId는 단조증가 serial을 포함한다. 이름·날짜만으로 유일성을 만들지 않는다.

`StoryBeatDefinition {id,residentId,prerequisites,effects,nextIds,repeatPolicy}`로 콘텐츠의3막+마무리 그래프를 표현한다. 의뢰는 `QuestProgress {questId,status: available|accepted|ready|completed,requestedPotionId,quantity,acceptedDay,completedEventId?}`. deadline은1차안에 없다. 완료 사건만 다음 막의 진입조건을 만족시키며, 팝업을 닫거나 상점 탭을 열었다고 완료하지 않는다. 신규 의뢰를 받은 날 해결하지 못해도 실패처리하지 않는다.

선행조건 언어는 `factKnown(id)`, `eventDone(id)`, `questState(id,state)`, `recipeKnown(id)`, `trustStageAtLeast(stage)`의 AND/OR로 제한한다. UI에는 디자이너가 붙인 spoilerSafeWaitText를 사용하고 내부 미래 조건/정답을 그대로 출력하지 않는다. 조건과 효과에서 임의 실행코드를 허용하지 않는다. 데이터 검증으로 없는ID·도달불가 순환·자기해금 조건을 막는다.

### 일정 정책

첫3일 핵심 부탁→연구→후기→소개→협회 연결을 보존하고 새 주민은 개인 이야기 해금 이후 차례로 초대한다. 첫3일 안에8명을 모두 강제 배치하지 않는다. 순환 해금 방지를 위한 독립입구는 콘텐츠와 동일하게 luna=협회완료, doran=시야 성공후기, nari=준 첫성공후기 OR 협회완료, sage=기존 희귀거래 해금이다. 소개는 대사변형/후속사건 조건으로 쓰되 독립입구를 다시 잠그지 않는다. 아래 구체 슬롯수와 스케줄은 core를 구현하는 **선택 가능한 기본안**이며 사용자 지정 고정일정이 아니다. 기존3방문/일을 유지하고 최대2칸은 준비된 개인 사건/밀린 약속 방문, 나머지는 변형 일상주문에 쓴다. 실제 수요량 증대는 별도 균형검증 항목이다.

`buildDaySchedule(day,progress)`는 밤에 다음날 준비 화면/미리보기를 처음 열 때 `nextDayPlan {day,planId,sourceRevision,visits}`을 한 번 만들고 즉시 저장한다. `nextDay`는 이 plan의 동일 visitId/내용을 현재큐로 승격하고 plan을 비운다. 밤 미리보기를 한 번도 열지 않았으면 nextDay에서 처음 생성 후 승격한다. 이미 표시된 계획은 밤 연구/제조/소개조건 변화로 재추첨하지 않는다. 계획 확정 후 새로 열린 개인사건은 그다음 계획에 반영하고, 기존 방문에서 예정되었던 연구부탁의 제조가능 여부/현재재고 같은 상태 정보만 최신값으로 표시한다. 영업도중 내일목록은 아직 미확정임을 표시하거나 밤안내로 보내며 확정인 척 하지 않는다.

큐 정렬은 마지막으로 이야기를 제안받은 날이 오래된 주민→대기 시작일→안정ID, 하루 주민1회. 준비된 사건이8명이고2칸씩 사용 가능하면 최대4영업일 안에 제안되는 목표다. 같은 주민을 계속 건너뛰더라도 다른 주민의 제안을 밀어내지 않게 lastOfferedDay를 갱신한다. 개인 사건이0개면 일상주문으로 채운다. 다음날 미리보기는 저장된 plan을 읽으며 재접속/창 열기마다 손님을 다시 뽑지 않는다. 손님이 실제로 제안받기 전엔 lastOfferedDay를 갱신하지 않는다.

고정 큐에 아직 만들 수 없는 새 물약이 들어가면 그 방문은 판매 성공을 요구하는 주문이 아니라 연구 부탁으로 정의되어야 한다. 뒤늦게 조건이 만족됐다고 당일 도착 손님을 바꾸지 않는다. 다음 큐를 생성할 때 반영한다. 대량 협회 의뢰는 일반3방문과 별개 기한 없는 장부 항목으로 유지한다.

### 완료 명령과 중복방지

`resolveVisit(visitId,outcome)`은 pending 방문에 한 번만 적용한다. outcome은 saleSuccess|wrongPotionExit|declined|outOfStockDeferred|researchRequested|talkOnly. 실제 수량/돈 변화는 판매명령에서 처리하고 사건 완료에서 다시 더하지 않는다. `completeQuest(questId,expectedRevision)`는 발견/재고/수량/선행조건을 확인한 뒤 재고차감·보상·완료ID를 한 스냅샷으로 갱신한다. 같은 의뢰 두 번 클릭, 서로 다른 화면의 동시 실행, 재시작 후 다시완료는 효과0이다. 잘못된 물약1회는 기존 재시도,2회는 기존 방문이탈; 개인 이야기를 영구실패시키지 않는다.

### 구현 가능한 그래프 예시 두 주민

모든8주민의 기본ID 규칙은 `<resident>.a1`, `.a2`, `.a3`, `.epilogue`; 막 안에서 다음방문이 필요한 부사건은 `.a1.followup`처럼 명시한다. 대화안은 콘텐츠 문서, 아래 표는 전이계약이다. `laterVisit(event)`은 그 사건이 확정된 방문과 다른 이후 적격방문이며 날짜가 자동진행한다는 뜻이 아니다. 새로운 부탁을 수락만 하고 미완료면 해당 quest만 남기고, 막 문구를 매 방문 재보상하지 않는다.

| beatID | 전제 | 한 번의 효과 | 다음방문 조건·선택branch |
|---|---|---|---|
| robin.a1 | 첫실제 sleep 판매 성공, 해당beat 미완료 | 새벽 약초 fact, 재료 promise 기록; 이미 받은35G 외 추가현금0 | robin.a1.followup을 다음적격방문에 예약 |
| robin.a1.followup | promise 증거, laterVisit(robin.a1) | 거미줄1+눈물1 선물claim, 숙면후기, 약속회수fact | 현재구매 없어도 지급. robin.a2는 그다음적격방문 |
| robin.a2 | followup완료, 미완료a2 | 스승 씨앗 fact, quest robin.sprout 수락가능; sage접근 없으면 소개/기존협회 안내 | P04 실제연구해금은 sage소개까지 충족; 미수락/미제조 시 기한없이대기 |
| robin.a3 | robin.sprout에 실제1병 전달, laterVisit(전달) | 발아성공후기, 씨앗나눔 의향, sage교환회 소개사건 | 추가 P04 판매 불필요. 참가선택 또는 sage회신 대기 |
| robin.epilogue | a3완료 AND 교환회참가 OR sage회신 중 하나, laterVisit(a3) | 개인마무리·공동연결fact, 관계핵심사건 완료 | 평범한숙면수요만 재개; 씨앗위기/선물 재시작없음 |
| nari.a1 | 독립입구=jun첫후기 OR 기존협회완료 | 책받침소음/말은지우지않음 fact, quest nari.hush, reed거래접근 | 수락/연구/제조/실제전달을 기다림 |
| nari.a2 | nari.hush에1병 전달, laterVisit(전달) | 소음완화후기, 낭독고민fact, quest nari.clearvoice | 선택질문 없이도 필수요구 전달; P12 전까지기한없이대기 |
| nari.a3 | nari.clearvoice에1병 전달, laterVisit(전달) | 낭독후기, jun초대장/mina간식 연결사건, 행사준비선택 | `scent`이면 P10연구/준비, `noScent`이면 향준비 완료표시. 동등한성공조건 |
| nari.epilogue | a3완료, 초대장전달/간식회신 확인, scent준비 OR noScent확정, laterVisit(a3) | 책모임후기·공동행사 기록·관계핵심사건 완료 | jun/mina의 전체개인서사 완료 요구없음. 향없는선택에 낮은보상/호감없음 |

OR/AND 표현은 실제조건AST에서 괄호로 고정한다. robin.epilogue는 `a3 AND (participated OR replyReceived) AND laterVisit`, nari.epilogue는 `a3 AND invitationDelivered AND snackReply AND (scentReady OR noScent) AND laterVisit`이다. 외부 회신은 해당연결요청 후 다음적격방문/장부회신의 별도사건이며 임의시간/자동일수만으로 완료를 조작하지 않는다. 나머지6주민도 같은표 형식으로 콘텐츠3막을 데이터화한 후 순환/도달성 검증을 통과해야 구현완료로 본다.

## SRv204 — 반복 응대로 해금하는 호감/신뢰

호감의 구현명은 trust로 두고 유저 표시는 콘텐츠의 “낯익은 손님→이야기를 나누는 이웃→믿고 부탁하는 사이” 세 단계다. **React의 상점 전체 reputation과 주민별 trust는 별개**이며 React 평판50/+10/−15나 해금 reqRep를 이식하지 않는다. 수치가 필요하더라도 플레이어에게 보이지 않는 무제한 판매 포인트를 만들지 않는다. 단계는 확인된 사건 조건으로 계산한다: 첫 소개/주문 기록→첫 도움 완료 AND 고유 정보1개 확인(대화 또는 자동후기)→개인 약속/후기/공동연결 중 주민별 핵심사건 완료. 모든 주민에게 똑같은 선물이나 거래를 강요하지 않는다. 최종 단계의 선행인 개인 약속은 그 단계 전에 받을 수 있어야 하며 그래프 순환을 데이터 검증한다. 처음 만나 판매하지 않은 상태도 다이어리 프로필을 열 수 있고 다음 방문을 잃지 않는다.

`ResidentProgress {met,successfulServices,knownFactIds,seenDialogueIds,completedBeatIds,fulfilledPromiseIds,lastOfferedDay}`를 저장한다. `trustStage`는 이 영속 사건들로 계산하는 ordinal enum `familiar(0)/sharing(1)/trusted(2)`다. 미등장 주민은 met=false로 구분한다. **질적 호감도 시스템은 존재하며**, 포인트 반복파밍만 쓰지 않는 것이다. successfulServices는 후기 진위에 필요한 집계이며 unlock threshold를 반복횟수로 두지 않는다. 고유 이야기 사건/새로운 사실만 신뢰 조건에 기여한다. 동일 물약100병 판매·같은 질문 연타·연습 반복·화면재접속은 새 정보/신뢰를 만들지 않는다.

이야기 진행은 주민당 방문1사건/1막 한도로 둔다. 방문 시작 시 storyBeatId를 고정하고, firstHelp와fact가 동시에 생겨도 다음막은 이후 적격방문의 큐에 넣는다. 사용후기도 약을 받은 이후의 다음 적격방문에만 전달한다. 첫소개+3막+마무리가 대략4–6회의 의미 있는 방문에 걸치도록 설계하되 이는 페이싱 목표이며 강제판매횟수/검증된 소요일이 아니다. 개인상황에 따라 대화와납품을 같은 사건으로 묶을 수 있지만 여러막을 한날 모두 소진하지 않는다. 현재 기본3방문/일로8주민 전체 이야기를 보려면 여러 영업일이 필요하므로 day3 안에 전체콘텐츠 완료를 약속하지 않는다. 기한 없는 사건대기와 위 공정순환으로 무작위방문 운에 진전을 맡기지 않는다.

`DialogueDefinition {id,residentId,prerequisites,textKey,revealFactIds,onDeliveredEventId?,isOptional}`. 선택적 추가질문은 필요한 사실을 얻는 한 경로이며 필수 질문을 못 골랐다고 스토리가 막히지 않도록 주문본문/자동후기에서도 필수정보를 전달한다. 선택지 목록에 질문이 보인 것만으로 답 내용을 공개하지 않는다. 실제 대화가 제시되거나 “대화 건너뛰기”로 해당 필수본문이 전달 확정될 때 `recordDialogueDelivered(visitId,dialogueId)`를 처리하고 중복fact는 Set으로 합친다. 읽는 속도·끝까지 기다리기·질문클릭 횟수로 신뢰를 보상하지 않는다. 전달된 핵심정보는 건너뛰어도 다이어리에 남고 아직 선택하지 않은 선택질문 답은 남지 않는다. 사용 후기에는 해당 주민·해당 물약의 과거 실제 판매 성공이 필요하며 날짜만으로 만들어내지 않는다.

품절·거절·오판매로 호감 수치를 깎거나 숨겨진 만회노가다를 요구하지 않는다. 서사적으로 아쉬운 한 줄은 가능하지만 재방문 경로는 열린다. 선물은 대화·판매조건과 분리된 `promiseId` 사건으로, 예컨대 로빈의 약속한 재료는 이전 약속 증거가 있고 다음 방문하면 현재 구매여부와 무관하게1회 지급한다. 신규 선물/가격은 콘텐츠 정의와 명시적 승인 후 반영한다.

## SRv205 — 다이어리는 확인된 사건의 기록

다이어리 탭을 채택한다면 주민별 프로필, 확인한 정보, 진행중 부탁, 지킬/받을 약속, 사용 후기, 개인 이야기 기록을 제공한다. 별도 탭을 채택하지 않더라도 SRv203/204의 사실·약속 상태는 필요하며 기존 주문/기록 화면에서 노출할 수 있다. 아직 만나지 않은 주민은 빈 항목/미등록 수로만 표현하며 이름·숨은 사연·정답을 노출하지 않는다. 잠긴 후속 단계는 “다음에 다시 이야기해 보기”처럼 spoilerSafeWaitText만 표시한다. 연구 레시피를 발견하기 전 주민 다이어리에 정답배열을 기록하지 않는다.

`DiaryEntry {entryId,residentId,kind,sourceEventId,day,textKey,templateArgs,read}`를 저장한다. entryId는 `sourceEventId:entryKind`로 안정화한다. 시스템 확정사건의 effect 목록에 diary key를 포함해 같은 거래/대화에서 증거와 다이어리가 함께 저장된다. 과거 사건 문구가 콘텐츠 업데이트로 의미를 바꾸지 않도록 textKey에 버전을 붙이고, 수량/물약/날짜는 templateArgs로 보존한다. 문구 전문을 유일키로 쓰지 않는다.

정보 공개 시 “다이어리에 기록됨” 알림은 방문당 묶어서 한 번 표시한다. 새 표시는 읽으면 사라지고 읽기 자체가 호감도를 올리지 않는다. 닫기/정렬/검색은 Game 진행을 바꾸지 않는다. 이야기 완료/의뢰완료/사용후기는 서로 다른 사건이므로 조제 성공만으로 사용후기를 기록하지 않는다. 거절/품절 기록은 다음 행동을 찾는 중립적 메모로 남기고 실패 낙인·빨간 경고 누적으로 만들지 않는다.

## 저장 스키마와 원자성

### 현재 사실과 제안 구분

현재 실제 `Game.encode/decode`는 version2, `ResearchSession`은 version1이다. 이전 `docs/playtest-1598880/system-spec.ko.md`의 Game version3·연구 version2는 **구현되지 않은 제안**이다. 이를 배포된 저장처럼 마이그레이션하지 않는다. 이번 v2 확장도 구현 전 제안이며, 실제 착수 때 단일 schema 명세로 통합한다.

제안 Game `version:3`은 기존 필드와 다음 묶음을 저장한다: `contentVersion`, `tutorialProgress`, `researchByPotionId`, `residentProgress`, `questProgress`, `visitQueue`, `visitCursor`, `nextVisitSerial`, `nextDayPlan`, `processedOneShotEventIds`, `diaryEntries`, 선택한 `daySummary` 확장. 기존 필드명 version을 유지하며 디코더 한 곳에서2/3을 판독한다. 연구 노트는 제안version2로 targetId/recipeVersion을 포함한다. 이전 원장SR08이 함께 구현되면 그 필드도 이 schema3 명세에 합치며 별도의 또 다른 v3 의미를 만들지 않는다.

### v2 → 제안v3 이행 규칙

1. 원본 문자열 백업을 별도키에 먼저 보관하고 파싱/검증이 끝난 스냅샷만 기존키에 쓰기. 오류 시 원본을 유지하고 사용자가 이어하기/새게임을 선택할 수 있게 하며 자동초기화로 진전을 없애지 않는다.
2. day/gold/stock/materials/discovered/level/phase/customer와 기존 일일금액을 그대로 보존. 신규 recipe/material ID만0으로 채움. 부재와 잘못된 음수·형식 오류를 구분한다. 새 카탈로그가 늘었다는 이유로 구저장을 거부하지 않는다.
3. 기존 attempts/researchNotebook은 `sight` 연구로만 매핑. score/slot 중복/기존성공 검증 유지. 이미 sleep/sight 발견 상태를 보존하고 실험병을 추가 지급하지 않는다. 기존 독립 연구 이관도 발견ID와 이관claim을 함께 확인해1회만 처리한다.
4. 기존 이어하기는 `tutorial.status=legacySatisfied`로 두어 첫 로빈 판매/영업을 다시 하지 않음. 도입부 stage0이며 아직 거래·연구·날짜진행이 전혀 없는 새 상태만 notStarted로 진입 가능. stage1 등 저장이 애매하면 기존 흐름을 계속하고 도움말의 무보상 연습을 제공한다. 연구를 이미 마친 사람에게 강제 오답 교육을 삽입하지 않는다.
5. 기존 고객 이름·day/index를 고정 매핑하여 현재 방문 큐를 복원하고 현재 customer 위치를 보존. completed 플래그에 따라 당시 엘리 주문대사 분기를 유지한다. 다음날부터 새 스케줄을 쓴다. 기존 `customer<=3` 제약은 실제 저장 큐 길이 검증으로 전환한다.
6. 과거에 성공했는지 없는 고객별 후기를 추측하지 않음. 새로운 관계 상태는 met/knownFact 기본값과 명시적으로 증명 가능한 현재사건만 채운다. 로빈 약속도 기존 story 저장만 보고 보상수령 여부를 추정하지 않고 unknown으로 두어 일괄선물 지급하지 않음. 과거 모든 날짜의 고객 성공을 생성하지 않는다.
7. 기존 협회 supplierUnlocked를 기존 guild quest 완료로 연결하되 돈/해금보상 재지급 없음. 후속 신규 사건은 “기존 특별주문 완료 이후의 첫 신규 대화” 진입점을 별도로 두어 로빈 약속/신뢰 이력 부재 때문에 전체 확장이 잠기지 않게 한다. 이 진입대화는 실제 발생 후 사실/관계에 기록한다.
8. 기존 opening/stories/free-shop/standalone-research 저장은 각각의 슬롯 정체성을 유지. 다른 슬롯의 호감도·돈·다이어리를 합치지 않음. 모르는 상위 schema는 덮어쓰지 않고 호환불가 안내. 아직 배포되지 않은 예전 문서의 가상v3 fixture를 실제사용자 저장으로 취급하지 않음.

### 명령과 저장 경계

연구결과·판매·의뢰·선물·대화명령은 `expectedRevision`과 안정 eventId를 검증한 뒤 게임복사본에서 효과를 계산한다. 금액/재고/신뢰/다이어리/claim을 같은 Game JSON 스냅샷에 묶는다. 현재 SharedPreferences 저장큐를 확장하되 mutator별 따로 저장해 부분보상 상태를 만들지 않는다. 성공적 저장 후 완료 알림을 표시한다. 쓰기 실패 시 dirty snapshot을 유지해 재시도하고 다음 영속 명령/다음날 전환은 막되 읽기·노트 확인은 가능하게 한다. 재시작은 마지막 성공 스냅샷으로 복구하므로 “저장되지 않은 선물도 이미 영구 수령했다”고 표시하지 않는다.

모든 클릭 eventId를 무제한 저장하지 않는다. 의뢰/선물/스토리 같은1회 사건은 콘텐츠에 한정된 ID set으로, 판매는 현재 visit.outcome/해결상태로, 반복 성공집계는 그 방문확정과 함께 저장한다. 종료된 방문은 일일요약/필요한 후기 이력만 남기고 일상 클릭로그를 누적하지 않는다. diary는 정보·story 사건 단위로 중복제거하며 일상 같은판매100회를100개 항목으로 쌓지 않는다.

## 실패·반복·경계 시나리오 수용표

| 사례 | 요구 결과 |
|---|---|
| 첫연습 첫/둘째 오답 | 정해진 교육 진행, 비용·호감·재고 영향0. 자유연구 오답과 구분 |
| 자유연구 첫 제출 정답 | 즉시발견, 실험병1회, 실패횟수 조건없음 |
| 잘못된 물약1회/2회 | 기존설명·재도전/이탈 유지, 신뢰삭감·의뢰영구실패없음 |
| 품절→낮 제조→판매 | 정상성공, 미구매/실패기록 미확정 |
| 품절/거절로 방문종료 | 해당방문만 해결, 이야기는 재제안큐 유지, 없는 사용후기 생성안함 |
| 같은질문10회/다이어리10회 열기 | fact/신뢰/보상 추가0 |
| 같은주민100회 동일판매 | 실거래 수입만 정상, 숨겨진 반복횟수 스토리gate 없음 |
| 같은recipe 두주민 요청 | 연구1개·발견보상1회, 각각의 의뢰는 별도 납품/완료 |
| 의뢰완료 더블클릭/다른화면 재실행 | 재고·돈·신뢰·다이어리 효과1회 |
| 연습/실험/선물 도중 재시작 | 마지막 확정스냅샷 복원, 누락/중복효과 없음 |
| 구v2 중간영업/미완연구 | 돈·재고·주문위치·기록보존, 강제튜토리얼없음 |
| 구v2 협회완료 | 보상재지급없음, 관계기록없어도 신규 소개대화 진입가능 |
| 개인이야기 조건동시만족 | 주민당 방문1막, 다음막 다음방문, 다이어리 사실만공개 |
| eligible 주민8명 | 일별2개이야기슬롯에서 제안기회4영업일 이내, 큐 재시작동일 |
| 밤예고 후 연구해금/재시작/nextDay | nextDayPlan 방문ID·내용동일승격, 뒤늦은새사건은 다음계획, 재고표시는갱신 |
| 나리 향없음 branch/로빈 현재구매거절 | 동일핵심결말가능/과거약속선물유지, 새물약전부구매 강제없음 |
| 하나의 스토리 조건순환 | 정적 데이터검증 실패로 출시차단 |
| 레시피12개/주민8개 작은화면 | 모든항목 탐색가능, 오버플로없음, 아트없어도 이름식별 |
| 미래schema/손상save | 원본보존, 자동리셋/숨은상태초기화없음 |

테스트 구성: 순수 scorer/튜토리얼 reducer/조건평가/스케줄 unit; frozen v2 fixtures 마이그레이션; saving 실패·재시작 idempotence; 도입부→첫판매→엘리자유연구 widget/integration; 신규주민 부탁→연구→다음방문 후기→다이어리→개인이야기 흐름. 이전 F08/F09 회귀와 기존 제조·판매 재시도 테스트를 함께 유지한다. 위 기준은 **향후 실행할 검증**이며 현재 통과 결과가 아니다.

## 구현 승인 뒤 작업 순서

1. 콘텐츠12종/8주민 데이터와 ID를 확정하고 정적 그래프/recipe 검증부터 준비.
2. 저장 registry 확장·version2 fixtures·명령 원자성을 먼저 구현. 기존 플레이 이어가기 보존 확인.
3. SRv201 연습을 별도 reducer로 이식하여 첫판매 연동까지 검증. 무료 sight 자유연구 회귀.
4. SRv202 연구별 세션을 연결하고 새 레시피를1종부터 end-to-end로 확인한 뒤12종 데이터 적용.
5. SRv203 방문큐/의뢰와 SRv204 사건 기반신뢰를 구현, SRv205 다이어리는 같은 사건결과에서 투영.
6. 주민1명3막+마무리 전체를 검증한 뒤 나머지7명 적용. 준비수요·경제수치·후기진위·반복노가다를 별도 플레이테스트.
7. F11–F14 아트·장식·표정·발명연출은 기능흐름 검증 이후. 배포·게시·머지는 별도 명시적 승인 전 진행하지 않음.
