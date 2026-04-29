# wiki / feature-docs / qmd 경계 규칙

> 작성: 2026-04-23 | peach-team-analyze 결과 반영

## 1. 3개 도구 역할 계층

```
[검색]  qmd              ← wiki·feature-docs·소스코드 공통 피검색 대상
          ↓
[지도]  peach-wiki       ← 프로젝트 전체 아키텍처·모듈 간 관계·횡단 개념
          ↓
[심층]  feature-docs     ← 단일 기능 암묵지·설계결정·TDD가이드 (수정 전 컨텍스트)
```

3개 도구는 계층이 달라 기능 중복이 아님. 단, **경계 규칙 없으면 wiki entities ↔ feature-docs 처리흐름이 중복 작성되어 오버엔지니어링 전락.**

---

## 2. 경계 규칙

### peach-wiki `docs/wiki/entities/`에 쓸 것
- 모듈 간 관계, 의존성, 데이터 흐름 (특정 기능에 속하지 않는 지식)
- 아키텍처 패턴, 도메인 개념 (`concepts/`)
- 의사결정·트레이드오프 (`synthesis/`)
- 프로젝트 전체 온보딩 맥락

### `docs/기능별설명/{카테고리}/{기능}/`에 쓸 것 (feature-docs)
- 단일 기능의 처리 흐름, 에러코드, 권한 체크, 이력 기록
- 설계결정(ADR): 매직넘버 이유, 함수명 변경 배경, 테이블 컬럼 크기 근거
- TDD 가이드: 테스트 케이스 목록, 실행법, 함정 (bunqldb camelCase 등)
- 버그픽스 이력

### 중간 지점 처리 원칙
- wiki `entities/module-이름.md` → 기능 개요 + `"심화는 docs/기능별설명/{카테고리}/{기능}/ 참조"` 링크
- feature-docs `{기능}-개요.md` → `"모듈 간 관계는 docs/wiki/entities/ 참조"` 역참조

---

## 3. AGENTS.md 소유권 규칙

`peach-setup-harness`와 `peach-wiki INIT`은 대상 프로젝트의 동일한 AGENTS.md를 수정한다.
충돌 방지를 위해 아래 섹션 소유권을 분리한다.

| AGENTS.md 섹션 | 소유 스킬 | 규칙 |
|---------------|-----------|------|
| 공통 원칙, 네이밍, 타입, 보안 | `peach-setup-harness` | 수정 금지 (harness 기본 틀) |
| wiki 참조, qmd 인덱스 | `peach-wiki INIT` | wiki INIT 실행 시 자동 추가 |
| 기능별 가이드, 모듈별 규칙 | 해당 스킬 | 각자 담당 섹션만 수정 |

**원칙: 자신이 추가한 섹션만 수정, 다른 스킬이 추가한 섹션은 건드리지 않는다.**

---

## 4. peach-wiki 통합 완료 (2026-04-23)

peach-wiki를 peach-harness에 **v1.17.0에서 통합 완료**했다.

**완료된 선결 과제:**
1. peach-wiki 런북·템플릿 qmd 명령 불일치 수정 완료
2. AGENTS.md 소유권 충돌 규칙 정의 완료 (이 문서 §3)
3. Obsidian 포지셔닝 — peach-wiki 스킬이 자동 감지 로직으로 처리, 별도 명시 불필요로 결정

**통합 내용:**
- `skills/peach-wiki/` — 스킬 본체 + references 추가
- `docs/위키스킬/` — LLM Wiki 배경 이론 문서 7개 이전
- peach-wiki 저장소 아카이브

상세 분석 이력: `docs/위키스킬/06-harness-통합-분석.md`
