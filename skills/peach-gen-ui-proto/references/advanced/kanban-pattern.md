# 칸반 보드 (Kanban Board) 패턴 가이드

> 이 패턴은 test-data에 가이드 코드가 없습니다. MCP(Context7)를 활용하세요.

## 목차

- [개요](#개요)
- [라이브러리](#라이브러리)
- [생성 파일 구조](#생성-파일-구조)
- [board.vue 패턴](#boardvue-패턴)
- [kanban-column.vue](#kanban-columnvue)
- [kanban-card.vue](#kanban-cardvue)
- [useKanban.ts (Composable)](#usekanbanTS-composable)
- [Store 요구사항](#store-요구사항)
- [타입 추가](#타입-추가)
- [핵심 포인트](#핵심-포인트)

---

## 개요

상태별로 카드를 관리하고 드래그 앤 드롭으로 상태를 변경하는 패턴입니다.

**사용 시기**:
- 업무 진행 상태 관리
- 프로젝트 태스크 관리
- 워크플로우 시각화

**MCP 활용**: Context7 (vuedraggable/SortableJS 문서) + Sequential Thinking

---

## 라이브러리

```bash
# vuedraggable 설치
bun add vuedraggable@next
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   └── board.vue              ← 칸반 보드 메인
├── components/
│   ├── kanban-column.vue      ← 상태별 컬럼
│   └── kanban-card.vue        ← 개별 카드
├── modals/
│   └── [모듈명]-detail.modal.vue
└── composables/
    └── useKanban.ts
```

---

## board.vue 패턴

```vue
<template>
  <div class="p-6">
    <!-- 헤더 -->
    <div class="mb-6 flex items-center justify-between">
      <h1 class="text-2xl font-bold">업무 보드</h1>
      <u-button color="primary" @click="openInsertModal">
        새 업무 추가
      </u-button>
    </div>

    <!-- 칸반 보드 -->
    <div class="flex gap-4 overflow-x-auto pb-4">
      <kanban-column
        v-for="column in columns"
        :key="column.status"
        :column="column"
        :cards="getCardsByStatus(column.status)"
        @card-move="onCardMove"
        @card-click="onCardClick"
      />
    </div>

    <!-- 상세 모달 -->
    <detail-modal
      v-model:open="isOpenDetail"
      :[pk]-seq="selectedSeq"
      @update-ok="fetchData"
      @remove-ok="fetchData"
    />

    <!-- 등록 모달 -->
    <insert-modal
      v-model:open="isOpenInsert"
      @insert-ok="fetchData"
    />
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [ModuleName]Detail } from '@/modules/[모듈명]/type/[모듈명].type';
import { ref, computed, onMounted } from 'vue';

import KanbanColumn from '../components/kanban-column.vue';
import DetailModal from '../modals/[모듈명]-detail.modal.vue';
import InsertModal from '../modals/[모듈명]-insert.modal.vue';

const store = use[ModuleName]Store();

// 컬럼 정의
const columns = [
  { status: 'WAIT', label: '대기', color: 'gray' },
  { status: 'PROGRESS', label: '진행', color: 'blue' },
  { status: 'REVIEW', label: '검토', color: 'yellow' },
  { status: 'DONE', label: '완료', color: 'green' }
];

// 모달 상태
const isOpenDetail = ref(false);
const isOpenInsert = ref(false);
const selectedSeq = ref(0);

// 전체 카드 데이터
const cards = computed(() => store.listData);

// 상태별 카드 필터링
const getCardsByStatus = (status: string) => {
  return cards.value.filter((card) => card.status === status);
};

// 카드 이동 (Optimistic UI)
const onCardMove = async (event: {
  cardSeq: number;
  fromStatus: string;
  toStatus: string;
  newIndex: number;
}) => {
  const { cardSeq, toStatus, newIndex } = event;

  // 1. UI 즉시 업데이트 (Optimistic)
  const card = cards.value.find((c) => c.[pk]Seq === cardSeq);
  if (card) {
    const originalStatus = card.status;
    card.status = toStatus;

    try {
      // 2. 백엔드 API 호출
      await store.updateStatus(cardSeq, toStatus, newIndex);

      useToast().add({
        title: '상태 변경',
        description: `${columns.find((c) => c.status === toStatus)?.label}로 이동`,
        color: 'success'
      });
    } catch (error) {
      // 3. 실패 시 롤백
      card.status = originalStatus;

      useToast().add({
        title: '이동 실패',
        description: '상태 변경에 실패했습니다.',
        color: 'error'
      });
    }
  }
};

// 카드 클릭 → 상세
const onCardClick = (card: [ModuleName]Detail) => {
  selectedSeq.value = card.[pk]Seq;
  isOpenDetail.value = true;
};

// 등록 모달 열기
const openInsertModal = () => {
  isOpenInsert.value = true;
};

// 데이터 조회
const fetchData = async () => {
  await store.list({});
};

onMounted(() => {
  fetchData();
});
</script>
```

---

## kanban-column.vue

```vue
<template>
  <div class="flex w-72 flex-shrink-0 flex-col rounded-lg bg-gray-100 dark:bg-gray-800">
    <!-- 컬럼 헤더 -->
    <div class="flex items-center justify-between p-3">
      <div class="flex items-center gap-2">
        <div :class="['h-3 w-3 rounded-full', `bg-${column.color}-500`]" />
        <span class="font-semibold">{{ column.label }}</span>
        <u-badge color="neutral" size="xs">{{ cards.length }}</u-badge>
      </div>
    </div>

    <!-- 카드 리스트 (드래그 영역) -->
    <draggable
      v-model="localCards"
      :group="{ name: 'kanban', pull: true, put: true }"
      item-key="[pk]Seq"
      class="flex-1 space-y-2 p-2 min-h-[200px]"
      :animation="200"
      ghost-class="opacity-50"
      @change="onDragChange"
    >
      <template #item="{ element }">
        <kanban-card
          :card="element"
          @click="$emit('card-click', element)"
        />
      </template>
    </draggable>

    <!-- 빈 상태 -->
    <div v-if="cards.length === 0" class="p-4 text-center text-gray-500">
      항목이 없습니다
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import draggable from 'vuedraggable';
import KanbanCard from './kanban-card.vue';

interface Column {
  status: string;
  label: string;
  color: string;
}

const props = defineProps<{
  column: Column;
  cards: any[];
}>();

const emit = defineEmits(['card-move', 'card-click']);

// 로컬 카드 상태 (드래그용)
const localCards = ref([...props.cards]);

// props 변경 시 동기화
watch(
  () => props.cards,
  (newCards) => {
    localCards.value = [...newCards];
  },
  { deep: true }
);

// 드래그 변경 이벤트
const onDragChange = (event: any) => {
  if (event.added) {
    // 다른 컬럼에서 이동해 온 경우
    emit('card-move', {
      cardSeq: event.added.element.[pk]Seq,
      fromStatus: event.added.element.status,
      toStatus: props.column.status,
      newIndex: event.added.newIndex
    });
  }
};
</script>
```

---

## kanban-card.vue

```vue
<template>
  <u-card
    class="cursor-pointer transition-shadow hover:shadow-md"
    @click="$emit('click')"
  >
    <!-- 카드 헤더 -->
    <div class="flex items-start justify-between">
      <h4 class="font-medium">{{ card.subject }}</h4>
      <u-badge :color="priorityColor" size="xs">
        {{ card.priority }}
      </u-badge>
    </div>

    <!-- 카드 설명 -->
    <p v-if="card.description" class="mt-2 text-sm text-gray-500 line-clamp-2">
      {{ card.description }}
    </p>

    <!-- 카드 푸터 -->
    <div class="mt-3 flex items-center justify-between text-xs text-gray-500">
      <div class="flex items-center gap-1">
        <u-icon name="i-lucide-calendar" />
        <span>{{ dayjs(card.dueDate).format('MM/DD') }}</span>
      </div>
      <div v-if="card.assignee" class="flex items-center gap-1">
        <u-avatar :src="card.assignee.avatar" size="xs" />
        <span>{{ card.assignee.name }}</span>
      </div>
    </div>
  </u-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import dayjs from 'dayjs';

const props = defineProps<{
  card: {
    [pk]Seq: number;
    subject: string;
    description?: string;
    priority: string;
    dueDate: string;
    assignee?: { name: string; avatar: string };
  };
}>();

defineEmits(['click']);

const priorityColor = computed(() => {
  switch (props.card.priority) {
    case 'HIGH':
      return 'red';
    case 'MEDIUM':
      return 'yellow';
    case 'LOW':
      return 'green';
    default:
      return 'gray';
  }
});
</script>
```

---

## useKanban.ts (Composable)

```typescript
// composables/useKanban.ts
import { ref, computed } from 'vue';

interface KanbanCard {
  seq: number;
  status: string;
  order: number;
  [key: string]: any;
}

interface KanbanColumn {
  status: string;
  label: string;
  color: string;
}

export function useKanban<T extends KanbanCard>(
  columns: KanbanColumn[],
  updateFn: (seq: number, status: string, order: number) => Promise<void>
) {
  const cards = ref<T[]>([]);
  const isMoving = ref(false);

  const getCardsByStatus = (status: string) => {
    return cards.value
      .filter((card) => card.status === status)
      .sort((a, b) => a.order - b.order);
  };

  const moveCard = async (
    cardSeq: number,
    toStatus: string,
    newIndex: number
  ) => {
    const card = cards.value.find((c) => c.seq === cardSeq);
    if (!card || isMoving.value) return;

    const originalStatus = card.status;
    const originalOrder = card.order;

    try {
      isMoving.value = true;

      // Optimistic update
      card.status = toStatus;
      card.order = newIndex;

      // API 호출
      await updateFn(cardSeq, toStatus, newIndex);
    } catch (error) {
      // Rollback
      card.status = originalStatus;
      card.order = originalOrder;
      throw error;
    } finally {
      isMoving.value = false;
    }
  };

  const setCards = (newCards: T[]) => {
    cards.value = newCards;
  };

  return {
    cards,
    columns,
    isMoving,
    getCardsByStatus,
    moveCard,
    setCards
  };
}
```

---

## Store 요구사항

```typescript
// [모듈명].store.ts
async updateStatus(seq: number, status: string, order?: number) {
  await api.patch(`/[모듈명]/${seq}/status`, { status, order });
}

async updateOrder(seq: number, order: number) {
  await api.patch(`/[모듈명]/${seq}/order`, { order });
}
```

---

## 타입 추가

```typescript
// [모듈명].type.ts
export interface [ModuleName]Task {
  [pk]Seq: number;
  subject: string;
  description: string;
  status: 'WAIT' | 'PROGRESS' | 'REVIEW' | 'DONE';
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
  order: number;
  dueDate: string;
  assigneeSeq: number;
  assignee?: {
    name: string;
    avatar: string;
  };
}
```

---

## 핵심 포인트

### 1. Optimistic UI

```typescript
// UI 먼저 변경
card.status = toStatus;

try {
  // API 호출
  await updateStatus(cardSeq, toStatus);
} catch {
  // 실패 시 롤백
  card.status = originalStatus;
}
```

### 2. vuedraggable 설정

```vue
<draggable
  v-model="localCards"
  :group="{ name: 'kanban', pull: true, put: true }"
  item-key="[pk]Seq"
  :animation="200"
  ghost-class="opacity-50"
  @change="onDragChange"
>
```

### 3. 컬럼 간 이동 감지

```typescript
const onDragChange = (event) => {
  if (event.added) {
    // 다른 컬럼에서 이동
    emit('card-move', { ... });
  }
  if (event.moved) {
    // 같은 컬럼 내 순서 변경
    emit('card-reorder', { ... });
  }
};
```

### 4. 가로 스크롤

```css
.board-container {
  @apply flex gap-4 overflow-x-auto pb-4;
}
```
