---
name: peach-team-dev
model: opus
description: |
  PeachSolution 신규 모듈 개발을 조율하는 통합 팀 스킬.
  준비된 DB 스키마와 Spec, ui-proto 기반 표준 모드 + Spec만 모드 + 자연어 prompt 모드를 지원.
  "팀으로 만들어줘", "풀스택 개발", "팀 개발", "백엔드+UI 전체 생성",
  "버그 수정해줘", "이 화면에 X 추가해줘", "API와 화면 같이 만들어줘",
  "백엔드만 만들어줘", "API만 만들어줘", "UI만 추가" 키워드로 트리거.
  mode=backend(API+Store) | ui(UI만) | fullstack(전체) 지원하며,
  mode/proto 없이 자연어 입력만으로도 즉흥적 버그 수정·기능 추가 가능.
  대규모 작업은 기능 큐와 Contract Gate로 1차 완성도를 높이는 방향을 따른다.
  peach-team-e2e와 함께 하나의 개발-검증 납품 흐름을 이루되, E2E 검증 독립성은 유지한다.
  Claude Code 팀 기능이 있으면 team mode로, Codex/skills.sh 일반 환경에서는 generic mode로 실행한다.
  기존 팀 개발 스킬의 개발 조율 역할을 대체하며, DB 생성은 peach-gen-db 선행 단계로 분리한다.
---

# Peach Team Dev

PeachSolution 개발을 조율하는 통합 오케스트레이터.

## Overview

신규 기능 개발부터 즉흥적 버그 수정까지 한 스킬에서 처리한다. 기존 팀 개발 스킬의 조율 역할을 대체하면서 다음 기능을 추가했다.

- **검증 기준의 외부화** — ui-proto + Spec을 본 개발의 검증 기준으로 삼는다
- **proto 자동 복사** — ui-proto 저장소의 `_spec.md`를 본 프로젝트로 자동 이전
- **prompt 모드** — Spec/proto 없이 자연어 입력만으로도 즉흥적 작업 가능
- **1차 완성도 극대화** — 대규모 작업은 기능 큐, Contract Gate, 기능별 상태 기록으로 누락과 재작업을 줄인다
- **PRD-first 대응** — PRD는 참고 원천으로만 사용하고, 구현은 Spec/schema 기준으로 진행한다
- **런타임 어댑터** — Claude team mode와 Codex/skills.sh generic mode를 모두 지원한다

DB 마이그레이션 생성/적용은 이 스킬의 책임이 아니다. `mode=backend|fullstack`은 `peach-gen-db`로 생성된 `api/db/schema/...`가 준비된 뒤 실행한다.

## 개발-검증 납품 흐름

`peach-team-dev`와 `peach-team-e2e`는 사용자 입장에서는 하나의 납품 흐름이다. `team-dev`가 구현과 코드 수준 검증을 끝낸 뒤, `team-e2e`가 실제 사용자 흐름과 기획 부합을 검증한다.

```text
peach-team-dev
  → 구현
  → TDD
  → lint/build
  → API-Store Contract Gate
  → TEST_ID 구현 상태 갱신
  → E2E 잔여 리스크 정리

peach-team-e2e
  → 사용자 흐름 검증
  → ui-proto/Spec 부합 검증
  → 미스매치 분류
  → 명확한 코드 문제는 team-dev로 위임
```

두 스킬은 흐름으로 연결하지만 역할과 컨텍스트는 분리한다. `team-dev`는 E2E 판정을 자체 책임으로 끌고 오지 않고, `team-e2e`는 본 프로젝트 코드 수정을 직접 수행하지 않는다.

## TDD/E2E 역할 분리 (필수 인지)

team-dev는 **본 개발 + TDD까지** 책임지고, **사용자 경험 검증(E2E)은 `peach-team-e2e`로 위임**한다. 두 팀의 경계를 명확히 한다.

| 영역 | 담당 | 검증 대상 |
|------|------|---------|
| **TDD** (team-dev 책임) | backend-qa / frontend-qa | API 동작, 타입 체크, 빌드, lint, Spec 기반 코드 수준 검증 |
| **E2E** (team-e2e 책임) | e2e-suite-qa | UI 흐름, ui-proto 부합, 비즈니스 규칙의 외부 가시 결과 |

운영 규칙:

