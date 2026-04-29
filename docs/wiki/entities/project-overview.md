---
tags: [wiki, entities]
created: 2026-04-12
updated: 2026-04-23
sources: [readme.md, agents.md, .claude-plugin/plugin.json, .claude-plugin/marketplace.json]
related_files: [readme.md, agents.md, .claude-plugin/plugin.json, .claude-plugin/marketplace.json]
---

# peach-harness — 프로젝트 개요
> PeachSolution 하네스 시스템 — 멀티 AI 도구를 지원하는 스킬 패키지

## 역할

- SKILL.md 오픈 스탠다드 기반 14+ AI 코딩 도구 지원
- 배포 스킬 33개 + 로컬 전용 릴리스 스킬 1개 운영
- 스킬, 서브에이전트, QA 파이프라인, wiki 지식 레이어 통합
- Claude Code, Cursor, Windsurf 등에서 동작

## 구조

```
peach-harness/
├── skills/             ← 배포 스킬 (33개, `peach-wiki` 포함)
├── .claude/skills/     ← 로컬 전용 스킬 (`release`)
├── .claude-plugin/     ← 버전·마켓플레이스 메타
├── docs/               ← 아키텍처·워크플로우 문서
├── docs/wiki/          ← LLM 전용 누적형 위키 레이어
└── agents.md           ← AI 에이전트 가이드
```

## 배포 스킬 분류 (33개)

| 카테고리 | 스킬 |
|---------|------|
| 생성 | peach-gen-backend, peach-gen-ui, peach-gen-ui-proto, peach-gen-db, peach-gen-store, peach-gen-design, peach-gen-spec |
| 문서화 | peach-doc-feature |
| 팀 | peach-team, peach-team-3a, peach-team-analyze, peach-team-refactor |
| DB | peach-db-migrate, peach-db-query, peach-db-extract-schema |
| E2E | peach-e2e-setup, peach-e2e-scenario, peach-e2e-browse, peach-e2e-suite |
| 추가 | peach-add-api, peach-add-cron, peach-add-print |
| 설정 | peach-setup-harness, peach-setup-project, peach-setup-ui-proto |
| 리팩토링 | peach-refactor-backend, peach-refactor-frontend |
| 지식·운영 | peach-help, peach-markitdown, peach-qa-gate, peach-skill-feedback, peach-wiki, peach-erd |

## 로컬 전용 스킬 (.claude/skills/)

| 스킬 | 역할 |
|------|------|
| release | 릴리스 자동화 (버전 업 → PR → GitHub Release) |

`wiki-code`는 삭제된 과거 로컬 스킬이며, 현재는 `skills/peach-wiki/`가 배포 스킬로 통합됐다.

## 버전 관리

- 버전 파일: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- 현재 버전: `1.17.0`
- 릴리스: `develop` → PR → `main`

## 연결된 위키 페이지

- [[entities/skill-peach-wiki]]
- [[entities/skill-release]]
- [[entities/skill-wiki-code]]
- [[entities/skill-wiki-integration-decision]]
- [[concepts/skill-architecture]]

## 원본 소스

- `readme.md`
- `agents.md`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
