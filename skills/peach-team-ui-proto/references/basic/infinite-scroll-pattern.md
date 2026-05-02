# 무한 스크롤 패턴 가이드

## 개요

페이지네이션 없이 스크롤 시 자동으로 다음 데이터를 로드하는 패턴입니다.

**사용 시기**:
- 피드형 UI (SNS, 뉴스)
- 모바일 최적화
- 대량 데이터 탐색

**참조**: `front/src/modules/test-data/pages/infinite-scroll-list/`

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   ├── list.vue
│   ├── list-search.vue
│   └── list-table.vue       ← v-infinite-scroll 적용
└── modals/
    └── detail.modal.vue
```

---

## Store 요구사항

무한 스크롤은 **cursor 기반 페이징**이 필요합니다.

### Store에 추가할 액션

```typescript
// [모듈명].store.ts
async cursorList(params: { limit: number; cursor?: string; keyword?: string }) {
  const res = await api.get('/[모듈명]/cursor', { params });
  return res.data as {
    data: [ModuleName]Detail[];
    nextCursor: string | null;
  };
}
```

### Backend API 응답 형식

```json
{
  "data": [
    { "seq": 1, "subject": "제목1", ... },
    { "seq": 2, "subject": "제목2", ... }
  ],
  "nextCursor": "eyJzZXEiOjEwfQ==" // base64 인코딩된 커서, 없으면 null
}
```

---

## list-table.vue 핵심 패턴

### 템플릿

```vue
<template>
  <div>
    <div class="flex items-center justify-between py-5">
      <div class="flex items-center gap-3">
        <div>총 {{ listData.length }}개의 항목</div>
        <div v-if="isLoading" class="flex items-center gap-2 text-blue-500">
          <i class="i-lucide-loader-2 animate-spin"></i>
          <span class="text-sm">로딩 중...</span>
        </div>
      </div>
    </div>

    <perfect-scrollbar
      id="infinite-scroll-container"
      ref="listRef"
      v-infinite-scroll="{
        onScrollEnd: handleLoadMore,
        elementId: listRef?.id,
        threshold: 100,
        throttleDelay: 1000
      }"
      class="max-h-[70vh] overflow-y-auto"
    >
      <div v-if="listData.length > 0">
        <easy-data-table
          :headers="headers"
          :items="listData"
          :rows-per-page="999999"
          hide-footer
          hide-rows-per-page
          @click-row="onTableRowClick"
        >
          <!-- 슬롯들 -->
        </easy-data-table>

        <!-- 추가 로딩 상태 -->
        <div v-if="isLoading && listData.length > 0" class="py-5 text-center">
          <div class="flex items-center justify-center gap-2 text-blue-500">
            <i class="i-lucide-loader-2 animate-spin"></i>
            <span>추가 데이터를 불러오는 중...</span>
          </div>
        </div>

        <!-- 더 이상 데이터 없음 -->
        <div v-if="!hasMore && listData.length > 0" class="py-5 text-center">
          <div class="text-gray-500">모든 데이터를 불러왔습니다.</div>
        </div>
      </div>

      <div v-else-if="!isLoading" class="py-5 text-center">
        <u-card>
          <div class="mt-5 mb-5">조회된 내역이 없습니다.</div>
        </u-card>
      </div>
    </perfect-scrollbar>

    <!-- 초기 로딩 상태 -->
    <div v-if="isLoading && listData.length === 0" class="py-5 text-center">
      <u-card>
        <div class="mt-5 mb-5">
          <u-icon name="i-lucide-loader-2" class="animate-spin" />
          데이터를 불러오는 중...
        </div>
      </u-card>
    </div>

    <!-- Detail Modal -->
    <detail :[pk]-seq="selectedKey" v-model:open="isOpenDetail" />
  </div>