- team-dev는 **TDD 통과 + lint + build 통과**를 완료 기준으로 삼는다. UI 흐름 검증을 자체 보완 루프로 끌고 가지 않는다.
- prompt 모드(자연어 즉흥 작업)에서도 동일하다. 사용자 흐름 검증이 필요한 변경이면 완료 후 `peach-team-e2e` 호출을 안내한다.
- E2E 단계에서 발견되는 **로직 버그**는 team-e2e가 직접 수정하지 않고 team-dev로 다시 넘어온다. 반대로 team-dev는 **시나리오 검증/UI 흐름 부합**을 자체 책임으로 떠안지 않는다.
- 완료 보고에는 `peach-team-e2e`로 넘길 잔여 리스크, Contract Gate 결과, TEST_ID 구현 상태를 남긴다.

## 입력 모드 3가지

| 모드 | 입력 | 검증 기준 | 적합 케이스 |
|------|------|---------|-----------|
| **표준** | mode + proto 경로 | ui-proto 화면 + Spec | 신규 기능 (재구성 핵심 경로) |
| **Spec만** | mode (proto 생략) | `docs/spec/...` Spec | 백엔드 중심, 기존 화면 수정, 단순 CRUD |
| **prompt** | 자연어 입력 | prompt 텍스트 | 버그 수정, 즉흥적 변경, 핫픽스 |

prompt 모드는 검증 기준이 약하므로 **결과를 직접 확인해야 한다**. 변경 규모가 크면 Spec 작성을 자동 권고한다.

Spec만 모드는 UI Proto가 없어도 진행할 수 있지만 화면 검증 기준이 약하다. 신규 화면이 많거나 다단계 폼/상태 전이/권한 분기가 복잡하면 `peach-team-ui-proto` 생성을 먼저 권고한다.

## PRD-first 개발 기준

PRD가 함께 주입된 경우에도 구현 기준은 `Spec + api/db/schema/...`다. PRD는 누락 확인용 원천 자료로만 사용한다.

| 상황 | 처리 |
|------|------|
| PRD와 Spec/schema가 일치 | Spec/schema 기준으로 구현 |
| PRD에는 있으나 Spec에 없음 | `PRD_TO_SPEC_REQUIRED`로 기록하고 해당 기능 blocked |
| PRD와 schema가 충돌 | `DB_DECISION_REQUIRED` 또는 `DB_CHANGE_REQUIRED`로 분리 |
| PRD 해석만으로 구현 가능해 보임 | 직접 구현하지 않고 Spec 보강 권고 |

대규모 PRD-first 신규 개발은 `mode=backend`를 먼저 실행해 API/Store Contract를 안정화한 뒤 UI 또는 E2E로 진행하는 것을 권장한다.

## Modes

| mode | 용도 | 포함 역할 |
| --- | --- | --- |
| `backend` | 준비된 DB 스키마 기준 API + Store 연결 | backend-dev, backend-qa, store-dev, frontend-qa |
| `ui` | Store 기반 UI만 구현 | ui-dev, frontend-qa |
| `fullstack` | 준비된 DB 스키마 기준 API + Store + UI 생성 | backend-dev, backend-qa, store-dev, ui-dev, frontend-qa |

## 대규모 작업 1차 완성도 원칙

대규모 작업의 목표는 한 번에 무조건 100% 완료가 아니라, 첫 실행에서 TDD/타입/빌드/주요 연결/핵심 흐름이 대부분 통과하는 상태까지 끌어올리는 것이다.

운영 규칙:

- 여러 Spec이나 여러 기능을 한 팀에 그대로 넣지 않고 **기능 큐**로 나눈다.
- 기능별 입력(Spec `TEST_ID`, schema, proto 화면, mode)을 명시한다.
- 기능별 상태를 `pending / running / qa_failed / blocked / done`으로 기록한다.
- 실패한 기능만 재시도하고, 기준이 모호한 기능은 `blocked`로 분리한다.
- Backend, Store, UI 연결은 `API-Store Contract Gate`로 team-dev 단계에서 먼저 잡는다.
- 기능 큐 상태는 team-dev 내부 운영 상태다. Spec의 `TEST_ID별 상태` 표에는 구현 상태 축만 `I01/I02/I03/I90`으로 갱신하고, UI Proto 상태(`Uxx`)와 E2E 검증 상태(`Vxx`)는 변경하지 않는다.
- `TEST_ID별 상태` 표의 구현 상태를 갱신하면 `상태 요약`의 전체 Spec 상태, 전체 구현 상태, 구현 완료 수, Blocked 수, 마지막 확인일, 잔여 리스크도 함께 재계산한다.

권장 상태 파일:

```text
docs/qa/{년}/{월}/[작업명]-team-dev-status.md
```

