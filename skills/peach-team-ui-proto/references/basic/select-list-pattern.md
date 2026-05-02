# 선택 리스트 (Select List) 패턴 가이드

## 개요

다른 화면에서 호출하여 데이터를 선택하는 모달 패턴입니다.

**사용 시기**:
- 참조 데이터 선택 (회원 선택, 상품 선택 등)
- FK 관계의 데이터 선택
- 다중 선택이 필요한 경우

**참조**: `front/src/modules/test-data/modals/list-table-select.modal.vue`

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── modals/
│   └── [모듈명]-select.modal.vue
└── pages/[페이지명]/
    └── demo.vue                   ← 사용 예제
```

---

## select.modal.vue 패턴

```vue
<template>
  <u-modal
    v-model:open="isOpen"
    :title="`${moduleLabel} 선택`"
    :ui="{ width: 'sm:max-w-4xl' }"
  >
    <!-- 검색 영역 -->
    <div class="mb-4 flex gap-2">
      <u-input
        v-model="searchKeyword"
        placeholder="검색어 입력"
        class="flex-1"
        @keyup.enter="handleSearch"
      />
      <u-button @click="handleSearch">검색</u-button>
      <u-button variant="outline" @click="handleReset">초기화</u-button>
    </div>

    <!-- 선택된 항목 표시 -->
    <div v-if="selectedItems.length > 0" class="mb-4">
      <div class="flex flex-wrap gap-2">
        <u-badge
          v-for="item in selectedItems"
          :key="item.[pk]Seq"
          color="primary"
          class="cursor-pointer"
          @click="removeItem(item)"
        >
          {{ item.subject }}
          <u-icon name="i-lucide-x" class="ml-1" />
        </u-badge>
      </div>
      <div class="mt-2 text-sm text-gray-500">
        {{ selectedItems.length }}개 선택됨
      </div>
    </div>

    <!-- 테이블 -->
    <easy-data-table
      v-model:items-selected="tableSelected"
      :headers="headers"
      :items="listData"
      :server-items-length="listTotalRow"
      hide-footer
      @click-row="onRowClick"
    >
      <template #item-subject="item">
        <div class="cursor-pointer">{{ item.subject }}</div>
      </template>
    </easy-data-table>

    <!-- 페이지네이션 -->
    <div v-if="listData.length > 0" class="flex justify-center py-3">
      <u-pagination
        v-model:page="listParams.page"
        :items-per-page="listParams.row"
        :total="listTotalRow"
        @update:page="handlePageChange"
      />
    </div>

    <!-- 푸터 버튼 -->
    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="outline" @click="handleClose">취소</u-button>
        <u-button color="primary" @click="handleSelect">
          선택 완료 ({{ selectedItems.length }})
        </u-button>
      </div>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [ModuleName]Detail, [ModuleName]PagingDto } from '@/modules/[모듈명]/type/[모듈명].type';
import { computed, ref, watch } from 'vue';
import { type Header } from 'vue3-easy-data-table';

// Props & Emits
const props = defineProps<{
  open: boolean;
  selectList: [ModuleName]Detail[];  // 이미 선택된 항목
  multi?: boolean;                    // 다중 선택 여부 (기본: true)
}>();

const emit = defineEmits<{
  'update:open': [value: boolean];
  'select-ok': [items: [ModuleName]Detail[]];
  close: [];
}>();

// 모듈 설정
const moduleLabel = '[모듈명]';

// Store 연결
const store = use[ModuleName]Store();
const listData = computed(() => store.listData);
const listTotalRow = computed(() => store.listTotalRow);

// 로컬 상태
const searchKeyword = ref('');
const selectedItems = ref<[ModuleName]Detail[]>([]);
const tableSelected = ref<[ModuleName]Detail[]>([]);

// 페이징 파라미터
const listParams = ref<[ModuleName]PagingDto>({
  page: 1,
  row: 10,
  keyword: ''
});

