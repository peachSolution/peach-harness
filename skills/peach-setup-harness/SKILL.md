---
name: peach-setup-harness
description: |
  대상 프로젝트에 피치 하네스 시스템을 설정합니다. CLAUDE.md를 최소 진입점으로 정리하고, AGENTS.md에 하네스 운영 지침(세션 시작 handoff 체크, 스킬 카탈로그 참조)을 추가합니다.
  Use when: "하네스 설정", "프로젝트 초기 설정", "CLAUDE.md 정리", "AGENTS.md 업데이트", "세션 시작 설정", "handoff 설정" 키워드.
model: opus
---

# peach-setup-harness — 하네스 시스템 설정

대상 프로젝트의 CLAUDE.md와 AGENTS.md를 하네스 시스템에 맞게 설정한다.
CLAUDE.md는 20줄 이내 최소 진입점, AGENTS.md는 상세 규칙 원칙.

## 페르소나

하네스 시스템 설정 전문가.
CLAUDE.md에서 AGENTS.md와 중복되는 내용을 제거하고, 세션 시작 시 handoff 체크 지침을 추가한다.
AGENTS.md 필수 섹션을 점검하여 누락 시 보완하고, cursor rules는 삭제한다.

---

## 전제조건

- **대상 프로젝트 루트**에서 실행 (peach-harness 자체가 아닌 대상 프로젝트)
- peach-harness 스킬이 설치되어 있어야 함

---

## Workflow

### Step 1: 현재 상태 분석

다음을 확인한다:

```bash
# CLAUDE.md 존재 여부 + 내용
cat CLAUDE.md 2>/dev/null || echo "CLAUDE.md 없음"

# AGENTS.md 존재 여부 + 내용
cat AGENTS.md 2>/dev/null || echo "AGENTS.md 없음"

# docs/handoff/ 디렉토리 존재 여부
ls docs/handoff/ 2>/dev/null || echo "docs/handoff/ 없음"

# 프로젝트 구조 감지
ls -d api/ front/ 2>/dev/null || echo "모노레포 아님"

# Controller 프레임워크 감지 (Koa vs Elysia)
head -3 api/src/modules/test-data/controller/test-data.controller.ts 2>/dev/null || echo "controller 없음"

# DAO 라이브러리 감지 (bunqldb vs sql-template-strings)
head -5 api/src/modules/test-data/dao/test-data.dao.ts 2>/dev/null || echo "dao 없음"

# DB 종류 감지
grep -i "host\|database\|mysql\|postgres" api/env.local.yml 2>/dev/null | head -5 || echo "env.local.yml 없음"

# cursor rules 존재 여부
ls api/.cursor/rules/ 2>/dev/null && echo "api cursor rules 존재" || echo "api cursor rules 없음"
ls front/.cursor/rules/ 2>/dev/null && echo "front cursor rules 존재" || echo "front cursor rules 없음"
ls .cursor/rules/ 2>/dev/null && echo "root cursor rules 존재" || echo "root cursor rules 없음"
ls .cursorrules 2>/dev/null && echo ".cursorrules 존재" || echo ".cursorrules 없음"
```

분석 결과를 정리:
- CLAUDE.md: 존재 여부, 현재 줄 수, AGENTS.md와 중복되는 섹션 목록
- AGENTS.md: 존재 여부, "하네스 시스템 연동" 섹션 존재 여부
- docs/handoff/: 존재 여부
- 프로젝트 유형:
  - `api/ + front/` 모노레포 (기존)
  - 단독 `api/` (기존)
  - 단독 `front/` (기존)
- Controller 프레임워크: Koa (routing-controllers) 또는 Elysia (api/ 없으면 해당 없음)
- DB 종류: MySQL 또는 PostgreSQL (api/ 없으면 해당 없음)
- cursor rules: 존재 여부 및 파일 목록 (`api/.cursor/rules/`, `front/.cursor/rules/`, `.cursor/rules/`, `.cursorrules`)

