# 공통 UI 패턴 가이드

> 🔴 **필수 문서**: 이 파일은 **모든 UI 패턴에서 반드시 적용**해야 하는 핵심 패턴을 담고 있습니다.
> crud, page, two-depth, infinite-scroll 등 **어떤 패턴을 선택하든** 아래 내용을 숙지하고 적용하세요!

---

## ⚠️ 필수 적용 체크리스트

코드 생성 전 아래 항목이 모두 적용되었는지 확인하세요:

| # | 패턴 | 적용 위치 | 확인 |
|---|------|----------|------|
| 1 | `<form @submit.prevent="listAction">` | list-search.vue | □ |
| 2 | `@change="listAction"` (select) | list-search.vue, list-table.vue | □ |
| 3 | `@update:modelValue="listAction"` (date) | list-search.vue | □ |
| 4 | `@update:page="listMovePage"` (pagination) | list-table.vue | □ |
| 5 | watch 패턴 (route → listParams) | list-search.vue | □ |
| 6 | watch 패턴 (route → getList) | list-table.vue | □ |
| 7 | `listAction()` 함수 | list-search.vue, list-table.vue | □ |
| 8 | `resetAction()` 함수 | list-search.vue | □ |
| 9 | `listMovePage()` 함수 | list-table.vue | □ |

---

## URL Watch 패턴 (필수)

> 🚨 **중요 경고**: 이 패턴은 AI가 매번 다르게 생성해서 오류가 많이 발생하는 핵심 부분입니다.
> **절대 변형하지 말고 test-data와 100% 동일하게 생성하세요!**
>
> **절대 금지 사항**:
> - watch 구조 변경 금지
> - 조건문 변경 금지 (`if (route.query && Object.keys(route.query).length > 0)` 고정)
> - Object.assign 대신 다른 방법 사용 금지
> - immediate/deep 옵션 누락 금지
> - 주석 생략 금지
> - `route.path.includes()` 사용 금지 (엄격 비교 `===` 또는 `==` 사용)

### list-search.vue (검색 조건 동기화)

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      // 검색 관련 파라미터만 listParams에 적용
      const { startDate, endDate, keyword, opt, isUse, selected } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword, opt, isUse, selected });
    } else {
      // 검색 파라미터 초기화
      resetAction();
    }
  },
  { immediate: true, deep: true }
);
```

**핵심 포인트**:
- 구조분해 할당으로 필요한 필드만 추출: `const { ... } = route.query` (필드명은 모듈에 맞게 변경)
- `Object.assign`으로 동기화 (다른 방법 사용 금지)
- query 없으면 `resetAction()` 호출
- 주석 포함 필수

### list-table.vue (데이터 조회)

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      // route 파라미터를 listParams에 적용
      Object.assign(listParams.value, route.query);
      listParams.value.page = Number(listParams.value.page);
      listParams.value.row = Number(listParams.value.row);

      // route 파라미터가 있고 특정 페이지일 때만 조회
      if (route.path === '/[모듈명]/list') {
        getList();
      }
    }
  },
  { immediate: true, deep: true }
);
```

**핵심 포인트**:
- 전체 query 동기화: `Object.assign(listParams.value, route.query)`
- page, row 숫자 변환: `Number()` 필수
- 경로 체크: `route.path === '/[모듈명]/list'` 또는 `route.path == '/[모듈명]/list'` (엄격 비교 사용)
- 주석 포함 필수

**❌ 절대 금지 패턴**:
```typescript
// ❌ 잘못된 예시 1: watch 대상 변경
watch(route.query, () => { ... })  // route 전체를 감시해야 함

// ❌ 잘못된 예시 2: 다른 조건문 사용
if (route.query?.length) { ... }  // 정확한 조건문 사용 필수

// ❌ 잘못된 예시 3: 다른 동기화 방법
listParams.value = { ...route.query }  // Object.assign 사용 필수

// ❌ 잘못된 예시 4: includes 사용
if (route.path.includes('/list')) { ... }  // 엄격 비교 사용 필수
```

---

## Modal Props Watch 패턴 (필수)

