# AI 에이전트 가이드

> PeachSolution 아키텍처 기반 프로젝트용 공개 에이전트 가이드
> Backend(api/) + Frontend(front/) 모노레포 구조

---

## 1. 공통 원칙

### 기본 규칙
- 응답 언어: **한국어**
- Code-First: 문서보다 가이드 코드 참조
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.service.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |

### 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지

### 가이드 코드 위치
코드 생성 = **가이드 코드 참조** → 도메인 분석 → Bounded Autonomy 범위 내 적응
- Backend: `api/src/modules/test-data/`
- Frontend: `front/src/modules/test-data/`

---

## 2. 백엔드 규칙 (api/)

### 기술 스택
- Koa + routing-controllers 또는 Elysia (프로젝트별 자동 감지)
- sql-template-strings 또는 bunqldb (DAO)
- class-validator (Koa) / TypeBox `t` (Elysia) (Validator)
- bun:test (테스트)

### Controller 프레임워크 자동 감지

```bash
head -3 api/src/modules/test-data/controller/test-data.controller.ts
```

- `routing-controllers` → Koa 모드 (데코레이터 패턴, class-validator)
- `elysia` / `createElysia` → Elysia 모드 (체이닝 패턴, TypeBox, docs/)

### DAO 라이브러리 자동 감지

```bash
head -5 api/src/modules/test-data/dao/test-data.dao.ts
```

- `from 'bunqldb'` → 재할당 방식 (`sql\`${query} AND ...\``)
- `from 'sql-template-strings'` → append 방식 (`.append(SQL\`AND ...\``)

### 모듈 구조
```
[모듈명]/
├── controller/[모듈명].controller.ts, [모듈명].validator.ts
├── service/[모듈명].service.ts
├── dao/[모듈명].dao.ts
├── type/[모듈명].type.ts
└── test/[모듈명].test.ts
```

### 표준 메서드명
| Controller | Service/DAO |
|------------|-------------|
| getAll, getOne | findPaging, findList, findOne |
| insert, update | insert, update |
| updateUse, softDelete, hardDelete | updateUse, softDelete, hardDelete |

### DB 규칙
- Boolean: `CHAR(1)` Y/N
- 금액: `DECIMAL(14,0)`
- PK: `seq`
- 감사 칼럼: `is_use`, `is_delete`, `insert_seq`, `insert_date`, `update_seq`, `update_date`
- 스키마 확인: `db/schema/[테이블명].sql`
- 표준 타입: `[테이블명]`, `[테이블명]PagingDto`, `[테이블명]InsertDto`, `[테이블명]UpdateDto`

### 핵심 원칙
- Service: **static 메서드**
- DAO: **sql-template-strings** 또는 **bunqldb**
- Controller: **routing-controllers** 또는 **Elysia**
- Validator: **class-validator** 또는 **TypeBox**
- 파일 업로드: `_common/file` 사용 (common 모듈 금지)
- 에러: 기능오류 → HTTP 200 + `{success:false}` | 시스템예외 → `ErrorHandler`

### 에러 처리 전략

```typescript
// 기능적 오류: HTTP 200 + JSON 응답
return {
  success: false,
  code: 'AUTH_FAILED',
  message: '비밀번호가 일치하지 않습니다.'
};

// 시스템 오류: ErrorHandler 사용
if (!user) {
  throw new ErrorHandler(404, '사용자를 찾을 수 없습니다.');
}
```

### Bun SQL / bunqldb 사용 패턴

```typescript
import { sql, DB } from 'src/utils/db/db';

// 재할당 방식 (bunqldb)
let query = sql`SELECT * FROM users WHERE 1=1`;
if (status) {
  query = sql`${query} AND status = ${status}`;
}
const result = await DB.many<User>(query);

// 페이징
const result = await DB.paginateSql<User>(
  sql`SELECT * FROM users ORDER BY seq DESC`,
  { page: 1, row: 10 }
);
```

