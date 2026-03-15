---
name: peach-setup-harness
description: |
  대상 프로젝트에 피치 하네스 시스템을 설정합니다. CLAUDE.md를 최소 진입점으로 정리하고, AGENTS.md에 하네스 운영 지침(세션 시작 handoff 체크, 스킬 카탈로그 참조)을 추가합니다.
  Use when: "하네스 설정", "프로젝트 초기 설정", "CLAUDE.md 정리", "AGENTS.md 업데이트", "세션 시작 설정", "handoff 설정" 키워드.
---

# peach-setup-harness — 하네스 시스템 설정

대상 프로젝트의 CLAUDE.md와 AGENTS.md를 하네스 시스템에 맞게 설정한다.
CLAUDE.md는 20줄 이내 최소 진입점, AGENTS.md는 상세 규칙 원칙.

## 페르소나

하네스 시스템 설정 전문가.
CLAUDE.md에서 AGENTS.md와 중복되는 내용을 제거하고, 세션 시작 시 handoff 체크 지침을 추가한다.

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
```

분석 결과를 정리:
- CLAUDE.md: 존재 여부, 현재 줄 수, AGENTS.md와 중복되는 섹션 목록
- AGENTS.md: 존재 여부, "하네스 시스템 연동" 섹션 존재 여부
- docs/handoff/: 존재 여부
- 프로젝트 유형: api/+front/ 모노레포, 단독 api/, 단독 front/, 기타

### Step 2: 변경 계획 생성

사용자에게 변경 계획을 제시한다:

**CLAUDE.md 변경:**
- 제거할 중복 섹션 (AGENTS.md에 이미 있는 내용)
- 추가할 "세션 시작" 섹션
- 최종 예상 줄 수

**AGENTS.md 변경:**
- 추가할 "하네스 시스템 연동" 섹션

**기타:**
- docs/handoff/ 디렉토리 생성 필요 여부

### Step 3: 사용자 확인

변경 계획에 대해 사용자 동의를 받는다. 수정 요청이 있으면 반영한다.

### Step 4: 적용

승인 후 변경을 적용한다:

1. **CLAUDE.md 정리 + "세션 시작" 섹션 추가**
   - AGENTS.md와 중복되는 섹션 제거
   - 프로젝트별 고유 지침은 보존 (Electron IPC, 특수 설정 등)
   - "세션 시작" 섹션 추가
   - 20줄 이내 유지

2. **AGENTS.md에 "하네스 시스템 연동" 섹션 추가**
   - 기존 마지막 섹션 번호 확인 후 다음 번호로 추가

3. **docs/handoff/ 디렉토리 생성** (없는 경우)
   - `.gitkeep` 파일 생성

### Step 5: 완료 확인

적용 결과를 출력한다:
- CLAUDE.md 변경 전/후 줄 수
- AGENTS.md 추가된 섹션
- docs/handoff/ 생성 여부

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
- "가이드 코드" 섹션은 모노레포(api/+front/)인 경우에만 포함

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
전체 스킬 목록과 워크플로우는 `/peach-harness-help`를 실행하라.
```

---

## 완료 조건 체크리스트

- [ ] CLAUDE.md가 20줄 이내로 정리됨
- [ ] CLAUDE.md에 "세션 시작" 섹션이 포함됨
- [ ] CLAUDE.md에서 AGENTS.md 중복 내용이 제거됨
- [ ] AGENTS.md에 "하네스 시스템 연동" 섹션이 추가됨
- [ ] docs/handoff/ 디렉토리가 존재함
- [ ] 프로젝트별 고유 지침이 보존됨
