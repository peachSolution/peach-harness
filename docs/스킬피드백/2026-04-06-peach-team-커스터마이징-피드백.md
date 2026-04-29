---
status: completed
target_skill: peach-team, peach-gen-backend, peach-gen-store, peach-gen-ui, peach-setup-project
severity: 높음 4 / 중간 2 / 낮음 0
completed_at: 2026-04-06
applied_by: 사용자 직접 반영
---

# 스킬 커스터마이징 가이드

> 작성일: 2026-04-06
> 최종 수정일: 2026-04-06
> 목적: 스킬 체계의 역할 분리 의사결정 기록 + 프로젝트별 커스터마이징 참조 가이드
> **작성 근거**: peach-team으로 실제 클라이언트 프로젝트 개발 후 발견된 개선/보완 사항

---

## 0. 의사결정 기록

### 배경

peach-harness 스킬로 실제 클라이언트 프로젝트들을 개발하면서
스킬에 반영되지 않은 프로젝트 구성 패턴들이 발견되었다.

- modules 분리 구조 (modules-domain/, modules-external/ 등)
- `_common/` 기본 구성 (constants, file, log)
- 프로젝트 상수 import, @Transactional 제한적 사용, 주석 필수 항목
- 서브에이전트가 references를 참조하지 못하는 구조적 문제

### 핵심 문제: "세팅"과 "감지"의 혼재

| | 프로젝트 초기 세팅 | 모듈 생성 시 감지 |
|---|---|---|
| **시점** | 프로젝트 시작 시 **1회** | 모듈 추가할 때 **매번** |
| **작업** | modules 구조 결정, _common 배치, 가이드코드 연결 | 이미 세팅된 구조를 읽고 적응 |
| **판단** | 설계 판단 (어떻게 분리할까) | 감지 판단 (이미 분리된 걸 따르기) |

한 스킬이 "만들기"와 "감지+적응"을 동시에 하면, 실행할 때마다 "이미 있는지 없는지" 분기가 폭발한다.

### 결정 사항

**"세팅"은 `peach-setup-project` (신규 스킬), "감지+적응"은 기존 스킬 보강**

| 역할 | 담당 스킬 | 시점 |
|------|---------|------|
| 프로젝트 모듈 구조 + _common 세팅 | `peach-setup-project` (신규) | 초기 1회 |
| modules 분리 감지 + 위치 적응 | `peach-gen-*`, `peach-team` (보강) | 모듈 생성 시 매번 |
| 서브에이전트 references 연결 | `peach-team` 오케스트레이터 (보강) | 팀 실행 시 매번 |

### 워크플로우 변경

```
신규 프로젝트:
/peach-gen-spec → /peach-gen-db → /peach-setup-project (초기 1회) → /peach-team

기존 프로젝트 (모듈 추가):
/peach-gen-db → /peach-team (자동 감지)

기존 프로젝트 (기능 수정):
/peach-doc-feature → /peach-team
```

### 실제 프로젝트 modules 분리 사례

| 프로젝트 유형 | 분리 구조 | 분리 기준 |
|-------------|---------|---------|
| 소규모 백오피스 | `modules/` 단일 | (분리 없음) |
| 중규모 터치 시스템 | `modules/` + `modules-domain/` | 인프라 vs 비즈니스 도메인 |
| 대규모 세금신고 시스템 | `modules/` + `modules-domain/` + `modules-external/` | 도메인 + 외부API 격리 |

### modules 분리 전략 유형

| 전략 | 예시 | 분리 기준 |
|------|------|---------|
| 단일 구조 | `modules/` | 분리 없음 (소규모) |
| 도메인 분리 | `modules/` + `modules-domain/` | 인프라 vs 비즈니스 |
| 외부API 분리 | `modules-external/` 추가 | 외부 연동 격리 |
| 권한/조직 분리 | `modules-admin/`, `modules-branch/`, `modules-public/` | 접속 권역별 |
| 복합 분리 | 위 전략 조합 | 시스템 규모에 따라 |

**공통 규칙:**
- `modules/`에는 항상 `_common/`, `test-data/`, `sign/`, `system/` 등 인프라 모듈
- `modules-*/` 각각에 자체 `_common/` 가능 (도메인 공통)
- 모듈 간 독립성 원칙은 동일 (`_common`만 import)

### _common 기본 구성 (모든 프로젝트 공통)

**Backend** (다수 프로젝트 교차 검증):

| 서브모듈 | 필수/선택 | 역할 |
|---------|---------|------|
| `constants/` | **필수** | 프로젝트 상수 (상태값, 코드값) |
| `file/` | **필수** | 파일 업로드/다운로드 (Local + S3) |
| `log/` | **필수** | 공통 로깅 |
| `config/` | 선택 | 설정 관리 |
| `email/` | 선택 | 이메일 발송 |
| `slack/` | 선택 | Slack 알림 |
| `sms/` | 선택 | SMS 발송 |

