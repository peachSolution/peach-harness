# 탭 내 리스트 (Tab List) 패턴 가이드

> 이 패턴은 test-data에 가이드 코드가 없습니다. MCP(Context7)를 활용하세요.

---

## 개요

상세 화면의 탭 내부에서 독립된 리스트를 조회하는 패턴입니다.

**사용 시기**:
- 사용자 상세 + 접속이력/결제내역
- 상품 상세 + 리뷰/문의
- 주문 상세 + 배송이력/환불내역

**MCP 활용**: Context7 (Nuxt UI 공식 문서 참조)

---

## UI 구조

```
┌─────────────────────────────────────────────────────────────────┐
│  [기본정보]  [접속이력]  [결제내역]                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  검색: [________]  [검색]                                 │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │  번호  │  IP 주소      │  접속일시          │  디바이스   │ │
│  │  1    │  192.168.1.1  │  2024-01-01 10:00  │  PC        │ │
│  │  2    │  192.168.1.2  │  2024-01-02 14:30  │  Mobile    │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │                      [1] [2] [3]                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   └── detail.vue              ← 상세 페이지 (탭 포함)
├── components/tabs/
│   ├── tab-basic-info.vue      ← 기본정보 탭
│   ├── tab-access-history.vue  ← 접속이력 탭 (리스트)
│   └── tab-payment-history.vue ← 결제내역 탭 (리스트)
└── store/
    ├── [모듈명].store.ts       ← 메인 Store
    └── [모듈명]-history.store.ts ← 탭용 Store
```

---

## detail.vue 패턴

```vue
<template>
  <div class="p-6">
    <!-- 헤더 -->
    <div class="mb-6 flex items-center justify-between">
      <h1 class="text-2xl font-bold">{{ detailData.name }} 상세</h1>
      <u-button variant="outline" @click="router.back()">목록으로</u-button>
    </div>

    <!-- 탭 -->
    <u-tabs v-model="activeTab" :items="tabItems" class="w-full">
      <template #basic>
        <tab-basic-info :data="detailData" />
      </template>

      <template #access>
        <tab-access-history :[pk]-seq="seq" />
      </template>

      <template #payment>
        <tab-payment-history :[pk]-seq="seq" />
      </template>
    </u-tabs>
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { storeToRefs } from 'pinia';
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';

import TabBasicInfo from '../components/tabs/tab-basic-info.vue';
import TabAccessHistory from '../components/tabs/tab-access-history.vue';
import TabPaymentHistory from '../components/tabs/tab-payment-history.vue';

const route = useRoute();
const router = useRouter();
const store = use[ModuleName]Store();
const { detailData } = storeToRefs(store);

// 현재 seq
const seq = computed(() => Number(route.params.seq));

// 활성 탭
const activeTab = ref('basic');

// 탭 정의
const tabItems = [
  { label: '기본정보', value: 'basic' },
  { label: '접속이력', value: 'access' },
  { label: '결제내역', value: 'payment' }
];

// 메인 데이터 로드
onMounted(async () => {
  await store.detail(seq.value);
});
</script>
```

---

## tab-access-history.vue (탭 내 리스트)

