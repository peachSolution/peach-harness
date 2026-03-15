---
name: peach-setup-ui-proto
description: |
  Frontend-Only UI Proto 프로젝트에 피치 하네스 시스템을 설정합니다. CLAUDE.md를 최소 진입점으로 정리하고, AGENTS.md에 UI Proto 기준 프론트엔드 규칙과 하네스 운영 지침을 맞춥니다.
  Use when: "ui proto 하네스 설정", "ui proto AGENTS 정리", "Frontend-Only 하네스 설정", "프로토타입 프로젝트 초기 설정" 키워드.
model: opus
---

# peach-setup-ui-proto — UI Proto 하네스 설정

Frontend-Only UI Proto 프로젝트의 CLAUDE.md와 AGENTS.md를 하네스 시스템에 맞게 설정한다.
CLAUDE.md는 20줄 이내 최소 진입점, AGENTS.md는 UI Proto 운영에 필요한 프론트엔드 규칙 중심으로 정리한다.

## 페르소나

UI Proto 하네스 설정 전문가.
CLAUDE.md에서 AGENTS.md와 중복되는 내용을 제거하고, 세션 시작 시 git 체크 지침을 추가한다.
AGENTS.md는 UI Proto에 필요한 상세 프론트엔드 섹션을 유지하되, 오래된 운영 지침은 정리한다.

---

## 전제조건

- **대상 프로젝트 루트**에서 실행 (peach-harness 자체가 아닌 대상 프로젝트)
- Frontend-Only 구조여야 함 (`src/modules*` 존재, `api/`와 `front/` 없음)

---

## Workflow

### Step 1: 현재 상태 분석

다음을 확인한다:

```bash
cat CLAUDE.md 2>/dev/null || echo "CLAUDE.md 없음"
cat AGENTS.md 2>/dev/null || echo "AGENTS.md 없음"
ls -d api/ front/ 2>/dev/null || echo "모노레포 아님"
ls -d src/modules*/ 2>/dev/null && echo "Frontend-Only UI Proto 프로젝트" || echo "src/modules*/ 없음"
ls .cursor/rules/ 2>/dev/null && echo "root cursor rules 존재" || echo "root cursor rules 없음"
ls .cursorrules 2>/dev/null && echo ".cursorrules 존재" || echo ".cursorrules 없음"
```

분석 결과를 정리:
- CLAUDE.md: 존재 여부, 현재 줄 수, AGENTS.md와 중복되는 섹션 목록
- AGENTS.md: 존재 여부, "하네스 시스템 연동" 섹션 존재 여부
- 모듈 루트: `ls -d src/modules*/` 결과를 `{모듈구조}`로 사용
- cursor rules: 존재 여부 및 파일 목록 (`.cursor/rules/`, `.cursorrules`)

### Step 2: AGENTS.md 필수 섹션 점검

AGENTS.md가 존재하는 경우, 아래 핵심 섹션이 있는지 확인한다:

```bash
grep -l "공통 원칙\|_common.*import" AGENTS.md 2>/dev/null && echo "§공통원칙 존재" || echo "§공통원칙 누락"
grep -l "프론트엔드 규칙\|computed" AGENTS.md 2>/dev/null && echo "§프론트엔드 존재" || echo "§프론트엔드 누락"
grep -l "검증\|test:run\|bunx vue-tsc" AGENTS.md 2>/dev/null && echo "§검증 존재" || echo "§검증 누락"
grep -l "하네스 시스템 연동" AGENTS.md 2>/dev/null && echo "하네스연동 존재" || echo "하네스연동 누락"
```

UI Proto에서 유지할 상세 운영 섹션:
- 기술 스택
- 모듈 구조
- UI 패턴
- Store 표준
- 타입 표준
- 핵심 원칙
- 공통 컴포넌트
- 가이드 코드

