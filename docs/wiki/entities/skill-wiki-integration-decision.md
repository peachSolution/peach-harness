---
tags: [wiki, entities]
created: 2026-04-23
updated: 2026-04-23
sources: [docs/위키스킬/06-harness-통합-분석.md, docs/08-wiki-feature-docs-경계규칙.md, skills/peach-wiki/SKILL.md]
related_files:
  - docs/위키스킬/06-harness-통합-분석.md
  - docs/08-wiki-feature-docs-경계규칙.md
  - skills/peach-wiki/SKILL.md
---

# peach-wiki harness 통합 결정

> 2026-04-23 분석 이후 `v1.17.0`에 통합 완료

## 결정: 통합 완료

`peach-wiki`는 `peach-harness` 배포 스킬로 편입되었고, 별도 저장소 운용은 종료됐다.

## 판단 근거

wiki + qmd + feature-docs 3개는 검색 → 지도 → 심층 계층 구조로 역할이 다르다.
경계 규칙은 `docs/08-wiki-feature-docs-경계규칙.md`에 정리되어 있다.

## 완료된 선결 과제

| # | 선결 과제 | 해결 위치 |
|---|-----------|-----------|
| 1 | peach-wiki references/ 자기모순 (SKILL.md vs 런북 qmd 명령 불일치) | `skills/peach-wiki/`, `docs/위키스킬/` |
| 2 | AGENTS.md 소유권 충돌 규칙 | `docs/08-wiki-feature-docs-경계규칙.md` |
| 3 | Obsidian 포지셔닝 결정 | `skills/peach-wiki/SKILL.md` 자동 감지 로직으로 흡수 |

## 통합 결과

- `skills/peach-wiki/` 추가
- `docs/위키스킬/`로 배경 문서 이전
- `readme.md`, `agents.md`, 경계 규칙 문서에 통합 사실 반영
- 과거 `wiki-code`는 히스토리 문서만 유지

## 연결된 위키 페이지

- [[skill-peach-wiki]] — 현재 배포 스킬
- [[skill-wiki-code]] — 과거 로컬 스킬 이력
- [[project-overview]] — peach-harness 전체 구조