### 품질 검증
```bash
bun start                  # 서버 실행
bun test                   # 테스트
bun run lint:fixed         # 린트
bun run db:up-dev          # 마이그레이션 적용
```

---

## 3. 프론트엔드 규칙 (front/)

### 기술 스택
- Vue 3 + Vite + Pinia
- NuxtUI v3 + TailwindCSS v4
- Yup (유효성 검증)
- Vitest (테스트)

### 모듈 구조
```
[모듈명]/
├── pages/list.vue, list-search.vue, list-table.vue, detail.vue, insert.vue, update.vue
├── store/[모듈명].store.ts
├── type/[모듈명].type.ts
└── [모듈명].routes.ts
```

### UI 패턴
| 패턴 | 설명 | 참고 |
|------|------|------|
| crud | 독립 페이지 (목록/상세/등록/수정) | `pages/crud/` |
| two-depth | 좌우 분할 (좌:목록, 우:상세+탭) | `pages/two-depth/` |
| select-list | 모달 선택 (단일/다중) | `pages/select-list/` |

### Store 표준 (Pinia Option API)
- 상태: `listParams`, `listData`, `listTotalRow`, `detailData`
- 액션: `paging()`, `list()`, `detail()`, `insert()`, `update()`, `updateUse()`, `softDelete()`
- 표준 타입: `[모듈명]`, `[모듈명]SearchDto`, `[모듈명]PagingDto`, `[모듈명]InsertDto`, `[모듈명]UpdateDto`

### 핵심 원칙
- **Composition API**: `<script setup>` 필수
- **Store 경유**: 모든 API는 Store 통해 호출
- **Yup 검증**: 유효성 검증 필수
- **반응형**: 모바일/데스크톱 지원
- 파일 업로드: `_common/components/file/` 사용 (common 모듈 금지)
- UI 컴포넌트: NuxtUI 우선 (`UFormField`, `UModal`, `USwitch`, `UTabs`, `UBadge`, `EasyDataTable`)

### _common 래퍼 컴포넌트 우선 사용
대상 프로젝트에 `_common/components/` 디렉토리가 존재하면, NuxtUI 직접 사용보다 래퍼 컴포넌트를 우선 사용합니다.

```bash
ls front/src/modules/_common/components/
# p-input-box, p-nuxt-select, p-file-upload 등 존재 여부 확인
```

| NuxtUI | _common 래퍼 (있는 경우 우선) |
|--------|------------------------------|
| `<UInput>` | `<p-input-box>` |
| `<USelect>` | `<p-nuxt-select>` |
| `<UFormField>` | `<p-form-field>` |

### TailwindCSS 클래스 그룹핑
5개 이상 클래스 시 배열 기반 그룹핑:
```html
<input
  :class="[
    'block flex w-full h-full px-3 py-1.5',
    'text-base text-gray-900 rounded-xs border',
    'placeholder:text-gray-400 focus:outline-indigo-200',
  ]"
/>
```

### Store Computed 래핑 규칙
```vue
<!-- 잘못된 방법 -->
<p>{{ store.detailData.name }}</p>

<!-- 올바른 방법 -->
<script setup>
const detail = computed(() => store.detailData);
</script>
<template>
  <p>{{ detail.name }}</p>
</template>
```

### 품질 검증
```bash
bun run dev           # 서버 실행
npx vitest run        # 테스트
npx vue-tsc --noEmit  # 타입 체크
bun run lint:fix      # 린트
bun run build         # 빌드
```

---

## 4. 스킬 개발 규칙

### SKILL.md frontmatter 필수 필드
```yaml
---
name: peach-[스킬명]
description: |
  한 줄 설명 (트리거 키워드 포함)
---
```

### 스킬 네이밍 규칙
- 접두어: `peach-` 필수
- 형식: `peach-[동사]-[대상]` (예: `peach-gen-backend`, `peach-add-api`)
- 팀 스킬: `peach-agent-[대상]` (예: `peach-agent-team`, `peach-agent-team-refactor`)

