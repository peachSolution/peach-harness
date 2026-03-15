# AI 에이전트 가이드

> PeachSolution 아키텍처 기반 프로젝트용 공개 에이전트 가이드
> Backend(api/) + Frontend(front/) 모노레포 구조

---

## 1. 공통 원칙

### 기본 규칙
- 응답 언어: **한국어**
- Code-First: 문서보다 가이드 코드 참조
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.service.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |

### 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지

### 가이드 코드 위치
코드 생성 = **가이드 코드 참조** → 도메인 분석 → Bounded Autonomy 범위 내 적응
- Backend: `api/src/modules/test-data/`
- Frontend: `front/src/modules/test-data/`

> **대상 프로젝트 기술 스택 규칙** (백엔드/프론트엔드/테스트/Validator)은
> `peach-setup-harness/references/` 를 Source of Truth로 관리한다.
> - `backend-rules.md` — 백엔드 규칙 (api/)
> - `frontend-rules.md` — 프론트엔드 규칙 (front/)
> - `testing-rules.md` — 테스트 및 품질
> - `validator-rules.md` — Validator/타입 규칙

---

## 2. 스킬 개발 규칙

### SKILL.md frontmatter 필수 필드
```yaml
---
name: peach-[스킬명]
description: |
  한 줄 설명 (트리거 키워드 포함)
---
```

### 스킬 네이밍 규칙
- 접두어: `peach-` 필수
- 형식: `peach-[동사]-[대상]` (예: `peach-gen-backend`, `peach-add-api`)
- 팀 스킬: `peach-agent-[대상]` (예: `peach-agent-team`, `peach-agent-team-refactor`)

### skills.sh 호환 설치
```bash
npx skills add peachSolution/peach-harness --skill [스킬명] -a claude-code
```

### references 정책
- 스킬 내부 `references/` 폴더: 스킬별 상세 가이드
- 조건부 참조: 필요한 참조만 로드 (토큰 절약)
- 외부 프로젝트 파일 직접 참조 금지 (설치 후 대상 프로젝트 경로 안내로 대체)

### 버전 관리 규칙

#### 버전 파일
두 파일의 version을 **항상 동일하게** 유지한다. 불일치 시 auto update가 실패한다.

- `.claude-plugin/marketplace.json` → `plugins[0].version`
- `.claude-plugin/plugin.json` → `version`

#### Semver 기준

| 변경 유형 | 버전 | 예시 |
|----------|------|------|
| **patch** (x.x.+1) | 문서 수정, 오타, 버그 수정 | SKILL.md 오류 수정, 참조 경로 수정 |
| **minor** (x.+1.0) | 스킬/에이전트 추가, 기존 기능 개선 | 새 스킬 추가, 에이전트 로직 변경 |
| **major** (+1.0.0) | 하위호환 파괴, 구조 변경 | 배포 구조 변경, 스킬 인터페이스 변경 |

#### 버전 업데이트 시점
- **커밋 단위가 아닌 릴리스 단위**로 버전을 올린다
- **develop 브랜치에서** 버전을 업데이트한다 (main은 머지만)

#### 버전 업데이트 절차
1. develop에서 작업 완료
2. develop에서 두 파일의 version을 동시에 업데이트
3. 커밋 메시지: `Release v{버전}` (예: `Release v1.1.0`)
4. main에 머지 (`git merge develop --no-ff`) 후 push

---

## 3. AI 자율성 허용 범위 (Bounded Autonomy)

AI는 가이드 코드(test-data)를 기준으로 삼되, 아래 규칙에 따라 제한된 자율성을 가진다.

### 3-1. Must Follow (절대 준수)

아래 영역은 AI가 변경하면 안 된다.

- 모듈 경계 규칙 (`_common`만 import, 타 모듈 import 금지)
- 네이밍 규칙 (snake_case/kebab-case/PascalCase/camelCase)
- 타입 원칙 (옵셔널 금지, null/undefined 금지)
- 보안 규칙 (SQL injection, XSS, OWASP top 10 방지)
- 공통 에러 처리 원칙 (기능오류 → 200+success:false, 시스템예외 → ErrorHandler)
- 테스트 통과 기준 (bun test / vitest)
- lint/build 통과 기준
- QA 재검증 요구

### 3-2. May Adapt (분석 후 보완 가능)

