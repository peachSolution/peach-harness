# 좌우 분할 (Two-Depth) 패턴 가이드

## 개요

화면을 좌측(목록)과 우측(상세)으로 분할하여 동시에 표시하는 패턴입니다.

**사용 시기**:
- 마스터-디테일 구조
- 목록 탐색과 상세 확인을 동시에
- 모달 대신 인라인 상세 표시

**참조**: `front/src/modules/test-data/pages/two-depth/`

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   ├── list.vue              ← 좌우 분할 레이아웃
│   ├── list-search.vue       ← 좌측 검색
│   ├── list-table.vue        ← 좌측 테이블
│   ├── list-detail.vue       ← 우측 상세 (탭 구조)
│   └── _[페이지명].routes.ts
└── components/tab/           ← 탭 컴포넌트들
    ├── detail-tab-default.vue
    ├── detail-tab-address.vue
    └── detail-tab-xxx.vue
```

---

## list.vue (레이아웃)

```vue
<template>
  <div :class="['flex flex-row items-stretch gap-6', 'bg-bodyBg dark:bg-black']">
    <!-- 좌측: 검색 + 목록 (고정 폭) -->
    <div class="bg-bodyBg flex h-full w-full max-w-[350px] flex-col dark:bg-black">
      <u-card class="w-full">
        <list-search />
        <list-table />
      </u-card>
    </div>

    <!-- 우측: 상세 (유동 폭) -->
    <div class="w-full">
      <list-detail />
    </div>
  </div>
</template>

<script setup lang="ts">
import ListSearch from './list-search.vue';
import ListTable from './list-table.vue';
import ListDetail from './list-detail.vue';
</script>
```

---

## list-search.vue (좌측 검색)

> ⚠️ **필수**: crud 패턴과 동일한 URL 상태관리 패턴 적용

```vue
<template>
  <form @submit.prevent="listAction">
    <div class="p-3">
      <u-form-field label="키워드">
        <u-field-group class="w-full">
          <u-input v-model="listParams.keyword" placeholder="검색어 입력" />
          <u-button type="submit" size="sm" color="primary" icon="i-lucide-search" />
        </u-field-group>
      </u-form-field>

      <u-form-field label="사용여부" class="mt-2">
        <p-nuxt-select
          v-model="listParams.isUse"
          :options="isUseList"
          class="w-full"
          @change="listAction"
        />
      </u-form-field>
    </div>
  </form>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import dayjs from 'dayjs';
import type { [ModuleName]SearchDto } from '@/modules/[모듈명]/type/[모듈명].type';

const route = useRoute();
const router = useRouter();

const listParams = ref<[ModuleName]SearchDto>({
  startDate: dayjs().subtract(5, 'year').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  keyword: '',
  isUse: ''
});

const isUseList = ref([
  { text: '전체', value: '' },
  { text: '사용', value: 'Y' },
  { text: '미사용', value: 'N' }
]);

// ⚠️ 필수: URL로 상태 관리
const listAction = () => {
  router.push({
    query: {
      ...route.query,
      ...listParams.value,
      page: 1,
      time: dayjs().format('YYYYMMDDHHmmssSSS')
    }
  });
};

const resetAction = () => {
  listParams.value = {
    startDate: dayjs().subtract(5, 'year').format('YYYY-MM-DD'),
    endDate: dayjs().format('YYYY-MM-DD'),
    keyword: '',
    isUse: ''
  };
  router.push({
    query: {
      ...route.query,
      ...listParams.value,
      sortBy: 'insertDate',
      sortType: 'desc',
      row: 10,
      page: 1
    }
  });
};

// ⚠️ 필수: URL watch 패턴
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      const { startDate, endDate, keyword, isUse } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword, isUse });
    } else {
      resetAction();
    }
  },
  { immediate: true, deep: true }
);
</script>
```

---

## list-table.vue (좌측 테이블)

### 핵심 차이점

- 모달 대신 **activeSeq** 상태로 우측 상세 표시
- Store의 `detail()` 액션 직접 호출
- ⚠️ **동일 적용**: URL watch 패턴, listAction, listMovePage

```vue
<template>
  <div>
    <div class="flex items-center justify-between py-2">
      <p-nuxt-select
        v-model="listParams.row"
        :options="rowList"
        class="w-20"
        @change="listAction"
      />
    </div>

    <easy-data-table
      :headers="headers"
      :items="listData"
      hide-footer
      @click-row="onTableRowClick"
    >
      <template #item-subject="item">
        <div
          :class="[
            'cursor-pointer',
            activeSeq === item.[pk]Seq ? 'font-bold text-primary' : ''
          ]"
        >
          {{ item.subject }}
        </div>
      </template>
    </easy-data-table>

    <div v-if="listData.length > 0" class="flex justify-center py-3">
      <u-pagination
        v-model:page="listParams.page"
        :items-per-page="listParams.row"
        :total="listTotalRow"
        size="xs"
        @update:page="listMovePage"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { FormService } from '@/modules/_common/services/form.service.ts';
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import dayjs from 'dayjs';
import type { [ModuleName]PagingDto } from '@/modules/[모듈명]/type/[모듈명].type';

