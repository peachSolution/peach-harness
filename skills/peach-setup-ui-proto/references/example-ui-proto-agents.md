# Frontend-Only UI Proto 프로젝트 AGENTS.md 예시

> peach-setup-ui-proto Source of Truth — Frontend-Only UI Proto 프로젝트의 정제된 AGENTS.md 템플릿
>
> `{모듈구조}` 플레이스홀더를 `ls -d src/modules*/`로 감지된 실제 디렉토리 목록으로 치환한다.

---

```markdown
# {프로젝트명} - AI 에이전트 가이드

> Frontend-Only 프로토타이핑 도구

## 1. 공통 원칙

### 기본 규칙
- 응답 언어: **한국어**
- Code-First: 문서보다 가이드 코드 참조
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- Mock 모드: Backend API 없음, 모든 API는 Mock 데이터 반환
- 모듈 루트: {모듈구조}

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블 | snake_case | test_data |
| 파일/폴더 | kebab-case | test-data |
| 클래스/타입 | PascalCase | TestData |
| 변수/함수 | camelCase | testData |

### 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지

### 가이드 코드 위치
코드 생성 = **가이드 코드 복사** + 모듈명 치환
- Frontend: `src/modules/test-data/`

## 2. 프론트엔드 규칙

### 기술 스택
| 항목 | 버전 |
|------|------|
| Vue | ^3.x |
| Vite | ^6.x |
| Pinia | ^3.x |
| NuxtUI | ^4.x |
| TailwindCSS | ^4.x |
| TypeScript | ^5.x |
| Vitest | ^3.x |

### 모듈 구조
```text
[모듈명]/
├── pages/
│   ├── _[모듈명].routes.ts
│   ├── [모듈명]-list.vue
│   ├── [모듈명]-list-search.vue
│   ├── [모듈명]-list-table.vue
│   └── [모듈명]-detail.vue
├── modals/
│   ├── _[모듈명].validator.ts
│   ├── [모듈명]-insert.modal.vue
│   └── [모듈명]-update.modal.vue
├── store/[모듈명].store.ts
├── type/[모듈명].type.ts
├── mock/[모듈명].mock.ts
└── test/[모듈명].test.ts
```

### UI 패턴
| 패턴 | 설명 | 참고 |
|------|------|------|
| crud | 독립 페이지 (목록/상세/등록/수정) | `pages/crud/` |
| crud-excel | 엑셀 업로드/다운로드 | `pages/crud-excel/` |
| two-depth | 좌우 분할 (좌:목록, 우:상세+탭) | `pages/two-depth/` |
| select-list | 모달 선택 (단일/다중) | `pages/select-list/` |
| infinite-scroll | 무한스크롤 페이징 | `pages/infinite-scroll-list/` |

### Store 표준 (Pinia Option API 필수)
- 상태: `listParams`, `listData`, `listTotalRow`, `detailData`
- 액션: `paging()`, `list()`, `detail()`, `insert()`, `update()`, `updateUse()`, `softDelete()`
- 초기화: `listParamsInit()`, `detailDataInit()`

### 타입 표준
`[모듈명]`, `[모듈명]SearchDto`, `[모듈명]PagingDto`, `[모듈명]InsertDto`, `[모듈명]UpdateDto`

### 핵심 원칙
- **Composition API**: 컴포넌트는 `<script setup>` 필수
- **Option API**: Store는 반드시 Option API 방식
- **Store 경유**: 모든 API는 Store 통해 호출
- **Store 래핑**: 컴포넌트에서 Store 값은 반드시 `computed()`로 래핑
- **Yup 검증**: 유효성 검증 필수
- **isLoading 금지**: NuxtUI 버튼 `loading` 속성을 우선 사용
- **반응형**: 모바일/데스크톱 지원
- 파일 업로드: `_common/components/file/` 및 `_common/services` 활용
- NuxtUI 및 `_common` 래퍼 컴포넌트 우선 사용

### 공통 컴포넌트 (p- 프리픽스)
| 카테고리 | 컴포넌트 | 용도 |
|---------|---------|------|
| 날짜 | `p-date-picker-work` | 날짜 단일 선택 |
| 날짜 | `p-date-picker-multi-work` | 날짜 범위 선택 |
| 날짜 | `p-day-select` | 요일 선택 |
| 폼 | `p-nuxt-select` | 드롭다운 선택 |
| 폼 | `p-input-box` | 포맷팅 입력 |
| 폼 | `p-select-box` | 셀렉트 박스 |
| 폼 | `p-checkbox` | 체크박스 |
| 폼 | `p-radiobox` | 라디오 버튼 |
| 폼 | `p-form-row` | 폼 행 레이아웃 |
| 폼 | `p-button` | 공통 버튼 |
| 파일 | `p-file-upload` | 파일 업로드 |
| 레이아웃 | `p-bread-crumb` | 브레드크럼 |
| 모달 | `p-modal`, `p-modal-common`, `p-modal-alert`, `p-modal-confirm` | 공통 모달 |
| 페이지네이션 | `p-pagination-work` | 페이지네이션 |
| 에디터 | `p-editor-quill`, `p-editor-html-only` | 편집/뷰어 |
| 주소 | `p-post-code` | 우편번호/주소 검색 |
| NuxtUI | `UFormField`, `UModal`, `USwitch`, `UTabs`, `UBadge` | NuxtUI 기본 컴포넌트 |

## 3. Mock 모드 특이사항

- 모든 API 호출은 `src/modules/_common/services/api.service.ts`의 Mock 구현으로 처리
- Mock 데이터는 `src/modules/test-data/mock/test-data.mock.ts`를 기준으로 설계
- 인증 로직은 없다고 가정

## 4. 검증

```bash
bun run test:run
bunx vue-tsc --noEmit
bun run lint
bun run build
```

## 5. 하네스 시스템 연동

### 세션 시작 체크리스트
1. `git status && git branch` 확인
2. 미완료 작업이 있으면 `docs/spec/` 또는 `git log`로 컨텍스트 파악

### 스킬 카탈로그 참조
전체 스킬 목록과 워크플로우는 `/peach-help`를 실행하라.
```