### Step 2: AGENTS.md 필수 섹션 점검

AGENTS.md가 존재하는 경우, 아래 핵심 섹션이 있는지 확인한다:

```bash
grep -l "공통 원칙\|_common.*import" AGENTS.md 2>/dev/null && echo "§공통원칙 존재" || echo "§공통원칙 누락"
grep -l "백엔드 규칙\|ErrorHandler" AGENTS.md 2>/dev/null && echo "§백엔드 존재" || echo "§백엔드 누락"
grep -l "프론트엔드 규칙\|computed" AGENTS.md 2>/dev/null && echo "§프론트엔드 존재" || echo "§프론트엔드 누락"
grep -l "테스트\|TDD" AGENTS.md 2>/dev/null && echo "§테스트 존재" || echo "§테스트 누락"
grep -l "하네스 시스템 연동" AGENTS.md 2>/dev/null && echo "하네스연동 존재" || echo "하네스연동 누락"
```

누락 섹션 발견 시 아래 references 파일을 소스로 사용한다:

**공통 (항상 참조):**
| 누락 섹션 | 소스 파일 |
|----------|---------|
| 공통 원칙 (네이밍, 타입, Bounded Autonomy, 독립도메인) | `peach-setup-harness/references/common-rules.md` |
| 백엔드 규칙 (기술스택, 모듈구조, 에러처리, bunqldb 등) | `peach-setup-harness/references/backend-rules.md` |
| 프론트엔드 규칙 (NuxtUI v4, Store표준, Computed래핑 등) | `peach-setup-harness/references/frontend-rules.md` |
| 테스트 및 품질 (TDD, 필수설정, 검증명령어) | `peach-setup-harness/references/testing-rules.md` |
| Validator/타입 규칙 (class-validator/TypeBox, 인터페이스 구조) | `peach-setup-harness/references/validator-rules.md` |

**Elysia 감지 시 추가 참조:**
| 항목 | 소스 파일 |
|------|---------|
| Plugin System, try-catch 금지, Auth, Bun Native API, 로깅, 주석금지, API문서화 | `peach-setup-harness/references/backend-elysia-rules.md` |

**AGENTS.md 없는 새 프로젝트 (완성형 참조):**
| 프레임워크/유형 | 소스 파일 |
|--------------|---------|
| Koa 프로젝트 전체 AGENTS.md 템플릿 | `peach-setup-harness/references/example-koa-agents.md` |
| Elysia 프로젝트 전체 AGENTS.md 템플릿 | `peach-setup-harness/references/example-elysia-agents.md` |

Elysia 감지 시 추가 확인:
```bash
grep -l "Plugin System\|try-catch 금지" AGENTS.md 2>/dev/null && echo "Elysia 규칙 존재" || echo "Elysia 규칙 누락"
```

누락 섹션 목록을 기록한다.

### Step 3: 변경 계획 생성

사용자에게 변경 계획을 제시한다:

**CLAUDE.md 변경:**
- 제거할 중복 섹션 (AGENTS.md에 이미 있는 내용)
- 추가할 "세션 시작" 섹션
- 최종 예상 줄 수

**AGENTS.md 변경:**
- 누락된 필수 섹션 목록 + 추가할 내용 요약
- 추가할 "하네스 시스템 연동" 섹션

**cursor rules 삭제 (존재하는 경우):**
- 삭제 대상 파일/디렉토리 목록
- 삭제 사유: "기본 지침(AGENTS.md) + 스킬 베이스로 작업 진행. cursor rules는 더 이상 사용하지 않음"

**기타:**
- docs/handoff/ 디렉토리 생성 필요 여부

### Step 4: 사용자 확인

변경 계획에 대해 사용자 동의를 받는다. 수정 요청이 있으면 반영한다.

### Step 5: 적용

승인 후 변경을 적용한다:

