# wiki-log — 작업 타임라인

> append-only. 최신 항목이 맨 위.

---

## 2026-04-23 | DRIFT+LINT | peach-harness

- `docs/08-wiki-feature-docs-경계규칙.md` 기준으로 wiki 드리프트 점검
- `WIKI-AGENTS.md`를 최신 템플릿 형식에 맞춰 갱신
- `entities/skill-peach-wiki.md` 신규 작성
- `entities/project-overview.md`, `entities/skill-wiki-integration-decision.md`, `entities/skill-wiki-code.md` 갱신
- 깨진 raw source 참조(`.claude/skills/wiki-code`) 제거
- `wiki-index.md` 카탈로그/통계 갱신
- `qmd --index peach-harness update && qmd --index peach-harness embed` 실행 예정

## 2026-04-12 | INIT | peach-harness

- docs/wiki/ 최초 생성
- WIKI-AGENTS.md, wiki-index.md, wiki-log.md 초기화
- entities/project-overview.md 생성
- entities/skill-wiki-code.md 생성 (wiki-code 스킬)
- entities/skill-peach-release.md 생성 (peach-release 스킬)
- concepts/skill-architecture.md 생성
- AGENTS.md에 wiki 참조 섹션 추가
- qmd update && qmd embed 실행