### skills.sh 호환 설치
```bash
npx skills add peachSolution/peach-harness --skill [스킬명] -a claude-code
```

### references 정책
- 스킬 내부 `references/` 폴더: 스킬별 상세 가이드
- 조건부 참조: 필요한 참조만 로드 (토큰 절약)
- 외부 프로젝트 파일 직접 참조 금지 (설치 후 대상 프로젝트 경로 안내로 대체)

### 버전 관리 규칙

#### 버전 파일
두 파일의 version을 **항상 동일하게** 유지한다. 불일치 시 auto update가 실패한다.

- `.claude-plugin/marketplace.json` → `plugins[0].version`
- `.claude-plugin/plugin.json` → `version`

#### Semver 기준

| 변경 유형 | 버전 | 예시 |
|----------|------|------|
| **patch** (x.x.+1) | 문서 수정, 오타, 버그 수정 | SKILL.md 오류 수정, 참조 경로 수정 |
| **minor** (x.+1.0) | 스킬/에이전트 추가, 기존 기능 개선 | 새 스킬 추가, 에이전트 로직 변경 |
| **major** (+1.0.0) | 하위호환 파괴, 구조 변경 | 배포 구조 변경, 스킬 인터페이스 변경 |

#### 버전 업데이트 시점
- **커밋 단위가 아닌 릴리스 단위**로 버전을 올린다
- **develop 브랜치에서** 버전을 업데이트한다 (main은 머지만)

#### 버전 업데이트 절차
1. develop에서 작업 완료
2. develop에서 두 파일의 version을 동시에 업데이트
3. 커밋 메시지: `Release v{버전}` (예: `Release v1.1.0`)
4. main에 머지 (`git merge develop --no-ff`) 후 push

---

## 5. AI 자율성 허용 범위 (Bounded Autonomy)

AI는 가이드 코드(test-data)를 기준으로 삼되, 아래 규칙에 따라 제한된 자율성을 가진다.

### 5-1. Must Follow (절대 준수)

아래 영역은 AI가 변경하면 안 된다.

- 모듈 경계 규칙 (`_common`만 import, 타 모듈 import 금지)
- 네이밍 규칙 (snake_case/kebab-case/PascalCase/camelCase)
- 타입 원칙 (옵셔널 금지, null/undefined 금지)
- 보안 규칙 (SQL injection, XSS, OWASP top 10 방지)
- 공통 에러 처리 원칙 (기능오류 → 200+success:false, 시스템예외 → ErrorHandler)
- 테스트 통과 기준 (bun test / vitest)
- lint/build 통과 기준
- QA 재검증 요구

### 5-2. May Adapt (분석 후 보완 가능)

아래 영역은 AI가 분석 후 보완할 수 있다.

- service 메서드 분리 방식
- DAO 내부 쿼리 구성의 세부 형태
- validator 구조의 세부 배치
- UI 상호작용 흐름
- 문서 보완 방식
- 코드 가독성 및 성능 개선

### 5-3. Adapt 조건

AI가 가이드 코드와 다르게 생성하려면 다음 4가지를 모두 만족해야 한다.

1. 왜 다른 구조가 필요한지 설명할 수 있어야 한다
2. Must Follow를 침범하면 안 된다
3. 결과가 test/lint/build/QA를 통과해야 한다
4. 차이점과 이유를 세션 기록에 남겨야 한다

---

## 6. 테스트 및 품질

- 새로운 Service 로직에는 **bun test 기반 TDD** 테스트 포함
- 테스트는 실제 데이터베이스 사용, 모킹 지양
- 작업 후 린트/타입체크/빌드 확인

### 테스트 필수 설정 (Backend)
```typescript
describe('Domain Service', () => {
  beforeAll(async () => {
    Server.setEnv();
    await Server.externalModule();
  }, 30000);

  afterAll(async () => {
    await DB.close();
  }, 10000);
});
```

---

## 7. Validator / 타입 규칙