1. **CLAUDE.md 정리 + "세션 시작" 섹션 추가**
   - AGENTS.md와 중복되는 섹션 제거
   - 프로젝트별 고유 지침은 보존 (Electron IPC, 특수 설정 등)
   - "세션 시작" 섹션 추가
   - 20줄 이내 유지

2. **AGENTS.md 누락 섹션 추가/업데이트**
   - AGENTS.md **없음** → 프레임워크/유형에 맞는 example 파일 기반으로 전체 생성
     - Koa: `example-koa-agents.md` 기반 생성
     - Elysia: `example-elysia-agents.md` 기반 생성
   - AGENTS.md **있음** → 누락 섹션만 개별 references에서 추출하여 추가
     - `common-rules.md` → 공통 원칙 섹션
     - `backend-rules.md` → 백엔드 규칙 섹션
     - `backend-elysia-rules.md` → Elysia 전용 섹션 (Elysia인 경우)
     - `frontend-rules.md` → 프론트엔드 규칙 섹션
     - `testing-rules.md` → 테스트 및 품질 섹션
     - `validator-rules.md` → Validator/타입 규칙 섹션
   - 프레임워크(Koa/Elysia)에 맞는 내용으로 작성

3. **AGENTS.md에 "하네스 시스템 연동" 섹션 추가**
   - 기존 마지막 섹션 번호 확인 후 다음 번호로 추가

4. **cursor rules 삭제** (존재하는 경우)
   - `api/.cursor/rules/` 디렉토리 삭제
   - `front/.cursor/rules/` 디렉토리 삭제
   - 루트 `.cursor/rules/` 디렉토리 삭제
   - 루트 `.cursorrules` 파일 삭제

5. **docs/handoff/ 디렉토리 생성** (없는 경우)
   - `.gitkeep` 파일 생성

### Step 6: 완료 확인

적용 결과를 출력한다:
- CLAUDE.md 변경 전/후 줄 수
- AGENTS.md 추가/업데이트된 섹션 목록
- 삭제된 cursor rules 파일 목록
- docs/handoff/ 생성 여부

### Step 7: 변경 이력 문서화

변경 사항을 `docs/handoff/` 에 기록한다:

```markdown
# 하네스 시스템 설정 이력

날짜: {YYYY-MM-DD}
실행자: peach-setup-harness

## 변경 내용
- CLAUDE.md: {전} → {후} 줄
- AGENTS.md 추가 섹션: {목록}
- 삭제된 cursor rules: {목록 또는 없음}
- 프로젝트 환경: {Koa/Elysia}, {MySQL/PostgreSQL}
```

---

---

## AGENTS.md 최소화 원칙

AGENTS.md를 새로 생성하거나 보완할 때 아래 원칙을 적용한다.

**근거:** 긴 AGENTS.md는 AI 성공률을 떨어뜨린다. "추론 불가능한 것만 남겨라."
- 가이드 코드(`test-data/`)에서 추론 가능한 내용 → 가이드 코드 포인터로 대체
- 린터(Biome/ESLint)가 잡을 수 있는 규칙 → 제거
- 코드 예시 → `파일 경로 참조` 1줄로 대체

**유지 (추론 불가 항목):**
- 한국어 응답
- `_common`만 import, FK 금지
- 타입 규칙 (옵셔널/null/undefined 금지)
- PK `seq` 접미사 + 감사 칼럼
- 에러 처리 원칙 (기능오류 200+success:false / 시스템예외 ErrorHandler)
- Elysia: try-catch 금지, Plugin System 자동 래핑
- Store: Pinia Option API + computed 래핑 + isLoading 금지
- TDD/실DB/모킹 금지
- 완전 독립 도메인
- 하네스 연동 섹션
- 네이밍 컨벤션 (4종: snake_case, kebab-case, PascalCase, camelCase)
- DB 마이그레이션 명령어 (db:up-dev, db:down-dev, db:extract-schema)

