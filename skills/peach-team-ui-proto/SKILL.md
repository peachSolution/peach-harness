---
name: peach-team-ui-proto
description: |
  Backend 없이 Mock 데이터 기반 프로토타입 UI를 생성·검증하는 기획 구체화 산출물 스킬. Vue 3 + TypeScript + NuxtUI v4.
  별도 ui-proto 저장소(예: peach-ui-proto-backoffice)의 src/modules-task 폴더에 태스크별 화면을 누적한다.
  "프로토타입 만들어줘", "Mock 화면", "proto UI", "기획 화면 빠르게",
  "ui-proto 작업", "기획자 검토용 화면", "태스크 폴더 추가", "팀 ui-proto" 키워드로 트리거.
  Spec 문서가 입력으로 주어지면 후속 team-dev/team-e2e 입력 품질을 높이기 위해 조건부 팀 모드(랄프루프 5/10회)로 전환되며,
  Spec 없이 기획자가 직접 작업하는 경우 단독 모드로 동작한다.
  실제 API 연동이 필요하면 peach-gen-ui를 사용한다.
---

# Peach Team UI Proto

ui-proto 화면을 만들고 검증하는 기획 구체화 산출물 스킬.

이 스킬의 핵심은 팀 자동화가 아니라, 사람의 의도를 화면/액션/상태/`TEST_ID` 매핑으로 구체화해 `peach-team-dev`와 `peach-team-e2e`가 개발과 검증을 오래 자율 수행할 수 있는 기준을 만드는 것이다.

## 핵심 원칙

- **Backend 없음**: 모든 API는 Mock interceptor 경유 (useApi() 호출 유지)
- **생성 방식**: test-data 가이드 코드를 기준 골격으로 참조 후 Mock 특화 적응
- **컴포넌트 사용**: 케밥케이스 사용 (예: `<u-button>`, `<u-modal>`, `<my-component>`)
- **완료 기준**: vue-tsc + lint + build 모두 통과
- **프로덕션 전환 대비**: API 시그니처 유지, Mock 교체만으로 실서버 연동 가능
- **저장소 분리 (2026-04-27 결정)**: 본 프로젝트가 아닌 **별도 ui-proto 저장소**의 `src/modules-task/{년월}/{태스크폴더}/`에 누적
- **검증 기준 산출물**: `_spec.md` + 화면 파일이 본 개발(`peach-team-dev`)의 검증 기준이 됨
- **1차 완성도 지원**: 화면 목록, 주요 액션, 완료/오류 상태, Spec `TEST_ID` 매핑을 남겨 `team-dev`와 `team-e2e`의 누락을 줄임
- **기획 구체화 우선**: Spec 없이 기획자가 직접 구체화하는 경우에는 단독/대화형 흐름을 우선하고, AI 팀이 임의로 요구를 증폭하지 않는다

## 역할 경계

| 스킬 | 책임 |
|------|------|
| `peach-team-ui-proto` | Mock 기반 기획 검토용 화면 + `_spec.md` + 태스크 메타 + 화면/액션/상태 매핑 생성·검증 |
| `peach-team-dev` | 준비된 DB/Spec/ui-proto 기준 본 프로젝트 코드 구현 |
| `peach-team-e2e` | 본 개발 완료 후 실제 브라우저 흐름과 기획 부합 검증 |
| `peach-gen-ui` | 실제 API/Store 기반 UI 단독 생성 |

ui-proto는 본 개발 코드가 아니다. 프로덕션 코드 수정, 실제 API 연동, E2E 최종 판정, 완전한 E2E 시나리오 설계는 이 스킬에서 처리하지 않는다.

## ui-proto 저장소 구조

이 스킬은 **별도 ui-proto 저장소**에서 실행한다 (예: `peach-ui-proto-backoffice`).
본 프로젝트가 아닌 시점이면 사용자에게 저장소 위치를 확인한다.

```
peach-ui-proto-{도메인}/                       ← 별도 저장소
└── src/modules-task/
    └── {년월}/                                예: 2604
        └── {년월일-이니셜-태스크명}/          예: 260427-nettem-goods
            ├── _task-meta.ts                  메타 (날짜/담당자/제목/modules)
            ├── _spec.md                       Spec 원본 (Source of Truth)
            ├── _routes.ts                     overview + 서브모듈 라우트
            ├── layout/
            │   ├── task-layout.vue            서브모듈용 (배너+사이드바)
            │   └── task-overview-layout.vue   기획서용 (배너+전체)
            ├── overview/pages/overview.vue    기획서 화면
            └── {서브모듈}/                    실제 UI 화면
                ├── pages/
                ├── store/
                └── type/
```

