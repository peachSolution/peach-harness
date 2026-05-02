# Page 패턴 (파일 분리)

> test-data/pages/crud 기반 페이지 구조 패턴

## 목차

- [파일 구조](#파일-구조)
- [list.vue (껍데기)](#listvue-껍데기)
- [list-search.vue (검색 영역)](#list-searchvue-검색-영역)
- [list-table.vue (테이블 영역)](#list-tablevue-테이블-영역)
- [_페이지명.routes.ts](#_페이지명routests)
- [URL watch 패턴 (필수)](#url-watch-패턴-필수)
- [핵심 패턴](#핵심-패턴)

---

## 파일 구조

```
front/src/modules/[모듈명]/pages/[페이지명]/
├── list.vue          ← 목록 페이지 (껍데기)
├── list-search.vue   ← 검색 영역 컴포넌트
├── list-table.vue    ← 테이블 영역 컴포넌트
└── _[페이지명].routes.ts  ← 라우트 설정
```

---

## list.vue (껍데기)

```vue
<template>
  <div class="mb-6"></div>
  <!-- E : HEAD -->
  <list-search></list-search>
  <list-table></list-table>
</template>

<script setup lang="ts">
import ListSearch from './list-search.vue';
import ListTable from './list-table.vue';
</script>
```

**핵심 원칙:**
- 단순 래퍼 컴포넌트
- 비즈니스 로직 없음
- 자식 컴포넌트만 임포트

---

## list-search.vue (검색 영역)

```vue
<template>
  <form @submit.prevent="listAction">
    <div class="w-full rounded-lg border border-gray-300 bg-white dark:border-gray-700 dark:bg-gray-800">
      <div class="p-3">
        <div class="flex w-full flex-col gap-3 lg:flex-row">
          <!-- 조회기간 -->
          <u-form-field label="조회기간">
            <div class="flex flex-col items-center gap-2 lg:flex-row">
              <p-date-picker v-model="listParams.startDate" @update:modelValue="listAction" />
              <span class="hidden lg:block">~</span>
              <p-date-picker v-model="listParams.endDate" @update:modelValue="listAction" />
              <p-day-select v-model="listParams.startDate" @setDate="setDate" />
            </div>
          </u-form-field>

          <!-- 키워드 -->
          <u-form-field label="키워드" class="flex-1">
            <div class="flex items-center gap-2">
              <u-field-group class="w-full">
                <u-input v-model="listParams.keyword" placeholder="키워드를 입력하세요." />
                <u-button type="submit" size="sm" color="primary" icon="i-lucide-search" />
              </u-field-group>
              <u-button variant="soft" icon="i-lucide-plus" label="상세검색" @click="toggleSearch" />
            </div>
          </u-form-field>
        </div>

        <!-- 상세검색 (토글) -->
        <div v-if="isSearchExpanded" class="mt-3 flex flex-col gap-3">
          <!-- 상세 검색 필드들 -->
        </div>
      </div>

      <!-- 하단 버튼 (상세검색 시) -->
      <div v-if="isSearchExpanded" class="flex justify-between rounded-b-lg border-t p-3">
        <u-button icon="i-lucide-rotate-ccw" label="초기화" @click="resetAction" />
        <div class="flex items-center gap-2">
          <u-button type="submit" icon="i-lucide-search" label="상세조건 검색" />
          <u-button variant="outline" label="닫기" @click="toggleSearch" />
        </div>
      </div>
    </div>
  </form>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import dayjs from 'dayjs';
import type { [모듈명PascalCase]SearchDto } from '@/modules/[모듈명]/type/[모듈명].type';

const route = useRoute();
const router = useRouter();

// 검색 파라미터 로컬 상태로 관리
const listParams = ref<[모듈명PascalCase]SearchDto>({
  startDate: dayjs().subtract(5, 'year').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  keyword: '',
  opt: 'all',
  isUse: '',
  selected: ''
});

// 검색 영역 확장/축소 상태
const isSearchExpanded = ref(false);

const toggleSearch = () => {
  isSearchExpanded.value = !isSearchExpanded.value;
};

const setDate = (date: any) => {
  listParams.value.startDate = date.startDate;
  listParams.value.endDate = date.endDate;
};

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
    opt: 'all',
    isUse: '',
    selected: ''
  };
  router.push({
    query: {
      ...route.query,
      ...listParams.value,
      sortBy: 'insertDate',
      sortType: 'desc',
      sortData: 'insertDate,desc',
      row: 10,
      page: 1
    }
  });
};

// ⚠️ URL watch 패턴 (필수)
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      const { startDate, endDate, keyword, opt, isUse, selected } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword, opt, isUse, selected });
    } else {
      resetAction();
    }
  },
  { immediate: true, deep: true }
);
</script>
```

---

## list-table.vue (테이블 영역)

```vue
<template>
  <div class="flex items-center justify-between py-5">
    <div class="flex items-center gap-2">
      <u-button variant="outline" @click="removeCheck">선택삭제</u-button>
      <u-button variant="outline" @click="checkChangeUse">선택사용</u-button>
      <p-nuxt-select v-model="listParams.sortData" :options="sortList" @change="handleSortChange" />
      <p-nuxt-select v-model="listParams.row" :options="rowList" @change="listAction" />
      <div>선택({{ listCheckBoxs.length }}개)</div>
    </div>
    <div class="flex space-x-2">
      <u-button variant="solid" color="primary" @click="goInsert">글 등록</u-button>
    </div>
  </div>

  <div v-if="listData.length > 0">
    <easy-data-table
      v-model:server-options="listParams"
      v-model:items-selected="listCheckBoxs"
      :server-items-length="listTotalRow"
      :headers="headers"
      :items="listData"
      :sort-by="listParams.sortBy"
      :sort-type="listParams.sortType"
      server-side-sorting
      hide-footer
      @update-sort="updateSort"
      @click-row="onTableRowClick"
    >
      <!-- 슬롯 정의 -->
    </easy-data-table>
  </div>
  <div v-else class="py-5 text-center">
    <u-card>
      <div class="mt-5 mb-5">조회된 내역이 없습니다.</div>
    </u-card>
  </div>

  <div v-if="listData.length > 0" class="flex justify-center py-3">
    <u-pagination
      v-model:page="listParams.page"
      :items-per-page="listParams.row"
      :total="listTotalRow"
      @update:page="listMovePage"
    />
  </div>

  <!-- 모달들 -->
  <insert v-model:open="isOpenInsert" @insert-ok="listAction" />
  <detail :test-seq="selectedKey" v-model:open="isOpenDetail" @remove-ok="listAction" @go-update="goUpdate" />
  <update :test-seq="selectedKey" v-model:open="isOpenUpdate" @update-ok="listAction" />
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import dayjs from 'dayjs';
import { FormService } from '@/modules/_common/services/form.service.ts';
import { use[모듈명PascalCase]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [모듈명PascalCase]ListItem, [모듈명PascalCase]PagingDto } from '@/modules/[모듈명]/type/[모듈명].type';
import { type Header } from 'vue3-easy-data-table';

// 모달 컴포넌트 임포트
import Detail from '../../modals/detail.modal.vue';
import Insert from '../../modals/insert.modal.vue';
import Update from '../../modals/update.modal.vue';

const route = useRoute();
const router = useRouter();
const [모듈명]Store = use[모듈명PascalCase]Store();
const listData = computed(() => [모듈명]Store.listData);
const listTotalRow = computed(() => [모듈명]Store.listTotalRow);

// 페이지별 첫 번호 계산
const rowNumber = computed(() =>
  listTotalRow.value - listParams.value.row * (listParams.value.page - 1)
);

// 체크박스 선택 상태 로컬 관리
const listCheckBoxs = ref<[모듈명PascalCase]ListItem[]>([]);

// selectedKey 로컬 상태로 관리
const selectedKey = ref(0);

// 테이블 파라미터 로컬 상태로 관리
const listParams = ref({} as [모듈명PascalCase]PagingDto);

// 모달 상태
const isOpenInsert = ref(false);
const isOpenDetail = ref(false);
const isOpenUpdate = ref(false);

// 정렬 옵션 (sortBy,sortType 형식)
// handleSortChange에서 split(',')으로 분리하여 사용
const sortList = [
  { text: '등록일순', value: 'insertDate,asc' },
  { text: '등록일역순', value: 'insertDate,desc' },
  { text: '아이디', value: '[pk]Seq,asc' },
  { text: '아이디역순', value: '[pk]Seq,desc' }
];

// 페이지당 표시 개수 옵션
const rowList = [
  { text: '10개', value: 10 },
  { text: '20개', value: 20 },
  { text: '30개', value: 30 },
  { text: '50개', value: 50 },
  { text: '100개', value: 100 }
];

const headers: Header[] = [
  { text: '번호', value: 'nIndex', width: 100, fixed: true },
  { text: '아이디', value: '[pk]Seq', width: 100, sortable: true },
  { text: '제목', value: 'subject', width: 300, sortable: true },
  { text: '사용여부', value: 'isUse', width: 100 },
  { text: '등록일', value: 'insertDate', width: 100, sortable: true },
  { text: '비고', value: 'handle', width: 50 }
];

// ===== 액션 메서드들 =====

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

const listMovePage = async (page: number) => {
  listParams.value.page = page;
  listAction();
};

const listAction = () => {
  listParams.value.time = dayjs().format('YYYYMMDDHHmmssSSS');
  router.push({ query: { ...route.query, ...listParams.value } });
};

// 정렬 변경 핸들러 (test-data 표준 패턴)
const handleSortChange = () => {
  listParams.value.sortBy = listParams.value.sortData?.split(',')[0];
  listParams.value.sortType = listParams.value.sortData?.split(',')[1];
  listAction();
};

const getList = async () => {
  await FormService.loading(async () => {
    await [모듈명]Store.paging(listParams.value);

    if (listData.value.length === 0 && listParams.value.page > 1) {
      await router.push({ query: { ...route.query, page: 1 } });
      return;
    }
  });
};

// ⚠️ URL watch 패턴 (필수)
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

## _[페이지명].routes.ts

```typescript
import type { RouteRecordRaw } from 'vue-router';

export const [모듈명]Routes: RouteRecordRaw = {
  path: '/[모듈명]',
  name: '[모듈명]',
  redirect: '/[모듈명]/list',
  children: [
    {
      path: 'list',
      name: '[모듈명]-list',
      component: () => import('./list.vue')
    },
    {
      path: 'detail/:seq',
      name: '[모듈명]-detail',
      component: () => import('./detail-page.vue')
    }
  ]
};
```

---

## URL watch 패턴 (필수)

### list-search.vue

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      // 검색 관련 파라미터만 listParams에 적용
      const { startDate, endDate, keyword, opt, isUse, selected } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword, opt, isUse, selected });
    } else {
      resetAction();
    }
  },
  { immediate: true, deep: true }
);
```

### list-table.vue

```typescript
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      Object.assign(listParams.value, route.query);
      listParams.value.page = Number(listParams.value.page);
      listParams.value.row = Number(listParams.value.row);

      // 해당 경로일 때만 조회
      if (route.path === '/[모듈명]/list') {
        getList();
      }
    }
  },
  { immediate: true, deep: true }
);
```

---

## 핵심 패턴

### 1. 파일 분리

```
list.vue → 껍데기 (로직 없음)
├── list-search.vue → 검색 상태/로직
└── list-table.vue → 테이블/모달 상태/로직
```

### 2. router.push로 상태 관리

```typescript
// 검색/페이징 시 URL query로 상태 관리
router.push({
  query: {
    ...route.query,
    ...listParams.value,
    page: 1,
    time: dayjs().format('YYYYMMDDHHmmssSSS')
  }
});
```

### 3. watch로 URL 동기화

```typescript
// URL 변경 시 로컬 상태 동기화 + API 호출
watch(route, () => { ... }, { immediate: true, deep: true });
```
