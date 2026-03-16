# 섹션 2. 프론트엔드 규칙

> AGENTS.md 섹션 2 소스 — 가이드 코드가 말 못하는 것만

기술 스택: Vue 3 · Vite · Pinia · **NuxtUI v4** · TailwindCSS v4 · TypeScript · Vitest

-> 가이드 코드 `src/modules/test-data/` 참조

**추론 불가 규칙:**
- `<script setup lang="ts">` 필수
- Store: Pinia Option API 필수, `isLoading`/`error` 상태 금지
- Store 값은 반드시 `computed()`로 래핑
- 모든 API는 Store 통해 호출 (Mock interceptor 경유)
- 컴포넌트 태그: 케밥케이스 사용 (예: `<u-button>`, `<p-modal>`)
- 파일 업로드: `_common/components/file/` 및 `_common/services` 사용
- NuxtUI 및 `_common` 래퍼 컴포넌트 우선 사용
- 공통 컴포넌트(p- 프리픽스): `src/modules/_common/components/` 참조
- UI 패턴: `crud`, `crud-excel`, `two-depth`, `select-list`, `infinite-scroll`
- 완전 독립 도메인: 다른 도메인의 Store/타입 import 금지 (단, _common 컴포넌트 및 타 모듈 모달 호출은 허용)

인터페이스 명명: `[모듈명]`, `[모듈명]SearchDto`, `[모듈명]PagingDto`, `[모듈명]InsertDto`, `[모듈명]UpdateDto`

품질 검증: `bun run local && bun run test:run && bunx vue-tsc --noEmit && bun run lint && bun run build`