상태 파일 필드:

| 필드 | 설명 |
|------|------|
| feature_id | 기능 큐 ID |
| mode | backend/ui/fullstack |
| input | Spec, schema, proto 기준 |
| status | pending/running/qa_failed/blocked/done |
| failed_reason | 실패 원인 |
| retry_count | Ralph Loop 또는 재시도 횟수 |
| evidence | TDD/lint/build/Contract Gate 결과 |

Spec `TEST_ID별 상태` 갱신 규칙:

| team-dev 내부 상태 | Spec 구현 상태 | 기준 |
|--------------------|----------------|------|
| pending | I01 구현전(TODO) | 아직 구현 시작 전 |
| running | I02 일부구현(PARTIAL) | 구현 진행 중이거나 일부 레이어만 완료 |
| qa_failed | I02 일부구현(PARTIAL) | 코드가 있으나 TDD/lint/build/Contract Gate 실패 |
| blocked | I90 차단(BLOCKED) | Spec/schema/권한/DB 변경 결정이 필요해 구현 불가 |
| done | I03 구현완료(DONE) | 코드 구현과 team-dev 책임 검증(TDD/lint/build/Contract Gate)이 통과 |

`I03 구현완료(DONE)`은 E2E 최종 검증 완료를 의미하지 않는다. E2E 통과 여부는 `peach-team-e2e`가 검증 상태 축(`Vxx`)으로 남긴다.

## Preconditions

### 표준 모드 (proto 인자 사용)

- ui-proto 저장소의 태스크 폴더가 존재하고 `_spec.md`를 포함해야 한다.
- 본 프로젝트는 `docs/spec/{년}/{월}/` 폴더 구조를 가져야 한다 (없으면 자동 생성).
- DB 스키마가 필요한 모드(`backend`, `fullstack`)에서는 `api/db/schema/[도메인]/[테이블].sql`이 존재해야 한다. 없으면 먼저 `peach-gen-db`를 실행한다.

### Spec만 모드

- DB 스키마가 필요한 모드(`backend`, `fullstack`)에서는 `api/db/schema/[도메인]/[테이블].sql`이 존재해야 한다.
- `ui` 모드에서는 `front/src/modules/[모듈명]/store/[모듈명].store.ts`가 존재해야 한다.
- Store가 없으면 먼저 `peach-gen-store`, UI가 없으면 `peach-gen-ui`를 기준으로 생성한다.
- 기존 기능 수정 맥락에서 실행하는 경우 `docs/기능별설명/{카테고리명}/{기능명}/`가 있으면 개요 → 로직 → 명세 → TDD 순으로 먼저 읽고 컨텍스트를 주입한다.
- Spec의 `화면 흐름 요약`이 있으면 UI 흐름의 최소 기준으로 사용한다.
- Spec에 화면 흐름 요약이 없고 신규 복잡 화면이면 `peach-team-ui-proto` 또는 Spec 보강을 권고하고, 강행 시 완료 보고에 검증 한계를 남긴다.

### prompt 모드

- 사전 조건 없음. 자연어 입력만 있으면 동작.
- 단, 변경 규모 추정 후 대규모로 판단되면 Spec 작성 권고가 자동으로 뜬다.

## Inputs

```bash
# 표준 모드 (Spec + DB 스키마 + ui-proto 기반)
/peach-team-dev [모듈명] mode=backend|ui|fullstack proto=<경로> [옵션]

# 대규모 작업 기능 큐 모드
/peach-team-dev [작업명] queue=<기능큐.md> [proto=<경로>] [옵션]

# Spec만 모드 (proto 생략)
/peach-team-dev [모듈명] mode=backend|ui|fullstack [옵션]

# prompt 모드 (mode/proto 생략, 자연어 입력)
/peach-team-dev "버그/개선 사항 자연어 설명" [force=Y] [옵션]

# 공통 옵션
# model=sonnet|opus|haiku  (서브에이전트 모델 override, 기본값: sonnet)
# figma=[URL]
# ui=crud|page|two-depth|infinite-scroll|select-list
# file=Y
# excel=Y
# storeTdd=Y
```