새 태스크 생성 시 기존 태스크 폴더(예: `2603/260320-nettem-board/`)를 통째로 복사 후 메타·라우트·서브모듈명만 수정하는 게 빠르다. 상세는 ui-proto 저장소의 `AGENTS.md` 참조.

---

## 조건부 팀화 (2026-04-27 결정, 2026-05-04 방향 보강)

이 스킬은 입력에 따라 **팀 모드/단독 모드**로 분기한다. 단, 팀 모드의 목적은 자율 개발이 아니라 후속 개발/검증 기준의 품질을 높이는 것이다.

### 모드 결정 트리

```
Spec 문서가 입력으로 주어짐?
       │
       ├─ Yes → 조건부 팀 모드
       │       (proto-ui-dev + proto-ui-qa)
       │       목적: 화면/액션/상태/TEST_ID 매핑 품질 보강
       │       랄프루프: 5회(단순) / 10회(복잡)
       │
       └─ No  → 단독 모드 (기존 동작)
               기획자가 직접 구체화하는 경우
               랄프루프: 5회 (단독 검증만)
```

`team=N` 인자로 단독 모드 강제 가능.

### 팀 모드 (Spec 입력 시)

#### 입력 형태

```bash
/peach-team-ui-proto [모듈명] spec=<Spec 파일 경로> [옵션]
```

또는 위치 인자로 자연어 입력:
```bash
/peach-team-ui-proto "Spec: docs/spec/26/04/nettem-260427-상품관리.md" 상품관리
```

#### 팀 구성

| 역할 | 책임 |
|------|------|
| **proto-ui-dev** | Spec 기반 화면 구현 (modules-task 폴더 생성) |
| **proto-ui-qa** | Spec 부합 검증 + 시각/UX 검증 + 후속 dev/e2e 입력 적합성 검증 (독립 worktree, 읽기전용) |

#### proto-ui-qa 검증 항목

1. Spec의 화면 요구사항이 모두 반영되었는가
2. NuxtUI v4 컴포넌트 사용 규칙 준수 여부
3. 본 프로젝트(`peach-{도메인}`)의 컴포넌트 패턴과 일치 여부
4. AI Slop 패턴(그라데이션, 보라색 등) 회피 여부
5. modules-task 폴더 구조 규칙 준수 (`_task-meta.ts`, `_routes.ts`, layout 분리 등)
6. 라우트 통합 규칙 준수 (`_task.routes.ts`의 taskDetailRoutes에 추가)
7. DESIGN.md가 있을 경우 디자인 시스템 규칙(색상, 컴포넌트 네이밍, 타이포그래피) 준수 여부
8. 화면 목록과 Spec 기능/`TEST_ID`가 매핑되어 있는가
9. 주요 액션(검색/저장/승인/반려/업로드/다운로드 등)의 완료 상태와 오류 상태가 화면에 표현되어 있는가
10. `team-e2e`가 단위 시나리오를 분할할 수 있도록 화면 전환 흐름의 단서가 충분한가
11. `team-dev`가 구현 기준으로 사용할 수 있도록 화면/Store/API 기대가 충분히 드러나는가

#### 랄프루프 5/10 판단 기준

| 모드 | 최대 반복 |
|------|----------|
| 단순 화면 (목록만, 단일 모달) | 5회 |
| 복잡 화면 (멀티탭, 다중 모달, 차트, 다단계 폼) | 10회 |

상한 도달 시 사용자에게 보고하고 중단.

### 단독 모드 (Spec 없을 때, 기존 동작)

기획자가 직접 구체화하는 경우. 자체 검증만 수행 (별도 QA 에이전트 없음).
랄프루프 5회 (vue-tsc + lint + build 통과 시도).

### 모듈명/태스크 폴더명 자동 생성

Spec이 입력되었을 때:
- Spec 본문과 사용자 입력에서 `planner`, `date`, `title` 후보를 추출
- 태스크 폴더명: `{YYMMDD}-{planner}-{영문슬러그}` 형식 (한글 금지)
- 확정된 메타로 `_task-meta.ts`를 생성한다. 이후 `peach-team-dev proto=<경로>`는 이 `_task-meta.ts`를 읽어 Spec 사본 파일명을 산출한다
- 사용자에게 자동 추출 결과 보여주고 확정 받기

