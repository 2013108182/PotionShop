# V2 로컬 검증 결과

검증일: 2026-10-05
검증 대상 구현 커밋: e19343eef9fc020e5ee4c0686c49a0144b3c60c2
브랜치: development/v2-resident-stories
환경: Windows, Flutter 3.47.6 stable, Dart 3.13.5

## 실제 실행 결과

- flutter pub get: 성공, 종료 코드 0.
- flutter analyze: 성공, No issues found, 종료 코드 0.
- flutter test: 89개 통과, 4개 실패, 종료 코드 1.
- flutter build web --release: 성공, build/web 생성, 종료 코드 0.
- 웹 빌드 경고: CupertinoIcons 폰트가 포함되지 않았다는 경고가 발생함. 실행 화면에서 영향 확인 필요.
- 브라우저 로딩 및 플레이 검증: 이 기록 시점에는 미완료.

## 실패한 테스트

1. planning_book_test.dart: Research selection passes the selected target without a solution. warmth 콜백을 기대했지만 null이 반환됨.
2. opening_test.dart: 1280x720 도입부 진행 테스트. action 헬퍼가 버튼을 찾지 못해 Bad state: No element 발생.
3. opening_test.dart: 360x800 도입부 진행 테스트. 동일한 버튼 검색 실패.
4. service_sequence_test.dart: Arrival, conversation, selection and response reveal only their own UI. 기대한 163 G 표시를 찾지 못함.

실패 원인이 기능 오류인지 V2 변경에 맞지 않는 테스트 전제인지 아직 확정하지 않았음.
테스트를 삭제하거나 통과로 표시하지 않았으며, 구현 코드도 이 검증 기록을 위해 변경하지 않았음.

## GitHub 반영 범위

ZIP의 Git bundle에 포함된 구현 및 기획 커밋 4개를 원래 이력 그대로 개발 브랜치에 푸시함.
main 병합 및 프로덕션 배포는 수행하지 않았음.
본 문서는 별도의 검증 결과 기록이며 배포 승인이나 전체 기능 검증 완료를 의미하지 않음.