| 인자 | 역할 |
|------|------|
| `[모듈명]` | 표준/Spec만 모드에서 권장. prompt 모드에서는 AI가 후보 제안 후 사용자 확정 |
| `mode` | 표준/Spec만 모드에서 필수 |
| `queue` | 선택. 대규모 작업용 기능 큐 문서. 지정 시 기능별 mode/input/status를 기준으로 반복 실행 |
| `proto` | 선택. ui-proto 저장소의 태스크 폴더 절대 경로 |
| `prompt` | 위치 인자. 자연어 작업 설명 (mode/proto 없을 때) |
| `force` | 선택. prompt 모드에서 큰 변경에도 Spec 권고 무시하고 강제 진행 (`force=Y`) |
| `model` | 선택. 서브에이전트 모델 override |

## proto 인자 자동 처리

`proto=<경로>`가 주어지면 다음 절차를 자동 실행한다. 상세는 `references/proto-sync.md` 참조.

1. **proto 경로 검증** — 폴더 존재, `_spec.md` 존재
2. **메타 추출** — `_task-meta.ts`에서 `planner`, `date`, `title` 읽기
3. **Spec 자동 복사** — `_spec.md` → `docs/spec/{년}/{월}/{planner}-{YYMMDD}-{title}.md`
4. **DB 기준 확인** — `mode=backend|fullstack`이면 `api/db/schema/...` 존재 확인
5. **충돌 감지** — 본 프로젝트에 같은 파일이 이미 있으면 사용자에게 (a) 덮어쓰기 / (b) 유지 / (c) diff 보기 선택
6. **컨텍스트 주입** — 복사된 Spec과 ui-proto 화면 폴더를 구현 참고/검증 기준으로 서브에이전트 프롬프트에 주입

## prompt 모드 동작

mode/proto 없이 자연어 입력이 주어지면 다음 절차로 동작한다. 상세는 `references/prompt-mode.md` 참조.

1. **입력 분석**
   - 작업 규모 추정 (단일 파일 vs 다중 파일, 신규 vs 수정)
   - 영향 범위 추정 (백엔드/UI/풀스택)
   - 모듈 후보 식별 (파일 경로, 도메인 키워드 기반)
   - 기존 기능 수정이면 `peach-doc-feature` 권고 여부 판단

2. **모듈명 확정 (사용자 확인)**
   - prompt 분석 결과로 모듈 후보 1~3개를 제안한다
   - 사용자가 선택 또는 직접 입력
   - 단일 후보가 명확하면 자동 채택 안내 후 진행

3. **분기**
   - **소규모** (단일 파일, 명확한 패턴): 즉시 단독 모드 실행
   - **중규모** (여러 파일, 단일 모듈): 팀 모드 실행, Spec 자동 생성 제안 (선택)
   - **대규모** (모듈 추가, 다중 모듈): Spec 권고 안내 → 사용자가 (a) `/peach-gen-spec` 작성 후 재진입 / (b) `force=Y`로 강제 진행 선택

4. **실행**
   - prompt를 임시 컨텍스트로 주입
   - 단독/팀 모드에 따라 서브에이전트 분배
   - 랄프루프 5회 (prompt 모드는 검증 기준이 약하므로 10회 비권장)

## 구현 기준 우선순위 규칙

ui-proto는 본질적으로 Mock이라 100% 구현되지 않을 수 있다. team-dev는 다음 기준으로 구현/TDD 범위를 잡고, 실제 브라우저 흐름 부합 검증은 `peach-team-e2e`로 넘긴다.

| 항목 | team-dev 기준 | 최종 검증 |
|----------|---------|---------|
| 화면 레이아웃, 컴포넌트 배치 | ui-proto 화면을 구현 참고 자료로 사용 | `peach-team-e2e` |
| 사용자 인터랙션 흐름 | ui-proto/Spec을 기준으로 코드 구조와 이벤트를 구현 | `peach-team-e2e` |
| 비즈니스 규칙 (검증, 권한, 분기) | Spec 기준으로 API/Store/UI 코드와 TDD 작성 | TDD + `peach-team-e2e` |
| 데이터 정확성 (API 응답값) | Spec 기준으로 타입/API/TDD 검증 | TDD |
| 에러/예외 처리 | Spec 기준으로 코드와 테스트 작성 | TDD + 필요 시 E2E |

**핵심 원칙**: team-dev는 구현과 코드 수준 검증까지 책임진다. 화면 흐름이 실제 사용자 관점에서 기획 의도와 맞는지는 team-e2e가 판정한다.

## API-Store Contract Gate

`mode=backend|fullstack` 완료 전에는 다음 항목을 반드시 확인한다. 이 게이트는 E2E에서 늦게 발견되는 런타임 연결 오류를 줄이기 위한 1차 완성도 게이트다.
상세 보고 형식과 실패 처리는 `references/contract-gate.md`를 따른다.