```vue
<template>
  <div class="space-y-4">
    <!-- 검색 -->
    <div class="flex items-center gap-4">
      <u-input
        v-model="searchParams.keyword"
        placeholder="IP 주소 검색"
        class="w-64"
        @keyup.enter="handleSearch"
      />
      <u-button @click="handleSearch">검색</u-button>
    </div>

    <!-- 테이블 -->
    <easy-data-table
      :headers="headers"
      :items="listData"
      :server-items-length="listTotalRow"
      hide-footer
    >
      <template #item-accessDate="item">
        {{ dayjs(item.accessDate).format('YYYY-MM-DD HH:mm:ss') }}
      </template>
      <template #item-deviceType="item">
        <u-badge :color="item.deviceType === 'PC' ? 'blue' : 'green'">
          {{ item.deviceType }}
        </u-badge>
      </template>
    </easy-data-table>

    <!-- 빈 상태 -->
    <div v-if="listData.length === 0" class="py-10 text-center text-gray-500">
      접속 이력이 없습니다.
    </div>

    <!-- 페이지네이션 -->
    <div v-if="listData.length > 0" class="flex justify-center">
      <u-pagination
        v-model:page="searchParams.page"
        :items-per-page="searchParams.row"
        :total="listTotalRow"
        @update:page="handlePageChange"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useAccessHistoryStore } from '@/modules/[모듈명]/store/[모듈명]-history.store.ts';
import { ref, computed, watch, onMounted } from 'vue';
import { type Header } from 'vue3-easy-data-table';
import dayjs from 'dayjs';

// Props
const props = defineProps<{
  [pk]Seq: number;
}>();

// Store
const store = useAccessHistoryStore();
const listData = computed(() => store.listData);
const listTotalRow = computed(() => store.listTotalRow);

// 검색 파라미터 (독립적)
const searchParams = ref({
  page: 1,
  row: 10,
  keyword: ''
});

// 테이블 헤더
const headers: Header[] = [
  { text: '번호', value: 'nIndex', width: 80 },
  { text: 'IP 주소', value: 'ipAddress', width: 150 },
  { text: '접속일시', value: 'accessDate', width: 180 },
  { text: '디바이스', value: 'deviceType', width: 100 },
  { text: 'OS', value: 'osName', width: 100 },
  { text: '브라우저', value: 'browserName', width: 100 }
];

// 데이터 조회
const fetchData = async () => {
  await store.paging({
    [pk]Seq: props.[pk]Seq,
    ...searchParams.value
  });
};

// 검색
const handleSearch = () => {
  searchParams.value.page = 1;
  fetchData();
};

// 페이지 변경
const handlePageChange = (page: number) => {
  searchParams.value.page = page;
  fetchData();
};

// Props 변경 시 (탭 전환 후 다시 돌아왔을 때)
watch(
  () => props.[pk]Seq,
  (newSeq) => {
    if (newSeq) {
      searchParams.value.page = 1;
      fetchData();
    }
  }
);

// 탭 활성화 시 데이터 로드 (Lazy Fetch)
onMounted(() => {
  if (props.[pk]Seq) {
    fetchData();
  }
});
</script>
```

---

## [모듈명]-history.store.ts (탭용 Store)

```typescript
// store/[모듈명]-history.store.ts
import { defineStore } from 'pinia';
import api from '@/modules/_common/services/api.service';

interface AccessHistory {
  historySeq: number;
  [pk]Seq: number;
  ipAddress: string;
  accessDate: string;
  deviceType: string;
  osName: string;
  browserName: string;
}

interface SearchParams {
  [pk]Seq: number;
  page: number;
  row: number;
  keyword?: string;
}

export const useAccessHistoryStore = defineStore('[moduleName]AccessHistory', {
  state: () => ({
    listData: [] as AccessHistory[],
    listTotalRow: 0
  }),

  actions: {
    async paging(params: SearchParams) {
      const res = await api.get('/[모듈명]/access-history', { params });
      this.listData = res.data.list;
      this.listTotalRow = res.data.totalRow;
    },

    resetList() {
      this.listData = [];
      this.listTotalRow = 0;
    }
  }
});
```

---

## Lazy Fetch 패턴

탭이 활성화될 때만 데이터를 로드합니다.

### 방법 1: onMounted + watch

```typescript
// 탭 컴포넌트가 마운트될 때 데이터 로드
onMounted(() => {
  if (props.[pk]Seq) {
    fetchData();
  }
});

// Props 변경 감지 (다른 항목 선택 시)
watch(
  () => props.[pk]Seq,
  (newSeq) => {
    if (newSeq) {
      fetchData();
    }
  }
);
```

### 방법 2: 부모에서 activeTab 감시

```vue
<!-- detail.vue -->
<script setup>
watch(activeTab, (newTab) => {
  if (newTab === 'access' && seq.value) {
    accessHistoryStore.paging({ [pk]Seq: seq.value, page: 1, row: 10 });
  }
});
</script>
```