// 테이블 헤더
const headers: Header[] = [
  { text: 'ID', value: '[pk]Seq', width: 80 },
  { text: '제목', value: 'subject', width: 300 },
  { text: '등록일', value: 'insertDate', width: 120 }
];

// v-model:open 패턴
const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

// 목록 조회
const getList = async () => {
  await store.paging({
    ...listParams.value,
    keyword: searchKeyword.value
  });
};

// 검색
const handleSearch = () => {
  listParams.value.page = 1;
  getList();
};

// 초기화
const handleReset = () => {
  searchKeyword.value = '';
  listParams.value.page = 1;
  getList();
};

// 페이지 변경
const handlePageChange = (page: number) => {
  listParams.value.page = page;
  getList();
};

// 행 클릭 (단일 선택 모드)
const onRowClick = (item: [ModuleName]Detail) => {
  if (props.multi === false) {
    // 단일 선택: 기존 선택 대체
    selectedItems.value = [item];
  } else {
    // 다중 선택: 토글
    const index = selectedItems.value.findIndex((i) => i.[pk]Seq === item.[pk]Seq);
    if (index > -1) {
      selectedItems.value.splice(index, 1);
    } else {
      selectedItems.value.push(item);
    }
  }
};

// 선택 항목 제거
const removeItem = (item: [ModuleName]Detail) => {
  const index = selectedItems.value.findIndex((i) => i.[pk]Seq === item.[pk]Seq);
  if (index > -1) {
    selectedItems.value.splice(index, 1);
  }
};

// 선택 완료
const handleSelect = () => {
  emit('select-ok', [...selectedItems.value]);
  emit('update:open', false);
};

// 닫기
const handleClose = () => {
  emit('close');
  emit('update:open', false);
};

// 모달 열릴 때 초기화
watch(
  () => props.open,
  (newVal) => {
    if (newVal) {
      // 이미 선택된 항목 복원
      selectedItems.value = [...props.selectList];
      tableSelected.value = [...props.selectList];

      // 검색 초기화 및 목록 조회
      searchKeyword.value = '';
      listParams.value.page = 1;
      getList();
    }
  }
);

// 테이블 체크박스 동기화 (다중 선택 모드)
watch(
  tableSelected,
  (newVal) => {
    if (props.multi !== false) {
      // 현재 페이지에서의 선택 변경 반영
      const currentPageSeqs = listData.value.map((item) => item.[pk]Seq);

      // 기존 선택에서 현재 페이지 항목 제거
      selectedItems.value = selectedItems.value.filter(
        (item) => !currentPageSeqs.includes(item.[pk]Seq)
      );

      // 새로 선택된 항목 추가
      selectedItems.value.push(...newVal);
    }
  },
  { deep: true }
);
</script>
```

---

## 호출하는 쪽 사용법

### demo.vue

```vue
<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-4">데이터 선택 데모</h1>

    <!-- 선택 버튼 -->
    <div class="flex gap-4 mb-6">
      <u-button @click="openSelectModal">
        데이터 선택 ({{ selectedData.length }}개)
      </u-button>
      <u-button variant="outline" @click="clearSelected">
        선택 초기화
      </u-button>
    </div>

    <!-- 선택된 데이터 표시 -->
    <div class="bg-gray-50 rounded-lg p-4">
      <h3 class="font-semibold mb-3">선택된 데이터</h3>
      <div v-if="selectedData.length === 0" class="text-gray-500">
        선택된 데이터가 없습니다.
      </div>
      <div v-else class="space-y-2">
        <div
          v-for="item in selectedData"
          :key="item.[pk]Seq"
          class="bg-white rounded p-3 border"
        >
          <div class="font-medium">ID: {{ item.[pk]Seq }}</div>
          <div class="text-sm text-gray-600">{{ item.subject }}</div>
        </div>
      </div>
    </div>

    <!-- 선택 모달 -->
    <[module-name]-select-modal
      v-model:open="isOpenSelect"
      :select-list="selectedData"
      :multi="true"
      @select-ok="onSelectOk"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import [ModuleName]SelectModal from '@/modules/[모듈명]/modals/[모듈명]-select.modal.vue';