**Frontend** (다수 프로젝트 교차 검증):

| 서브모듈 | 필수/선택 | 역할 |
|---------|---------|------|
| `components/` | **필수** | 공용 UI 컴포넌트 |
| `services/` | **필수** | API 호출 서비스 |
| `store/` | **필수** | Pinia 글로벌 스토어 |
| `type/` | **필수** | 공용 타입 정의 |
| `constants/` | 선택 | 프론트 상수 |
| `directives/` | 선택 | Vue 커스텀 디렉티브 |
| `composables/` | 선택 | Vue 3 Composition API |

### 스킬별 적용 범위

| 문서 섹션 | peach-setup-project | peach-gen-* | peach-team |
|----------|-------------------|------------|-----------|
| 1. 모듈 위치 구조 | **구조 결정** | 감지 | 감지→주입 |
| 2. _common 사용 규칙 | **기본 구성 배치** | 상수 감지+사용 | 감지→주입 |
| 3. 트랜잭션 패턴 | - | references 추가 | - |
| 4. 주석 필수 항목 | - | Bounded Autonomy 추가 | - |
| 5. store/UI 위치 | **구조 결정** | 감지 | 감지→주입 |

---

## 1. 모듈 위치 구조

> **담당**: `peach-setup-project`(구조 결정) / `peach-gen-*`, `peach-team`(감지+적응)

### 1-1. modules 분리 구조

스킬 기본값은 `modules/` 단일 구조이지만, 시스템 규모와 성격에 따라 `modules-*`로 분리한다.

```
[스킬 기본값 — 단일 구조]
api/src/modules/{name}/
  controller/ service/ dao/ type/ docs/ test/

[분리 구조 예시 A — 도메인 + 외부API 분리]
api/src/
├── modules/                  ← 인프라 (sign, system, test-data, _common)
├── modules-domain/           ← 비즈니스 도메인
│   └── {domain}/{sub}/
└── modules-external/         ← 외부 API 연동
    └── {sub}/

[분리 구조 예시 B — 권한/조직별 분리]
api/src/
├── modules/                  ← 인프라 (sign, system, test-data, _common)
├── modules-admin/            ← 본사 전용
│   └── {sub}/
├── modules-branch/           ← 지점 전용
│   └── {sub}/
└── modules-public/           ← 인증 없는 외부 엔드포인트
    └── {sub}/

[분리 구조 예시 C — 복합 (도메인 + 권한 + 외부)]
api/src/
├── modules/                  ← 인프라
├── modules-domain/           ← 비즈니스 도메인
├── modules-admin/            ← 본사 전용
├── modules-branch/           ← 지점 전용
└── modules-external/         ← 외부 API 연동
```

`peach-setup-project`가 시스템 성격을 질문하여 적절한 분리 전략을 결정한다.
**분리 전략 유형은 섹션 0의 "modules 분리 전략 유형" 참조.**

### 1-2. front↔api 1:1 매칭 원칙

프론트엔드와 백엔드 모듈 구조를 **동일한 경로로 1:1 매칭**한다.

```
[API]                                    [Frontend]
api/src/modules-domain/order/       ↔   front/src/modules-domain/order/
api/src/modules-external/payment/   ↔   front/src/modules-domain/payment/
                                         (프론트는 domain으로 통합)
```

- 모듈 간 독립성이 보장되어야 AI 에이전트가 모듈 단위로 병렬 작업 가능
- 공유 로직은 `_common/`에만 배치, 모듈 간 교차 참조 금지

---

### 1-3. 서브모듈 내부 파일 구조

```
[스킬 기본값]
{name}.controller.ts
{name}.service.ts
{name}.dao.ts
{name}.type.ts

[프로젝트 오버라이드 — test-data 패턴 완전 준수]
controller/
  {name}.controller.ts        ← 엔드포인트 (Elysia 체이닝 라우터 겸용)
  {name}.validator.ts         ← TypeBox 검증 (controller와 동일 폴더)
service/
  {name}.service.ts           ← 비즈니스 로직 (static 메서드)
  {name}-tdd.service.ts       ← TDD 초기화/정리 전용
  {name}-transaction.service.ts  ← 트랜잭션 로직 (필요 시만)
dao/
  {name}.dao.ts
type/
  {name}.type.ts
docs/
  {name}.docs.ts              ← Elysia API 문서화 (필수)
test/
  {name}.test.ts
  {name}-transaction.test.ts  ← 트랜잭션 테스트 (필요 시만)
```

---

### 1-4. 권한 필터 (프로젝트 전용 — 스킬 반영 대상 아님)

