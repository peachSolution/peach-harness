# peach-harness-plugin

PeachSolution 하네스 시스템 — 스킬, 서브에이전트, QA 파이프라인을 통합한 Claude Code 플러그인입니다.

## 문서

- **[AGENTS.md](AGENTS.md)** - 아키텍처 가이드 (공통 원칙, 백엔드/프론트엔드 패턴)
- **[CLAUDE.md](CLAUDE.md)** - Claude Code 진입점

## 설치

```bash
# Plugin 설치 (권장)
/plugin install peach-harness-plugin

# skills.sh 설치 (호환)
npx skills add peachSolution/peach-harness-plugin --skill '*' -a claude-code

# 특정 스킬만 설치
npx skills add peachSolution/peach-harness-plugin --skill peach-agent-team -a claude-code
```

## 구조

```
peach-harness-plugin/
├── .claude-plugin/plugin.json
├── skills/                        # 스킬 (실행 절차 정의)
│   ├── peach-agent-team/          # 신규 기능 팀 조율
│   ├── peach-agent-team-refactor/ # 리팩토링 팀 조율
│   ├── peach-gen-backend/         # Backend 생성
│   ├── peach-gen-store/           # Store 생성
│   ├── peach-gen-ui/              # UI 생성
│   └── ...                        # 기타 생성/추가 스킬
└── agents/                        # 서브에이전트 (역할 실행자)
    ├── backend-dev.md             # Backend 개발
    ├── backend-qa.md              # Backend QA
    ├── store-dev.md               # Store 개발
    ├── ui-dev.md                  # UI 개발
    ├── frontend-qa.md             # Frontend QA
    ├── refactor-backend.md        # Backend 리팩토링
    └── refactor-frontend.md       # Frontend 리팩토링
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
- `peach-gen-feature-docs` — 기능 문서
- `peach-gen-prd` — PRD 문서
- `peach-gen-store` — Frontend Store
- `peach-gen-ui` — Frontend UI

### 추가 계열

- `peach-add-api` — 외부 API 호출 코드
- `peach-add-cron` — Cron 작업
- `peach-add-print` — 인쇄 페이지

### 리팩토링 계열

- `peach-refactor-backend` — Backend 리팩토링
- `peach-refactor-frontend` — Frontend 리팩토링

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

## Ralph Loop

QA 실패 시 구조화된 피드백 주입 패턴 (Vercel Labs):

| 횟수 | 단계 | 행동 |
|------|------|------|
| 1~3 | 자율 수정 | QA 피드백 반영 |
| 4~7 | 가이드 재참조 | test-data 기준골격 재읽기 |
| 8~10 | 최소 수정 | Must Follow만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

## 마이그레이션

| 기존 (peach-skills) | 현재 (peach-harness-plugin) |
|---------------------|---------------------------|
| skills/ only | skills/ + agents/ |
| 에이전트 역할 → SKILL.md 내부 흡수 | 에이전트 → agents/ 별도 파일 |
| Failure → 단순 재시도 | Failure → Ralph Loop |

## 팀 스킬 정책

- `peach-agent-team`: mode 파라미터로 backend/ui/fullstack 분기
- `peach-agent-team-refactor`: layer 파라미터로 backend/frontend/all 분기
- 서브에이전트는 `agents/` 디렉토리에 독립 파일로 정의
- QA 에이전트는 읽기전용 + worktree 격리로 확증 편향 방지
