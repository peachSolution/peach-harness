# UI 패턴별 차이점

## ui=crud (기본)

목록 + 모달 방식

- `list.vue` (껍데기)
- `list-search.vue` (검색)
- `list-table.vue` (테이블+버튼)
- `modals/*.modal.vue` (등록/수정/상세)

## ui=two (투뎁스)

좌우 분할 레이아웃

- 좌: 검색+목록
- 우: 상세
- `list-detail.vue` 추가
- 참조: `front/src/modules/test-data/pages/two-depth/`

## ui=select (선택 모달)

다른 화면에서 데이터 선택용

- `select.modal.vue`
- 단일/다중 선택 지원
- 참조: `front/src/modules/test-data/pages/select-list/`