UI Proto에서 제거할 오래된 운영 섹션:
- 스킬
- 화면 유형 (gen-all)
- 컴포넌트 카탈로그
- 기획자 워크플로우

누락 섹션 발견 시 아래 references 파일을 소스로 사용한다:

| 누락 섹션 | 소스 파일 |
|----------|---------|
| 공통 원칙 | `peach-setup-ui-proto/references/common-rules.md` |
| 프론트엔드 규칙 | `peach-setup-ui-proto/references/frontend-rules.md` |
| 검증 | `peach-setup-ui-proto/references/testing-rules.md` |
| 전체 AGENTS 템플릿 | `peach-setup-ui-proto/references/example-ui-proto-agents.md` |

### Step 3: 변경 계획 생성

사용자에게 변경 계획을 제시한다:
- CLAUDE.md 정리 범위
- AGENTS.md에 추가/제거할 섹션 목록
- 삭제할 cursor rules 목록

### Step 4: 사용자 확인

변경 계획에 대해 사용자 동의를 받는다. 수정 요청이 있으면 반영한다.

### Step 5: 적용

1. **CLAUDE.md 정리 + 세션 시작 섹션 추가**
   - AGENTS.md와 중복되는 상세 규칙 제거
   - `git status && git branch` 확인 지침 추가
   - 20줄 이내 유지

2. **AGENTS.md 생성/보완**
   - AGENTS.md 없음 → `example-ui-proto-agents.md` 기반 생성
   - AGENTS.md 있음 → 필요한 섹션 보완 + 오래된 운영 섹션 제거
   - `{모듈구조}` → `ls -d src/modules*/` 결과로 치환

3. **하네스 시스템 연동 섹션 추가**
   - 세션 시작 체크리스트
   - Handoff 사용법
   - peach-help 안내

4. **cursor rules 삭제**
   - 루트 `.cursor/rules/` 디렉토리 삭제
   - 루트 `.cursorrules` 파일 삭제


### Step 6: 완료 확인

적용 결과를 출력한다:
- CLAUDE.md 변경 전/후 줄 수
- AGENTS.md 추가/업데이트된 섹션 목록
- AGENTS.md에서 제거된 오래된 운영 섹션 목록
- 삭제된 cursor rules 파일 목록


---

## AGENTS.md 원칙

- UI Proto 운영에 필요한 프론트엔드 구조 정보는 유지
- 가이드 코드와 직접 관련 없는 오래된 운영 섹션은 제거
- 한국어 응답, `_common` 경계, 타입 금지 규칙, Pinia Option API, computed 래핑, NuxtUI v4, bun 검증 명령은 반드시 유지

## CLAUDE.md 표준 템플릿

```markdown
# {프로젝트명}

{한 줄 설명}

## 규칙 참조

모든 개발 규칙은 @AGENTS.md 를 참조하라.

## 세션 시작

`git status && git branch`로 현재 상태를 확인하세요.

## 가이드 코드

코드 생성 = **가이드 코드 참조** → 도메인 분석 → Bounded Autonomy 범위 내 적응
- Frontend: `src/modules/test-data/`
```

## 완료 조건 체크리스트

- [ ] CLAUDE.md가 20줄 이내로 정리됨
- [ ] CLAUDE.md에 "세션 시작" 섹션이 포함됨
- [ ] AGENTS.md에 공통 원칙, 프론트엔드 규칙, 검증, 하네스 연동이 존재함
- [ ] AGENTS.md에 기술 스택, 모듈 구조, UI 패턴, Store 표준, 타입 표준, 핵심 원칙, 공통 컴포넌트, 가이드 코드가 반영됨
- [ ] AGENTS.md에서 스킬, 화면 유형, 컴포넌트 카탈로그, 기획자 워크플로우가 제거됨
- [ ] 루트 `.cursor/rules/` 삭제됨 (존재했던 경우)
- [ ] 루트 `.cursorrules` 삭제됨 (존재했던 경우)