| 항목 | 확인 내용 | 실패 시 |
|------|-----------|---------|
| Backend 타입 | `api/src/modules/[모듈]/type/`의 응답 타입과 controller 반환 구조 일치 | backend-dev 재수정 |
| Store 타입 | `front/src/modules/[모듈]/type/`, store state/action 타입 일치 | store-dev 재수정 |
| 응답 키 | API 응답 키와 Store 변환/컴포넌트 사용 필드 일치 | store-dev 또는 ui-dev 재수정 |
| 페이지네이션 | `list/totalRow/page/limit` 등 프로젝트 규약 일치 | backend-dev/store-dev 재수정 |
| 에러 응답 | validator/service 에러와 UI 처리 방식 일치 | backend-dev/ui-dev 재수정 |
| 옵션 기능 | file/excel/external API가 Backend→Store→UI까지 연결됨 | 해당 레이어 재수정 |
| DB 변경 필요 | 구현에 필요한 컬럼/인덱스/상태값이 schema에 존재함 | `DB_CHANGE_REQUIRED` 작성 후 blocked |

완료 보고에는 Contract Gate 결과를 `통과/실패/스킵`으로 남긴다. 스킵은 UI 없는 backend-only처럼 사유가 명확할 때만 허용한다.

### PRD_TO_SPEC_REQUIRED 처리

PRD에는 있으나 Spec에 정제되지 않은 요구를 발견하면 구현하지 않고 해당 기능을 `blocked`로 분리한다.

```markdown
## PRD_TO_SPEC_REQUIRED

| 항목 | 내용 |
|------|------|
| PRD 위치 | [문서 경로/섹션] |
| 누락 요구 | [PRD에 있으나 Spec에 없는 내용] |
| 필요한 정제 | TEST_ID/권한/상태/오류/화면 흐름/DB 후보 |
| 영향 레이어 | Backend/Store/UI/E2E |
| 권장 후속 | peach-gen-spec 보강 후 재개 |
```

`PRD_TO_SPEC_REQUIRED`는 Ralph Loop 대상이 아니다. 기준 보강 후 blocked 기능만 재개한다.

### DB_CHANGE_REQUIRED 처리

개발 중 DB 변경이 필요해지면 team-dev가 직접 마이그레이션을 만들지 않는다. 해당 기능 상태를 `blocked`로 바꾸고 다음 형식으로 상태 파일과 완료 보고에 남긴다.

```markdown
## DB_CHANGE_REQUIRED

| 항목 | 내용 |
|------|------|
| 요청 유형 | 컬럼 추가/컬럼 수정/인덱스 추가/상태값 추가 |
| 대상 테이블 | [테이블명] |
| 대상 컬럼 | [컬럼명 또는 신규 컬럼명] |
| 필요한 이유 | [구현 중 막힌 이유] |
| 관련 TEST_ID | [T-001] |
| 영향 레이어 | Backend/Store/UI/E2E |
| 권장 후속 | peach-gen-db 또는 peach-db-migrate 실행 |
```

DB 변경 반영 후 갱신된 `api/db/schema/...`를 기준으로 blocked 기능만 재개한다.

## Orchestration

### Reference 선택

| 상황 | 읽을 reference |
|------|----------------|
| Claude/Codex 실행 모드 선택 | `references/runtime-adapter.md` |
| proto 인자 처리 | `references/proto-sync.md` |
| prompt 모드 | `references/prompt-mode.md` |
| fullstack 병렬 개발 | `references/fullstack-workflow.md` |
| Mock Store → 실제 Store 연결 | `references/connect-workflow.md` |
| Figma 입력 | `references/figma-workflow.md` |
| API-Store-UI 연결 검증 | `references/contract-gate.md` |
| 역할별 dev/qa 지시 | `references/*-agent.md` |
| QA 판정/완료 보고 | `references/qa-policy.md` |

### 0. 입력 검증

#### 런타임 모드 선택

먼저 `references/runtime-adapter.md`를 읽고 실행 모드를 정한다.

| 조건 | 모드 |
|------|------|
| Claude Code 팀 도구 사용 가능 | Claude team mode |
| Codex 또는 일반 skills.sh 환경 | generic mode |
| Claude Code지만 팀 기능 비활성 | team mode 활성화 안내 후 generic mode 가능 여부 확인 |

Claude team mode에서는 `TeamCreate`, `TaskCreate`, `SendMessage`를 사용한다. generic mode에서는 해당 도구를 전제로 하지 않고, 오케스트레이터가 역할 큐를 순차 또는 제한 병렬로 수행한다.

