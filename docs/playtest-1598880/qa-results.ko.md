# 클라우드 검증 기록

검증일: 2026-10-04 UTC. 대상: `main` 기준 커밋 `159888011876cd95337e0c00012f94f158552cf6`의 `flutter/`와 이번 로컬 F08/F09 수정. 사용자 PC, Windows 실행 세션, 배포 서버를 사용하지 않았다.

## 결과와 차단 사유

**F08/F09는 소스에서 원인을 확인하고 회귀 테스트를 작성했지만, Flutter 실행 검증은 완료하지 못했다.** 아래 명령은 모두 Dart SDK 다운로드 단계에서 `curl: (56) CONNECT tunnel failed, response 403`으로 종료됐다. 테스트 러너와 분석기가 시작되지 않았으므로 통과/실패 개수나 컴파일 성공을 주장하지 않는다. 자동 승인 검토의 거절이 아니라 실제 네트워크 프록시의 응답이다.

| 확인 | 실행 위치 / 명령 | 결과 | 증거 |
|---|---|---|---|
| 수정 전 전체 테스트 | 별도 원본 추출본에서 `flutter test` | 실행 차단, exit 56 | [baseline-test.log](evidence/baseline-test.log) |
| 수정 전 회귀 테스트 | 원본에 새 테스트만 복사하여 `flutter test test/playtest_regression_test.dart` | 실행 차단, exit 56; red 미확인 | [baseline-regression-test.log](evidence/baseline-regression-test.log) |
| 의존성 확보 | 수정본에서 `flutter pub get` | 실행 차단, exit 56 | [pub-get.log](evidence/pub-get.log) |
| 수정 후 집중 테스트 | `flutter test test/playtest_regression_test.dart test/shop_test.dart` | 실행 차단, exit 56 | [regression-test.log](evidence/regression-test.log) |
| 수정 후 전체 테스트 | `flutter test` | 실행 차단, exit 56 | [full-test.log](evidence/full-test.log) |
| 정적 분석기 | `flutter analyze` | 실행 차단, exit 56 | [analyze.log](evidence/analyze.log) |

## 환경 확보 내역

- 시작 시 실행 가능한 Flutter/Dart SDK는 없었다. `/workspace`, `/tmp`, `/opt` 및 시스템 경로를 확인했다.
- 공식 `https://github.com/flutter/flutter.git`의 stable 소스를 `/workspace/tools/flutter`에 shallow clone했다. 확보한 태그는 **3.47.6**, 커밋 `5fc346839b5d0eef006ed8404392afb4dfae428d`, engine `692136cb6582dbfc5af3fb33c2515a069f2f66d0`이다. 저장소 기존 `VALIDATION.md`의 Flutter 버전과 일치한다.
- SDK bootstrap은 `https://storage.googleapis.com/flutter_infra_release/flutter/692136cb6582dbfc5af3fb33c2515a069f2f66d0/dart-sdk-linux-x64.zip` 접근이 필요하다. 일반 실행과 추가권한 실행 모두 CONNECT 403이었다.
- 공식 저장소 별칭 `storage-download.googleapis.com`, `commondatastorage.googleapis.com`, 하이픈 버킷 별칭 및 `storage.flutter-io.cn`도 CONNECT 403이었다. 밑줄 버킷 별칭은 CONNECT 400이었다. GitHub 릴리스 API 접근도 403이었다. `pub.dev`와 Git clone은 접근 가능했으나 SDK 바이너리를 대체하지 못한다.
- 수정 전 원본은 `/workspace/qa-baseline-1598880/flutter`에 `git archive`로 별도 추출했다. 회귀 테스트만 추가하여 원본 코드의 실패 여부를 검증할 준비를 했다.

## 회귀 테스트의 검증 의도

신규 [playtest_regression_test.dart](../../flutter/test/playtest_regression_test.dart)는 1280×720, 애니메이션 축소 환경에서 다음 6개 시나리오를 정의한다.

1. F08: 설비, 영업 장부, 재료 상인을 각각 연 뒤 일반 닫기/열기는 선택을 유지하고, 상단 협회 바로가기는 항상 주문서를 연다(3개).
2. F09: 연구 대기, 연구 완료, 요청 없음에 따라 마감 버튼이 실제 가능한 밤 활동을 안내한다. 버튼으로 밤에 진입하고 저장되며, 연구 버튼은 대기 상태에만 존재한다(3개).

소스와 테스트의 독립 교차 검토 중 상인 해금 fixture의 `supplierUnlocked=true`만으로는 `Game.decode`의 유효 진행 조건을 충족하지 못함을 발견했다. 완료 상태에는 시야 레시피 해금도 필요하다는 점을 수정 담당에게 전달했고 최종 테스트 fixture에 `discovered.add('sight')` 반영을 확인했다. 이 검토는 실행 테스트를 대체하지 않는다.

