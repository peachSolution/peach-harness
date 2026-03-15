# Frontend-Only 프로젝트 AGENTS.md 예시

> peach-setup-harness Source of Truth — Frontend-Only(ui-proto) 프로젝트의 정제된 AGENTS.md 템플릿
>
> `{모듈구조}` 플레이스홀더를 `ls -d src/modules*/`로 감지된 실제 디렉토리 목록으로 치환한다.

---

```markdown
# {프로젝트명} - AI 에이전트 가이드

> Frontend-Only 프로젝트 (api/ 없음)

---

## 1. 공통 원칙

- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- 타입 규칙: 옵셔널(`?`)/`null`/`undefined` 금지
- 가이드 코드: `src/modules/test-data/`

모듈 디렉토리: {모듈구조}

---

## 2. 프론트엔드 규칙 (src/)

기술 스택: Vue 3 · TypeScript · NuxtUI v4 · Pinia · TailwindCSS v4

→ 가이드 코드 `src/modules/test-data/` 참조

**추론 불가 규칙:**
- `<script setup>` 필수
- Pinia Option API (Setup 스타일 금지)
- Store computed 래핑: 컴포넌트에서 `store.list` 직접 사용 금지 → `computed(() => store.list)`
- isLoading 금지: UButton의 `loading` 속성 사용
- NuxtUI 컴포넌트 우선, Headless UI 직접 사용 금지

**AI Slop 금지:**
- 그라데이션 남용 금지 (브랜드 색상 외)
- 과도한 box-shadow, border-radius 금지
- 무의미한 애니메이션 금지

---

## 3. Mock 데이터 전략

API 없이 동작하는 프로토타입 UI를 생성한다.

- Mock 데이터는 Store 내부에 정의 (`state()` 초기값)
- `actions`에서 실제 API 호출 없이 Mock 데이터 반환
- Mock 구조는 실제 API 응답 형식과 동일하게 유지 (추후 연동 용이)
- `useMockDelay()` 패턴으로 비동기 흐름 시뮬레이션

---

## 4. 검증

```bash
# 타입 검사
vue-tsc --noEmit

# Lint
npx eslint src/ --ext .ts,.vue

# 빌드
bun run build
```

---

## 5. 하네스 시스템 연동

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