### 방법 3: activeTab Props 감시 (test-data 표준)

상세 모달 내부 탭에서 사용하는 패턴입니다.

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
    if (value === 'expire') {
      setTimeout(async () => {
        console.log('expire tab activated');
        // 탭별 데이터 로드 로직
        // await fetchExpireData();
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
- 상세 모달 내부의 탭 컴포넌트 (detail.modal.vue 내부)
- 탭이 활성화될 때만 데이터 로드 필요 시
- 부모에서 activeTab을 props로 전달받는 경우

**부모 컴포넌트 (detail.modal.vue):**
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

**실제 예시**: `front/src/modules/test-data/components/tab/detail-tab-expire.vue` (라인 44-54)

---

## 다중 탭 리스트 예시

```vue
<template>
  <u-tabs v-model="activeTab" :items="tabItems">
    <!-- 기본정보 (일반 컴포넌트) -->
    <template #basic>
      <tab-basic-info :data="detailData" />
    </template>

    <!-- 접속이력 (리스트 + 페이징) -->
    <template #access>
      <tab-access-history :[pk]-seq="seq" />
    </template>

    <!-- 결제내역 (리스트 + 페이징) -->
    <template #payment>
      <tab-payment-history :[pk]-seq="seq" />
    </template>

    <!-- 포인트이력 (리스트 + 페이징) -->
    <template #point>
      <tab-point-history :[pk]-seq="seq" />
    </template>
  </u-tabs>
</template>
```

---

## 타입 정의

```typescript
// type/[모듈명]-history.type.ts
export interface AccessHistory {
  historySeq: number;
  [pk]Seq: number;
  ipAddress: string;
  accessDate: string;
  deviceType: 'PC' | 'MOBILE' | 'TABLET';
  osName: string;
  browserName: string;
}

export interface PaymentHistory {
  paymentSeq: number;
  [pk]Seq: number;
  orderNo: string;
  amount: number;
  paymentDate: string;
  status: 'PAID' | 'REFUND' | 'CANCEL';
}

export interface HistorySearchParams {
  [pk]Seq: number;
  page: number;
  row: number;
  keyword?: string;
  startDate?: string;
  endDate?: string;
}
```

---

## 핵심 포인트

### 1. 독립적인 Store

각 탭 리스트는 별도의 Store를 사용하여 상태를 분리합니다.

```typescript
// 메인 데이터
const mainStore = use[ModuleName]Store();

// 탭별 리스트 데이터
const accessStore = useAccessHistoryStore();
const paymentStore = usePaymentHistoryStore();
```

### 2. 독립적인 페이징/검색

탭 내부의 검색과 페이징은 메인 데이터와 독립적으로 동작합니다.

```typescript
const searchParams = ref({
  page: 1,
  row: 10,
  keyword: ''
});
```

### 3. Lazy Fetch

탭이 처음 활성화될 때만 API를 호출하여 불필요한 요청을 방지합니다.

### 4. Props로 부모 키 전달

```vue
<tab-access-history :[pk]-seq="seq" />
```

### 5. 전체 페이지 스크롤 사용

탭 내부 테이블은 자체 스크롤 없이 페이지 전체 스크롤을 사용합니다.

```css
/* 자체 스크롤 X */
.tab-content {
  overflow: visible;
}
```

### 6. activeTab Props 감시 (모달 내부 탭)

모달 내부 탭 컴포넌트에서는 부모의 activeTab을 props로 받아 감시합니다.

```typescript
watch(
  () => [props.activeTab],
  ([value]) => {
    if (value === '[탭명]') {
      setTimeout(async () => {
        // 탭 활성화 시 로직
      }, 100);
    }
  },
  { immediate: true, deep: true }
);
```

**핵심 포인트**:
- 배열 구조분해로 감시
- setTimeout으로 DOM 안정화
- immediate/deep 옵션 필수
- 특정 탭명 체크

**실제 예시**: `front/src/modules/test-data/components/tab/detail-tab-expire.vue`
