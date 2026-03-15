# 프론트엔드 규칙 (front/)

> peach-setup-harness Source of Truth — 대상 프로젝트 AGENTS.md의 프론트엔드 규칙 섹션 기준

## 기술 스택
- Vue 3 + Vite + Pinia · **NuxtUI v4** + TailwindCSS v4 · Vitest · **ESLint**

## 모듈 구조
→ `front/src/modules/test-data/` 참조
- pages/ · components/ · store/ · modals/ · types/
- 계층: `{module}/` · `{domain}/{module}/` · `{domain}/{category}/{module}/`

## UI 패턴
- `crud`, `crud-excel`, `two-depth`, `select-list`, `infinite-scroll`
- 상세 패턴은 test-data 가이드 코드를 우선 참조

## Store 표준 (Pinia Option API)
- 표준 상태: `listParams`, `listData`, `listTotalRow`, `detailData`
- 표준 액션: `paging()`, `list()`, `detail()`, `insert()`, `update()`, `updateUse()`, `softDelete()`
- 초기화: `listParamsInit()`, `detailDataInit()`

## 타입 표준
- `[모듈명]`, `[모듈명]SearchDto`, `[모듈명]PagingDto`, `[모듈명]InsertDto`, `[모듈명]UpdateDto`

## 핵심 원칙 (추론 불가)
- Composition API: `<script setup lang="ts">` 필수
- Store는 Pinia Option API만 사용
- 모든 API는 Store 통해 호출
- Store 값은 반드시 `computed()`로 래핑
- `isLoading` 상태 금지, 버튼 `loading` 속성 우선
- 파일 업로드: `_common/components/file/` 사용
- NuxtUI와 `_common` 래퍼 컴포넌트를 우선 사용

## 공통 컴포넌트
- 날짜: `p-date-picker-work`, `p-date-picker-multi-work`, `p-day-select`
- 폼: `p-nuxt-select`, `p-input-box`, `p-select-box`, `p-checkbox`, `p-radiobox`, `p-form-row`, `p-button`
- 파일/모달/페이지네이션: `p-file-upload`, `p-modal`, `p-modal-common`, `p-pagination-work`
- NuxtUI: `UFormField`, `UModal`, `USwitch`, `UTabs`, `UBadge`

## 파일명 규칙
- 페이지: `{module-name}-{page-type}.vue`
- 모달: `{module-name}-{action}.modal.vue`
- 컴포넌트: `{module-name}-{name}.component.vue`
- 스토어: `{module-name}.store.ts`
- 타입: `{module-name}.type.ts`
- 라우트: `_{module-name}.routes.ts`

## 품질 검증
```bash
bun run dev && bun run test && bunx vue-tsc --noEmit && bun run lint:fix && bun run build
```
