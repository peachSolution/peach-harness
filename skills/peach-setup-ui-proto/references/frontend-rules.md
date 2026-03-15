# UI Proto 프론트엔드 규칙

> peach-setup-ui-proto Source of Truth — Frontend-Only UI Proto 프론트엔드 규칙

## 기술 스택
- Vue 3 + Vite + Pinia · **NuxtUI v4** + TailwindCSS v4 · TypeScript · Vitest

## 모듈 구조
```text
[모듈명]/
├── pages/
├── modals/
├── store/
├── type/
├── mock/
└── test/
```

## UI 패턴
- `crud`, `crud-excel`, `two-depth`, `select-list`, `infinite-scroll`

## Store 표준
- 상태: `listParams`, `listData`, `listTotalRow`, `detailData`
- 액션: `paging()`, `list()`, `detail()`, `insert()`, `update()`, `updateUse()`, `softDelete()`
- 초기화: `listParamsInit()`, `detailDataInit()`

## 타입 표준
- `[모듈명]`, `[모듈명]SearchDto`, `[모듈명]PagingDto`, `[모듈명]InsertDto`, `[모듈명]UpdateDto`

## 핵심 원칙
- `<script setup lang="ts">` 필수
- Store는 Pinia Option API만 사용
- 모든 API는 Store 통해 호출
- Store 값은 반드시 `computed()`로 래핑
- `isLoading` 상태 금지, 버튼 `loading` 속성 우선
- 파일 업로드는 `_common/components/file/` 및 `_common/services` 사용
- NuxtUI와 `_common` 래퍼 컴포넌트를 우선 사용

## 공통 컴포넌트
- 날짜: `p-date-picker-work`, `p-date-picker-multi-work`, `p-day-select`
- 폼: `p-nuxt-select`, `p-input-box`, `p-select-box`, `p-checkbox`, `p-radiobox`, `p-form-row`, `p-button`
- 파일/모달/페이지네이션: `p-file-upload`, `p-modal`, `p-modal-common`, `p-pagination-work`
- NuxtUI: `UFormField`, `UModal`, `USwitch`, `UTabs`, `UBadge`
