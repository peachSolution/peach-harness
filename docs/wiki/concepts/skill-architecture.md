---
tags: [wiki, concepts]
created: 2026-04-12
updated: 2026-05-03
sources: [agents.md, docs/01-아키텍처.md]
related_files: [agents.md, docs/01-아키텍처.md]
---

# 스킬 아키텍처 패턴
> peach-harness 스킬의 구조·역할 분리·자율성 범위 핵심 패턴

## 스킬 vs 서브에이전트

| 구분 | 역할 | 파일 위치 |
|------|------|-----------|
| 스킬 (SKILL.md) | 오케스트레이터 — 실행 절차 정의, 팀 조율 | `skills/*/skill.md` |
| 서브에이전트 | 역할 실행자 — 독립 컨텍스트에서 작업 수행 | `skills/*/references/*-agent.md` |

`peach-intake`는 구현 오케스트레이터가 아니라 진입 게이트다. 요청을 받아 작업 규모와 후속 스킬 경로를 판정하고, 코드/DB/proto/E2E 산출물은 만들지 않는다.

## 배포 스킬 vs 로컬 스킬

```
skills/           ← 배포 스킬 (마켓플레이스 배포, 타 프로젝트 설치 가능)
.claude/skills/   ← 로컬 전용 스킬 (peach-harness 자체 운영용)
```

## Bounded Autonomy (3단계)

| 수준 | 내용 |
|------|------|
| Must Follow | 스킬 네이밍, frontmatter 필수 필드, 버전 파일 동기화, references 정책 |
| May Adapt | 워크플로우 세부 단계 보완, references 파일 구성, 안내 문구 개선 |
| May Suggest | 스킬 워크플로우 단계 추가/삭제, 새 스킬 생성, Bounded Autonomy 변경 |

## 에이전트 모델 정책

| 스킬 유형 | 권장 모델 |
|-----------|-----------|
| 팀 스킬 (peach-team, peach-team-3a 등) | opus |
| 서브에이전트 기본 | sonnet |
| architect/reviewer (peach-team-3a) | opus |

## Runtime Adapter

팀 스킬은 런타임에 따라 실행 방식을 나눈다.

| 런타임 | 방식 |
|--------|------|
| Claude Code 플러그인 | team mode — TeamCreate/TaskCreate/SendMessage/worktree isolation 사용 |
| Codex 또는 일반 skills.sh | generic mode — 같은 역할 큐를 순차 또는 제한 병렬로 수행 |

팀 스킬은 독립 실행성을 위해 `references/runtime-adapter.md`를 스킬 내부에 둔다. 중복은 허용하되 정책 변경 시 관련 로컬 사본을 함께 갱신한다.

## Ralph Loop 패턴

- QA 실패 시 구조화된 피드백 주입으로 같은 실수 반복 방지
- 에스컬레이션 도달 시 `docs/qa/` 검증 보고서에 이력 기록

## 연결된 위키 페이지

- [[entities/project-overview]]
- [[entities/skill-release]]
- [[entities/skill-wiki-code]]
