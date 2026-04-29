---
tags: [wiki, entities]
created: 2026-04-12
updated: 2026-04-23
sources: [docs/08-wiki-feature-docs-경계규칙.md]
related_files: [docs/08-wiki-feature-docs-경계규칙.md]
---

# wiki-code 스킬
> peach-harness 초기 위키 관리용 로컬 스킬 이력 문서

## 역할

- 코드베이스와 프로젝트 문서를 Raw Source로 삼아 `.wiki/` 레이어를 관리
- qmd CLI를 기본 경로로 사용하고, MCP가 있으면 검색 보조로 사용
- peach-harness 저장소 전용 wiki 운영 스킬

## 상태

- **삭제됨**: 2026-04-12
- **현재 상태**: `peach-wiki` 통합 이후 히스토리 문서만 유지
- **삭제 이유**: peach-wiki(`docs/wiki/` 기반)와 구조 충돌 — `wiki-code`는 `.wiki/` 폴더, peach-wiki는 `docs/wiki/` 폴더 사용
- 이 페이지는 히스토리 참조용으로 유지

## 주요 오퍼레이션

| 오퍼레이션 | 트리거 |
|-----------|--------|
| INIT | `.wiki/WIKI-AGENTS.md` 없을 때 |
| INGEST | "wiki에 추가", 파일 언급 |
| QUERY | "어떻게 동작해?", "흐름 설명" |
| DRIFT | "wiki 업데이트해줘" |
| LINT | "wiki 점검" |

## 연결된 위키 페이지

- [[entities/skill-peach-wiki]]
- [[entities/skill-release]]
- [[concepts/skill-architecture]]

## 원본 소스

- `docs/08-wiki-feature-docs-경계규칙.md`
