# Koa 프로젝트 AGENTS.md 예시

> peach-setup-harness Source of Truth — Koa(routing-controllers) 프로젝트의 정제된 AGENTS.md 템플릿

---

```markdown
# {프로젝트명} - AI 에이전트 가이드

> Backend(api/) + Frontend(front/) 모노레포

---

## 1. 공통 원칙

- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지
- 타입 규칙: 옵셔널(`?`)/`null`/`undefined` 금지
- 가이드 코드: `api/src/modules/test-data/` · `front/src/modules/test-data/`

---

## 2. 백엔드 규칙 (api/)

기술 스택: Bun · Koa + routing-controllers · bunqldb · class-validator · Biome

→ 가이드 코드 `api/src/modules/test-data/` 참조

**추론 불가 규칙:**
- Service: static 메서드
- DB PK: `int` 자동증가, 접미사 `seq` (예: `member_seq`)
- DB 감사 칼럼: `is_use`, `is_delete`, `insert_seq`, `insert_date`, `update_seq`, `update_date`
- DB Boolean: `CHAR(1)` Y/N · 금액: `DECIMAL(14,0)`
- 에러: 기능오류 → HTTP 200 + `{success:false}` | 시스템예외 → `ErrorHandler`
- 파일 업로드: `_common/file` 사용

품질 검증: `bun start && bun test && bun run lint:fixed`

---

## 3. 프론트엔드 규칙 (front/)

기술 스택: Vue 3 · Pinia · NuxtUI v4 · TailwindCSS v4 · Vitest · ESLint

→ 가이드 코드 `front/src/modules/test-data/` 참조

**추론 불가 규칙:**
- `<script setup lang="ts">` 필수
- Store: Pinia Option API, `isLoading`/`error` 상태 금지
- Store 값은 반드시 `computed()`로 래핑
- 모든 API는 Store 통해 호출
- 5개 이상 TailwindCSS 클래스 → 배열 그룹화

품질 검증: `bun run dev && bun run test && npx vue-tsc --noEmit && bun run lint:fix && bun run build`

---

## 4. 테스트 및 품질

- Service 로직: bun test 기반 TDD 필수, 실제 DB 사용, 모킹 금지
- 모든 테스트 100% 성공 필수

Koa 테스트 설정: `api/src/modules/test-data/test/test-data.test.ts` 참조
- `await Server.externalModule()` 필수 (30000ms timeout)
- `afterAll: await DB.close()`

Frontend 테스트 설정: `VitestSetup.initializeTestEnvironment()` + `VitestSetup.sign('test', 'test!%#')`

---

## 5. Validator (class-validator)

→ `api/src/modules/test-data/controller/test-data.validator.ts` 참조

필드 배치 순서: 비즈니스 필드 → 감사 필드 → 파일 필드

---

## 6. 완전 독립 도메인

다른 도메인의 DAO/Service/타입 import 금지. 필요한 모든 쿼리는 자체 DAO에 구현.

---

## 7. 하네스 시스템 연동

### 세션 시작
1. `docs/handoff/` 디렉토리의 최신 파일 확인
2. 미완료 작업이 있으면 요약 출력
3. `git status && git branch` 확인

### Handoff 사용법
- 세션 종료 시: `/peach-handoff` → save 모드
- 세션 시작 시: `/peach-handoff` → load 모드
- 저장 위치: `docs/handoff/{년}/{월}/[YYMMDD]-[한글기능명].md`

전체 스킬 목록과 워크플로우: `/peach-help`
```