자연어 입력으로 들어온 경우:
- AI가 1~3개 후보 제안 → 사용자 선택

---

## 프로토타입 특성

- Backend 없이 Mock interceptor로 `useApi()` 호출을 처리한다.
- Mock 데이터는 `mock/`에 분리하고, 실제 API 전환 시 시그니처를 유지한다.
- 시각 품질과 AI Slop 방지 상세는 [visual-guide.md](references/core/visual-guide.md)를 따른다.

## 1차 완성도 산출물

Spec 입력이 있는 조건부 팀 모드에서는 `_spec.md` 하단에 다음 섹션을 반드시 남긴다. 이 정보는 완전한 E2E 시나리오가 아니라 `team-dev`와 `team-e2e`가 누락을 줄이기 위한 화면/액션/상태 연결 기준이다.

```markdown
## UI Proto 검증 매핑

### 화면 목록
| 화면 | 경로 | 관련 TEST_ID | 목적 |
|------|------|--------------|------|

### 주요 액션
| 액션 | 시작 화면 | 결과 화면/상태 | 관련 TEST_ID | E2E 후보 |
|------|-----------|----------------|--------------|----------|

### 완료/오류 상태
| 상태 | 표시 위치 | 메시지/피드백 | 관련 TEST_ID |
|------|-----------|---------------|--------------|

### Spec 미반영/검증 불가
| TEST_ID | 사유 | 후속 처리 |
|---------|------|-----------|
```

작성 규칙:

- Spec에 있는 `TEST_ID`가 화면에 없으면 숨기지 말고 `Spec 미반영/검증 불가`에 기록한다.
- Mock 데이터 한계로 실제 데이터 정확성을 검증할 수 없는 항목은 `team-e2e` 또는 TDD 검증 대상으로 넘긴다.
- 화면 흐름은 ui-proto 기준, 권한/상태/오류 규칙은 Spec 기준으로 구분한다.
- 시나리오의 세부 셀렉터, fixture, suite 조합은 `peach-team-e2e` 책임으로 남긴다.

---

## 절대 필수 패턴 (모든 UI 패턴 공통)

> **경고**: 아래 패턴은 모든 UI 패턴에서 반드시 적용해야 합니다.
> 누락 시 검색, 페이징, URL 상태관리가 동작하지 않습니다.

### 필수 체크리스트

| # | 패턴 | 적용 위치 |
|---|------|----------|
| 1 | `<form @submit.prevent="listAction">` | list-search.vue |
| 2 | `@change="listAction"` (select, radio) | list-search.vue, list-table.vue |
| 3 | `@update:modelValue="listAction"` (date) | list-search.vue |
| 4 | `@update:page="listMovePage"` (pagination) | list-table.vue |
| 5 | watch 패턴 (route → listParams) | list-search.vue |
| 6 | watch 패턴 (route → getList) | list-table.vue |
| 7 | `listAction()`, `resetAction()`, `listMovePage()` | 각 컴포넌트 |

> **상세 코드와 금지 패턴**: [common-patterns.md](references/core/common-patterns.md) 참조 (필수)

---

## 입력 방식

```
/peach-team-ui-proto [모듈명] [옵션]
```

### 옵션
| 옵션 | 기본값 | 설명 |
|------|--------|------|
| excel | N | 엑셀 다운로드/업로드 기능 (Mock) |
| file | N | 파일 업로드 기능 (Mock) |
| spec | (없음) | Spec 파일 경로. 지정 시 **팀 모드** 자동 진입 |
| team | (자동) | `team=N`으로 팀 모드 강제 비활성화 |

### 예시
```
# 단독 모드 (기획자 직접 작업)
/peach-team-ui-proto notice-board
/peach-team-ui-proto member-manage excel=Y
/peach-team-ui-proto product file=Y excel=Y

# 팀 모드 (Spec 기반)
/peach-team-ui-proto product spec=docs/spec/26/04/nettem-260427-상품관리.md

# 팀 모드 강제 비활성화
/peach-team-ui-proto product spec=... team=N
```

