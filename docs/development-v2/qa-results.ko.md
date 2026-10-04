# v2 개발 클라우드 QA 기록

기준 브랜치: `development/v2-resident-stories`. 개발 시작 커밋: `2a7af6b`. 검증일: 2026-10-04 UTC.

## 실행 상태

**동적 Flutter/Dart 테스트와 analyze는 아직 실행하지 못했다.** 기존 Flutter SDK 소스는 `/workspace/tools/flutter`에 있지만 `bin/cache/dart-sdk/bin/dart` 및 Linux 테스트 엔진이 없다. 시스템 PATH에도 Flutter/Dart 실행파일이 없다. 사용자 PC에 의존하지 않는다.

공식 다운로드 경로는 이번 작업에서 한 번만 재확인했다: `https://storage.googleapis.com/flutter_infra_release/flutter/692136cb6582dbfc5af3fb33c2515a069f2f66d0/dart-sdk-linux-x64.zip`. 결과는 **`curl: (56) CONNECT tunnel failed, response 403`**, HTTPS CONNECT 단계의 프록시 접근 거부였다. 자동 승인 거절이나 단순한 일시 네트워크 오류로 해석하지 않는다. 명시적 거부 이후 대체 경로/우회 재시도는 하지 않는다.

재개에 필요한 최소 변경은 `storage.googleapis.com:443`의 공식 `/flutter_infra_release/flutter/` artifact 다운로드 접근 허용 또는 지원되는 방식으로 동일 **Flutter 3.47.6 / Dart 3.13.5 / engine 692136cb6582dbfc5af3fb33c2515a069f2f66d0** SDK·Linux 테스트 엔진·프로젝트 의존성 캐시를 이 클라우드에 제공하는 것이다. Dart 바이너리만으로 widget test가 가능한 것은 아니다.

## 검증 재개

[verify-v2.sh](../../scripts/verify-v2.sh)는 SDK 존재를 먼저 검사하고, 없으면 exit 2로 종료하여 거부된 다운로드를 반복하지 않는다. 완전한 SDK를 제공한 뒤 `bash scripts/verify-v2.sh`로 버전→의존성→analyze→전체 테스트를 실행한다. 다른 SDK는 `FLUTTER_BIN`으로 지정할 수 있으며 경로는 해당 Flutter SDK의 `bin/flutter`여야 한다. 로그는 `docs/development-v2/evidence/resumed/`에 보존한다.

현재 preflight는 예상대로 exit 2로 종료했다([sdk-preflight.log](evidence/sdk-preflight.log)). 이는 테스트 실패나 통과가 아니라 테스트 실행 불가 확인이다. 스크립트의 `bash -n`은 통과했다.

## 기준 회귀 범위

기존 테스트는 도입부, 자유 연구, 제조/재고, 잘못된 판매 재시도, 저장 복원, 협회 납품, F08 바로가기 및 F09 마감 안내를 포함한다. 이전 Windows `VALIDATION.md`나 v1의 정적 검토를 이번 v2 테스트 통과 결과로 대체하지 않는다. v2 변경 후 기존 전체 테스트와 새 통합 시나리오를 함께 실행해야 한다.

## 작성한 통합 검증

[flutter/test/v2_integration_test.dart](../../flutter/test/v2_integration_test.dart)에 다음 3개 테스트를 작성했다. **코드 작성과 정적 검토까지이며 실행 통과 결과가 아니다.**

1. 협회 납품 이후 충분한 자금 fixture에서 최대 80일의 실제 방문 스케줄을 따라 주민 8명의 4개 이야기와 물약 12종에 도달하는지 확인한다. 부탁받은 미발견 약은 밤에 연구하고, 납품 다음 방문의 후기만 완료로 인정한다. 매일 저장 복원, 밤 예고 고정, 중복 방문/오래된 callback의 보상 중복 방지, 무료 연구의 돈·재료 불변을 검사한다. 자금을 넉넉히 준 기능 검증이며 장기 경제나 재미의 검증이 아니다.
2. 실제 ShopScreen에서 물약을 팔지 않는 이야기 완료→저장→앱 재진입→주민 다이어리 재열람을 확인하는 widget 흐름이다.
3. 나리의 향 없는 책모임 선택이 물약 발견·판매·허위 사용후기 없이도 해당 이야기를 완료하고, 저장 후 중복 처리되지 않는지 확인한다.