#### 입력 모드 분기

다음 순서로 입력 형태를 판별한다.

```
1. queue 인자 있음 → 대규모 작업 기능 큐 모드
   → 기능별 mode/input/status를 읽고 순차 또는 제한 병렬 처리
2. 위치 인자가 자연어 문장이고 mode/proto 없음 → prompt 모드 진입
   → references/prompt-mode.md 절차 수행
3. mode 지정 + proto 인자 있음 → 표준 모드
   → references/proto-sync.md로 Spec 복사 후 진행
4. mode 지정 + proto 없음 → Spec만 모드
   → docs/spec/... 의 기존 Spec 사용
5. 모두 누락 → 사용자에게 모드 선택 안내
```

**mode 미지정 시 (Spec만 모드 진입 시도):**
```
mode를 선택해주세요:
1. backend — 기존 UI에 API + Store 연결
2. ui — Store 기반 UI만 구현
3. fullstack — 준비된 DB 스키마 기준 전체 생성
```

**모듈명 미지정 시:**
- 표준/Spec만 모드: 직접 입력 요청
- prompt 모드: 위 "prompt 모드 동작 §2"에 따라 후보 제안 후 확정

**model 옵션:**
- 미지정: 기본값 sonnet으로 모든 서브에이전트 실행
- 지정 시: 모든 서브에이전트를 해당 모델로 override
- 허용 값: sonnet, opus, haiku

### 1. 환경 확인

```bash
# 스키마 / 타입 / 가이드 코드 확인
ls api/db/schema/
head -5 api/src/modules/test-data/dao/test-data.dao.ts
head -3 api/src/modules/test-data/controller/test-data.controller.ts
ls front/src/modules/test-data/

# DAO 라이브러리 감지
# from 'bunqldb' → 재할당 방식
# from 'sql-template-strings' → append 방식

# modules 분리 구조 감지
ls -d api/src/modules*/
ls -d front/src/modules*/

# _common 구성 감지
ls api/src/modules/_common/
ls api/src/modules/_common/constants/ 2>/dev/null

# 스킬 references 경로 감지
BACKEND_REFS=$(find ~/.claude ~/.agents -path "*/peach-gen-backend/references" -type d 2>/dev/null | head -1)
STORE_REFS=$(find ~/.claude ~/.agents -path "*/peach-gen-store/references" -type d 2>/dev/null | head -1)
UI_REFS=$(find ~/.claude ~/.agents -path "*/peach-gen-ui/references" -type d 2>/dev/null | head -1)
```

### 1.2. Pre-flight 확인

대규모 작업 또는 `queue=` 모드에서는 개발 전에 다음을 확인한다.

| 항목 | 확인 내용 |
|------|----------|
| Spec 완성도 | 권한, 상태 전이, 오류, 외부 의존성, `TEST_ID` 존재 |
| UI Proto 매핑 | 화면 목록, 주요 액션, 완료/오류 상태와 Spec `TEST_ID` 연결 |
| DB 정합성 | schema 파일, 상태 필드, 인덱스, 필수 컬럼 존재 |
| PRD 정합성 | PRD 원천 요구가 Spec `TEST_ID`로 반영됐는지, PRD-only 요구가 있는지 |
| 공통 자원 | `_common/constants`, `_common/components` 신규 추가/수정 필요 여부 |
| 모듈 경계 | 기존 모듈과 네이밍, 경로, 책임 충돌 여부 |
| Spec-only 한계 | UI Proto 없음, 화면 흐름 요약 존재 여부, E2E 신뢰도 제한 |

Pre-flight 결과:

- 명확한 항목 → 기능 큐에 넣고 진행
- 기준이 모호한 항목 → `blocked`로 기록하고 사용자 확인
- PRD-only 요구 → `PRD_TO_SPEC_REQUIRED`로 기록하고 해당 기능은 `blocked` 처리
- DB/schema가 없는 항목 → `peach-gen-db` 선행 필요로 기록
- DB 컬럼/인덱스/상태값 부족 항목 → `DB_CHANGE_REQUIRED`로 기록하고 해당 기능은 `blocked` 처리

### 1.5. 도메인 분석 (Analyze)

오케스트레이터가 대상 도메인의 스키마(또는 prompt 입력)를 읽고, test-data 대비 차이점을 파악한 뒤 서브에이전트 프롬프트에 컨텍스트로 주입한다.