const route = useRoute();
const router = useRouter();
const store = use[ModuleName]Store();

const listData = computed(() => store.listData);
const listTotalRow = computed(() => store.listTotalRow);

// 테이블 파라미터 로컬 상태
const listParams = ref({} as [ModuleName]PagingDto);

// 현재 선택된 항목 (우측에 표시할 상세)
const activeSeq = ref(0);

const rowList = [
  { text: '10개', value: 10 },
  { text: '20개', value: 20 },
  { text: '50개', value: 50 }
];

// 목록에서 항목 선택 (two-depth 고유)
const onTableRowClick = (item: any) => {
  activeSeq.value = item.[pk]Seq;
  store.detail(item.[pk]Seq);
};

// ⚠️ 필수: 페이지 이동
const listMovePage = (page: number) => {
  listParams.value.page = page;
  listAction();
};

// ⚠️ 필수: URL로 상태 관리
const listAction = () => {
  listParams.value.time = dayjs().format('YYYYMMDDHHmmssSSS');
  router.push({ query: { ...route.query, ...listParams.value } });
};

// 목록 조회
const getList = async () => {
  await FormService.loading(async () => {
    await store.paging(listParams.value);

    // 데이터 없으면 첫 페이지로
    if (listData.value.length === 0 && listParams.value.page > 1) {
      await router.push({ query: { ...route.query, page: 1 } });
      return;
    }
  });
};

// 첫 번째 항목 자동 선택 (two-depth 고유)
watch(
  listData,
  (newData) => {
    if (newData.length > 0 && activeSeq.value === 0) {
      activeSeq.value = newData[0].[pk]Seq;
      store.detail(newData[0].[pk]Seq);
    }
  },
  { immediate: true }
);

// ⚠️ 필수: URL watch 패턴
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      Object.assign(listParams.value, route.query);
      listParams.value.page = Number(listParams.value.page);
      listParams.value.row = Number(listParams.value.row);

      if (route.path === '/[모듈명]/list') {
        getList();
      }
    }
  },
  { immediate: true, deep: true }
);
</script>
```

---

## list-detail.vue (우측 상세)

탭 구조를 포함한 상세 화면입니다.

```vue
<template>
  <div v-if="detailData.[pk]Seq" class="h-full">
    <u-card class="h-full">
      <!-- 헤더 -->
      <template #header>
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold">{{ detailData.subject }}</h3>
          <div class="flex gap-2">
            <u-button size="sm" variant="outline" @click="handleEdit">
              수정
            </u-button>
            <u-button size="sm" color="error" variant="soft" @click="handleDelete">
              삭제
            </u-button>
          </div>
        </div>
      </template>

      <!-- 탭 -->
      <u-tabs v-model="activeTab" :items="tabItems" class="w-full">
        <template #default="{ item }">
          <component :is="getTabComponent(item.value)" />
        </template>
      </u-tabs>
    </u-card>
  </div>

  <div v-else class="flex h-full items-center justify-center">
    <u-card class="w-full">
      <div class="py-10 text-center text-gray-500">
        좌측 목록에서 항목을 선택하세요.
      </div>
    </u-card>
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { storeToRefs } from 'pinia';
import { ref, computed, markRaw } from 'vue';

// 탭 컴포넌트 import
import DetailTabDefault from '../../components/tab/detail-tab-default.vue';
import DetailTabAddress from '../../components/tab/detail-tab-address.vue';
import DetailTabExpire from '../../components/tab/detail-tab-expire.vue';

const store = use[ModuleName]Store();
const { detailData } = storeToRefs(store);

// 탭 상태
const activeTab = ref('default');

const tabItems = [
  { label: '기본정보', value: 'default' },
  { label: '주소정보', value: 'address' },
  { label: '만료정보', value: 'expire' }
];

// 탭 컴포넌트 매핑
const tabComponents: Record<string, any> = {
  default: markRaw(DetailTabDefault),
  address: markRaw(DetailTabAddress),
  expire: markRaw(DetailTabExpire)
};

