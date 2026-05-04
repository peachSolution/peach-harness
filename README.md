# peach-harness

PeachSolution 하네스 시스템 — 멀티 AI 도구를 지원하는 스킬 패키지입니다.

스킬, 서브에이전트, QA 파이프라인을 통합하며, [SKILL.md 오픈 스탠다드](https://skills.sh)를 기반으로 14+ AI 코딩 도구에서 동작합니다.

## 지원 AI 도구

| 도구 | 권장 설치 방식 |
|------|---------------|
| **Claude Code** | 네이티브 플러그인 권장, `skills.sh`는 대안 |
| **OpenAI Codex CLI** | `skills.sh` + AGENTS.md 자동 인식 |
| **Cursor** | `skills.sh` + SKILL.md 네이티브 지원 |
| **Google Antigravity** | `skills.sh` 호환 |
| **GitHub Copilot** | `skills.sh` 호환 |
| **Gemini CLI, Roo Code, Windsurf 등** | `skills.sh` 호환 |

## 설치

### 1. Claude Code 사용자

Claude Code에서는 플러그인 설치를 권장합니다.
`agents/`, `hooks/`를 포함한 Claude Code 전용 구성을 함께 사용할 수 있습니다.

```bash
# 1. 마켓플레이스 등록
/plugin marketplace add peachSolution/peach-harness

# 2. 플러그인 설치
/plugin install peach
```

### 2. Codex, Cursor, Gemini CLI 등 다른 AI 도구 사용자

`skills.sh`로 설치합니다. 설치와 업데이트는 같은 명령이며, `-y`는 기존 설치를 덮어씁니다.

#### macOS / Linux

```bash
npx skills add peachSolution/peach-harness \
  -a codex \
  -a cursor \
  -a gemini-cli \
  -a antigravity \
  -g -y
```

#### Windows PowerShell

```powershell
npx skills add peachSolution/peach-harness `
  -a codex `
  -a cursor `
  -a gemini-cli `
  -a antigravity `
  -g -y
```

> Windows는 PowerShell 기준으로 안내합니다.
> `-g` 없이 실행하면 현재 디렉터리에만 적용됩니다.

### 3. Claude Code까지 포함해 전체 AI를 skills.sh로 통일 설치하고 싶은 경우

Claude Code 플러그인 대신 `skills.sh` 하나로 통일할 수 있습니다.

#### macOS / Linux

```bash
npx skills add peachSolution/peach-harness \
  -a claude-code \
  -a codex \
  -a cursor \
  -a gemini-cli \
  -a antigravity \
  -g -y
```

#### Windows PowerShell

```powershell
npx skills add peachSolution/peach-harness `
  -a claude-code `
  -a codex `
  -a cursor `
  -a gemini-cli `
  -a antigravity `
  -g -y
```

### 지원 에이전트 ID

| AI 도구 | 에이전트 ID |
|--------|-----------|
| Claude Code | `claude-code` |
| OpenAI Codex CLI | `codex` |
| Cursor | `cursor` |
| Gemini CLI | `gemini-cli` |
| Google Antigravity | `antigravity` |
| GitHub Copilot | `github-copilot` |
| Windsurf | `windsurf` |
| Roo Code | `roo` |
| Continue | `continue` |

## 문서

- **[docs/01-하네스-방향과-전략.md](docs/01-하네스-방향과-전략.md)** - 하네스 상위 방향, 오래 자율 개발, 1차 완성도 전략
- **[docs/04-워크플로우.md](docs/04-워크플로우.md)** - 작업 유형별 스킬 선택 플로우 (시작점)
- **[docs/03-SDD-가이드.md](docs/03-SDD-가이드.md)** - SDD 개념, 3가지 시나리오, TDD 전략
- **[docs/02-아키텍처.md](docs/02-아키텍처.md)** - 4계층 구조, Bounded Autonomy, Ralph Loop
- **[docs/05-배포구조.md](docs/05-배포구조.md)** - 배포 구조 (멀티 AI 도구 지원 근거)
- **[AGENTS.md](AGENTS.md)** - 아키텍처 가이드 (공통 원칙, 백엔드/프론트엔드 패턴)
- **[CLAUDE.md](CLAUDE.md)** - Claude Code 진입점

## 구조

```
peach-harness/
├── .claude-plugin/
│   ├── marketplace.json             # 마켓플레이스 정의 (source: "./")
│   └── plugin.json                  # 플러그인 정의
├── .claude/
│   └── skills/                      # 로컬 전용 스킬 (배포 제외 — Claude Code 전용)
│       └── release/                 # 릴리스 자동화 (peach-harness 저장소 전용)
├── skills/                          # 스킬 (실행 절차 정의, 모든 AI 도구 공통)
│   ├── peach-intake/                # 요청 접수/규모/후속 스킬 경로 판정
│   ├── peach-team-dev/              # 신규 기능 풀스택 팀 (Spec/proto/prompt 모드)
│   │   └── references/              # 에이전트 정의 + 런타임 어댑터 (자기완결성)
│   ├── peach-team-e2e/              # E2E 검증 팀 (ui-proto + Spec 부합 검증)
│   │   └── references/              # 에이전트 정의 + 런타임 어댑터 (자기완결성)
│   ├── peach-team-3a/               # 3-에이전트 단일 기능 루프
│   ├── peach-team-analyze/          # 범용 분석 팀
│   ├── peach-qa-gate/                # QA 검증 게이트 (팀 스킬 완료 시 자동 후속 호출 가능)
│   ├── peach-review-ux/             # 선택적 UX 리뷰 (읽기전용)
│   ├── peach-gen-backend/           # Backend 생성 (Tier 2)
│   ├── peach-gen-store/             # Store 생성 (Tier 2)
│   ├── peach-gen-ui/                # UI 생성 (Tier 2)
│   └── ...                          # 기타 생성/추가/E2E 스킬
├── hooks/                           # Git hooks (PUBLIC 저장소 시크릿 차단)
│   ├── pre-commit-secrets.sh        # 사내 도메인/시크릿/사업자번호/개인경로 차단
│   ├── install.sh                   # .git/hooks/pre-commit 설치 (macOS/Linux)
│   ├── install.ps1                  # .git/hooks/pre-commit 설치 (Windows)
│   ├── claude-precommit-gate.sh     # Claude Code PreToolUse 훅 헬퍼 (3 OS 공용)
│   └── claude-precommit-gate.ps1    # Claude Code 훅 헬퍼 — 수동 호출용 (Windows)
└── templates/                       # 템플릿
```

## 스킬 목록

### 진입 판정 (Tier 0)

| 스킬 | 용도 | 파라미터 |
|------|------|---------|
| `peach-intake` | 요청/PRD를 분석해 Spec, DB, ui-proto, dev, e2e 필요 여부와 후속 경로 판정 | 자연어, prd=경로, spec=경로, proto=경로 |

### 팀 조율 (오케스트레이터, Tier 1)

| 스킬 | 용도 | 파라미터 |
|------|------|---------|
| `peach-team-ui-proto` | Mock 기반 UI Proto 생성·검증 | spec=경로, team=Y/N, file=Y, excel=Y |
| `peach-team-dev` | 신규 기능 풀스택 개발 (peach-team 흡수 통합) | mode=backend/ui/fullstack, proto=경로, prompt=자연어, force=Y |
| `peach-team-e2e` | E2E 검증 (ui-proto + Spec 부합 자동 검증) | proto=경로 |
| `peach-team-3a` | 단일 기능 설계·구현·검토 (3-에이전트 루프) | layer=backend/frontend/fullstack |
| `peach-team-analyze` | 범용 분석 팀 (동적 구성) | - |

> 2026-04-27 v1.18.0: `peach-team`은 `peach-team-dev`로 흡수 통합, 리팩토링 스킬 3개(`peach-team-refactor`, `peach-refactor-backend`, `peach-refactor-frontend`)는 폐기됨. 리팩토링은 AI Plan 모드 + Edit으로 처리한다.

### 생성 / 문서화 계열

- `peach-gen-backend` — Backend API 생성
- `peach-gen-db` — DB DDL/마이그레이션
- `peach-gen-diagram` — Unicode box-drawing/Mermaid/D2 기반 워크플로우·아키텍처·구조 다이어그램 생성
- `peach-gen-design` — 디자인 시스템 컨설팅
- `peach-doc-feature` — 기존 기능 개선 전 as-is 분석 문서
- `peach-gen-spec` — Spec 문서
- `peach-gen-store` — Frontend Store
- `peach-gen-ui` — Frontend UI
- `peach-gen-ui-proto` — `peach-team-ui-proto` 이전 이름 호환용 alias
- `peach-review-ux` — 화면/프로토타입 UX 법칙 기반 읽기전용 리뷰

### 추가 계열

- `peach-add-api` — 외부 API 호출 코드
- `peach-add-cron` — Cron 작업
- `peach-add-print` — 인쇄 페이지
- `peach-markitdown` — 문서파일을 md로 변환 (`MarkItDown` + `HWPX` 보완, YouTube/음성은 별도 스킬 또는 NotebookLM 사용)

### DB 도구

- `peach-db-migrate` — dbmate 마이그레이션 관리 (상태/실행/롤백/생성)
- `peach-db-extract-schema` — DB 현재 상태를 DDL 스키마 파일로 추출
- `peach-db-query` — 개발 DB에 SQL 직접 실행하여 데이터 조회
- `peach-erd` — Mermaid ERD 생성/수정/미리보기/PNG·SVG 저장

### E2E 도구

- `peach-e2e-setup` — E2E 테스트 환경 설정 (글로벌 도구, Chrome Beta 확인)
- `peach-e2e-browse` — agent-browser CLI로 Chrome Beta 제어, 페이지 탐색/검증
- `peach-e2e-scenario` — E2E 시나리오 생성/실행/자동수정 (auto/create/run)
- `peach-e2e-suite` — 통합 테스트 시나리오 md 생성/실행 (단위 시나리오 조합)

### 지식 관리

- `peach-wiki` — LLM Wiki 패턴 기반 누적형 지식베이스 구축·유지 (코드 프로젝트 + Obsidian 지원)

### 프로세스 게이트 / 설정

- `peach-qa-gate` — 작업 완료 전 QA 검증 게이트 (팀 스킬 완료 시 자동 후속 호출 가능)
- `peach-skill-feedback` — 스킬 사용 중 발견된 문제점/노하우를 구조화하여 문서화
- `peach-help` — 하네스 시스템 안내 (스킬 추천, 워크플로우 질문 응답)
- `peach-setup-project` — 신규 프로젝트 모듈 구조 + _common 기본 구성 세팅 (초기 1회)
- `peach-setup-harness` — 대상 프로젝트에 하네스 시스템 설정 (모노레포/api/front)
- `peach-setup-ui-proto` — Frontend-Only UI Proto 프로젝트 하네스 설정

### 내부 전용 스킬 (skills.sh 배포 제외)

`.claude/skills/`에 위치하며 `metadata.internal: true`로 skills.sh 배포에서 제외됩니다. Claude Code에서만 동작합니다.

| 스킬 | 용도 | 위치 |
|------|------|------|
| `release` | 릴리스 자동화 (버전 업 → PR → GitHub Release) | `.claude/skills/release/` |

> **배포 제외 메커니즘**: SKILL.md frontmatter에 `metadata.internal: true`를 설정하면 `npx skills add`에서 자동 제외됩니다.
> `--skill '*'`이나 `--skill release`로 명시적 지정하면 internal 스킬도 포함됩니다.

### 스킬 유형 분류

| 유형 | 스킬 |
|------|------|
| 능력 향상형 | gen-design, gen-diagram, gen-spec, doc-feature, peach-help, team-analyze, markitdown, peach-wiki, peach-review-ux |
| 선호도 인코딩형 | gen-backend, gen-db, gen-store, gen-ui, gen-ui-proto, add-api, add-cron, add-print, team-dev, team-3a |
| 프로세스 게이트 | qa-gate, skill-feedback, setup-harness, setup-project, setup-ui-proto |
| 진입 게이트 | peach-intake |
| DB 도구 | db-migrate, db-extract-schema, db-query, erd |
| E2E 도구 | team-e2e, e2e-setup, e2e-scenario, e2e-suite, e2e-browse |

## 서브에이전트

스킬(오케스트레이터)이 서브에이전트(역할 실행자)를 조율합니다.

| 에이전트 | 역할 | QA 격리 |
|---------|------|---------|
| backend-dev | Backend API 생성 | - |
| backend-qa | Backend 검증 (읽기전용) | worktree |
| store-dev | Store 생성 | - |
| ui-dev | UI 생성 | - |
| frontend-qa | Frontend 검증 (읽기전용) | worktree |
| proto-ui-dev | ui-proto 화면 생성 (Spec 기반) | - |
| proto-ui-qa | ui-proto 검증 (읽기전용) | worktree |
| e2e-scenario-dev | 단위 시나리오 자동 분할/작성 | - |
| e2e-scenario-qa | 단위 시나리오 검증 (읽기전용) | worktree |
| e2e-suite-dev | 통합 suite 생성 | - |
| e2e-suite-qa | 통합 suite 실행 + 부합 검증 (읽기전용) | worktree |

> 팀 스킬의 `skills/*/references/*-agent.md`가 에이전트 정의의 **Source of truth**입니다.
> `agents/` 디렉토리는 Claude Code 네이티브 서브에이전트 시스템용 복사본이며, references와 동기화해야 합니다.

## 설계 원칙

### SKILL.md 오픈 스탠다드

SKILL.md는 Anthropic이 공개한 에이전트 스킬 사양으로, 파일시스템 기반 표준입니다.
마크다운을 읽을 수 있는 에이전트라면 코드 변경 없이 동작합니다.

### 자기완결적 스킬

팀 스킬(`peach-team-dev`, `peach-team-e2e`, `peach-team-3a`, `peach-team-analyze`)은 `references/` 디렉토리에 에이전트 정의와 런타임 어댑터 정책을 포함합니다.
Claude Code 팀 도구가 있으면 team mode로 실행하고, Codex/일반 skills.sh 환경에서는 generic mode로 같은 역할 큐를 순차 또는 제한 병렬로 실행합니다.

### agents/ 호환

`agents/` 디렉토리는 필요한 경우 Claude Code 네이티브 서브에이전트 시스템용 복사본으로 둘 수 있습니다.
현재 Source of Truth는 팀 스킬의 `skills/*/references/*-agent.md`이며, `isolation: worktree` 같은 Claude 전용 기능은 런타임 어댑터 기준으로 적용합니다.

## Ralph Loop

QA 실패 시 구조화된 피드백 주입 패턴 (Vercel Labs):

| 횟수 | 단계 | 행동 |
|------|------|------|
| 1~3 | 자율 수정 | QA 피드백 반영 |
| 4~7 | 가이드 재참조 | test-data 기준골격 재읽기 |
| 8~10 | 최소 수정 | Must Follow만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

## peach-wiki 별도 설치 → harness 마이그레이션

`peach-wiki`가 harness에 통합되었습니다 (v1.17.0~). 별도로 설치했던 peach-wiki는 제거하세요.

### Claude Code 플러그인으로 설치했던 경우

```bash
/plugin remove peach-wiki
```

이후 `/plugin update` 또는 "Enable auto update" 설정으로 harness를 최신 버전으로 업데이트하면 `peach-wiki` 스킬이 포함됩니다.

### skills.sh로 설치했던 경우

```bash
# 글로벌 설치 제거
npx skills remove peach-wiki -g

# 프로젝트 스코프 설치 제거 (해당 프로젝트 디렉터리에서)
npx skills remove peach-wiki
```

이후 harness를 재설치하면 `peach-wiki` 스킬이 포함됩니다.

```bash
npx skills add peachSolution/peach-harness -a codex -a cursor -g -y
```

## Hooks (시크릿 차단 게이트)

peach-harness는 PUBLIC 저장소이므로 커밋 시점에 사내 정보 노출을 1차 방어한다.
**clone 후 한 번만 실행**하면 이후 `git commit`마다 자동 작동한다.

```bash
# 설치 (clone 직후 1회 실행)

# macOS / Linux
./hooks/install.sh

# Windows (PowerShell)
.\hooks\install.ps1
```

- **pre-commit-secrets.sh**: 사내 도메인 / 비밀번호·토큰 / 사업자번호 / 개인 절대경로를 staged diff에서 탐지·차단
- **install.sh / install.ps1**: `.git/hooks/pre-commit`에 심볼릭 링크 설치, 권한 부족 시 복사로 폴백 (Node 종속성 0)
- **자동 탐지 한계**: 한글 사내 어휘·짧은 영문 코드네임은 정규식으로 잡히지 않으므로 직접 diff 검토 필요
- **우회**: `git commit --no-verify` (지양). 오탐이면 스크립트의 화이트리스트 grep 패턴에 추가
- **Claude Code 사용 시**: `.claude/settings.json`의 PreToolUse hook이 `bash hooks/claude-precommit-gate.sh`를 호출한다. 헬퍼가 stdin JSON 페이로드(`tool_input.command`)를 jq로 파싱해 `git commit` 명령일 때만 게이트를 발동시키므로, install 미실행 환경에서도 Claude의 commit 시도를 차단한다. Windows에서도 Git for Windows의 bash·jq를 사용하므로 3 OS 공용 (Claude Code 한정)