> UI 패턴은 실행 후 대화형으로 선택 (1단계)
> Spec 입력 시 팀 모드 자동 진입 (proto-ui-dev + proto-ui-qa, 랄프루프 5/10회)

---

## 워크플로우

### Step 0. 디자인 시스템 확인

```bash
cat DESIGN.md 2>/dev/null | head -200
```

- **있으면**: 컴포넌트 규칙·색상·타이포그래피를 컨텍스트에 주입하여 이후 단계에 반영
- **없으면**: 아래 경고 출력 후 계속 진행

```
⚠️ DESIGN.md 없음 — 디자인 시스템 문서가 없습니다. 작성을 권장합니다.
   참고: peach-harness/templates/DESIGN-template.md (또는 /peach-gen-design)
```

---

### 1단계: UI 패턴 필수 선택

> **이 단계는 생략 불가!** 기획자에게 반드시 UI 패턴을 질문하고 선택을 받은 후 진행합니다.
> 선택 없이 코드 생성을 시작하면 안 됩니다.

기획자에게 **반드시** 아래 질문을 하고 선택을 받으세요:

```
## UI 패턴 선택 (필수)

어떤 UI 패턴을 사용할까요?

### 기본 UI 패턴 (test-data 가이드 있음)
| 패턴 | 설명 | 사용 시기 |
|------|------|----------|
| **crud** | 목록 + 모달 | 일반적인 CRUD, 입력 10개 미만 |
| page | 목록 + 별도 페이지 | 입력 10개 이상, URL 공유 필요 |
| two-depth | 좌우 분할 | 목록/상세 동시 표시 |
| infinite-scroll | 무한 스크롤 | 피드형, 모바일 최적화 |
| select-list | 선택 모달 | 다른 화면에서 데이터 참조 |
| show-more | 더보기 버튼 | 적은 데이터, 단계별 로드 |
| batch-process | 일괄 처리 | 순차 작업 진행바 |

### 추가 옵션 (기본 패턴과 조합)
| 옵션 | 설명 |
|------|------|
| excel | 엑셀 다운로드/업로드 (Mock 로컬 생성) |
| file | 파일 업로드 (Mock UUID 반환) |

### 고급 UI 패턴 (MCP 활용, test-data 없음)
| 패턴 | 설명 |
|------|------|
| adv-search | 복합 검색 (5개 이상 조건) |
| calendar | 달력 UI |
| kanban | 칸반 보드 |
| mega-form | 대량 입력 폼 (50개+) |
| tab-list | 탭 내 리스트 |

선택해주세요 (예: crud, excel=Y)
```

**가이드 코드 경로**:
- crud: `src/modules/test-data/pages/crud/`가 있으면 우선 참조
- 기타 패턴: `src/modules/test-data/pages/[패턴명]/` 또는 가장 가까운 기존 `src/modules-task/{년월}/{태스크폴더}/`

---

### 2단계: test-data 가이드 코드 확인 + ui-proto 저장소 감지

```bash
# test-data 모듈 존재 여부 확인
ls src/modules/test-data/ 2>/dev/null

# _common 래퍼 컴포넌트 존재 여부 확인
ls src/modules/_common/components/ 2>/dev/null

# 빌드 도구 감지
ls package.json && head -20 package.json
ls bun.lockb 2>/dev/null && echo "BUILD_TOOL=bun"
```

- **test-data 있음** → 가이드 코드 기반으로 생성
- **test-data 없음** → references 문서 기반으로 생성

#### 빌드 도구 기준

| 파일 존재 | 빌드 도구 | 검증 명령어 |
|-----------|----------|------------|
| `bun.lockb` | bun | `bunx vue-tsc --noEmit && bun run lint:fix && bun run build` |

#### _common 래퍼 우선 사용 (조건부)

> 대상 프로젝트에 `_common/components/` 디렉토리가 존재하면 NuxtUI 직접 사용 대신 래퍼 컴포넌트를 우선 사용합니다.

| NuxtUI | _common 래퍼 (있는 경우 우선) |
|--------|------------------------------|
| `<UInput>` | `<p-input-box>` |
| `<USelect>` | `<p-nuxt-select>` |
| `<UFormField>` | `<p-form-field>` |
| `<UFileInput>` | `<p-file-upload>` |

- `_common/components/` 없으면 → NuxtUI 직접 사용 (기존 방식 유지)

---

### 2.5단계: 도메인 분석 (Analyze)

