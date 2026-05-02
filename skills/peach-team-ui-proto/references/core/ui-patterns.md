# UI 패턴 비교 가이드

## 목차

- [빠른 선택 플로우차트](#빠른-선택-플로우차트)
- [기본 UI 패턴 비교](#기본-ui-패턴-비교)
- [패턴 1: crud (목록 + 모달)](#패턴-1-crud-목록--모달)
- [패턴 2: page (별도 페이지 전환)](#패턴-2-page-별도-페이지-전환)
- [패턴 3: two-depth (좌우 분할)](#패턴-3-two-depth-좌우-분할)
- [패턴 4: infinite-scroll (무한 스크롤)](#패턴-4-infinite-scroll-무한-스크롤)
- [패턴 5: show-more (더보기 버튼)](#패턴-5-show-more-더보기-버튼)
- [패턴 6: select-list (선택 모달)](#패턴-6-select-list-선택-모달)
- [추가 옵션](#추가-옵션)
- [고급 UI 패턴](#고급-ui-패턴)
- [패턴 조합 예시](#패턴-조합-예시)

---

## 빠른 선택 플로우차트

```
┌─────────────────────────────────────────────────────────────────┐
│                      UI 패턴 선택 가이드                         │
└─────────────────────────────────────────────────────────────────┘

Q1: 입력 항목이 몇 개인가요?
├── 50개 이상 → mega-form
├── 10개 이상 → page (별도 페이지)
└── 10개 미만 → Q2로

Q2: URL 공유가 필요한가요?
├── 필요 (상세 URL 북마크) → page
└── 불필요 → crud (모달)

Q3: 특수 UI가 필요한가요?
├── 목록+상세 동시 표시 → two-depth
├── 피드형/모바일 최적화 → infinite-scroll
├── 더보기 버튼 방식 → show-more
├── 데이터 참조 선택 → select-list
├── 일정 관리 → calendar
├── 상태별 카드 관리 → kanban
├── 탭 내 독립 리스트 → tab-list
└── 일괄 처리 작업 → batch-process
```

---

## 기본 UI 패턴 비교

| 패턴 | 설명 | 사용 시기 | 참조 |
|------|------|----------|------|
| **crud** | 목록 + 모달 방식 | 기본, 입력 10개 미만 | `pages/crud/` |
| **page** | 목록 + 별도 페이지 | 입력 10개 이상, URL 공유 필요 | `pages/crud/detail-page.vue` |
| **two-depth** | 좌우 분할 레이아웃 | 목록/상세 동시 표시 | `pages/two-depth/` |
| **infinite-scroll** | 무한 스크롤 | 피드형, 모바일, 대량 데이터 | `pages/infinite-scroll-list/` |
| **show-more** | 더보기 버튼 | 적은 데이터, 단계별 로드 | `pages/show-more-list/` |
| **select-list** | 선택 모달 | 다른 화면에서 데이터 참조 | `pages/select-list/` |

---

## 패턴 1: crud (목록 + 모달)

**사용 시기**: 기본 CRUD, 입력 항목 10개 미만

**생성 파일**:
```
pages/[모듈명]/
├── list.vue           ← 껍데기 (search + table import)
├── list-search.vue    ← 검색 영역
├── list-table.vue     ← 테이블 + 버튼
└── _[모듈명].routes.ts

modals/
├── insert.modal.vue   ← 등록 모달
├── update.modal.vue   ← 수정 모달
├── detail.modal.vue   ← 상세 모달
└── _[모듈명].validator.ts
```

**핵심 코드 패턴**:
```typescript
// list-table.vue
const isOpenInsert = ref(false);
const isOpenDetail = ref(false);
const isOpenUpdate = ref(false);
const selectedKey = ref(0);

const goDetail = (seq: number) => {
  selectedKey.value = seq;
  isOpenDetail.value = true;
};
```

**참조**: `front/src/modules/test-data/pages/crud/`

---

## 패턴 2: page (별도 페이지 전환)

**사용 시기**: 입력 항목 10개 이상, URL 공유 필요

**생성 파일**:
```
pages/[모듈명]/
├── list.vue
├── list-search.vue
├── list-table.vue
├── detail-page.vue    ← 상세 페이지 (탭 구조)
└── _[모듈명].routes.ts
```

**핵심 코드 패턴**:
```typescript
// list-table.vue
const goDetail = (seq: number) => {
  router.push(`/[모듈명]/detail/${seq}`);
};

// detail-page.vue
const route = useRoute();
const seq = computed(() => Number(route.params.seq));

onMounted(() => {
  store.detail(seq.value);
});
```

**참조**: `front/src/modules/test-data/pages/crud/detail-page.vue`

---

## 패턴 3: two-depth (좌우 분할)

**사용 시기**: 목록과 상세를 동시에 표시

**생성 파일**:
```
pages/[모듈명]/
├── list.vue           ← 좌우 분할 레이아웃
├── list-search.vue    ← 좌측 검색
├── list-table.vue     ← 좌측 테이블
└── list-detail.vue    ← 우측 상세 (탭 포함)

components/tab/
├── detail-tab-default.vue
└── detail-tab-xxx.vue
```

**핵심 코드 패턴**:
```vue
<!-- list.vue -->
<template>
  <div class="flex flex-row items-stretch gap-6">
    <div class="w-full max-w-[350px]">
      <u-card>
        <list-search />
        <list-table />
      </u-card>
    </div>
    <div class="w-full">
      <list-detail />
    </div>
  </div>
</template>
```

**참조**: `front/src/modules/test-data/pages/two-depth/`

---

## 패턴 4: infinite-scroll (무한 스크롤)

**사용 시기**: 피드형 UI, 모바일 최적화, 대량 데이터

**생성 파일**:
```
pages/[모듈명]/
├── list.vue
├── list-search.vue
└── list-table.vue     ← v-infinite-scroll 적용
```

**핵심 코드 패턴**:
```vue
<template>
  <perfect-scrollbar
    ref="listRef"
    v-infinite-scroll="{
      onScrollEnd: handleLoadMore,
      elementId: listRef?.id,
      threshold: 100,
      throttleDelay: 1000
    }"
    class="max-h-[70vh] overflow-y-auto"
  >
    <!-- 테이블 -->
  </perfect-scrollbar>
</template>

<script setup>
// cursor 기반 페이징
const listData = ref<Detail[]>([]);
const currentCursor = ref<string | null>(null);
const hasMore = ref(true);

const handleLoadMore = async () => {
  if (!hasMore.value) return;

  const result = await store.cursorList({
    limit: 10,
    cursor: currentCursor.value
  });

  listData.value = [...listData.value, ...result.data];
  currentCursor.value = result.nextCursor;
  hasMore.value = !!result.nextCursor;
};
</script>
```

**필수 Store 액션**:
```typescript
// store에 cursorList 액션 필요
async cursorList(params: { limit: number; cursor?: string }) {
  const res = await api.get('/[모듈]/cursor', { params });
  return res.data; // { data: [], nextCursor: string | null }
}
```

**참조**: `front/src/modules/test-data/pages/infinite-scroll-list/`

---

## 패턴 5: show-more (더보기 버튼)

**사용 시기**: 적은 데이터, 단계별 로드

**생성 파일**:
```
pages/[모듈명]/
├── list.vue
├── list-search.vue
└── list-table.vue     ← 더보기 버튼
```

**핵심 코드 패턴**:
```vue
<template>
  <div v-if="hasMore" class="text-center py-4">
    <u-button @click="loadMore">더보기</u-button>
  </div>
</template>

<script setup>
const page = ref(1);
const hasMore = computed(() => listData.value.length < totalRow.value);

const loadMore = async () => {
  page.value++;
  await store.appendList({ page: page.value });
};
</script>
```

**참조**: `front/src/modules/test-data/pages/show-more-list/`

---

## 패턴 6: select-list (선택 모달)

**사용 시기**: 다른 화면에서 데이터 참조 선택

**생성 파일**:
```
modals/
└── [모듈명]-select.modal.vue

pages/[모듈명]/
└── demo.vue           ← 사용 예제
```

**핵심 코드 패턴**:
```vue
<!-- 호출하는 쪽 -->
<template>
  <u-button @click="isOpenSelect = true">데이터 선택</u-button>

  <[모듈명]-select-modal
    v-model:open="isOpenSelect"
    :select-list="selectedData"
    @select-ok="onSelectOk"
  />
</template>

<script setup>
const selectedData = ref([]);
const onSelectOk = (list) => {
  selectedData.value = [...list];
};
</script>

<!-- select.modal.vue -->
<script setup>
const props = defineProps<{
  open: boolean;
  selectList: any[];
}>();

const emit = defineEmits(['update:open', 'select-ok']);

const handleSelect = () => {
  emit('select-ok', selectedItems.value);
  emit('update:open', false);
};
</script>
```

**참조**: `front/src/modules/test-data/pages/select-list/`

---

## 추가 옵션

### 옵션 1: excel (엑셀 다운로드/업로드)

**조합 예시**: `crud + excel`, `two-depth + excel`

**추가 파일**:
```
modals/
├── excel-upload.modal.vue
└── _[모듈명]-excel.validator.ts
```

**list-table.vue에 추가**:
```vue
<template>
  <div class="flex space-x-2">
    <u-button @click="downloadExcel">엑셀 다운로드</u-button>
    <u-button @click="isOpenExcelUpload = true">엑셀 업로드</u-button>
  </div>

  <excel-upload-modal
    v-model:open="isOpenExcelUpload"
    @upload-ok="handleExcelUpload"
  />
</template>
```

**참조**: `front/src/modules/test-data/pages/crud-excel/`

---

### 옵션 2: file (파일 업로드)

**조합 예시**: `crud + file`, `page + file`

**추가 파일**:
```
components/file/
└── p-[모듈명]-file-upload.vue
```

**모달에서 사용**:
```vue
<template>
  <p-[모듈명]-file-upload
    ref="fileUploadRef"
    v-model:fileList="detailData.fileList"
    storage-type="local"
  />
</template>
```

**참조**: `front/src/modules/test-data/components/file/`

---

## 고급 UI 패턴

| 패턴 | 설명 | MCP 활용 |
|------|------|----------|
| **adv-search** | 복합 검색 (5개+) | Context7 (Nuxt UI 문서) |
| **batch-process** | 순차 처리 | Context7 |
| **calendar** | 달력 UI | Context7 + Sequential |
| **kanban** | 칸반 보드 | Context7 + Sequential |
| **mega-form** | 대량 입력 폼 (50개+) | Context7 |
| **tab-list** | 탭 내 리스트 | Context7 |

### 고급 패턴 사용 시

```
고급 패턴은 test-data에 가이드 코드가 없습니다.
MCP 도구를 활용하여 구현합니다:

1. Context7로 관련 라이브러리 문서 조회
2. Sequential Thinking으로 단계별 분석
3. 기본 패턴 기반으로 확장 구현
```

---

## 패턴 조합 예시

| 요구사항 | 추천 조합 |
|----------|----------|
| 기본 CRUD + 엑셀 | `crud + excel` |
| 파일 첨부 게시판 | `crud + file` |
| 마스터-디테일 | `two-depth` |
| 모바일 피드 | `infinite-scroll` |
| 참조 데이터 선택 | `select-list` |
| 대시보드 + 엑셀 | `page + excel` |
| 복잡한 검색 조건 | `crud + adv-search` |
| 대량 데이터 일괄 처리 | `crud + batch-process` |
| 일정 관리 | `calendar` |
| 업무 진행 관리 | `kanban` |
| 복잡한 입력 폼 | `mega-form` |
| 사용자 상세 + 이력 | `page + tab-list` |