> 아래는 권한/조직 분리 구조를 채택한 프로젝트에서 **프로젝트별로 직접 설정**하는 내용이다.
> 프로젝트마다 권한 체계가 다르므로 스킬에 범용 반영하지 않는다.
> 필요 시 프로젝트 AGENTS.md 또는 Spec 문서에 명시한다.

```typescript
// 예시: 권한 분리 구조에서 DAO 필터
// modules-branch → 내 관할만
WHERE employee.branch_id = ${params.branchId}

// modules-admin → 전체 조회 (조건 없음)
```

---

## 2. _common 사용 규칙

> **담당**: `peach-setup-project`(기본 구성 배치) / `peach-gen-backend`(상수 감지+사용)

### 2-1. 프로젝트 상수 — 전역 관리 (핵심)

**위치:** `api/src/modules/_common/constants/{project}.constants.ts`

스킬이 코드를 생성할 때 **상태값/코드값을 하드코딩하지 않고** 반드시 상수 파일을 import해야 한다.

```typescript
// ❌ 스킬 기본 생성 방식 (금지)
if (order.status === '10') { ... }
product.status = '10';

// ✅ 프로젝트 상수 사용
import {
  OrderStatus,
  ProductStatus,
} from '../../_common/constants/shop.constants';

if (order.status === OrderStatus.CONFIRMED) { ... }
product.status = ProductStatus.ACTIVE;
```

**상수 클래스 설계 예시:**

| 클래스 | 설명 |
|--------|------|
| `MemberState` | 회원 상태 (01:가입대기, 10:완료, 11:탈퇴) |
| `OrderStatus` | 주문 상태 (01:대기, 10:확정, 20:취소) |
| `ProductStatus` | 상품 상태 (10:판매중, 20:품절) |
| `SystemId` | 시스템 사용자 ID (-1:System, -5:TDD) |

> 프로젝트별로 상수 클래스를 정의하되, 네이밍 규칙은 `{Domain}{Entity}` 또는 `{Entity}{속성}` 패턴을 따른다.

---

### 2-2. parent_code 규칙 — 하이픈(-) 패턴

test-data 가이드 코드의 `test-${seq}` 패턴과 동일하게 **하이픈(-) 사용**.

```typescript
// ❌ 금지 (언더스코어)
const parentCode = `product_${productSeq}`;

// ✅ 필수 (하이픈 패턴)
const parentCode = `product-${productSeq}`;       // "product-1"
const imageCode  = `product-${productSeq}-image`; // "product-1-image"

// ✅ 상수 클래스로 관리하면 더 좋음
import { ProductParentCode } from '../../_common/constants/shop.constants';

const parentCode = ProductParentCode.file(productSeq);   // "product-1"
const imageCode  = ProductParentCode.photo(productSeq);  // "product-1-image"
```

---

### 2-3. _common 공유 서비스 예시

프로젝트에서 여러 모듈이 공유하는 로직은 `_common/` 하위에 서브모듈로 배치한다.

```
_common/
├── constants/{project}.constants.ts   # 전역 상수
├── file/                              # 파일 업로드 (Local + S3)
│   ├── service/file-upload-local.service.ts
│   ├── service/file-upload-s3.service.ts
│   ├── dao/file.dao.ts
│   └── type/file.type.ts
└── log/                               # 공통 로깅
    ├── service/common-log.service.ts
    ├── dao/common-log.dao.ts
    └── type/common-log.type.ts
```

> `_common/`의 서비스는 모듈에서 import 가능하지만, 모듈 간 직접 import는 금지.

---

## 3. 트랜잭션 패턴

> **담당**: `peach-gen-backend` references/service-pattern.md에 반영

### 3-1. 제한적 사용 원칙

> **트랜잭션은 꼭 필요하다고 판단되는 곳에만 제한적으로 사용한다.**
> 단일 테이블 CRUD에는 적용하지 않는다. 2개 이상 테이블을 동시에 변경하는 경우에만 적용.

### 3-2. @Transactional() 데코레이터 (bunqldb 제공)

**가이드 코드:** `test-data-transaction.service.ts`, `test-data-transaction.test.ts`

```typescript
// ❌ 스킬 기본 방식 (사용 금지)
import { DB } from 'bunqldb';
await DB.transaction(async () => { ... });

// ✅ 프로젝트 방식
import { Transactional } from 'bunqldb';

@Transactional()
static async approve(approvalSeq: number, actorSeq: number): Promise<void> {
  // 이 블록 전체가 하나의 트랜잭션
  // 예외 발생 시 자동 전체 롤백
}
```

### 3-3. 트랜잭션 적용 기준 판단법

| 조건 | 트랜잭션 적용 |
|------|-------------|
| 2개 이상 테이블 동시 변경 | 적용 |
| 상태전이 + 이력 동시 기록 | 적용 |
| 다건 루프 일괄 처리 (엑셀 등) | 적용 |
| 단일 테이블 단건 CRUD | 불필요 |
| 조회 전용 | 불필요 |