</template>
```

### 스크립트

```typescript
<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [ModuleName]Detail, [ModuleName]CursorSearchDto } from '@/modules/[모듈명]/type/[모듈명].type';
import { FormService } from '@/modules/_common/services/form.service.ts';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import dayjs from 'dayjs';
import { ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { type Header } from 'vue3-easy-data-table';

import Detail from '../../modals/detail.modal.vue';

const route = useRoute();
const router = useRouter();
const store = use[ModuleName]Store();

// 로컬 상태로 cursor-based 리스트 데이터 관리
const listData = ref<[ModuleName]Detail[]>([]);
const currentCursor = ref<string | null>(null);
const hasMore = ref<boolean>(true);
const isLoading = ref<boolean>(false);
const isLoadingMore = ref<boolean>(false); // 중복 호출 방지
const listRef = ref<HTMLElement | null>(null);

// Modal 상태
const isOpenDetail = ref(false);
const selectedKey = ref(0);

// 검색 파라미터
const listParams = ref<[ModuleName]CursorSearchDto>({
  startDate: dayjs().format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  keyword: '',
  limit: 10
});

// 테이블 헤더
const headers: Header[] = [
  { text: '아이디', value: '[pk]Seq', width: 100 },
  { text: '제목', value: 'subject', width: 300 },
  { text: '등록일', value: 'insertDate', width: 150 },
  { text: '비고', value: 'handle', width: 120 }
];

// 무한 스크롤 데이터 로드
const handleLoadMore = async () => {
  // 중복 호출 방지
  if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

  try {
    isLoadingMore.value = true;
    isLoading.value = true;

    const params = {
      limit: listParams.value.limit,
      cursor: currentCursor.value || undefined,
      keyword: listParams.value.keyword || undefined
    };

    const result = await store.cursorList(params);

    // 기존 데이터에 새 데이터 추가
    listData.value = [...listData.value, ...result.data];
    currentCursor.value = result.nextCursor;
    hasMore.value = !!result.nextCursor;
  } catch (error) {
    console.error('Failed to load more data:', error);
  } finally {
    isLoading.value = false;
    // 로딩 완료 후 약간의 지연을 두고 플래그 해제
    setTimeout(() => {
      isLoadingMore.value = false;
    }, 300);
  }
};

// 상세 보기
const goDetail = ([pk]Seq: number) => {
  selectedKey.value = [pk]Seq;
  isOpenDetail.value = true;
};

// 테이블 행 클릭
const onTableRowClick = (item: [ModuleName]Detail, event: Event) => {
  if ((event.target as HTMLElement).tagName.toLowerCase() === 'button') return;
  goDetail(item.[pk]Seq);
};

// 초기 데이터 조회
const getList = async () => {
  await FormService.loading(async () => {
    isLoading.value = true;
    try {
      const params = {
        limit: listParams.value.limit,
        cursor: undefined,
        keyword: listParams.value.keyword || undefined
      };

      const result = await store.cursorList(params);

      // 새로운 검색이므로 기존 데이터 초기화
      listData.value = result.data;
      currentCursor.value = result.nextCursor;
      hasMore.value = !!result.nextCursor;
    } finally {
      isLoading.value = false;
    }
  });
};

// 검색 초기화
const handleReset = () => {
  const params = {
    startDate: dayjs().format('YYYY-MM-DD'),
    endDate: dayjs().format('YYYY-MM-DD'),
    keyword: '',
    limit: 10
  };
  router.push({ query: { ...route.query, ...params } });
};

// 라우트 변경 감지
watch(
  route,
  () => {
    if (route.query && Object.keys(route.query).length > 0) {
      const { startDate, endDate, keyword, limit } = route.query;
      Object.assign(listParams.value, { startDate, endDate, keyword });

      if (limit) listParams.value.limit = Number(limit);

      if (route.path === '/[모듈명]/list') {
        getList();
      }
    } else {
      handleReset();
    }
  },
  { immediate: true, deep: true }
);
</script>
```

---

## 핵심 포인트

### 1. v-infinite-scroll 디렉티브

```vue
v-infinite-scroll="{
  onScrollEnd: handleLoadMore,    // 스크롤 끝에 도달 시 콜백
  elementId: listRef?.id,         // 스크롤 컨테이너 ID
  threshold: 100,                 // 트리거 거리 (px)
  throttleDelay: 1000             // 디바운스 간격 (ms)
}"
```

### 2. 중복 호출 방지

```typescript
const isLoadingMore = ref(false);

const handleLoadMore = async () => {
  if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

  isLoadingMore.value = true;
  // ... 로직
  setTimeout(() => {
    isLoadingMore.value = false;
  }, 300);
};
```

### 3. 데이터 누적

```typescript
// 새 검색 시 초기화
listData.value = result.data;

// 무한 스크롤 시 추가
listData.value = [...listData.value, ...result.data];
```

### 4. 로딩 상태 분리

```vue
<!-- 초기 로딩 -->
<div v-if="isLoading && listData.length === 0">

<!-- 추가 로딩 -->
<div v-if="isLoading && listData.length > 0">

<!-- 완료 상태 -->
<div v-if="!hasMore && listData.length > 0">
```

---

## 페이지네이션과 차이점

| 항목 | 페이지네이션 | 무한 스크롤 |
|------|-------------|-------------|
| API 방식 | offset/limit | cursor/limit |
| 데이터 관리 | Store | 로컬 상태 |
| 누적 여부 | 대체 | 누적 |
| UPagination | 필요 | 불필요 |

---

## 타입 추가

```typescript
// [모듈명].type.ts
export interface [ModuleName]CursorSearchDto {
  startDate: string;
  endDate: string;
  keyword: string;
  limit: number;
}

export interface [ModuleName]CursorResponse {
  data: [ModuleName]Detail[];
  nextCursor: string | null;
}
```