모달 컴포넌트에서 `props.open`을 감시하여 데이터 로드/초기화하는 패턴입니다.

### insert.modal.vue (등록 모달 - 초기화)

```typescript
// 모달이 열릴 때 초기화
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      initOnCreated();
    }
  }
);
```

**핵심 원칙**:
- `props.open`만 감시 (복잡한 조건문 금지)
- 모달 열릴 때 `initOnCreated()` 호출하여 초기화
- options 없음 (immediate/deep 불필요)

### detail.modal.vue / update.modal.vue (상세/수정 모달 - 데이터 로드)

```typescript
// 모달이 열릴 때 데이터 로드
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      getDetail();
    }
  }
);
```

**핵심 원칙**:
- `props.open`만 감시 (복잡한 조건문 금지)
- 모달 열릴 때 `getDetail()` 호출하여 데이터 로드
- options 없음 (immediate/deep 불필요)

**❌ 잘못된 패턴**:
```typescript
// ❌ 복잡한 조건문 사용 (불필요)
watch(() => props.open, (newValue) => {
  if (newValue && props.[pk]Seq) {  // props.[pk]Seq 체크 불필요
    getDetail();
  }
});

// ❌ 중복 watch (불필요)
watch(() => props.[pk]Seq, (newValue) => {
  if (newValue && props.open) {  // 중복 watch, 부모가 관리
    getDetail();
  }
});
```

**올바른 접근**:
- 부모 컴포넌트가 `[pk]Seq`와 `open` 상태를 함께 관리
- 자식 모달은 `props.open`만 감시하고 데이터 로드/초기화에 집중
- 책임 분리: 부모(상태 관리) / 자식(렌더링)

---

## Tab Props Watch 패턴

탭 컴포넌트에서 `props.activeTab`을 감시하여 특정 탭 활성화 시 로직을 실행하는 패턴입니다.

### detail-tab-[name].vue (탭 활성화 감지)

```typescript
const props = defineProps({
  activeTab: {
    type: String,
    default: ''
  }
});

watch(
  () => [props.activeTab],
  ([value]) => {
    if (value === '[탭명]') {
      setTimeout(async () => {
        console.log('[탭명] tab activated');
        // 탭별 데이터 로드 로직
        // await fetchTabData();
      }, 100);
    }
  },
  { immediate: true, deep: true }
);
```

**핵심 원칙**:
- `props.activeTab`을 **배열 구조분해**로 감시: `() => [props.activeTab]`
- 특정 탭일 때만 로직 실행: `if (value === '[탭명]')`
- `setTimeout` 100ms로 DOM 안정화 대기
- `{ immediate: true, deep: true }` 옵션 필수

**사용 시기**:
- 상세 모달 내부의 탭 컴포넌트
- 탭 활성화 시 데이터 로드 필요 시
- 부모에서 `activeTab`을 props로 전달받는 경우

**부모 컴포넌트 예시**:
```vue
<template>
  <u-tabs v-model="activeTab" :items="tabs">
    <template #expire>
      <DetailExpire :active-tab="activeTab" />
    </template>
  </u-tabs>
</template>

<script setup>
const activeTab = ref('default');
</script>
```

---

## Selectbox 패턴 (p-nuxt-select) - ⚠️ @change 필수!

### 옵션 배열 정의 규칙

```typescript
// ✅ 올바른 패턴: 전체 옵션은 빈 문자열
const optList = ref([
  { text: '전체', value: '' },        // 빈 문자열로 전체 표현
  { text: '예시1', value: 'example1' },
  { text: '예시2', value: 'example2' },
  { text: '예시3', value: 'example3' }
]);

// 사용여부 예시
const optIsUseList = ref([
  { label: '전체', value: '' },
  { label: '사용', value: 'Y' },
  { label: '미사용', value: 'N' }
]);
```

### 템플릿 사용

> 🔴 **필수**: `@change="listAction"` 누락 금지!

