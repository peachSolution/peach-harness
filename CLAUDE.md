# peach-harness

PeachSolution 하네스 시스템 플러그인입니다.

## 아키텍처 가이드

→ **@AGENTS.md** 참조 (공통 원칙, 스킬 규칙, 에이전트 구조)

## 배포 구조

**단일 플러그인 + 자체 마켓플레이스** 방식으로 배포한다. `.claude-plugin/` 안에 marketplace.json과 plugin.json이 공존한다.

→ **@docs/04-배포구조.md** 참조 (의사결정 근거, 설치/업데이트 방법)

```
peach-harness/
├── .claude-plugin/
│   ├── marketplace.json         # 마켓플레이스 정의 (source: "./")
│   └── plugin.json              # 플러그인 정의 (컴포넌트)
├── skills/                      # 스킬 (오케스트레이터 + 생성)
├── agents/                      # 서브에이전트 (역할 실행자)
└── README.md
```

## 설치

Claude Code에서는 플러그인 방식 설치를 기본 권장한다.
Cursor, Codex, Gemini 등 다른 AI에서도 함께 사용하려면 해당 AI에는 `skills.sh`로 별도 설치한다.
전체 AI를 `skills.sh`로 통일 설치해도 동작은 하지만, Claude Code에서는 기본 권장 방식이 아니다.

```bash
# Claude Code 플러그인 (권장)
# 1. 마켓플레이스 등록
/plugin marketplace add peachSolution/peach-harness

# 2. 플러그인 설치
/plugin install peach

# 다른 AI에서 함께 사용할 경우 예시
npx skills add peachSolution/peach-harness \
  -a codex \
  -a cursor \
  -a gemini-cli \
  -a antigravity \
  -g
```
