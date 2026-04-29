---
tags: [wiki, entities]
created: 2026-04-23
updated: 2026-04-23
sources: [skills/peach-wiki/SKILL.md, docs/08-wiki-feature-docs-경계규칙.md, docs/위키스킬/00-위키스킬-안내.md]
related_files: [skills/peach-wiki/SKILL.md, docs/08-wiki-feature-docs-경계규칙.md, docs/위키스킬/00-위키스킬-안내.md]
---

# peach-wiki 스킬
> Karpathy LLM Wiki 패턴 기반 누적형 지식베이스 구축·유지 스킬

## 역할

- Raw Source를 읽어 `docs/wiki/`에 프로젝트 지식을 누적한다
- code 프로젝트와 Obsidian 보관소를 같은 구조로 관리한다
- `qmd`를 1순위 검색 경로로 사용해 wiki + 소스를 함께 찾는다

## 주요 오퍼레이션

| 오퍼레이션 | 역할 |
|-----------|------|
| INIT | `docs/wiki/` 구조 생성, `WIKI-AGENTS.md` 초기화, qmd 인덱스 연결 |
| INGEST | 모듈·문서·개념을 wiki 페이지로 추가 |
| QUERY | wiki 기반 질의응답 |
| DRIFT | git 변경을 기준으로 wiki 갱신 |
| LINT | 고아 페이지, 깨진 링크, 템플릿 드리프트, 미문서화 항목 점검 |

## harness 통합 상태

- `v1.17.0`부터 `peach-harness` 배포 스킬로 통합 완료
- 관련 배경 문서는 `docs/위키스킬/` 아래로 이전
- 과거 로컬 스킬 `wiki-code`는 히스토리 문서만 유지

## qmd 운영 규칙

- 모든 명령에 `--index peach-harness`를 붙인다
- 검색: `qmd --index peach-harness query "키워드" -c peach-harness`
- 대량 변경 반영: `qmd --index peach-harness update && qmd --index peach-harness embed`

## 연결된 위키 페이지

- [[entities/project-overview]]
- [[entities/skill-wiki-integration-decision]]
- [[entities/skill-wiki-code]]

## 원본 소스

- `skills/peach-wiki/SKILL.md`
- `docs/08-wiki-feature-docs-경계규칙.md`
- `docs/위키스킬/00-위키스킬-안내.md`
