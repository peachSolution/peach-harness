# 섹션 3. 프론트엔드 규칙 (front/)

> AGENTS.md 섹션 3 소스 — 가이드 코드가 말 못하는 것만

기술 스택: Vue 3 · Pinia · NuxtUI v4 · TailwindCSS v4 · Vitest · ESLint

→ 가이드 코드 `front/src/modules/test-data/` 참조

**추론 불가 규칙:**
- `<script setup lang="ts">` 필수
- Store: Pinia Option API, `isLoading`/`error` 상태 금지
- Store 값은 반드시 `computed()`로 래핑
- 모든 API는 Store 통해 호출
- 5개 이상 TailwindCSS 클래스 → 배열 그룹화
- 완전 독립 도메인: 다른 도메인의 Store/타입 import 금지 (단, _common 컴포넌트 및 타 모듈 모달 호출은 허용)

품질 검증: `bun run local && bun run test && bunx vue-tsc --noEmit && bun run lint:fix && bun run build`
