# WIKI-AGENTS — peach-harness 위키 운영 규칙

> Karpathy LLM Wiki 패턴 기반. 세션 시작 시 이 파일을 먼저 읽는다.
> 템플릿 버전: 0.1.0

## 역할 분리

| 역할 | 책임 |
|------|------|
| 사람 | 소스 추가, 방향 설정, 질문, INGEST 요청 |
| LLM | `docs/wiki/` 파일 생성·업데이트, Raw Source는 읽기만 |

## 3계층 구조

| 계층 | 위치 |
|------|------|
| Raw Source (읽기 전용) | `skills/*/SKILL.md`, `skills/*/references/*.md`, `docs/*.md`, `AGENTS.md`, `.claude-plugin/*.json` |
| Wiki Layer (LLM 소유) | `docs/wiki/` |
| Schema (협력 진화) | `docs/wiki/WIKI-AGENTS.md` |

## qmd 컬렉션

- 컬렉션명: `peach-harness`
- URI 접두사: `qmd://peach-harness/`
- 검색: `qmd --index peach-harness query "키워드" -c peach-harness`
- fallback: `qmd --index peach-harness query "키워드" -c peach-harness --no-rerank` → `qmd --index peach-harness search "키워드" -c peach-harness` → `rg "키워드"`

## 오퍼레이션

| 오퍼레이션 | 트리거 | 동작 |
|-----------|-------|------|
| INGEST | "wiki에 추가", 모듈/노트 언급 | 소스 → 위키 생성·업데이트 |
| QUERY | "어떻게 동작해?", "설명해줘" | 위키 기반 답변 |
| DRIFT | "wiki 업데이트" | git 변경 → 위키 갱신 (`.git` 있음 — 활성) |
| LINT | "wiki 점검", "lint" | 모순·고아·드리프트 탐지 |

## 핵심 원칙

- Raw Source 절대 수정 금지
- `docs/wiki/` 하위에만 쓰기
- qmd query 1순위
- qmd 인덱스 갱신 시 `--index peach-harness` 필수
- 언어: 한국어 (기술 용어는 영어 유지)