기존 `flutter/test/`는 도입부, 연구, 저장, 판매 거절/재시도, 재고/제조, 설비, 협회, 화면 탐색, 전환, 스프라이트 및 애니메이션 테스트를 포함한다. 기존 Windows `VALIDATION.md`의 “16개 통과”는 과거 기록이며 이번 클라우드 실행 결과로 재사용하지 않았다.

## 최소 클라우드 설정 변경

차단 지점은 **`storage.googleapis.com:443`에 대한 HTTPS CONNECT**이며, 실제 오류는 **`curl: (56) CONNECT tunnel failed, response 403`**이다. 이는 네트워크 프록시의 접근 거부로, 단순한 일시적 네트워크 실패나 자동 승인 검토의 거절이 아니다. 추가권한 실행도 같은 프록시 응답을 받았다. 거부된 경로를 우회하는 추가 시도는 하지 않는다.

검증을 재개하려면 다음 중 하나를 지원되는 클라우드 설정/파일 제공 경로로 적용해야 한다.

- `storage.googleapis.com:443`의 공식 Flutter artifact 경로 `https://storage.googleapis.com/flutter_infra_release/flutter/` 아래 SDK 및 Linux 테스트 엔진 다운로드에 필요한 HTTPS CONNECT 접근을 허용한다. 현재 즉시 차단된 파일은 `692136cb6582dbfc5af3fb33c2515a069f2f66d0/dart-sdk-linux-x64.zip`이다. 프록시가 CONNECT 단계에서 거부하므로 URL 경로 조건 지원 여부는 해당 네트워크 관리 기능에 달려 있다.
- 또는 동일한 **Flutter 3.47.6 / Dart 3.13.5**, engine `692136cb6582dbfc5af3fb33c2515a069f2f66d0`의 완전한 SDK, Linux 테스트 엔진 및 프로젝트 의존성 캐시를 지원되는 방식으로 이 클라우드에 제공한다. Dart 실행파일 하나만으로는 Flutter widget test를 실행할 수 없다.

이 변경은 사용자 PC를 켤 필요가 없으며, 앱 소스 수정이나 배포 권한 확대를 요구하지 않는다. SDK 단계 해소 후 의존성 확보가 별도로 거부된다면 그 실제 요청과 오류를 다시 확인해야 하며, 현재 `pub.dev` 기본 페이지 접근 성공만으로 모든 패키지 다운로드를 보장하지 않는다.

## 재개 절차

클라우드에서 공식 Flutter artifact 저장소 다운로드가 허용되거나 동일 버전의 완전한 SDK 캐시를 확보하면 아래 순서로 실행한다. 사용자 데스크톱이 필요하지 않다.

```sh
export PATH=/workspace/tools/flutter/bin:$PATH
cd /workspace/PotionShop/flutter
flutter --version
flutter pub get
flutter test test/playtest_regression_test.dart test/shop_test.dart
flutter test
flutter analyze
```

재개 스크립트: `bash scripts/verify-playtest-1598880.sh` (선택적으로 `FLUTTER_BIN`, `QA_LOG_DIR` 지정). 최초 실패에서 종료하며 새 로그를 `evidence/resumed/`에 보존한다. 스크립트는 `bash -n` 검사를 통과했고 최종 변경은 `git diff --check`를 통과했다. 이는 Dart 분석/테스트 통과를 의미하지 않는다.

원본 red 확인은 `/workspace/qa-baseline-1598880/flutter`에서 `flutter pub get` 후 `flutter test test/playtest_regression_test.dart`를 실행한다. 원본 F08은 주문서 목적지 assertion, F09 완료/요청없음은 올바른 버튼 assertion에서 실패해야 한다. 실제 결과를 확보한 뒤에만 red/green을 확정한다.

## 검증 범위의 한계

- 이번 실행에서 웹 브라우저 플레이, 화면 크기별 렌더링, 사운드, 웹/플랫폼 빌드는 검증하지 못했다.
- 보고서는 빌드 1598880의 3일차까지 관찰에 한정한다. 4일차 이후, 장기 경제, 이후 콘텐츠 존재 여부는 이번 QA로 확정하지 않는다.
- 입력 PDF는 부모 담당이 Library 원문 읽기로 4페이지를 확인했다. PDF 바이너리의 로컬 materialize는 접근 차단으로 완료되지 않았으므로 로컬 PDF 파일을 읽었다고 주장하지 않는다.
- 로컬 수정만 유지하며 merge/deploy/publish는 수행하지 않는다.