const getTabComponent = (tabValue: string) => {
  return tabComponents[tabValue] || DetailTabDefault;
};

// 수정 처리
const handleEdit = () => {
  // 인라인 수정 모드로 전환 또는 모달 오픈
};

// 삭제 처리
const handleDelete = async () => {
  if (!confirm('삭제하시겠습니까?')) return;
  await store.softDelete(detailData.value.[pk]Seq);
};
</script>
```

---

## 탭 컴포넌트 예시

### detail-tab-default.vue

```vue
<template>
  <div class="space-y-4 p-4">
    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="text-sm text-gray-500">제목</label>
        <div class="font-medium">{{ detailData.subject }}</div>
      </div>
      <div>
        <label class="text-sm text-gray-500">값</label>
        <div class="font-medium">{{ detailData.value }}</div>
      </div>
      <div>
        <label class="text-sm text-gray-500">사용여부</label>
        <u-badge :color="detailData.isUse === 'Y' ? 'success' : 'neutral'">
          {{ detailData.isUse === 'Y' ? '사용' : '미사용' }}
        </u-badge>
      </div>
      <div>
        <label class="text-sm text-gray-500">등록일</label>
        <div>{{ dayjs(detailData.insertDate).format('YYYY-MM-DD HH:mm') }}</div>
      </div>
    </div>

    <div>
      <label class="text-sm text-gray-500">설명</label>
      <div class="mt-1 rounded bg-gray-50 p-3" v-html="detailData.description"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { storeToRefs } from 'pinia';
import dayjs from 'dayjs';

const store = use[ModuleName]Store();
const { detailData } = storeToRefs(store);
</script>
```

---

## 레이아웃 스타일링

### 반응형 대응

```vue
<template>
  <div class="flex flex-col lg:flex-row items-stretch gap-6">
    <!-- 모바일: 세로 배치, 데스크톱: 가로 배치 -->
    <div class="w-full lg:w-[350px] lg:max-w-[350px]">
      <!-- 좌측 -->
    </div>
    <div class="w-full">
      <!-- 우측 -->
    </div>
  </div>
</template>
```

### 좌측 폭 조절

```css
/* 고정 폭 */
max-w-[350px]

/* 비율 기반 */
w-1/3
lg:w-[30%]

/* 최소/최대 */
min-w-[300px] max-w-[400px]
```

---

## 핵심 포인트

### ⚠️ 0. URL 상태관리 패턴 (crud와 동일 - 필수!)

> **중요**: two-depth도 crud와 동일한 URL 상태관리 패턴을 적용해야 합니다!

| 패턴 | 적용 위치 | 필수 여부 |
|------|----------|----------|
| `<form @submit.prevent="listAction">` | list-search.vue | ✅ 필수 |
| `@change="listAction"` | select, radio 등 | ✅ 필수 |
| `@update:page="listMovePage"` | u-pagination | ✅ 필수 |
| watch (list-search.vue) | route → listParams 동기화 | ✅ 필수 |
| watch (list-table.vue) | route → 데이터 조회 | ✅ 필수 |
| `listAction()` | router.push로 URL 업데이트 | ✅ 필수 |
| `resetAction()` | 검색 초기화 | ✅ 필수 |

### 1. 모달 없는 상세 표시 (two-depth 고유)

```typescript
// crud 패턴 (모달)
const goDetail = (seq: number) => {
  selectedKey.value = seq;
  isOpenDetail.value = true;  // 모달 오픈
};

// two-depth 패턴 (인라인)
const goDetail = (seq: number) => {
  activeSeq.value = seq;
  store.detail(seq);  // 우측에 바로 표시
};
```

### 2. 첫 번째 항목 자동 선택 (two-depth 고유)

```typescript
watch(
  listData,
  (newData) => {
    if (newData.length > 0 && activeSeq.value === 0) {
      activeSeq.value = newData[0].[pk]Seq;
      store.detail(newData[0].[pk]Seq);
    }
  },
  { immediate: true }
);
```

### 3. 선택 항목 하이라이트 (two-depth 고유)

```vue
<div :class="[activeSeq === item.[pk]Seq ? 'font-bold text-primary' : '']">
```

---

## 라우트 설정

```typescript
// _[페이지명].routes.ts
import type { RouteRecordRaw } from 'vue-router';

export const [moduleName]TwoDepthRoutes: RouteRecordRaw = {
  path: '/[모듈명]',
  name: '[ModuleName]TwoDepth',
  redirect: '/[모듈명]/list',
  children: [
    {
      path: 'list',
      name: '[ModuleName]TwoDepthList',
      component: () => import('./list.vue')
    }
  ]
};
```