### Validator 작성 (class-validator)
- DB 컬럼이 null 허용이면 `@IsOptional` 적용
- 주석은 필드 왼쪽에 배치
- 주요 데코레이터: `@IsNotEmpty()`, `@IsString()`, `@IsNumber()`, `@IsEmail()`, `@IsOptional()`

### 타입 인터페이스 구조
```typescript
export interface Example {
  // 비즈니스 필드
  seq: number;
  name: string;

  // 감사 필드
  isDelete: string;
  insertSeq: number;
  insertDate: string;
  updateSeq: number;
  updateDate: string;

  // 파일 필드
  fileList: any[];
}
```

### 필드 배치 순서
1. 비즈니스 필드
2. 감사 필드 (`isView`, `isUse`, `isDelete`, `insertSeq`, `insertDate`, `updateSeq`, `updateDate`)
3. 파일 필드 (`fileList`, `imageList`)

---

## 8. 스킬 목록

| 스킬 | 용도 | 팀 역할 |
|------|------|---------|
| `peach-ask` | 하네스 시스템 안내 (스킬 추천, 워크플로우 안내) | - |
| `peach-gen-prd` | PRD 문서 생성 (대화형 요구사항 수집) | - |
| `peach-gen-db` | DB DDL/마이그레이션 생성 | - |
| `peach-gen-backend` | Backend API 생성 (bun test 필수) | backend-dev |
| `peach-gen-store` | Frontend Store 생성 (vue-tsc 필수) | store-dev |
| `peach-gen-ui` | Frontend UI 생성 (vue-tsc/lint/build 필수) | ui-dev |
| `peach-gen-ui-proto` | UI 프로토타입 생성 (Mock 데이터 기반, 기획자용) | ui-dev |
| `peach-gen-design` | 디자인 시스템 컨설팅 | ui-dev |
| `peach-gen-feature-docs` | 기존 기능 개선 전 as-is 분석 문서 생성 | - |
| `peach-add-api` | 외부 REST API 호출 코드 생성 | - |
| `peach-add-cron` | Cron 작업 코드 생성 | - |
| `peach-add-print` | 인쇄 전용 페이지 생성 | - |
| `peach-refactor-backend` | Backend 리팩토링 | refactor-backend |
| `peach-refactor-frontend` | Frontend 리팩토링 | refactor-frontend |
| `peach-agent-team` | 신규 기능 팀 조율 (mode=backend/ui/fullstack) | 오케스트레이터 |
| `peach-agent-team-refactor` | 리팩토링 팀 조율 (layer=backend/frontend/all) | 오케스트레이터 |
| `peach-planning-gate` | 작업 시작 전 계획 수립 게이트 | - |
| `peach-evidence-gate` | 작업 완료 전 증거 수집 게이트 (팀 스킬 완료 시 자동 후속 호출) | - |
| `peach-handoff` | 세션 간 컨텍스트 인수인계 | - |

### 스킬 유형 분류

| 유형 | 스킬 | 테스트 전략 |
|------|------|-----------|
| 능력 향상형 (4) | gen-design, gen-prd, gen-feature-docs, ask | 새 모델 시 A/B 테스트 |
| 선호도 인코딩형 (12) | gen-backend, gen-db, gen-store, gen-ui, gen-ui-proto, add-api, add-cron, add-print, refactor-backend, refactor-frontend, agent-team, agent-team-refactor | Eval 충실도 검증 |
| 프로세스 게이트 (3) | planning-gate, evidence-gate, handoff | 워크플로우 품질 게이트 |

### 에이전트 팀원 역할

| 에이전트 | 역할 | 담당 스킬 |
|---------|------|---------|
| backend-dev | Backend API 개발 | peach-gen-backend |
| backend-qa | Backend QA 검증 | 검증 전용 |
| store-dev | Frontend Store 개발 | peach-gen-store |
| ui-dev | Frontend UI + 디자인 (FigmaRemote MCP) | peach-gen-ui + peach-gen-ui-proto + peach-gen-design |
| frontend-qa | Frontend QA 검증 | 검증 전용 |
| refactor-backend | Backend 리팩토링 | peach-refactor-backend |
| refactor-frontend | Frontend 리팩토링 | peach-refactor-frontend |