기존 `game_test.dart`는 120개 순열의 의미가 바뀌지 않도록 기존 기본재료 6개를 명시했다. 자유 연구의 12개 샘플 허용 결정에 따라 불허 재료 fixture는 실제 미등록 ID `unknown`으로 바꾸었다. `shop_test.dart`는 첫 판매의 명시적 선택을 유지하고 둘째 단일 물약 판매는 F04의 직접 건네기 버튼을 사용하도록 조정했다.

## 독립 정적 교차 검토

- 주민 마지막 사건 ID `.ending`과 신뢰 단계 코드의 `.epilogue` 불일치를 발견해 시스템 담당에게 전달했고 `.ending` 반영을 확인했다.
- Opening 저장 실패를 내부에서 삼키면 tutorial이 계속 진행/종료/판매할 수 있는 문제를 전달했다. 담당자가 저장 성공 bool, dirty 입력 잠금, 마지막 연습 저장 실패시 완료 화면 유지와 동일 snapshot 재시도, 연구 진입 전 저장 확인으로 수정했다. 최종 소스에서 해당 제어 흐름을 확인했다.
- main 저장은 queue와 snapshot 비교를 사용하며 실패시 본 화면 입력을 막는다. 별도 modal route는 본 화면 AbsorbPointer 밖이므로 저장중/실패중 추가 구매가 가능했던 경로를 전달했고, 담당자가 modal 진입과 거래 callback의 guard를 추가했다.
- 예전 장부 테스트가 `Game().encode()`를 사용하면 실제 구버전 migration fixture가 아니라는 점을 전달했다. 실제 version2 고정 fixture 검증은 시스템 담당의 신규 테스트가 담당한다.
- main 실패 저장의 실제 SharedPreferences backend 주입 widget test는 이번 QA 통합 파일에 포함하지 않는다. tutorial과 diary 담당 테스트에는 실패 callback/재시도 사례가 있지만, 이를 main 전체 저장 실패 실행 검증으로 확대 해석하지 않는다.

## 실행한 정적 검사

허용된 PyPI 경로에서 `tree-sitter 0.26.0`, `tree-sitter-dart 0.1.0`을 `/workspace/tools/qa-python`에 설치했다. 최신 통합 시점의 `flutter/**/*.dart` 44개 파일에서 parser `ERROR`/missing 노드 0개를 확인했다([dart-syntax-parse.log](evidence/dart-syntax-parse.log)). 이 검사는 **구문 파싱만** 수행하며 이름/타입 해석, Flutter API 적합성, 컴파일, analyzer, 테스트 실행을 대체하지 않는다. SDK 경로의 접근 거부를 우회한 것이 아니다.

`git diff --check`와 runner `bash -n`은 통과했다. 최종 검사에는 main/Opening/Diary의 저장중·실패중 화면 이탈 제한과 시스템 담당의 신규 테스트 파일도 포함했다. 테스트 파일은 25개이며 `test`/`testWidgets` 소스 선언은 85개다. 반복문으로 생성되는 시나리오가 있으므로 이 수를 실제 테스트 실행 개수로 해석하지 않는다. 실제 실행한 Flutter 테스트는 0개다. 이후 소스가 변경되면 구문 검사 수치와 로그를 갱신해야 한다.

## 남은 검증

Flutter analyzer와 신규/기존 전체 테스트 실행은 필수 후속 작업이다. UI 브라우저 플레이, 화면 크기별 실제 렌더링, 저장 실패의 플랫폼 동작, 4일차 이후 재미/장기 경제, 소리/아트 품질도 미검증이다. 기존 플레이테스트 보고서는 1598880의 3일차까지 관찰이므로 신규 주민 이야기의 플레이 검증 자료가 아니다. 배포·게시·merge는 수행하지 않았다.
