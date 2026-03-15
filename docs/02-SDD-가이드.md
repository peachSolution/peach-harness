# SDD(Spec-Driven Development) 가이드

피치 하네스에서 SDD 원칙을 적용하는 방법을 안내합니다.

## SDD란?

Spec-Driven Development는 **구현 전에 명세(Spec)를 작성**하고, 이를 AI 에이전트의 컨텍스트로 주입하여 일관된 코드를 생성하는 개발 방법론입니다.

2025년 Thoughtworks, Google, Red Hat 등에서 주류 트렌드로 자리잡았으며, Fastly 설문에 따르면 "문서화 후 AI 활용" 방식이 바이브코딩 대비 **2.5배 생산성** 향상을 보였습니다.

## 핵심 원칙

1. **명세가 먼저**: 코드 전에 Spec을 작성하면 AI가 정확한 맥락을 갖고 생성
2. **AI Plan 모드 활용**: 소규모 작업은 AI Plan 모드만으로 충분
3. **세션 분리**: 대규모 작업은 Spec 세션과 구현 세션을 분리
4. **문서는 자산**: 산출물(Spec, QA 보고서, Handoff)은 프로젝트 자산으로 축적

## 피치 하네스 스킬 매핑

| SDD 단계 | 피치 하네스 스킬 | 설명 |
|----------|-----------------|------|
| **명세 작성** | `peach-gen-spec` | To-Be 요구사항 수집 → Spec 문서 생성 |
| **As-Is 분석** | `peach-gen-feature-docs` | 기존 기능의 현재 상태를 구조화 |
| **DB 설계** | `peach-gen-db` | Spec 기반 DDL/마이그레이션 생성 |
| **구현** | `peach-agent-team` | 팀 단위 코드 생성 (Backend/Store/UI) |
| **검증** | `peach-qa-gate` | test/lint/build 증거 수집 |
| **인수인계** | `peach-handoff` | 세션 간 컨텍스트 보존 |

## gen-spec(To-Be) vs gen-feature-docs(As-Is)

| 구분 | peach-gen-spec | peach-gen-feature-docs |
|------|---------------|----------------------|
| 목적 | **새로 만들 기능** 정의 | **기존 기능** 분석 |
| 입력 | 대화형 요구사항 수집 | 코드 분석 |
| 산출물 | Spec 문서 (단일 파일) | Context Pack (4개 파일) |
| 시점 | 구현 전 | 수정 전 |
| 저장 | `docs/spec/{년}/{월}/` | `docs/기능별설명/{카테고리}/{기능명}/` |

### 조합 패턴

```
신규 기능:           /peach-gen-spec → 구현
기존 기능 수정:       /peach-gen-feature-docs → 구현
기존 기능 + 대규모 변경: /peach-gen-feature-docs → /peach-gen-spec → 구현
```

## 작업 규모별 권장 워크플로우

### 소규모 (1~2시간)

버그 수정, 단일 파일 변경, 간단한 기능 추가.

```
AI Plan 모드 → 구현 → (선택) /peach-qa-gate
```

- Spec 문서 불필요
- AI Plan 모드에서 계획 수립 후 바로 구현
- planning-gate는 AI Plan 모드로 대체

### 중규모 (반나절~1일)

새 모듈, 여러 파일 수정, CRUD 기능 추가.

```
AI Plan 모드 → (선택) /peach-gen-spec → /peach-gen-db → /peach-agent-team → /peach-handoff
```

- AI Plan 모드에서 계획 수립
- 복잡도에 따라 Spec 문서 선택적 작성
- 팀 스킬로 구현 + QA 자동화

### 대규모 (2일 이상)

복잡한 비즈니스 로직, 다수 모듈 연동, 세션 분리 필요.

```
세션 1: /peach-gen-spec → Spec 문서 생성 → /peach-handoff
세션 2: Spec 로드 → AI Plan 모드 → /peach-gen-db → /peach-agent-team → /peach-handoff
세션 N: /peach-handoff 로드 → 이어서 작업
```

- Spec 문서가 세션 간 컨텍스트 역할
- Handoff로 진행 상황 보존

## 산출물 저장 구조

모든 산출물은 `docs/` 아래 통일된 패턴으로 저장됩니다.

```
docs/
├── spec/                    # peach-gen-spec 산출물
│   └── {년}/{월}/[YYMMDD]-[한글기능명].md
├── qa/                      # peach-qa-gate 산출물
│   └── {년}/{월}/[YYMMDD]-[한글기능명].md
├── handoff/                 # peach-handoff 산출물
│   └── {년}/{월}/[YYMMDD]-[한글기능명].md
└── 기능별설명/               # peach-gen-feature-docs 산출물
    └── {카테고리}/{기능명}/
        ├── {기능명}-1-개요.md
        ├── {기능명}-2-로직.md
        ├── {기능명}-3-명세.md
        └── {기능명}-4-TDD-가이드.md
```

### 파일명 규칙

- 패턴: `[YYMMDD]-[한글기능명].md`
- 예시: `260315-결제기능.md`
- 년/월 폴더가 시간순 정리를 대체 (active/completed 분류 불필요)
- 파일 내 상태 표시로 진행 상태 판단

## 활용 가이드

### 시니어 개발자

- Spec을 직접 작성하거나 AI와 대화형으로 생성
- Spec 품질 검토 후 구현 세션 시작
- 팀원에게 Spec 문서 공유로 코드 리뷰 부담 감소

### 중급 개발자

- `/peach-help`로 워크플로우 확인
- `/peach-gen-spec`의 6단계 가이드를 따라 요구사항 정리
- 팀 스킬(`/peach-agent-team`)로 QA까지 자동화
