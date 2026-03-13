# 배포 구조

> 작성일: 2026-03-14
> 의사결정: 단일 플러그인 + 자체 마켓플레이스 방식

## 결정 사항

peach-harness-plugin은 **단일 플러그인**이며, `/plugin install`을 지원하기 위해 **자체 마켓플레이스를 겸한다.**

## 배경

Claude Code의 `/plugin install`은 등록된 마켓플레이스에서 플러그인을 검색하는 명령이다.
마켓플레이스 없이는 `/plugin install`로 설치할 수 없다.

따라서 하나의 저장소에 두 파일을 공존시킨다:

| 파일 | 역할 |
|------|------|
| `plugin.json` | 플러그인 정의 (스킬, 에이전트 등 컴포넌트) |
| `marketplace.json` | 검색/설치 경로 제공 (컴포넌트 정의 없음) |

**주의: marketplace.json에 skills 배열을 넣으면 plugin.json과 충돌한다.**
marketplace.json은 source 경로만 지정하고, 컴포넌트 정의는 plugin.json에 위임한다.

## 플러그인 vs 마켓플레이스 (개념 정리)

| 구분 | 플러그인(앱) | 마켓플레이스(앱스토어) |
|------|------------|-------------------|
| 저장소 구성 | 플러그인 1개 = 저장소 1개 | 플러그인 여러 개 = 저장소 1개 |
| 필요 파일 | `plugin.json` | `marketplace.json` + 각 플러그인의 `plugin.json` |
| 설치 방법 | 마켓플레이스 등록 필요 | `/plugin marketplace add owner/repo` → 안에서 선택 설치 |
| 자동 업데이트 | 지원됨 | 지원됨 |

### 마켓플레이스 확장 (향후)

여러 플러그인을 만들 경우, 별도 마켓플레이스 저장소를 만든다.

```
peach-marketplace/                    ← 별도 저장소
├── .claude-plugin/marketplace.json
└── plugins/
    ├── peach-harness-plugin/
    ├── peach-analytics-plugin/
    └── peach-deploy-plugin/
```

## 현재 배포 구조

```
peach-harness-plugin/
├── .claude-plugin/
│   ├── plugin.json              ← 컴포넌트 정의 (스킬, 에이전트 등)
│   └── marketplace.json         ← 검색/설치 경로 (컴포넌트 정의 없음)
├── skills/
├── agents/
├── hooks/
├── templates/
└── docs/
```

## 설치 방법

```bash
# 1. 마켓플레이스 등록
/plugin marketplace add peachSolution/peach-harness

# 2. 플러그인 설치
/plugin install peach-harness-plugin

# skills.sh 호환 설치
npx skills add peachSolution/peach-harness --skill '*' -a claude-code
```

## 업데이트

- GitHub에 push하면 설치한 사용자가 업데이트 가능
- `/plugin` → Installed 탭 → 해당 플러그인 선택 → Update
- "Enable auto update" 설정 시 Claude Code 실행마다 자동 최신화