```bash
# 표준/Spec만 모드: 대상 스키마 읽기
cat api/db/schema/[도메인]/[테이블].sql

# 표준 모드 추가: ui-proto 화면 폴더 분석
ls <proto경로>/
cat <proto경로>/_spec.md
```

**분석 항목**:
1. 스키마 비교: test-data 대비 필드 수, 타입 복잡도, 관계성
2. 비즈니스 로직 판단: 단순 CRUD vs 상태 전이/계산 필드/조건부 검증
3. 적응 결정: Must Follow → 그대로 / May Adapt → 도메인 맞춤 항목 식별
4. (표준 모드) ui-proto 화면 구조와 Spec의 비즈니스 규칙을 구현 항목으로 매핑

**분석 결과를 서브에이전트에게 전달**:
- 각 에이전트 생성 시 프롬프트에 "이 도메인의 특성: [분석 결과]"를 포함
- 모듈 생성 경로: `api/src/[감지된 modules 경로]/[모듈명]/`
- front 대응 경로: `front/src/[감지된 modules 경로]/[모듈명]/`
- _common 상수 목록: `[감지된 상수 파일 목록]` (존재 시 하드코딩 금지 지시)
- file 옵션 추론: 스키마에 파일 관련 요구가 보이면 `file=Y` 제안
- (표준 모드) 구현 기준 컨텍스트: ui-proto 화면 + Spec 기반 코드 수준 검증 지시
- references 경로 (역할별 분리 주입):
  - backend-dev: `${BACKEND_REFS}`
  - store-dev: `${STORE_REFS}`
  - ui-dev: `${UI_REFS}`

5. **구조 제안 (May Suggest)**:
   도메인 분석 결과 가이드코드(test-data)와 다른 구조가 더 적합하다고 판단되면:
   - 제안 내용과 이유를 사용자에게 먼저 제시
   - 사용자 확인 후 서브에이전트 프롬프트에 반영

   **제안 가능 범위:**
   - service 파일 분리 (예: 상태전이 전용 service)
   - DAO 구성 변경 (예: 복합 조회용 DAO 분리)
   - 트랜잭션 서비스 필요 여부
   - 모듈 내부 하위 디렉토리 (예: step1/step2 단계별 분리)

   **제안 불가 (Must Follow):**
   - 모듈 경계, 네이밍, 타입 원칙 등

### 2. 팀 구성 다이어그램

**mode=backend**
```
backend-dev ──→ backend-qa
       │
       └──→ store-dev ──→ frontend-qa
```

**mode=ui**
```
ui-dev ──→ frontend-qa
```

**mode=fullstack**
```
backend-dev ──→ backend-qa
       │
       └──→ store-dev ──→ ui-dev ──→ frontend-qa
```

**prompt 모드 (소규모, 단독)**
```
단일 dev-agent (영향 범위에 따라 backend-dev / ui-dev / store-dev 중 1개)
       │
       └──→ 해당 qa-agent (랄프루프 5회)
```

### 3. 팀 생성 및 작업 등록

Claude team mode에서는 다음처럼 팀을 생성한다. generic mode에서는 같은 순서를 역할 큐로 실행한다.

```
TeamCreate: team_name="[모듈명]-[mode]-team"

# mode=backend 작업 등록
TaskCreate:
1. "Backend API 개발" (owner: backend-dev)
2. "Backend QA 검증" (blockedBy: Task1, owner: backend-qa)
3. "Frontend Store 개발" (blockedBy: Task1, owner: store-dev)
4. "Frontend QA 검증" (blockedBy: Task3, owner: frontend-qa)

# mode=ui 작업 등록
TaskCreate:
1. "UI 컴포넌트 생성" (owner: ui-dev)
2. "Frontend QA 검증" (blockedBy: Task1, owner: frontend-qa)

# mode=fullstack 작업 등록
TaskCreate:
1. "Backend API 개발" (owner: backend-dev)
2. "Backend QA 검증" (blockedBy: Task1, owner: backend-qa)
3. "Frontend Store 개발" (blockedBy: Task1, owner: store-dev)
4. "Frontend UI 개발" (blockedBy: Task3, owner: ui-dev)
5. "Frontend QA 검증" (blockedBy: Task4, owner: frontend-qa)
```

prompt 모드 소규모는 팀 생성 생략하고 단일 에이전트에 직접 작업 위임. 중/대규모는 표준 모드와 동일한 팀 구성.

### 4. 역할별 지시

