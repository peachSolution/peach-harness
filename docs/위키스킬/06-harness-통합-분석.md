# peach-wiki harness 통합 분석 (2026-04-23)

> peach-team-analyze 스킬 (4명 팀 + Codex 교차검증) 결과 문서

## 결론 요약

**현 시점 통합 보류. 선결 과제 4개 해결 후 통합 권고.**

## 1. 오버엔지니어링 여부

**아님.** wiki + qmd + feature-docs는 계층이 다르다.

| 도구 | 역할 | 대체 불가 고유 가치 |
|------|------|---------------------|
| qmd | 검색 엔진 | 의미 기반 검색, 토큰 절약 |
| peach-wiki | 프로젝트 전체 지도 | 횡단 개념·아키텍처·DRIFT 자동 감지 |
| peach-doc-feature | 단일 기능 심층 암묵지 | CDM 질문·Git 고고학·ADR |

단, **경계 규칙 없으면** `wiki entities/` ↔ `feature-docs 처리흐름-*` 중복으로 오버엔지니어링 전락.

```
[검색]  qmd           ← wiki·feature-docs·코드 공통 피검색 대상
          ↓
[지도]  wiki          ← 프로젝트 전체 아키텍처·횡단 개념
          ↓
[심층]  feature-docs  ← 단일 기능 암묵지·설계결정·TDD가이드
```

## 2. 통합 분석

### 찬성 근거
- 설치 메커니즘 100% 동일 (`.claude-plugin/` 구조)
- 1인 운영 시 두 플러그인 버전 동기화·설치 2단계 인지 부하
- 실운영 10일+ 완료로 불확실성 일부 해소

### 반대 근거 (Codex 교차검증에서 발견)

| # | 문제 | 내용 |
|---|------|------|
| 1 | 릴리즈 blast radius | wiki 수정이 harness 전체 버전에 묻힘 (harness semver: team/gen=minor, 유틸=patch) |
| 2 | 업데이트 동조 비용 | harness는 e2e/gen 중심 고빈도 릴리즈, wiki는 저빈도 → wiki 사용자가 무관한 업데이트 계속 떠안음 |
| 3 | 내부 자기모순 (아래 섹션 참조) | SKILL.md vs 런북·템플릿 qmd 명령 불일치 |
| 4 | AGENTS.md 소유권 충돌 | `peach-setup-harness`와 `wiki INIT` 둘 다 AGENTS.md를 서로 다른 계약으로 수정 |
| 5 | Obsidian 포지셔닝 소멸 위험 | 감지 로직만 보존해서는 불충분. harness 공개 문서가 코드/E2E 전용 → Obsidian 시나리오 사라질 가능성 |

## 3. 선결 과제 (통합 전 반드시 해결)

### ① 내부 자기모순 수정 (이 저장소에서 해결)

**문제:** SKILL.md는 `--index "$QMD_INDEX"` 필수 명시, 런북·템플릿은 plain qmd 사용.

수정 대상 파일:
- `skills/peach-wiki/references/INIT-런북.md` — `qmd status/query` → `qmd --index "$QMD_INDEX" status/query`
- `skills/peach-wiki/references/WIKI-AGENTS-템플릿.md` — plain qmd 명령 전부 `--index` 포함으로 교체

### ② AGENTS.md 소유권 충돌 규칙 정의 (통합 시 harness에서 해결)

`peach-setup-harness`(5개 섹션 관리) ↔ `wiki INIT`(wiki+qmd 섹션 추가)가 동일 파일을 수정.
통합 시 어느 스킬이 AGENTS.md의 어느 섹션을 소유하는지 명시 필요.

### ③ 경계 규칙 문서화 (harness AGENTS.md에 추가)

```
wiki entities/   = 모듈 간 관계·횡단 개념·아키텍처 개요
feature-docs/    = 단일 기능 암묵지·설계결정·TDD가이드 (수정 전 컨텍스트)
→ wiki entities에 "심화는 docs/기능별설명/{기능}/ 참조" 링크 표준화
```

### ④ Obsidian 포지셔닝 결정

통합 시 harness README·설치 문서에 Obsidian 시나리오 명시 여부를 결정해야 함.
감지 로직 보존만으로는 불충분 — 문서 포지셔닝도 함께 유지해야 Obsidian 사용 가능성 보존.

## 4. 권장 실행 순서

```
① 이 저장소(peach-wiki): references/ 자기모순 수정
② harness: 경계 규칙 AGENTS.md 명시
③ harness: AGENTS.md 소유권 충돌 규칙 정의
④ Obsidian 포지셔닝 결정
⑤ 위 4개 완료 후 → 통합 실행 (기술 비용 낮음, 수 시간)
```

## 참고: 과거 분리 이력

`peach-harness/docs/wiki/entities/skill-wiki-code.md` (2026-04-12):
> 삭제 이유: peach-wiki 플러그인(`docs/wiki/`)과 구조 충돌 — wiki-code는 `.wiki/`, peach-wiki는 `docs/wiki/`

현재(2026-04-23)는 실운영 10일+ 완료로 불확실성 일부 해소. 선결 과제 해결 후 통합 재검토 유효.
