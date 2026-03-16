# 섹션 3. 테스트 및 품질

> AGENTS.md 섹션 3 소스 — 가이드 코드가 말 못하는 것만

- **모든 테스트 100% 성공** 필수
- 테스트 설정: `src/modules/test-data/test/test-data.test.ts` 참조

품질 검증: `bun run local && bun run test:run && bunx vue-tsc --noEmit && bun run lint && bun run build`
