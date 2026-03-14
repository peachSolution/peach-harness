# 복합 검색 (Advanced Search) 패턴 가이드

> 이 패턴은 test-data에 가이드 코드가 없습니다. MCP(Context7)를 활용하세요.

## 목차

- [개요](#개요)
- [UI 구조](#ui-구조)
- [생성 파일 구조](#생성-파일-구조)
- [list-search.vue 패턴](#list-searchvue-패턴)
- [Slideover 방식 (대안)](#slideover-방식-대안)
- [URL Query String 관리](#url-query-string-관리)
- [핵심 포인트](#핵심-포인트)

---

## 개요

검색 조건이 5개 이상일 때 화면 효율성을 위해 확장형 검색 UI를 사용하는 패턴입니다.

**사용 시기**:
- 검색 조건이 5개 이상
- 복잡한 필터링이 필요한 관리자 화면
- 사용자별 검색 조건 조합이 다양한 경우

**MCP 활용**: Context7 (Nuxt UI 공식 문서 참조)

---

## UI 구조

```
┌─────────────────────────────────────────────────────────────┐
│  [핵심 검색 필드]  [검색어 입력]  [검색] [상세검색 ▼]       │
├─────────────────────────────────────────────────────────────┤
│  ▼ 상세 검색 (펼침 시)                                      │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │  기간       │  상태       │  카테고리   │  담당자     │ │
│  ├─────────────┼─────────────┼─────────────┼─────────────┤ │
│  │  유형       │  등급       │  지역       │  ...        │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
│                                      [초기화] [검색]        │
└─────────────────────────────────────────────────────────────┘
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   ├── list.vue
│   ├── list-search.vue        ← 확장형 검색 UI
│   └── list-table.vue
└── composables/
    └── useSearchParams.ts     ← URL 파라미터 관리
```

---

## list-search.vue 패턴

```vue
<template>
  <div class="space-y-4">
    <!-- 기본 검색 영역 (항상 표시) -->
    <div class="flex items-center gap-4">
      <!-- 핵심 검색 필드 -->
      <u-select
        v-model="listParams.searchType"
        :options="searchTypeOptions"
        class="w-32"
      />
      <u-input
        v-model="listParams.keyword"
        placeholder="검색어 입력"
        class="w-64"
        @keyup.enter="handleSearch"
      />

      <u-button @click="handleSearch">검색</u-button>

      <!-- 상세 검색 토글 -->
      <u-button
        variant="ghost"
        :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="isExpanded = !isExpanded"
      >
        상세 검색
      </u-button>
    </div>

    <!-- 확장 검색 영역 -->
    <u-collapsible v-model:open="isExpanded">
      <div class="rounded-lg border bg-gray-50 p-4 dark:bg-gray-800">
        <div class="grid grid-cols-4 gap-4">
          <!-- 기간 -->
          <u-form-field label="기간">
            <div class="flex gap-2">
              <u-popover>
                <u-button variant="outline" size="sm">
                  {{ listParams.startDate || '시작일' }}
                </u-button>
                <template #content>
                  <date-picker v-model="listParams.startDate" />
                </template>
              </u-popover>
              <span class="text-gray-500">~</span>
              <u-popover>
                <u-button variant="outline" size="sm">
                  {{ listParams.endDate || '종료일' }}
                </u-button>
                <template #content>
                  <date-picker v-model="listParams.endDate" />
                </template>
              </u-popover>
            </div>
          </u-form-field>

          <!-- 상태 -->
          <u-form-field label="상태">
            <u-select
              v-model="listParams.status"
              :options="statusOptions"
              placeholder="전체"
            />
          </u-form-field>

          <!-- 카테고리 -->
          <u-form-field label="카테고리">
            <u-select
              v-model="listParams.categorySeq"
              :options="categoryOptions"
              placeholder="전체"
            />
          </u-form-field>

          <!-- 담당자 -->
          <u-form-field label="담당자">
            <u-input
              v-model="listParams.managerName"
              placeholder="담당자명"
            />
          </u-form-field>

          <!-- 유형 -->
          <u-form-field label="유형">
            <u-select
              v-model="listParams.type"
              :options="typeOptions"
              placeholder="전체"
            />
          </u-form-field>

          <!-- 등급 -->
          <u-form-field label="등급">
            <u-select
              v-model="listParams.grade"
              :options="gradeOptions"
              placeholder="전체"
            />
          </u-form-field>

          <!-- 사용여부 -->
          <u-form-field label="사용여부">
            <u-select
              v-model="listParams.isUse"
              :options="isUseOptions"
              placeholder="전체"
            />
          </u-form-field>

          <!-- 정렬 -->
          <u-form-field label="정렬">
            <u-select
              v-model="listParams.sortData"
              :options="sortOptions"
            />
          </u-form-field>
        </div>

        <!-- 버튼 영역 -->
        <div class="mt-4 flex justify-end gap-2">
          <u-button variant="outline" @click="handleReset">초기화</u-button>
          <u-button color="primary" @click="handleSearch">검색</u-button>
        </div>
      </div>
    </u-collapsible>

    <!-- 적용된 필터 표시 -->
    <div v-if="hasActiveFilters" class="flex flex-wrap gap-2">
      <u-badge
        v-for="filter in activeFilters"
        :key="filter.key"
        color="primary"
        variant="soft"
        class="cursor-pointer"
        @click="removeFilter(filter.key)"
      >
        {{ filter.label }}: {{ filter.value }}
        <u-icon name="i-lucide-x" class="ml-1" />
      </u-badge>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import dayjs from 'dayjs';

const route = useRoute();
const router = useRouter();

// 확장 상태
const isExpanded = ref(false);

// 검색 파라미터
const listParams = ref({
  searchType: 'all',
  keyword: '',
  startDate: dayjs().subtract(1, 'month').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  status: '',
  categorySeq: '',
  managerName: '',
  type: '',
  grade: '',
  isUse: '',
  sortData: 'insertDate,desc'
});

// 옵션들
const searchTypeOptions = [
  { label: '전체', value: 'all' },
  { label: '제목', value: 'subject' },
  { label: '내용', value: 'content' },
  { label: 'ID', value: 'seq' }
];

const statusOptions = [
  { label: '전체', value: '' },
  { label: '대기', value: 'WAIT' },
  { label: '진행', value: 'PROGRESS' },
  { label: '완료', value: 'DONE' }
];

const isUseOptions = [
  { label: '전체', value: '' },
  { label: '사용', value: 'Y' },
  { label: '미사용', value: 'N' }
];

const sortOptions = [
  { label: '최신순', value: 'insertDate,desc' },
  { label: '오래된순', value: 'insertDate,asc' },
  { label: 'ID순', value: 'seq,asc' }
];

// 활성 필터 계산
const activeFilters = computed(() => {
  const filters = [];
  if (listParams.value.status) {
    const opt = statusOptions.find((o) => o.value === listParams.value.status);
    filters.push({ key: 'status', label: '상태', value: opt?.label });
  }
  if (listParams.value.isUse) {
    const opt = isUseOptions.find((o) => o.value === listParams.value.isUse);
    filters.push({ key: 'isUse', label: '사용여부', value: opt?.label });
  }
  // ... 더 많은 필터
  return filters;
});

const hasActiveFilters = computed(() => activeFilters.value.length > 0);

// 필터 제거
const removeFilter = (key: string) => {
  (listParams.value as any)[key] = '';
  handleSearch();
};

// 검색 실행
const handleSearch = () => {
  router.push({
    query: {
      ...listParams.value,
      page: 1,
      time: dayjs().format('YYYYMMDDHHmmss')
    }
  });
};

// 초기화
const handleReset = () => {
  listParams.value = {
    searchType: 'all',
    keyword: '',
    startDate: dayjs().subtract(1, 'month').format('YYYY-MM-DD'),
    endDate: dayjs().format('YYYY-MM-DD'),
    status: '',
    categorySeq: '',
    managerName: '',
    type: '',
    grade: '',
    isUse: '',
    sortData: 'insertDate,desc'
  };
  handleSearch();
};

// URL 파라미터 동기화
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      Object.assign(listParams.value, route.query);
    }
  },
  { immediate: true, deep: true }
);
</script>
```

---

## Slideover 방식 (대안)

모바일 또는 더 많은 필터가 필요할 때:

```vue
<template>
  <div>
    <!-- 기본 검색 + 필터 버튼 -->
    <div class="flex items-center gap-4">
      <u-input v-model="keyword" placeholder="검색어" />
      <u-button @click="handleSearch">검색</u-button>
      <u-button variant="ghost" @click="isSlideoverOpen = true">
        <u-icon name="i-lucide-sliders" />
        필터 ({{ activeFilterCount }})
      </u-button>
    </div>

    <!-- Slideover -->
    <u-slideover v-model:open="isSlideoverOpen" title="상세 검색">
      <div class="space-y-4 p-4">
        <!-- 필터 필드들 -->
        <u-form-field label="상태">
          <u-select v-model="filters.status" :options="statusOptions" />
        </u-form-field>
        <!-- ... -->
      </div>

      <template #footer>
        <div class="flex gap-2">
          <u-button variant="outline" @click="resetFilters">초기화</u-button>
          <u-button color="primary" @click="applyFilters">적용</u-button>
        </div>
      </template>
    </u-slideover>
  </div>
</template>
```

---

## URL Query String 관리

### useSearchParams.ts

```typescript
// composables/useSearchParams.ts
import { ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';

export function useSearchParams<T extends Record<string, any>>(
  defaultParams: T
) {
  const route = useRoute();
  const router = useRouter();
  const params = ref({ ...defaultParams });

  // URL → 상태 동기화
  watch(
    () => route.query,
    (query) => {
      if (Object.keys(query).length > 0) {
        Object.keys(defaultParams).forEach((key) => {
          if (query[key] !== undefined) {
            (params.value as any)[key] = query[key];
          }
        });
      }
    },
    { immediate: true }
  );

  // 검색 실행
  const search = () => {
    router.push({ query: { ...params.value, page: 1 } });
  };

  // 초기화
  const reset = () => {
    params.value = { ...defaultParams };
    search();
  };

  return { params, search, reset };
}
```

### 사용 예시

```typescript
const { params, search, reset } = useSearchParams({
  keyword: '',
  status: '',
  startDate: dayjs().subtract(1, 'month').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD')
});
```

---

## 핵심 포인트

### 1. 핵심 필드 항상 노출

가장 자주 사용하는 1-2개 필드는 항상 표시합니다.

### 2. URL 동기화

새로고침 시 검색 조건이 유지되어야 합니다.

```typescript
router.push({ query: { ...params } });
```

### 3. 적용된 필터 시각화

현재 적용된 필터를 뱃지로 표시하고, 클릭으로 개별 해제합니다.

### 4. 반응형 고려

모바일에서는 Slideover, 데스크톱에서는 Collapsible 사용을 고려합니다.
