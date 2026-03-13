# peach-harness-plugin

PeachSolution 하네스 시스템 플러그인입니다.

## 아키텍처 가이드

→ **@AGENTS.md** 참조 (공통 원칙, 백엔드/프론트엔드 패턴, 스킬 규칙)

## 구조

```
peach-harness-plugin/
├── .claude-plugin/plugin.json   # 플러그인 매니페스트
├── skills/                      # 스킬 (오케스트레이터 + 생성)
├── agents/                      # 서브에이전트 (역할 실행자)
└── README.md
```

## 설치

```bash
# Plugin 설치 (권장)
/plugin install peach-harness-plugin

# skills.sh 설치 (호환)
npx skills add peachSolution/peach-harness-plugin --skill '*' -a claude-code
```