test-data UI와 요청된 도메인을 비교 분석합니다:

1. **UI 복잡도 판단**: 필드 수, 검색 조건, 테이블 컬럼 구성
2. **Mock 데이터 설계**: 도메인에 맞는 현실적인 샘플 데이터 구상
3. **적응 결정**:
   - Must Follow → 그대로 (script setup, 필수 패턴, AI Slop 금지)
   - May Adapt → 도메인 맞춤 (테이블 컬럼, 검색 폼, 모달 폼 구성)
4. **구조 제안 (May Suggest)**:
   분석 결과 가이드코드와 다른 구조가 더 적합하면 사용자에게 제안:
   - 컴포넌트 분리 (예: 복잡한 폼을 step별 컴포넌트로)
   - 페이지 구성 변경 (예: 탭 내 리스트, 상세 페이지 분리)
   - 사용자 확인 후 적용. Must Follow 침범 금지.

### 3단계: Mock 서비스 + Store + 코드 생성

선택된 패턴의 가이드 코드를 기준 골격으로 참조 후 도메인에 맞게 적응:

#### 3-1. Mock 데이터 생성 (필수)

**[mock-service-pattern.md](references/core/mock-service-pattern.md)** 참조

```
mock/[모듈명].mock.ts 생성:
- 도메인 맞춤 샘플 데이터 (5~10건)
- 동적 데이터 생성 함수
- API 시그니처 유지 (프로덕션 전환 대비)
```

#### 3-2. Store 생성 (Mock useApi() 경유)

**[mock-store-pattern.md](references/core/mock-store-pattern.md)** 참조

```
store/[모듈명].store.ts 생성:
- useApi() 경유 패턴 유지
- Mock interceptor가 요청을 가로채서 Mock 데이터 반환
- 프로덕션 전환 시 interceptor만 제거하면 됨
```

#### 3-3. 페이지 생성

| 패턴 | 가이드 코드 경로 | 참조 문서 |
|------|-----------------|----------|
| crud | `test-data/pages/crud/` | [page-pattern.md](references/basic/page-pattern.md) + [modal-pattern.md](references/basic/modal-pattern.md) |
| page | `test-data/pages/crud/` + `detail-page.vue` | [page-pattern.md](references/basic/page-pattern.md) |
| two-depth | `test-data/pages/two-depth/` | [two-depth-pattern.md](references/basic/two-depth-pattern.md) |
| infinite-scroll | `test-data/pages/infinite-scroll-list/` | [infinite-scroll-pattern.md](references/basic/infinite-scroll-pattern.md) |
| select-list | `test-data/pages/select-list/` | [select-list-pattern.md](references/basic/select-list-pattern.md) |
| batch-process | `test-data/modals/list-table-progress.modal.vue` | [batch-process-pattern.md](references/basic/batch-process-pattern.md) |

**필수 표준 패턴**: [common-patterns.md](references/core/common-patterns.md) 참조
- Selectbox 패턴 (전체 옵션 value='')
- Router 동기화 패턴 (listAction, resetAction, watch)
- Date 검색 패턴 (초기값: 5년 전 ~ 오늘)

---

### 4단계: 검증 & 완료

```bash
# ui-proto 저장소 루트 기준
bunx vue-tsc --noEmit  # 타입 체크
bun run lint:fix       # 린트
bun run build          # 빌드
```

> 에러 발생 시: 원인 분석 → 코드 수정 → 다시 검증 → 통과할 때까지 반복

---

## 생성 파일 구조

`src/modules-task/{년월}/{태스크폴더}/` 아래에 `_task-meta.ts`, `_spec.md`, `_routes.ts`, `layout/`, `overview/`, `{서브모듈}/pages`, `{서브모듈}/store`, `{서브모듈}/type`, `{서브모듈}/modals`를 생성한다. `peach-team-dev proto=<경로>`에는 이 태스크 폴더 경로를 넘긴다.

---

## Bounded Autonomy (자율 적응 규칙)

### Must Follow (절대 준수)
- `<script setup>` 필수
- NuxtUI 컴포넌트 우선, AI Slop 금지
- 필수 패턴: `listAction`, `resetAction`, `listMovePage`, watch 패턴
- `@submit.prevent="listAction"`, `@change="listAction"` 패턴
- 모듈 경계: `_common`만 import
- Mock 데이터는 `mock/` 디렉토리에 분리
- useApi() 경유 패턴 유지 (프로덕션 전환 대비)