```vue
<!-- ✅ 올바른 패턴: @change 필수 -->
<p-nuxt-select
  v-model="listParams.opt"
  :options="optList"
  class="w-full lg:w-[160px]"
  @change="listAction"
/>

<!-- ✅ row 선택도 동일 -->
<p-nuxt-select
  v-model="listParams.row"
  :options="rowList"
  class="w-20"
  @change="listAction"
/>

<!-- ❌ 잘못된 패턴: @change 누락 -->
<p-nuxt-select
  v-model="listParams.opt"
  :options="optList"
/>
```

**주의사항:**
- `value`는 빈 문자열('')로 "전체" 표현 (null, undefined 금지)
- 🔴 **`@change="listAction"` 필수** - 변경 시 즉시 검색 실행
- 컴포넌트 내부에서 `''` ↔ `'all'` 자동 변환 처리됨

---

## 모달 오픈 패턴 (필수)

### 모달 상태 정의

```typescript
const isOpenInsert = ref(false);
const isOpenDetail = ref(false);
const isOpenUpdate = ref(false);
const selectedKey = ref(0);
```

### 모달 오픈 메서드

```typescript
const goDetail = ([pk]Seq: number) => {
  selectedKey.value = [pk]Seq;
  isOpenDetail.value = true;
};

const goInsert = () => {
  isOpenInsert.value = true;
};

const goUpdate = ([pk]Seq: number) => {
  if (isOpenDetail.value) isOpenDetail.value = false;
  selectedKey.value = [pk]Seq;
  isOpenUpdate.value = true;
};
```

### 템플릿에서 모달 사용

```vue
<insert v-model:open="isOpenInsert" @insert-ok="listAction" />
<detail :[pk]-seq="selectedKey" v-model:open="isOpenDetail" @remove-ok="listAction" @go-update="goUpdate" />
<update :[pk]-seq="selectedKey" v-model:open="isOpenUpdate" @update-ok="listAction" />
```

---

## 검색 파라미터 초기화

```typescript
const initListParams = (): [ModuleName]PagingDto => ({
  page: 1,
  row: 10,
  sortBy: '[pk]Seq',
  sortType: 'DESC',
  startDate: dayjs().subtract(1, 'month').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  keyword: '',
  opt: 'subject',
  isUse: ''
});

const listParams = ref(initListParams());

const resetAction = () => {
  listParams.value = initListParams();
};
```

---

## Router 동기화 패턴 - ⚠️ 핵심 패턴!

> 🔴 **필수**: 이 패턴은 모든 UI에서 URL 상태관리의 핵심입니다. 절대 변형하지 마세요!

### list-search.vue: 검색 및 초기화

#### Form Submit 패턴 (필수!)

> 🔴 **필수**: `<form @submit.prevent="listAction">` 누락 금지!

```vue
<template>
  <!-- ✅ 올바른 패턴 -->
  <form @submit.prevent="listAction">
    <u-input v-model="listParams.keyword" />
    <u-button type="submit">검색</u-button>
  </form>

  <!-- ❌ 잘못된 패턴: form 없이 버튼만 -->
  <u-input v-model="listParams.keyword" />
  <u-button @click="listAction">검색</u-button>
</template>
```

#### listAction - 검색 실행 시

```typescript
const listAction = () => {
  // 기존 query 파라미터를 유지하면서 검색 파라미터만 업데이트
  router.push({
    query: {
      ...route.query,                              // 기존 query 파라미터 유지
      ...listParams.value,                         // 검색 파라미터 업데이트
      page: 1,                                     // 검색 시 페이지 초기화
      time: dayjs().format('YYYYMMDDHHmmssSSS')    // 캐시 무효화용 타임스탬프
    }
  });
};
```

#### resetAction - 초기화

```typescript
const resetAction = () => {
  // 검색 파라미터 초기화
  listParams.value = {
    startDate: dayjs().subtract(5, 'year').format('YYYY-MM-DD'),
    endDate: dayjs().format('YYYY-MM-DD'),
    keyword: '',
    opt: 'all',
    isUse: '',
    selected: ''
  };

  // 기존 query 파라미터를 유지하면서 검색 파라미터만 초기화
  router.push({
    query: {
      ...route.query,                              // 기존 query 파라미터 유지
      ...listParams.value,                         // 초기화된 검색 파라미터

      // 기본 정렬 설정 (test-data 표준 패턴)
      // sortBy/sortType: 백엔드 API에서 사용
      // sortData: 프론트엔드 select에서 사용 (handleSortChange에서 분리)
      sortBy: 'insertDate',
      sortType: 'desc',
      sortData: 'insertDate,desc',
      row: 10,                                     // row 값
      page: 1                                      // 페이지 초기화
    }
  });
};
```