**목표 크기:** 80줄 이내 (하네스 연동 + 네이밍 컨벤션 포함 ~100줄 허용)

---

## CLAUDE.md 표준 템플릿

대상 프로젝트의 CLAUDE.md를 아래 형식으로 정리한다.
프로젝트별 고유 지침은 별도 섹션으로 보존한다.

```markdown
# {프로젝트명}

{한 줄 설명}

## 규칙 참조

모든 개발 규칙은 @AGENTS.md 를 참조하라.

## 세션 시작

세션 시작 시 `docs/handoff/` 디렉토리의 최신 파일을 확인하고, 미완료 작업이 있으면 요약하세요.

## 가이드 코드

코드 생성 = **가이드 코드 참조** → 도메인 분석 → Bounded Autonomy 범위 내 적응
- Backend: `api/src/modules/test-data/`
- Frontend: `front/src/modules/test-data/`
```

### 핵심 원칙

- CLAUDE.md는 **20줄 이내** 유지
- AGENTS.md와 중복되는 섹션은 제거 ("Claude 특화 지침", "코딩 규칙" 등)
- 프로젝트별 고유 지침(Electron IPC, 특수 환경변수 등)은 별도 섹션으로 보존
- "세션 시작" 섹션이 핵심 추가사항
- "가이드 코드" 섹션:
  - 모노레포(api/+front/): `Backend: api/src/modules/test-data/` + `Frontend: front/src/modules/test-data/`
  - 단독 front/: `Frontend: front/src/modules/test-data/`

---

## AGENTS.md 추가 섹션

대상 프로젝트 AGENTS.md의 마지막에 아래 섹션을 추가한다.
섹션 번호는 기존 마지막 번호 + 1로 설정한다.

```markdown
## {N}. 하네스 시스템 연동

### 세션 시작 체크리스트
1. `docs/handoff/` 디렉토리의 최신 파일 확인
2. 미완료 작업이 있으면 요약 출력
3. `git status && git branch` 확인

### Handoff 사용법
- 세션 종료 시: `/peach-handoff` → save 모드
- 세션 시작 시: `/peach-handoff` → load 모드 (또는 AI가 자동 확인)
- 저장 위치: `docs/handoff/{년}/{월}/[YYMMDD]-[한글기능명].md`

### 스킬 카탈로그 참조
전체 스킬 목록과 워크플로우는 `/peach-help`를 실행하라.
```

---

## 완료 조건 체크리스트

기본:
- [ ] CLAUDE.md가 20줄 이내로 정리됨
- [ ] CLAUDE.md에 "세션 시작" 섹션이 포함됨
- [ ] CLAUDE.md에서 AGENTS.md 중복 내용이 제거됨
- [ ] AGENTS.md에 "하네스 시스템 연동" 섹션이 추가됨
- [ ] docs/handoff/ 디렉토리가 존재함
- [ ] 프로젝트별 고유 지침이 보존됨

추가 (신규):
- [ ] AGENTS.md에 필수 섹션이 모두 존재함 (공통원칙, 백엔드, 프론트엔드, 테스트, Validator, 독립도메인)
- [ ] Elysia 프로젝트인 경우 Elysia 전용 항목이 포함됨 (Plugin, try-catch금지, Auth, 로깅, API문서화 등)
- [ ] 기술 스택이 정확히 반영됨 (bunqldb, NuxtUI v4, Biome/ESLint, int PK)
- [ ] api/.cursor/rules/ 삭제됨 (존재했던 경우)
- [ ] front/.cursor/rules/ 삭제됨 (존재했던 경우)
- [ ] 루트 .cursor/rules/ 삭제됨 (존재했던 경우)
- [ ] 루트 .cursorrules 삭제됨 (존재했던 경우)
- [ ] 프로젝트 환경(Koa/Elysia, DB종류)에 맞는 내용으로 작성됨