아래 영역은 AI가 분석 후 보완할 수 있다.

- service 메서드 분리 방식
- DAO 내부 쿼리 구성의 세부 형태
- validator 구조의 세부 배치
- UI 상호작용 흐름
- 문서 보완 방식
- 코드 가독성 및 성능 개선

### 3-3. Adapt 조건

AI가 가이드 코드와 다르게 생성하려면 다음 4가지를 모두 만족해야 한다.

1. 왜 다른 구조가 필요한지 설명할 수 있어야 한다
2. Must Follow를 침범하면 안 된다
3. 결과가 test/lint/build/QA를 통과해야 한다
4. 차이점과 이유를 세션 기록에 남겨야 한다

---

## 4. 스킬 목록

| 스킬 | 용도 | 팀 역할 |
|------|------|---------|
| `peach-help` | 하네스 시스템 안내 (스킬 추천, 워크플로우 안내) | - |
| `peach-gen-spec` | Spec 문서 생성 (대화형 요구사항 수집) | - |
| `peach-gen-db` | DB DDL/마이그레이션 생성 | - |
| `peach-gen-backend` | Backend API 생성 (bun test 필수) | backend-dev |
| `peach-gen-store` | Frontend Store 생성 (vue-tsc 필수) | store-dev |
| `peach-gen-ui` | Frontend UI 생성 (vue-tsc/lint/build 필수) | ui-dev |
| `peach-gen-ui-proto` | UI 프로토타입 생성 (Mock 데이터 기반, 기획자용) | ui-dev |
| `peach-gen-design` | 디자인 시스템 컨설팅 | ui-dev |
| `peach-gen-feature-docs` | 기존 기능 개선 전 as-is 분석 문서 생성 | - |
| `peach-add-api` | 외부 REST API 호출 코드 생성 | - |
| `peach-add-cron` | Cron 작업 코드 생성 | - |
| `peach-add-print` | 인쇄 전용 페이지 생성 | - |
| `peach-refactor-backend` | Backend 리팩토링 | refactor-backend |
| `peach-refactor-frontend` | Frontend 리팩토링 | refactor-frontend |
| `peach-agent-team` | 신규 기능 팀 조율 (mode=backend/ui/fullstack) | 오케스트레이터 |
| `peach-agent-team-refactor` | 리팩토링 팀 조율 (layer=backend/frontend/all) | 오케스트레이터 |
| `peach-qa-gate` | 작업 완료 전 증거 수집 게이트 (팀 스킬 완료 시 자동 후속 호출) | - |
| `peach-handoff` | 세션 간 컨텍스트 인수인계 | - |
| `peach-setup-harness` | 대상 프로젝트에 하네스 시스템 설정 (CLAUDE.md/AGENTS.md) | - |

### 스킬 유형 분류

| 유형 | 스킬 | 테스트 전략 |
|------|------|-----------|
| 능력 향상형 (4) | gen-design, gen-spec, gen-feature-docs, peach-help | 새 모델 시 A/B 테스트 |
| 선호도 인코딩형 (12) | gen-backend, gen-db, gen-store, gen-ui, gen-ui-proto, add-api, add-cron, add-print, refactor-backend, refactor-frontend, agent-team, agent-team-refactor | Eval 충실도 검증 |
| 프로세스 게이트 (3) | qa-gate, handoff, setup-harness | 워크플로우 품질 게이트 |

### 에이전트 팀원 역할

| 에이전트 | 역할 | 담당 스킬 |
|---------|------|---------|
| backend-dev | Backend API 개발 | peach-gen-backend |
| backend-qa | Backend QA 검증 | 검증 전용 |
| store-dev | Frontend Store 개발 | peach-gen-store |
| ui-dev | Frontend UI + 디자인 (FigmaRemote MCP) | peach-gen-ui + peach-gen-ui-proto + peach-gen-design |
| frontend-qa | Frontend QA 검증 | 검증 전용 |
| refactor-backend | Backend 리팩토링 | peach-refactor-backend |
| refactor-frontend | Frontend 리팩토링 | peach-refactor-frontend |

### PR 코드리뷰 워크플로우

