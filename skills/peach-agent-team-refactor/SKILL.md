---
name: peach-agent-team-refactor
description: Use when refactoring existing PeachSolution backend or frontend modules into the test-data pattern while preserving behavior and coordinating independent QA.
---

# Peach Agent Team Refactor

## Overview

PeachSolution 레거시 모듈을 `test-data` 패턴으로 변환하는 리팩토링 전용 팀 스킬입니다.

기존 `team-refactor`를 대체하며, backend/frontend 역할 정의와 QA 절차를 이 문서 안에 포함합니다.

## Inputs

```bash
/peach-agent-team-refactor [모듈명] layer=backend|frontend|all [옵션]

# 옵션
# file=Y|N
# ui=crud|two-depth|select-list
# tdd=Y|N
```

## Preconditions

- 리팩토링 대상 모듈이 존재해야 합니다.
- Backend 리팩토링 시 DB 스키마가 존재해야 합니다.
- 기능 변경이 아니라 구조 정리만 수행합니다.

## Orchestration

### 1. 환경 확인

```bash
# 레거시 모듈 존재 확인
ls api/src/modules/[모듈명]/
ls front/src/modules/[모듈명]/

# DAO 라이브러리 감지 (중요!)
head -5 api/src/modules/test-data/dao/test-data.dao.ts
# from 'bunqldb' → 재할당 방식 (sql`${query} AND ...`)
# from 'sql-template-strings' → append 방식 (.append(SQL`AND ...`))

# Controller 프레임워크 감지
head -3 api/src/modules/test-data/controller/test-data.controller.ts
# routing-controllers → Koa / elysia / createElysia → Elysia

# DB 스키마 확인
ls api/db/schema/
```

### 2. 팀 구성 다이어그램

**layer=all**
```
refactor-backend ──→ backend-qa        (병렬)
         │
         └──→ refactor-frontend ──→ frontend-qa
```

**layer=backend**
```
refactor-backend ──→ backend-qa
```

**layer=frontend**
```
refactor-frontend ──→ frontend-qa
```

### 3. 팀 생성

```
TeamCreate: team_name="[모듈명]-refactor-team"

# layer=all
TaskCreate:
1. "Backend 리팩토링" (owner: refactor-backend)
2. "Backend QA 검증" (blockedBy: Task1, owner: backend-qa)
3. "Frontend 리팩토링" (blockedBy: Task1, owner: refactor-frontend)
4. "Frontend QA 검증" (blockedBy: Task3, owner: frontend-qa)

# layer=backend
TaskCreate:
1. "Backend 리팩토링" (owner: refactor-backend)
2. "Backend QA 검증" (blockedBy: Task1, owner: backend-qa)

# layer=frontend
TaskCreate:
1. "Frontend 리팩토링" (owner: refactor-frontend)
2. "Frontend QA 검증" (blockedBy: Task1, owner: frontend-qa)
```

## 역할별 지시

#### refactor-backend
- `peach-refactor-backend` 기준으로 type/dao/service/controller/test를 정리합니다.
- **DAO 라이브러리 분기**:
  - `bunqldb` 감지 시: 재할당 방식 (`sql\`${query} AND field = ${val}\``)
  - `sql-template-strings` 감지 시: append 방식 (`.append(SQL\`AND field = ${val}\``)
- 기존 기능은 유지하고 구조만 개선합니다.
- 4단계 리팩토링 순서: Type → DAO → Service/Controller → TDD
- 완료 기준: `bun test`, `bun run lint:fixed`, `bun run build`

#### backend-qa
- 리팩토링 후 구조, 패턴, 테스트, 빌드를 검증합니다.
- `test-data` 패턴 준수 여부를 확인합니다.
- **QA 체크리스트 (7항목)**:
  1. `type/`, `dao/`, `service/`, `controller/`, `test/` 구조 존재
  2. Service static 메서드 규칙 준수
  3. FK 제약조건 없음
  4. `bun test` 통과
  5. `bun run lint:fixed` 통과
  6. `bun run build` 성공
  7. 기능 100% 보존 확인