**적용 예시:**
```typescript
// ✅ 주문 확정 — order + inventory + order_hist 3테이블 동시 변경
@Transactional()
static async confirmOrder(orderSeq: number, actorSeq: number): Promise<void> {
  // 상태전이: 01(대기) → 10(확정)
  await OrderDao.updateStatus(orderSeq, OrderStatus.CONFIRMED, actorSeq);

  // 재고 차감
  const order = await OrderDao.findOne(orderSeq);
  await InventoryDao.decrease(order.productSeq, order.quantity);

  // 이력 기록
  await OrderHistDao.insert({ orderSeq, action: 'CONFIRM', actorSeq });
}

// ❌ 단일 테이블 — 트랜잭션 불필요
static async findPaging(params: PagingParams) {
  return OrderDao.findPaging(params);
}
```

### 3-4. 스킬 오버라이드 규칙

스킬에 전달할 트랜잭션 지시:
> "트랜잭션은 제한적 사용. 2개 이상 테이블 동시 변경 시에만 @Transactional() 적용.
> 단일 테이블 CRUD에는 절대 적용하지 않는다.
> 가이드: test-data-transaction.service.ts 참조."

---

## 4. 주석 필수 항목

> **담당**: `peach-gen-backend` Bounded Autonomy Must Follow에 반영

스킬이 생성하는 코드에서 아래 케이스는 반드시 주석을 포함해야 한다.

```typescript
// ✅ 상태전이 — 반드시 주석
// 상태전이: 01(대기) → 10(확정) — 주문 확정 시
await OrderDao.updateStatus(orderSeq, OrderStatus.CONFIRMED, actorSeq);

// ✅ 권한 필터 — 반드시 주석
// 지점 사용자는 자기 지점 주문만 조회 — branch_id 필터 필수
WHERE "order".branch_id = ${params.branchId}

// ✅ 환경 제한 — 반드시 주석
// prod 환경 물리삭제 차단 (보안)
if (process.env.STAGE === 'prod') {
  throw new ErrorHandler(403, '실운영에서는 삭제할 수 없습니다.');
}

// ❌ 단순 CRUD — 주석 불필요
return OrderDao.findPaging(params);
```

---

## 5. peach-gen-store / peach-gen-ui 적용 규칙

> **담당**: `peach-gen-store`, `peach-gen-ui` (modules 위치 감지)

### store 위치

```
[스킬 기본값]
front/src/modules/{name}/store/{name}.store.ts

[분리 구조 오버라이드]
front/src/modules-domain/{sub}/store/{sub}.store.ts
front/src/modules-admin/{sub}/store/{sub}.store.ts
```

### UI 파일 위치

```
[스킬 기본값]
front/src/modules/{name}/pages/

[분리 구조 오버라이드]
front/src/modules-domain/order/pages/order-list.vue
front/src/modules-domain/order/modals/order-detail.modal.vue
front/src/modules-admin/product/pages/product-list.vue
```

### 프론트 상수 사용

```typescript
// 백엔드와 동일하게 — 프론트에도 {project}.constants.ts 배치 검토
// 또는 API 응답의 names 매핑 활용
// 예: OrderStatus.names['10'] → '확정'
```

---

## 6. 스킬 업데이트 대상

이 문서의 의사결정을 반영해야 할 스킬 목록:

### 신규 스킬

| 스킬 | 역할 |
|------|------|
| `peach-setup-project` | 신규 프로젝트 모듈 구조 + _common 기본 구성 세팅 (초기 1회) |

### 기존 스킬 보강

| 스킬 | 수정 대상 | 수정 내용 |
|------|---------|---------|
| `peach-gen-backend` | SKILL.md | modules 위치 감지, _common/constants 감지, 주석 필수 |
| `peach-gen-backend` | references/service-pattern.md | @Transactional() 제한적 사용 섹션 추가 |
| `peach-gen-store` | SKILL.md | front modules 위치 감지, 프론트 상수 확인 |
| `peach-gen-ui` | SKILL.md | front modules 위치 감지 |
| `peach-team` | SKILL.md | 프로젝트 구성 감지 + references 경로 주입 |
| `peach-team` | references/*-agent.md | references 조건부 참조 목록 + 생성 경로 |

### 스킬 파일 위치

```bash
# skills.sh 글로벌 설치 시
~/.agents/skills/peachSolution/peach-harness/skills/

# skills.sh 프로젝트 설치 시
.agents/skills/peachSolution/peach-harness/skills/

# Claude Code 플러그인 설치 시
~/.claude/plugins/marketplaces/peach-harness/skills/

# 하네스 소스 (개발용)
~/source/peachSolution2/peach-harness/skills/
```