---

## 9. 완전 독립 도메인 구현

**"관리되는 독립성(Governed Independence)"** - 결합은 부채, 중복은 비용. 부채를 피하기 위해 통제 가능한 비용을 선택.

### 완전 독립성 체크리스트
- 다른 도메인의 DAO를 직접 호출하지 않음
- 필요한 모든 쿼리가 자체 DAO에 구현됨
- 다른 도메인의 서비스를 직접 호출하지 않음
- 다른 도메인의 타입을 import하지 않음

---

## 10. 서브에이전트 활용

### 스킬과 서브에이전트의 역할 분리

- **스킬** (SKILL.md): 오케스트레이터. 실행 절차를 정의하고 팀을 조율한다.
- **서브에이전트** (agents/*.md): 역할 실행자. 독립 컨텍스트에서 특정 작업을 수행한다.

### 서브에이전트 목록

| 에이전트 | 파일 | 역할 |
|---------|------|------|
| backend-dev | agents/backend-dev.md | Backend API 생성 |
| backend-qa | agents/backend-qa.md | Backend QA 검증 (읽기전용) |
| store-dev | agents/store-dev.md | Frontend Store 생성 |
| ui-dev | agents/ui-dev.md | Frontend UI 생성 |
| frontend-qa | agents/frontend-qa.md | Frontend QA 검증 (읽기전용) |
| refactor-backend | agents/refactor-backend.md | Backend 리팩토링 |
| refactor-frontend | agents/refactor-frontend.md | Frontend 리팩토링 |

### QA 에이전트 격리 원칙

- QA 에이전트(backend-qa, frontend-qa)는 **읽기전용**으로 실행한다.
- `isolation: worktree` 옵션으로 독립 작업 트리에서 검증한다.
- 구현 에이전트와 컨텍스트를 공유하지 않아 확증 편향을 방지한다.

### 자기완결적 스킬 원칙

팀 스킬은 `agents/` 디렉토리 없이도 완전하게 동작해야 한다. (멀티 AI 도구 지원)

- **`agents/*.md`**: Source of truth. Claude Code 네이티브 서브에이전트가 직접 참조한다.
- **`skills/*/references/*-agent.md`**: 팀 스킬 자기완결성을 위한 복사본. `agents/`를 인식하지 못하는 AI 도구에서 사용된다.
- **에이전트 정의 변경 시**: `agents/*.md`와 해당 `references/*-agent.md` 양쪽을 모두 업데이트한다.

| 파일 | 역할 | 사용 주체 |
|------|------|----------|
| `agents/backend-dev.md` | Source of truth | Claude Code, Codex CLI |
| `skills/peach-agent-team/references/backend-dev-agent.md` | 복사본 | Cursor, Copilot 등 |

---

## 11. Ralph Loop 규칙

### 정의

Ralph Loop(Vercel Labs)은 Agent → Verifier → Feedback Injection → Safety Limit 구조의 반복 검증 패턴이다.
단순 retry와 달리 구조화된 피드백을 주입하여 같은 실수를 반복하지 않는다.

### 에스컬레이션 단계

| 반복 횟수 | 단계 | 행동 |
|----------|------|------|
| 1~3회 | 자율 수정 | QA 피드백만으로 수정 |
| 4~7회 | 가이드 재참조 | test-data 기준골격 전체 재읽기 |
| 8~10회 | 최소 수정 | Must Follow만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

### 적용 원칙

- 모든 팀 스킬(peach-agent-team, peach-agent-team-refactor)에서 QA 실패 시 Ralph Loop를 적용한다.
- 에스컬레이션 도달 시 handoff 파일에 Ralph Loop 이력을 기록한다.
