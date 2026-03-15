# Elysia 프로젝트 AGENTS.md 예시

> peach-setup-harness Source of Truth — Elysia 프로젝트의 정제된 AGENTS.md 템플릿

---

```markdown
# {프로젝트명} - AI 에이전트 가이드

> Bun + Elysia 기반 API 서버와 Vue 3 프론트엔드 모노레포

---

## 1. 공통 원칙

- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지
- 타입 규칙: 옵셔널(`?`)/`null`/`undefined` 금지
- 가이드 코드: `api/src/modules/test-data/` · `front/src/modules/test-data/`

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블/칼럼 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.service.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |

---

## 2. 백엔드 규칙 (api/)

기술 스택: Bun · Elysia · bunqldb · TypeBox(`t`) · Biome

→ 가이드 코드 `api/src/modules/test-data/` 참조

**추론 불가 규칙:**
- Plugin System: `response.plugin.ts`가 성공 응답 자동 래핑 → Controller에서 try-catch 금지, 수동 success 래핑 금지
- 에러: `throw new ErrorHandler(상태코드, '메시지')` 만 사용
- 모든 엔드포인트: `docs/[module].docs.ts`로 API 문서화 필수
- 환경변수: `process.env.*` 사용 (`Bun.env.*` 금지)
- Bun Native API 우선: 파일은 `Bun.write/Bun.file`, 암호화는 `Bun.password.*`
- DB PK: `int auto_increment`, 접미사 `seq`
- 소프트 삭제: `is_delete` 컬럼
- 로그: 비즈니스 로직에서 info 로깅 금지, `ErrorHandler`만 사용

품질 검증: `bun test && bun run build && bun run lint:fixed`
DB 명령: `bun run db:up-dev` · `bun run db:down-dev` · `bun run db:extract-schema`

---

## 3. 프론트엔드 규칙 (front/)

기술 스택: Vue 3 · Pinia · NuxtUI v4 · TailwindCSS v4 · Vitest · ESLint

→ 가이드 코드 `front/src/modules/test-data/` 참조

**추론 불가 규칙:**
- `<script setup lang="ts">` 필수
- Store: Pinia Option API, `isLoading`/`error` 상태 금지, try-catch 금지
- Store 값은 반드시 `computed()`로 래핑
- 모든 API는 Store 통해 호출
- 5개 이상 TailwindCSS 클래스 → 배열 그룹화

품질 검증: `bun run test && bunx vue-tsc --noEmit && bun run build && bun run lint`

---

## 4. 테스트 및 품질

- Service 로직: bun test 기반 TDD 필수, 실제 DB 사용, 모킹 금지
- 모든 테스트 100% 성공 필수

Elysia 테스트 설정: `api/src/modules/test-data/test/test-data.test.ts` 참조
- `Server.externalModule()` — await 없음 (Elysia 방식)

Frontend 테스트 설정: `VitestSetup.initializeTestEnvironment()` + `VitestSetup.sign('test', 'test!%#')`

---

## 5. Validator (TypeBox)

→ `api/src/modules/test-data/controller/test-data.validator.ts` 참조

필드 배치 순서: 비즈니스 필드 → 감사 필드 → 파일 필드

---

## 6. 완전 독립 도메인

다른 도메인의 DAO/Service/타입 import 금지. 필요한 모든 쿼리는 자체 DAO에 구현.

---

## 7. 하네스 시스템 연동

### 세션 시작
1. `git status && git branch` 확인
2. 미완료 작업이 있으면 `docs/spec/` 또는 `git log`로 컨텍스트 파악

전체 스킬 목록과 워크플로우: `/peach-help`
```
