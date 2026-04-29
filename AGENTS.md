# AI 에이전트 가이드

> peach-harness 스킬 개발·유지보수를 위한 가이드
> 대상 프로젝트 규칙은 `peach-setup-harness/references/`가 Source of Truth

---

## 0. Code-First / qmd

- `qmd`가 설치되어 있으면 파일 열기 전에 `qmd search`로 위치를 먼저 찾는다.
- 컬렉션: `peach-harness`, URI 접두사: `qmd://peach-harness/`
- wiki 통합 검색: `qmd --index peach-harness query "키워드" -c peach-harness` (wiki + 소스 동시 검색)
- qmd 미설치 시: `docs/wiki/wiki-index.md` → 관련 페이지 직접 Read

## wiki / feature-docs 경계 규칙

→ **docs/08-wiki-feature-docs-경계규칙.md** 참조 (wiki entities vs feature-docs 작성 기준, AGENTS.md 소유권 분리)

## peach-wiki 스킬 문서

→ **docs/위키스킬/00-위키스킬-안내.md** 참조 (LLM Wiki 패턴 배경 이론, qmd 운영 가이드)

## qmd 인덱스 (필수)

이 프로젝트의 qmd 인덱스명: `peach-harness`
모든 qmd 명령에 `--index peach-harness`을 붙인다.
plain `qmd update/embed`는 다른 프로젝트 인덱스를 오염시킬 수 있으므로 금지.

```bash
# 검색
qmd --index peach-harness query "키워드" -c peach-harness

# 인덱스 갱신
qmd --index peach-harness update && qmd --index peach-harness embed
```

---

## 1. 스킬 개발 규칙

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
- 팀 스킬: `peach-team-[대상]` (예: `peach-team-dev`, `peach-team-e2e`, `peach-team-3a`)

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

핵심 스킬: team 계열(peach-team-*), gen 계열(peach-gen-*)

| 변경 유형 | 버전 | 예시 |
|----------|------|------|
| **patch** (x.x.+1) | 문서 수정, 오타, 버그 수정, 유틸 스킬 추가 | SKILL.md 오류 수정, 참조 경로 수정, 보조 스킬 1개 추가 |
| **minor** (x.+1.0) | 핵심 스킬 추가/개선, 에이전트 로직 변경 | 새 gen-* 스킬 추가, team 워크플로우 개선 |
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

## 2. 워크플로우 참조

스킬 수정 시 전체 흐름에서의 위치를 먼저 파악하라.
→ **docs/03-워크플로우.md** 참조 (표준 4단계 직선형)
→ **docs/05-스킬재구성-2026-04-27.md** 참조 (검증 기준 외부화, 통합 스킬 도입 의사결정)

## 2-1. 문서 다이어그램 작성 규칙

일반 구조·흐름도는 `peach-gen-diagram` 기준을 따른다.

---

## 3. AI 자율성 허용 범위 (Bounded Autonomy)

하네스 스킬 개발 시 AI의 자율성 범위를 정의한다.
대상 프로젝트의 Bounded Autonomy는 `peach-setup-harness/references/05-bounded-autonomy.md` 참조.

### 3-1. Must Follow (절대 준수)

- 스킬 네이밍 규칙 (`peach-` 접두어, kebab-case)
- SKILL.md frontmatter 필수 필드
- 버전 파일 동기화 (marketplace.json + plugin.json)
- references 정책 (조건부 참조, 외부 직접 참조 금지)
- 기존 스킬의 워크플로우 단계 순서 변경 금지

### 3-2. May Adapt (분석 후 자율 보완)

- SKILL.md 워크플로우 내 세부 단계 보완
- references 파일 구성 변경
- 에러 메시지, 안내 문구 개선

### 3-2b. May Suggest (제안 후 사용자 확인)

아래 영역은 AI가 더 좋은 구조를 제안할 수 있으나, **사용자 확인 후** 적용한다.

- 스킬 워크플로우 단계 추가/삭제
- 새로운 스킬 생성
- 서브에이전트 역할 변경
- Bounded Autonomy 규칙 변경

**Suggest 조건:**
1. 기존 구조 대비 구체적 이유를 설명할 수 있어야 한다
2. Must Follow를 침범하면 안 된다
3. 사용자 확인 없이 적용하면 안 된다

### 3-3. Adapt 조건

AI가 기존과 다르게 변경하려면 다음 4가지를 모두 만족해야 한다.

1. 왜 다른 구조가 필요한지 설명할 수 있어야 한다
2. Must Follow를 침범하면 안 된다
3. 기존 스킬의 동작에 영향이 없어야 한다
4. 차이점과 이유를 세션 기록에 남겨야 한다

---

## 4. 서브에이전트 활용

### 스킬과 서브에이전트의 역할 분리

- **스킬** (SKILL.md): 오케스트레이터. 실행 절차를 정의하고 팀을 조율한다.
- **서브에이전트** (`skills/*/references/*-agent.md`): 역할 실행자. 팀 스킬이 Agent 도구 프롬프트에 포함하여 독립 컨텍스트에서 실행한다.

### QA 에이전트 격리 원칙

- QA 에이전트(backend-qa, frontend-qa)는 **읽기전용**으로 실행한다.
- `isolation: worktree` 옵션으로 독립 작업 트리에서 검증한다.
- 구현 에이전트와 컨텍스트를 공유하지 않아 확증 편향을 방지한다.

### 에이전트 모델 정책

- 팀 스킬(peach-team-dev, peach-team-e2e, peach-team-3a, peach-team-analyze)은 `model: opus` 권장
- 서브에이전트는 기본 `model: sonnet`으로 실행
- 예외: peach-team-3a의 architect/reviewer는 `model: opus` (설계 판단·독립 판정 역할)

| 옵션 | 동작 |
|------|------|
| (미지정) | frontmatter 기본값 사용 (sonnet) |
| model=opus | 모든 서브에이전트를 opus로 실행 |
| model=haiku | 모든 서브에이전트를 haiku로 실행 |

### 에이전트 정의 위치

- 에이전트 정의: `skills/*/references/*-agent.md` (단일 Source of Truth)
- 변경 시 해당 파일만 업데이트. 확인: `ls skills/peach-team*/references/`

### 신규 통합 스킬 구조 (2026-04-27)

`peach-team-dev`, `peach-team-e2e`는 **진입점 + references/ 분리** 구조를 따른다.

```
skills/peach-team-dev/
├── SKILL.md              # 진입점 (개요, 인자, 호출 절차)
└── references/
    ├── backend-mode.md
    ├── ui-mode.md
    ├── fullstack-mode.md
    ├── proto-sync.md     # Spec 자동 복사 절차
    └── *-agent.md
```

이유: SKILL.md 비대화 방지, 조건부 참조로 토큰 절약, 기존 peach-team 패턴 일관성.

---

## 5. Ralph Loop 규칙

- Ralph Loop(Vercel Labs): 구조화된 피드백 주입으로 같은 실수를 반복하지 않는 반복 검증 패턴
- 모든 팀 스킬에서 QA 실패 시 적용. 에스컬레이션 단계는 각 팀 스킬 SKILL.md가 Source of Truth
- 에스컬레이션 도달 시 `docs/qa/` 검증 보고서에 Ralph Loop 이력을 기록한다
- **랄프루프 5/10회 판단 기준**:
  - 5회: 단순 변경, 단일 모듈, 명확한 패턴
  - 10회: 큰 변경, 다중 모듈, 복잡한 통합
  - 판단은 각 팀 스킬이 변경 규모를 보고 자체 결정
