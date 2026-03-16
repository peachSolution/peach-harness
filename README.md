# peach-harness

PeachSolution 하네스 시스템 — 멀티 AI 도구를 지원하는 스킬 패키지입니다.

스킬, 서브에이전트, QA 파이프라인을 통합하며, [SKILL.md 오픈 스탠다드](https://skills.sh)를 기반으로 14+ AI 코딩 도구에서 동작합니다.

## 지원 AI 도구

| 도구 | 지원 방식 |
|------|----------|
| **Claude Code** | skills.sh + 네이티브 플러그인 (agents/, hooks/ 포함) |
| **OpenAI Codex CLI** | skills.sh + AGENTS.md 자동 인식 |
| **Cursor** | skills.sh + SKILL.md 네이티브 지원 |
| **Google Antigravity** | skills.sh 호환 |
| **GitHub Copilot** | skills.sh 호환 |
| **Gemini CLI, Roo Code, Windsurf 등** | skills.sh 호환 |

## 설치

### skills.sh (권고 — 14+ AI 도구 지원)

> **권고**: `-g` (global) 옵션을 사용하면 모든 프로젝트에서 스킬을 공유할 수 있습니다.
> `-g` 없이 실행하면 현재 디렉터리 기준의 project 스코프에만 설치됩니다.

```bash
# 글로벌 설치 (권고 — 모든 프로젝트에서 공유)
npx skills add peachSolution/peach-harness --skill '*' -a claude-code -g

# 여러 AI 도구에 동시 글로벌 설치
npx skills add peachSolution/peach-harness --skill '*' \
  -a claude-code \
  -a codex \
  -a cursor \
  -a gemini-cli \
  -a antigravity \
  -g

# 모든 AI 도구에 일괄 글로벌 설치
npx skills add peachSolution/peach-harness --skill '*' --all -g

# 특정 스킬만 글로벌 설치
npx skills add peachSolution/peach-harness --skill peach-agent-team -a claude-code -g

# 프로젝트 스코프 설치 (현재 디렉터리에만 적용)
npx skills add peachSolution/peach-harness --skill '*' -a claude-code
```

**지원 에이전트 ID**

| AI 도구 | 에이전트 ID | 비고 |
|--------|-----------|------|
| Claude Code | `claude-code` | |
| OpenAI Codex CLI | `codex` | |
| Cursor / Cursor CLI (cursor-agent) | `cursor` | IDE Agent + background agent 공유 |
| Gemini CLI | `gemini-cli` | |
| Google Antigravity | `antigravity` | |
| GitHub Copilot | `github-copilot` | |
| Windsurf | `windsurf` | |
| Roo Code | `roo` | |
| Continue | `continue` | |

> **Cursor 참고**: `cursor-agent`는 Cursor CLI의 내부 명령어명입니다. skills CLI 에이전트 ID는 `cursor` 하나로 통합되며, Cursor IDE Agent와 Cursor CLI background agent가 동일한 스킬 디렉토리(`.cursor/skills/`)를 공유합니다.

### 업데이트

```bash
# 업데이트 확인
npx skills check -g

# 재설치로 업데이트 (권장 — 글로벌)
npx skills add peachSolution/peach-harness --skill '*' -a claude-code -g -y

# 여러 AI 도구 동시 업데이트 (글로벌)
npx skills add peachSolution/peach-harness --skill '*' \
  -a claude-code \
  -a codex \
  -a cursor \
  -a gemini-cli \
  -a antigravity \
  -g -y
```

> **`npx skills update` 비권장**: 새로 추가된 스킬이 설치되지 않는 버그가 있습니다.
> `npx skills add ... -g -y` 재설치를 사용하세요.

### Claude Code 플러그인 (호환 — Claude Code 전용 기능 포함)

```bash
# 1. 마켓플레이스 등록
/plugin marketplace add peachSolution/peach-harness

# 2. 플러그인 설치
/plugin install peach-harness-plugin
```

## 문서

- **[docs/03-워크플로우.md](docs/03-워크플로우.md)** - 작업 유형별 스킬 선택 플로우 (시작점)
- **[docs/02-SDD-가이드.md](docs/02-SDD-가이드.md)** - SDD 개념, 3가지 시나리오, TDD 전략
- **[docs/01-아키텍처.md](docs/01-아키텍처.md)** - 4계층 구조, Bounded Autonomy, Ralph Loop
- **[docs/04-배포구조.md](docs/04-배포구조.md)** - 배포 구조 (멀티 AI 도구 지원 근거)
- **[AGENTS.md](AGENTS.md)** - 아키텍처 가이드 (공통 원칙, 백엔드/프론트엔드 패턴)
- **[CLAUDE.md](CLAUDE.md)** - Claude Code 진입점

## 구조

```
peach-harness/
├── .claude-plugin/
│   ├── marketplace.json             # 마켓플레이스 정의 (source: "./")
│   └── plugin.json                  # 플러그인 정의
├── skills/                          # 스킬 (실행 절차 정의, 모든 AI 도구 공통)
│   ├── peach-agent-team/            # 신규 기능 팀 조율
│   │   └── references/              # 에이전트 정의 복사본 (자기완결성)
│   ├── peach-agent-team-refactor/   # 리팩토링 팀 조율
│   │   └── references/              # 에이전트 정의 복사본 (자기완결성)
│   ├── peach-qa-gate/                # QA 검증 게이트 (팀 스킬 완료 시 자동 후속 호출 가능)
│   ├── peach-gen-backend/           # Backend 생성
│   ├── peach-gen-store/             # Store 생성
│   ├── peach-gen-ui/                # UI 생성
│   └── ...                          # 기타 생성/추가 스킬
├── agents/                          # 서브에이전트 (Claude Code 전용, Source of truth)
│   ├── backend-dev.md               # Backend 개발
│   ├── backend-qa.md                # Backend QA
│   ├── store-dev.md                 # Store 개발
│   ├── ui-dev.md                    # UI 개발
│   ├── frontend-qa.md               # Frontend QA
│   ├── refactor-backend.md          # Backend 리팩토링
│   └── refactor-frontend.md         # Frontend 리팩토링
├── hooks/                           # Git hooks
│   └── pre-commit-gate.sh           # 품질 게이트 (테스트/린트/빌드)
└── templates/                       # 템플릿
```

## 스킬 목록

### 팀 조율 (오케스트레이터)

| 스킬 | 용도 | 파라미터 |
|------|------|---------|
| `peach-agent-team` | 신규 기능 개발 | mode=backend/ui/fullstack |
| `peach-agent-team-refactor` | 리팩토링 | layer=backend/frontend/all |

### 생성 계열

- `peach-gen-backend` — Backend API 생성
- `peach-gen-db` — DB DDL/마이그레이션
- `peach-gen-design` — 디자인 시스템 컨설팅
- `peach-gen-feature-docs` — 기존 기능 개선 전 as-is 분석 문서
- `peach-gen-spec` — Spec 문서
- `peach-gen-store` — Frontend Store
- `peach-gen-ui` — Frontend UI
- `peach-gen-ui-proto` — UI 프로토타입 (Mock 기반)

### 추가 계열

- `peach-add-api` — 외부 API 호출 코드
- `peach-add-cron` — Cron 작업
- `peach-add-print` — 인쇄 페이지

### 리팩토링 계열

- `peach-refactor-backend` — Backend 리팩토링
- `peach-refactor-frontend` — Frontend 리팩토링

### 프로세스 게이트

- `peach-qa-gate` — 작업 완료 전 QA 검증 게이트 (팀 스킬 완료 시 자동 후속 호출 가능)
- `peach-help` — 하네스 시스템 안내 (스킬 추천, 워크플로우 질문 응답)
- `peach-setup-harness` — 대상 프로젝트에 하네스 시스템 설정 (모노레포/api/front)
- `peach-setup-ui-proto` — Frontend-Only UI Proto 프로젝트 하네스 설정

## 서브에이전트

스킬(오케스트레이터)이 서브에이전트(역할 실행자)를 조율합니다.

| 에이전트 | 역할 | QA 격리 |
|---------|------|---------|
| backend-dev | Backend API 생성 | - |
| backend-qa | Backend 검증 (읽기전용) | worktree |
| store-dev | Store 생성 | - |
| ui-dev | UI 생성 | - |
| frontend-qa | Frontend 검증 (읽기전용) | worktree |
| refactor-backend | Backend 리팩토링 | - |
| refactor-frontend | Frontend 리팩토링 | - |

> `agents/` 디렉토리는 Claude Code 네이티브 서브에이전트의 **Source of truth**입니다.
> 팀 스킬의 `references/*-agent.md`는 다른 AI 도구의 자기완결성을 위한 복사본입니다.

## 설계 원칙

### SKILL.md 오픈 스탠다드

SKILL.md는 Anthropic이 공개한 에이전트 스킬 사양으로, 파일시스템 기반 표준입니다.
마크다운을 읽을 수 있는 에이전트라면 코드 변경 없이 동작합니다.

### 자기완결적 스킬

팀 스킬(`peach-agent-team`, `peach-agent-team-refactor`)은 `references/` 디렉토리에 에이전트 정의 복사본을 포함합니다.
`agents/` 디렉토리가 없는 AI 도구에서도 팀 스킬이 완전하게 동작합니다.

### agents/ 호환

`agents/` 디렉토리는 Claude Code 네이티브 서브에이전트 시스템과 Codex CLI(AGENTS.md 자동 인식)가 직접 참조합니다.
`isolation: worktree` 등 Claude Code 전용 기능은 이 파일에서만 동작합니다.

## Ralph Loop

QA 실패 시 구조화된 피드백 주입 패턴 (Vercel Labs):

| 횟수 | 단계 | 행동 |
|------|------|------|
| 1~3 | 자율 수정 | QA 피드백 반영 |
| 4~7 | 가이드 재참조 | test-data 기준골격 재읽기 |
| 8~10 | 최소 수정 | Must Follow만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

## Hooks

품질 게이트를 자동화하는 Git hooks입니다.

```bash
# 설치
cp hooks/pre-commit-gate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

- **pre-commit-gate.sh**: Backend(bun test, lint, build) + Frontend(vue-tsc, lint, build) 검증
- `api/` 또는 `front/` 디렉토리가 없으면 해당 단계 스킵