#### refactor-frontend
- `peach-refactor-frontend` 기준으로 type/store/pages/modals를 정리합니다.
- URL watch 패턴, Composition API, Pinia Option API를 강제합니다.
- 3단계 리팩토링 순서: Type & Store → Pages → Modals
- 완료 기준: `npx vue-tsc --noEmit`, `bun run lint:fix`, `bun run build`

#### frontend-qa
- 파일 구조, watch 패턴, UI 패턴, 빌드 결과를 검증합니다.
- 금지된 UI 패턴과 타입 규칙 위반 여부를 확인합니다.
- **QA 체크리스트 (8항목)**:
  1. 파일 구조 (pages/, modals/, store/, type/) 존재
  2. Composition API (`<script setup>`) 패턴 준수
  3. Pinia Option API Store 패턴 준수
  4. URL watch 패턴 적용 여부
  5. `listAction`, `resetAction`, `listMovePage` 함수 존재
  6. `npx vue-tsc --noEmit` 통과
  7. `bun run lint:fix` 통과
  8. `bun run build` 성공 + AI Slop 제거 확인

## Ralph Loop (반복 검증 메커니즘)

QA 실패 시 **Ralph Loop**(Vercel Labs) 패턴으로 구조화된 피드백을 주입한다.

### 에스컬레이션 단계

| 반복 횟수 | 단계 | 행동 |
|----------|------|------|
| 1~3회 | 자율 수정 | QA 피드백만으로 코드 수정 |
| 4~7회 | 가이드 재참조 | test-data 기준골격 전체 재읽기 후 수정 |
| 8~10회 | 최소 수정 | Must Follow 항목만 집중, 나머지 보류 |
| 11+ | 중단 | 사용자 에스컬레이션 |

### 적용 방식

- Backend QA 실패 → refactor-backend 수정 → backend-qa 재검증 (SendMessage)
- Frontend QA 실패 → refactor-frontend 수정 → frontend-qa 재검증

### 에스컬레이션 보고

```
## Ralph Loop 에스컬레이션
- 모듈: [모듈명]
- 반복: N/10회
- 단계: [현재 단계]
- 미해결: [위반 항목]
- 권장: [수동 개입 사항]
```

## Completion

기능 100% 보존과 QA 통과가 모두 확인되어야 완료입니다.

```
SendMessage(shutdown_request) → 모든 팀원에게
TeamDelete → 팀 정리
```

## 완료 보고 형식

```
✅ 리팩토링 팀 작업 완료

모듈: [모듈명]
layer: [all|backend|frontend]

결과:
✅ refactor-backend: Backend 리팩토링 완료
✅ backend-qa: TDD X개 통과
✅ refactor-frontend: Frontend 리팩토링 완료
✅ frontend-qa: vue-tsc + lint + build 통과

리팩토링된 파일:
Backend:
├── api/src/modules/[모듈명]/type/
├── api/src/modules/[모듈명]/dao/
├── api/src/modules/[모듈명]/service/
├── api/src/modules/[모듈명]/controller/
└── api/src/modules/[모듈명]/test/

Frontend:
├── front/src/modules/[모듈명]/type/[모듈명].type.ts
├── front/src/modules/[모듈명]/store/[모듈명].store.ts
├── front/src/modules/[모듈명]/pages/
└── front/src/modules/[모듈명]/modals/

변경 요약:
- [레거시 패턴 → 신규 패턴 목록]
- [제거된 AI Slop 항목]
- [개선된 구조 설명]
```

## Examples

```bash
# 전체 리팩토링
/peach-agent-team-refactor notice-board layer=all

# Backend만 리팩토링
/peach-agent-team-refactor product-manage layer=backend tdd=Y

# Frontend만 리팩토링
/peach-agent-team-refactor member-data layer=frontend ui=two-depth
```
