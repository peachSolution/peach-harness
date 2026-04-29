---
tags: [wiki, entities]
created: 2026-04-12
updated: 2026-04-12
sources: [.claude/skills/peach-release/SKILL.md]
related_files: [.claude/skills/peach-release/SKILL.md, .claude-plugin/plugin.json, .claude-plugin/marketplace.json]
---

# peach-release 스킬
> peach-harness 릴리스 일괄 처리 스킬 (로컬 전용)

## 역할

버전 업데이트부터 GitHub Release 생성까지 전체 릴리스 파이프라인을 자동화한다.

## 워크플로우 (5단계)

1. **상태 확인** — develop 브랜치 여부, 미스테이지 변경 확인
2. **변경 분석 및 버전 결정** — `Release v{현재버전}` 커밋 이후 신규 커밋 추출, AI가 semver 타입 결정
3. **릴리스 계획 제시 및 단일 승인** — CHANGELOG 초안 포함, 사용자 1회 승인
4. **일괄 실행** — 버전 파일 업데이트 → CHANGELOG → 커밋 → push → PR 생성 → 머지 → GitHub Release
5. **완료 보고** — PR URL, Release URL 출력

## 핵심 규칙

- `develop` 브랜치에서만 버전 업데이트 (main 직접 작업 금지)
- 두 버전 파일 (`plugin.json`, `marketplace.json`) 항상 동기화
- 신규 커밋 기준: `git log main..develop` 금지 → `Release v{현재버전}` 커밋 이후만 분석
- 승인 1회 원칙: 전체 계획 보여준 뒤 단 1회만 승인 받음
- `--delete-branch=false`: develop 브랜치 보존

## 버전 파일 위치

```
.claude-plugin/marketplace.json  → plugins[0].version
.claude-plugin/plugin.json       → version
```

## 연결된 위키 페이지

- [[entities/project-overview]]
- [[concepts/skill-architecture]]

## 원본 소스

- `.claude/skills/peach-release/SKILL.md`
