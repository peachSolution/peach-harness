# Backend + Store 연결 워크플로우

## Mock Store → 실제 Store 교체 전략

기존 UI가 Mock Store(정적 데이터)로 구현된 경우, 실제 API Store로 교체합니다.

### 1. 기존 Mock Store 분석

```bash
# Mock Store 구조 확인
cat front/src/modules/[모듈명]/store/[모듈명].store.ts

# 기존 타입 확인
cat front/src/modules/[모듈명]/type/[모듈명].type.ts
```

Mock Store 특징:
- 정적 데이터 배열 (`data: []`)
- 실제 API 호출 없음
- `await new Promise(resolve => setTimeout(resolve, 100))` 같은 가짜 지연

### 2. 인터페이스 호환성 체크

실제 Store 생성 시 기존 UI와 인터페이스를 맞춰야 합니다.

```typescript
// UI에서 사용하는 인터페이스 확인
// list.vue, list-table.vue 등에서 사용하는 store 속성/메서드 목록화

// 필수 유지 항목:
// - state: listData, listTotalRow, detailData, listParams
// - actions: paging(), list(), detail(), insert(), update(), updateUse(), softDelete()
```

### 3. 타입 업데이트

Backend API 타입과 Frontend 타입을 동기화:

```typescript
// Backend type/[모듈명].type.ts → Frontend type/[모듈명].type.ts 참조
// 필드명은 camelCase로 변환 (snake_case → camelCase)

// Backend:
interface TestData {
  insert_date: string;
  is_use: string;
}

// Frontend:
interface TestData {
  insertDate: string;
  isUse: string;
}
```

### 4. Store 교체 절차

```bash
# 1. 기존 파일 백업 (필요시)
# cp front/src/modules/[모듈명]/type/[모듈명].type.ts /tmp/

# 2. 새 Store 생성 (gen-store 스킬)
/gen-store [모듈명]

# 3. 타입 호환성 확인
cd front && npx vue-tsc --noEmit

# 4. 오류 수정 (타입 불일치)
```

## 의존성 흐름

```
[DB 스키마]
    │
    ▼
[team-backend-dev] ──→ API 타입 정의 (type/[모듈명].type.ts)
    │                        │
    │                        ▼
    │                 [team-store-dev] ──→ Pinia Store (store/[모듈명].store.ts)
    │                        │                    │
    ▼                        │                    ▼
[team-backend-qa]            │             [team-frontend-qa]
(TDD 검증)                   │             (vue-tsc + lint + build)
                             │
                     [기존 UI 파일들]
                     pages/*.vue
                     modals/*.modal.vue
```

## Store 인터페이스 유지 원칙

UI 변경을 최소화하려면 Store 공개 인터페이스를 유지해야 합니다.

```typescript
// ✅ 올바른 방법: 인터페이스 유지
export const use[모듈명]Store = defineStore('[모듈명]', {
  state: () => ({
    // 기존 UI에서 쓰는 state명 그대로 유지
    listData: [] as [모듈명][],
    listTotalRow: 0,
    listParams: {} as [모듈명]PagingDto,
    detailData: {} as [모듈명],
  }),
  actions: {
    // 기존 UI에서 쓰는 action명 그대로 유지
    async paging(params: [모듈명]PagingDto) { ... },
    async detail(seq: number) { ... },
    // ...
  }
});

// ❌ 잘못된 방법: action명 변경 → UI 전체 수정 필요
async fetchList() { ... }  // list() 대신
async loadDetail() { ... } // detail() 대신
```

## 주의사항

### API 응답 타입 변환

Backend는 snake_case, Frontend는 camelCase를 사용합니다.
Store의 axios 호출 시 변환이 자동으로 이루어지는지 확인:

```typescript
// axios 인터셉터에서 camelCase 변환 설정 여부 확인
// front/src/utils/axios.ts 또는 유사 파일

// 변환이 없으면 수동 매핑 필요
const result = await api.get('/[모듈명]/list');
return result.data.map((item: any) => ({
  insertDate: item.insert_date,
  isUse: item.is_use,
  // ...
}));
```

### CHAR(1) Boolean 처리

Backend는 `CHAR(1)` (Y/N)을 사용하므로 Frontend에서도 `string` 타입으로 처리:

```typescript
// ✅ 올바른 방법
interface [모듈명] {
  isUse: string; // 'Y' | 'N'
}

// ❌ 잘못된 방법
interface [모듈명] {
  isUse: boolean; // boolean 사용 금지
}
```