PeachSolution 규칙 검증은 QA 에이전트 + qa-gate가 담당합니다.
PR 생성 전 범용 코드리뷰가 필요하면 built-in 스킬을 사용합니다:
- `/requesting-code-review` — PR diff 기반 코드리뷰 요청
- `/receiving-code-review` — 리뷰 피드백 처리

---

## 5. 완전 독립 도메인 구현

**"관리되는 독립성(Governed Independence)"** - 결합은 부채, 중복은 비용. 부채를 피하기 위해 통제 가능한 비용을 선택.

### 완전 독립성 체크리스트
- 다른 도메인의 DAO를 직접 호출하지 않음
- 필요한 모든 쿼리가 자체 DAO에 구현됨
- 다른 도메인의 서비스를 직접 호출하지 않음
- 다른 도메인의 타입을 import하지 않음

---

## 6. 서브에이전트 활용

### 스킬과 서브에이전트의 역할 분리

- **스킬** (SKILL.md): 오케스트레이터. 실행 절차를 정의하고 팀을 조율한다.
- **서브에이전트** (agents/*.md): 역할 실행자. 독립 컨텍스트에서 특정 작업을 수행한다.

### 서브에이전트 목록

| 에이전트 | 파일 | 역할 |
|---------|------|------|
| backend-dev | agents/backend-dev.md | Backend API 생성 |
| backend-qa | agents/backend-qa.md | Backend QA 검증 (읽기전용) |
| store-dev | agents/store-dev.md | Frontend Store 생성 |
| ui-dev | agents/ui-dev.md | Frontend UI 생성 |
| frontend-qa | agents/frontend-qa.md | Frontend QA 검증 (읽기전용) |
| refactor-backend | agents/refactor-backend.md | Backend 리팩토링 |
| refactor-frontend | agents/refactor-frontend.md | Frontend 리팩토링 |

### QA 에이전트 격리 원칙

- QA 에이전트(backend-qa, frontend-qa)는 **읽기전용**으로 실행한다.
- `isolation: worktree` 옵션으로 독립 작업 트리에서 검증한다.
- 구현 에이전트와 컨텍스트를 공유하지 않아 확증 편향을 방지한다.

### 에이전트 모델 정책

- 팀 스킬(peach-agent-team, peach-agent-team-refactor)은 `model: opus` 권장
- 서브에이전트는 기본 `model: sonnet`으로 실행

| 옵션 | 동작 |
|------|------|
| (미지정) | frontmatter 기본값 사용 (sonnet) |
| model=opus | 모든 서브에이전트를 opus로 실행 |
| model=haiku | 모든 서브에이전트를 haiku로 실행 |

### 자기완결적 스킬 원칙

팀 스킬은 `agents/` 디렉토리 없이도 완전하게 동작해야 한다. (멀티 AI 도구 지원)

- **`agents/*.md`**: Source of truth. Claude Code 네이티브 서브에이전트가 직접 참조한다.
- **`skills/*/references/*-agent.md`**: 팀 스킬 자기완결성을 위한 복사본. `agents/`를 인식하지 못하는 AI 도구에서 사용된다.
- **에이전트 정의 변경 시**: `agents/*.md`와 해당 `references/*-agent.md` 양쪽을 모두 업데이트한다.

| 파일 | 역할 | 사용 주체 |
|------|------|----------|
| `agents/backend-dev.md` | Source of truth | Claude Code, Codex CLI |
| `skills/peach-agent-team/references/backend-dev-agent.md` | 복사본 | Cursor, Copilot 등 |

---

## 7. Ralph Loop 규칙

### 정의

Ralph Loop(Vercel Labs)은 Agent → Verifier → Feedback Injection → Safety Limit 구조의 반복 검증 패턴이다.
단순 retry와 달리 구조화된 피드백을 주입하여 같은 실수를 반복하지 않는다.

### 에스컬레이션 단계

| 반복 횟수 | 단계 | 행동 |
|----------|------|------|
| 1~3회 | 자율 수정 | QA 피드백만으로 수정 |
| 4~7회 | 가이드 재참조 | test-data 기준골격 전체 재읽기 |
| 8~10회 | 최소 수정 | Must Follow만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

### 적용 원칙

- 모든 팀 스킬(peach-agent-team, peach-agent-team-refactor)에서 QA 실패 시 Ralph Loop를 적용한다.
- 에스컬레이션 도달 시 handoff 파일에 Ralph Loop 이력을 기록한다.