각 역할의 전체 정의(페르소나, Bounded Autonomy, 워크플로우)는 `references/`에 있다.
서브에이전트 생성 시 해당 파일의 전체 내용을 프롬프트에 포함한다.
`model=` 옵션이 지정된 경우, 각 에이전트 호출 시 model 파라미터로 전달하여 frontmatter 기본값을 override한다.

| 역할 | 참조 파일 | 핵심 패턴 |
|------|----------|----------|
| backend-dev | references/backend-dev-agent.md | test-data 가이드 코드 |
| backend-qa | references/backend-qa-agent.md | 검증 전용 (읽기전용, worktree) |
| store-dev | references/store-dev-agent.md | test-data 가이드 코드 |
| ui-dev | references/ui-dev-agent.md | test-data 가이드 코드 + 디자인 시스템 |
| frontend-qa | references/frontend-qa-agent.md | 검증 전용 (읽기전용, worktree) |

> 위 페르소나 정의는 **gen-* 스킬과 동일한 가이드 코드 패턴**을 가리킨다.
> 진짜 SoT는 대상 프로젝트의 `test-data/` 폴더이며, gen-* 스킬과 team-dev는
> 같은 패턴을 두 가지 호출 방식(단독/팀 컨텍스트)으로 사용한다.

각 역할의 세부 체크리스트, Bounded Autonomy, 완료 보고 형식은 해당 `references/*-agent.md`를 따른다.

- backend-dev: API 코드 생성, TDD/lint/build까지 수행
- backend-qa: Backend 구조, TDD, lint, build, Spec 기반 엔드포인트 검증
- store-dev: Backend 타입 기반 Pinia Store 생성 및 `vue-tsc` 검증
- ui-dev: Store 기반 UI 생성, DESIGN.md/Figma/proto 반영, `vue-tsc/lint/build` 검증
- frontend-qa: Store/UI 구조, 타입, lint, build, AI Slop, proto/Spec 구현 반영 여부 검증

## QA 판정과 완료

QA 에이전트는 **APPROVED / CONDITIONAL / REJECTED** 3단계로 판정한다. `APPROVED` 후에는 `/peach-qa-gate`를 실행하고, `REJECTED`는 Ralph Loop로 dev 에이전트 수정 후 재검증한다.

상세 판정 규칙, prompt 모드 반복 상한, 완료 보고 필드는 `references/qa-policy.md`를 따른다.

## Examples

```bash
# === 표준 모드 (proto 사용) ===

# 풀스택 일괄
/peach-team-dev product-manage mode=fullstack proto=<PROTO_REPO>/src/modules-task/2604/260427-<initial>-goods

# 백엔드 먼저
/peach-team-dev product-manage mode=backend

# UI 이어서 (proto 화면 기반)
/peach-team-dev product-manage mode=ui proto=<PROTO_REPO>/.../260427-<initial>-goods

# === Spec만 모드 (기존 패턴) ===

# 기존 UI에 API + Store 연결
/peach-team-dev notice-board mode=backend

# UI만 구현
/peach-team-dev member-list mode=ui ui=two-depth figma=https://figma.com/file/xxx

# 전체 풀스택 생성 (DB 스키마 준비 후)
/peach-gen-db product-manage
/peach-team-dev product-manage mode=fullstack ui=page file=Y

# opus 모델로 서브에이전트 실행
/peach-team-dev product-manage mode=fullstack model=opus ui=page

# === prompt 모드 (자연어 입력) ===

# 즉흥적 버그 수정
/peach-team-dev "list.vue 검색 후 페이지네이션 클릭 시 검색어 초기화되는 문제 수정"

# 작은 기능 추가
/peach-team-dev "게시판 상세 화면에 인쇄 버튼 추가하고 인쇄 페이지도 만들어줘"

# 큰 변경 강제 진행 (Spec 권고 무시)
/peach-team-dev "주문 모듈에 환불 기능 전체 추가" force=Y
```

## 관련 스킬

- `peach-gen-spec` — Spec 단독 생성 (Tier 2)
- `peach-team-ui-proto` — 기획 검토용 ui-proto 팀 생성/검증 (선행 단계)
- `peach-gen-db` — DB 스키마/마이그레이션 생성 (team-dev 선행 단계)
- `peach-gen-backend`, `peach-gen-store`, `peach-gen-ui` — 단계별 단독 호출 (Tier 2)
- `peach-team-e2e` — E2E 검증 (다음 단계)
- `peach-team-3a` — 작은 단일 기능 (Architect→Builder→Reviewer 3-에이전트)
- `peach-doc-feature` — 기존 기능 As-Is 분석 (수정 작업 전)