const isOpenSelect = ref(false);
const selectedData = ref<any[]>([]);

const openSelectModal = () => {
  isOpenSelect.value = true;
};

const onSelectOk = (items: any[]) => {
  selectedData.value = [...items];

  useToast().add({
    title: '선택 완료',
    description: `${items.length}개 항목이 선택되었습니다.`,
    color: 'success'
  });
};

const clearSelected = () => {
  selectedData.value = [];
};
</script>
```

---

## Props & Emits 인터페이스

```typescript
// Props
interface Props {
  open: boolean;                    // 모달 열림 상태
  selectList: [ModuleName]Detail[]; // 이미 선택된 항목 (복원용)
  multi?: boolean;                  // 다중 선택 여부 (기본: true)
}

// Emits
interface Emits {
  'update:open': [value: boolean];
  'select-ok': [items: [ModuleName]Detail[]];
  close: [];
}
```

---

## 단일 선택 vs 다중 선택

### 단일 선택 사용

```vue
<[module-name]-select-modal
  v-model:open="isOpen"
  :select-list="selectedData"
  :multi="false"
  @select-ok="onSelectOk"
/>
```

### 다중 선택 사용 (기본)

```vue
<[module-name]-select-modal
  v-model:open="isOpen"
  :select-list="selectedData"
  @select-ok="onSelectOk"
/>
```

---

## 핵심 포인트

### 1. 선택 항목 복원

모달이 열릴 때 이전에 선택한 항목을 복원합니다.

```typescript
watch(
  () => props.open,
  (newVal) => {
    if (newVal) {
      selectedItems.value = [...props.selectList];
    }
  }
);
```

### 2. 페이지 간 선택 유지

다른 페이지로 이동해도 선택이 유지됩니다.

```typescript
// 현재 페이지 항목만 제거하고 새 선택 추가
selectedItems.value = selectedItems.value.filter(
  (item) => !currentPageSeqs.includes(item.[pk]Seq)
);
selectedItems.value.push(...newVal);
```

### 3. 선택 항목 시각화

선택된 항목을 뱃지로 표시하고 클릭으로 제거합니다.

```vue
<u-badge
  v-for="item in selectedItems"
  :key="item.[pk]Seq"
  @click="removeItem(item)"
>
  {{ item.subject }}
  <u-icon name="i-lucide-x" />
</u-badge>
```

---

## 실제 활용 예시

### 회원 선택 후 할당

```vue
<template>
  <u-form-field label="담당자">
    <div class="flex gap-2">
      <u-input
        :model-value="assignee?.name || ''"
        readonly
        placeholder="담당자를 선택하세요"
      />
      <u-button @click="isOpenMemberSelect = true">선택</u-button>
    </div>
  </u-form-field>

  <member-select-modal
    v-model:open="isOpenMemberSelect"
    :select-list="assignee ? [assignee] : []"
    :multi="false"
    @select-ok="onAssigneeSelect"
  />
</template>

<script setup>
const assignee = ref(null);

const onAssigneeSelect = (items) => {
  assignee.value = items[0] || null;
};
</script>
```

### 상품 다중 선택

```vue
<template>
  <u-form-field label="관련 상품">
    <div class="flex flex-wrap gap-2 mb-2">
      <u-badge v-for="product in relatedProducts" :key="product.productSeq">
        {{ product.name }}
      </u-badge>
    </div>
    <u-button size="sm" @click="isOpenProductSelect = true">
      상품 추가 ({{ relatedProducts.length }})
    </u-button>
  </u-form-field>

  <product-select-modal
    v-model:open="isOpenProductSelect"
    :select-list="relatedProducts"
    @select-ok="onProductSelect"
  />
</template>
```