#### watch - route query 동기화

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      // 검색 관련 파라미터만 listParams에 적용
      const { startDate, endDate, keyword, opt, isUse, selected } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword, opt, isUse, selected });
    } else {
      // 검색 파라미터 초기화
      resetAction();
    }
  },
  { immediate: true, deep: true }
);
```

### list-table.vue: 페이지 로드 시 데이터 조회

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      // route 파라미터를 listParams에 적용
      Object.assign(listParams.value, route.query);
      listParams.value.page = Number(listParams.value.page);
      listParams.value.row = Number(listParams.value.row);

      // route 파라미터가 있고 특정 페이지일 때만 조회
      if (route.path == '/[모듈명]/list') {
        getList();
      }
    }
  },
  { immediate: true, deep: true }
);
```

**핵심 포인트:**
- `{ immediate: true, deep: true }`: 컴포넌트 마운트 시 즉시 실행, 중첩 객체 변경 감지
- `...route.query` 스프레드로 기존 query 유지
- `page: 1`로 검색 시 항상 첫 페이지로 이동
- `time` 타임스탬프로 캐시 무효화

### 페이지 이동 패턴 (필수!)

> 🔴 **필수**: `@update:page="listMovePage"` 누락 금지!

```vue
<!-- ✅ 올바른 패턴 -->
<u-pagination
  v-model:page="listParams.page"
  :items-per-page="listParams.row"
  :total="listTotalRow"
  @update:page="listMovePage"
/>
```

```typescript
// ✅ 필수 함수
const listMovePage = (page: number) => {
  listParams.value.page = page;
  listAction();
};

// ✅ listAction에서 URL 업데이트
const listAction = () => {
  listParams.value.time = dayjs().format('YYYYMMDDHHmmssSSS');
  router.push({ query: { ...route.query, ...listParams.value } });
};
```

---

## Date 검색 패턴

### 기본 Date Picker (p-date-picker)

```vue
<p-date-picker
  v-model="listParams.startDate"
  class="w-full lg:w-[130px]"
  @update:modelValue="listAction"
/>
<span class="hidden lg:block">~</span>
<p-date-picker
  v-model="listParams.endDate"
  class="w-full lg:w-[130px]"
  @update:modelValue="listAction"
/>
```

### 빠른 날짜 선택 (p-day-select)

#### 템플릿

```vue
<p-day-select
  v-model="listParams.startDate"
  class="w-full lg:w-[160px]"
  @setDate="setDate"
/>
```

#### setDate 콜백 함수

```typescript
const setDate = (date: any) => {
  listParams.value.startDate = date.startDate;
  listParams.value.endDate = date.endDate;
};
```

**p-day-select 제공 옵션:**
- "기간선택", "내일", "오늘"
- "1일전", "2일전", "3일전", "7일전"
- "지난 12개월"
- "1년", "2년", "3년", "4년"

### 초기값 설정

```typescript
const listParams = ref({
  startDate: dayjs().subtract(5, 'year').format('YYYY-MM-DD'),  // 5년 전
  endDate: dayjs().format('YYYY-MM-DD'),                        // 오늘
  keyword: '',
  opt: 'all',
  isUse: '',
  selected: ''
});
```

**권장 사항:**
- 기본 기간: 5년 전 ~ 오늘 (업무 특성에 따라 조정 가능)
- p-date-picker: 정확한 날짜 입력 시
- p-day-select: 빠른 기간 선택 시 (둘 다 제공 권장)
- @update:modelValue="listAction": 날짜 변경 즉시 검색 실행

---

## 참조

실제 예시: `front/src/modules/test-data/pages/crud/`