### May Adapt (분석 후 보완)
- 테이블 컬럼 구성 (도메인 필드에 맞춤)
- 검색 폼 구성 (필드 수에 따른 레이아웃)
- 모달/페이지 폼 구성 (입력 필드 그룹핑)
- Mock 데이터 구성 (도메인 특수 샘플)
- UI 상호작용 흐름 (도메인 특수 UX)

### May Suggest (제안 후 사용자 확인)
- 컴포넌트 분리 (예: 복잡한 폼을 step별 컴포넌트로)
- 페이지 구성 변경 (예: 탭 내 리스트, 상세 페이지 분리)
- UI 패턴 변경 제안 (예: crud → page가 더 적합)

Suggest 시: 이유를 사용자에게 제시하고 확인 후 적용. Must Follow 침범 금지.

### Adapt 조건
보완 시 반드시: (1) 이유 설명 (2) Must Follow 미침범 (3) vue-tsc + lint + build 통과

---

## 완료 조건

- UI 패턴 선택 완료
- Mock 데이터, Store, 페이지/모달 컴포넌트 생성 완료
- `vue-tsc`, `lint`, `build` 통과
- 팀 모드는 `proto-ui-qa` APPROVED 또는 사용자 승인된 CONDITIONAL 필요

빌드 성공 없이 완료 선언 금지.

---

## 완료 후 안내

생성/수정 파일, `vue-tsc/lint/build` 결과, 브라우저 확인 경로, 프로덕션 전환 시 Mock 제거 범위를 보고한다.

---

## 조건부 참조 가이드 (토큰 절약)

> **중요**: 선택된 패턴의 참조 파일만 읽으세요!
> 모든 references를 한 번에 로드하지 마세요.

### 필수 참조 (반드시 읽기 - 생략 금지!)

> **경고**: 아래 파일은 **어떤 패턴을 선택하든 반드시 먼저 읽어야 합니다!**
> 이 파일을 읽지 않으면 검색, 페이징, URL 상태관리 패턴이 누락됩니다.

- **[common-patterns.md](references/core/common-patterns.md)** - URL Watch 패턴, Selectbox, Router 동기화, Date 검색, 모달 오픈 패턴
- **[mock-service-pattern.md](references/core/mock-service-pattern.md)** - Mock 데이터 정의, 동적 생성, API 시그니처 유지
- **[mock-store-pattern.md](references/core/mock-store-pattern.md)** - Mock useApi() 경유 Store 패턴

### 패턴별 참조 매핑

| 선택 패턴 | 읽어야 할 파일 |
|----------|---------------|
| **crud** | basic/page-pattern.md + basic/modal-pattern.md |
| **page** | basic/page-pattern.md |
| **two-depth** | basic/two-depth-pattern.md |
| **infinite-scroll** | basic/infinite-scroll-pattern.md |
| **select-list** | basic/select-list-pattern.md |
| **batch-process** | basic/batch-process-pattern.md |
| **adv-search** | advanced/adv-search-pattern.md |
| **calendar** | advanced/calendar-pattern.md |
| **kanban** | advanced/kanban-pattern.md |
| **mega-form** | advanced/mega-form-pattern.md |
| **tab-list** | advanced/tab-list-pattern.md |

### 옵션별 추가 참조

| 옵션 | 읽어야 할 파일 |
|------|---------------|
| excel=Y | options/excel-pattern.md |
| file=Y | options/file-upload-pattern.md |
| validator 필요 | options/validator-pattern.md |

### 조건부 참조

| 상황 | 읽어야 할 파일 |
|------|---------------|
| 로딩 상태 필요 | core/loading-state-pattern.md |
| 에러 처리 필요 | core/error-handling-pattern.md |

---

## 참조

- **가이드 코드 (우선)**: `src/modules/test-data/` 또는 기존 `src/modules-task/{년월}/{태스크폴더}/`
- **Mock 데이터**: `src/modules-task/{년월}/{태스크폴더}/{서브모듈}/mock/`
- **Store**: `src/modules-task/{년월}/{태스크폴더}/{서브모듈}/store/`

> test-data 가이드 코드를 기준 골격으로 참조하되, Mock 특화 + 도메인 특성에 맞게 Bounded Autonomy 범위 내에서 적응
