# 섹션 4. 테스트 및 품질

> AGENTS.md 섹션 4 소스 — 가이드 코드가 말 못하는 것만

- Service 새 로직: **bun test 기반 TDD** 필수
- 테스트는 실제 데이터베이스 사용, 모킹 금지
- **모든 테스트 100% 성공** 필수

테스트 설정: `api/src/modules/test-data/test/test-data.test.ts` 참조
Frontend 설정: `VitestSetup.initializeTestEnvironment()` + `VitestSetup.sign('test', 'test!%#')`
