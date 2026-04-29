# 순차 처리 (Batch Process) 패턴 가이드

## 개요

다중 선택된 데이터를 순차적으로 처리하며 진행 상황을 실시간으로 보여주는 패턴입니다.

**사용 시기**:
- 다수 항목 일괄 상태 변경
- 대량 삭제/수정 작업
- 일괄 발송/처리 작업

**MCP 활용**: Context7 (Nuxt UI 공식 문서 참조)

---

## UI 구조

```
┌─────────────────────────────────────────────────────────────┐
│  일괄 처리 중...                                    [X 닫기] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ████████████████████░░░░░░░░░░░  65%                      │
│  15 / 23 건 완료                                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  처리 로그                                                  │
│  ┌─────────────────────────────────────────────────────────┤
│  │ ✅ ID:101 - 처리 완료                                   │
│  │ ✅ ID:102 - 처리 완료                                   │
│  │ ❌ ID:103 - 실패: 이미 처리된 항목                      │
│  │ ✅ ID:104 - 처리 완료                                   │
│  │ ⏳ ID:105 - 처리 중...                                  │
│  └─────────────────────────────────────────────────────────┤
├─────────────────────────────────────────────────────────────┤
│                               [취소] (처리 중에는 비활성)    │
└─────────────────────────────────────────────────────────────┘
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── modals/
│   └── [모듈명]-batch-process.modal.vue
└── composables/
    └── useBatchProcess.ts
```

---

## batch-process.modal.vue 패턴

```vue
<template>
  <u-modal
    v-model:open="isOpen"
    :title="title"
    :ui="{ width: 'sm:max-w-xl' }"
    :prevent-close="isProcessing"
  >
    <!-- 진행률 -->
    <div class="space-y-4">
      <div class="text-center">
        <div class="text-2xl font-bold">
          {{ processedCount }} / {{ totalCount }}
        </div>
        <div class="text-gray-500">건 완료</div>
      </div>

      <u-progress
        :value="progressPercent"
        :max="100"
        :color="hasErrors ? 'warning' : 'primary'"
      />

      <div class="text-center text-sm text-gray-500">
        {{ progressPercent }}% 완료
        <span v-if="hasErrors" class="text-red-500">
          ({{ errorCount }}건 실패)
        </span>
      </div>
    </div>

    <!-- 처리 로그 -->
    <div class="mt-6">
      <div class="mb-2 flex items-center justify-between">
        <span class="font-medium">처리 로그</span>
        <u-button size="xs" variant="ghost" @click="scrollToBottom">
          최신으로
        </u-button>
      </div>

      <div
        ref="logContainer"
        class="h-64 overflow-y-auto rounded border bg-gray-900 p-3 font-mono text-sm"
      >
        <div
          v-for="(log, index) in logs"
          :key="index"
          :class="[
            'py-1',
            log.status === 'success' && 'text-green-400',
            log.status === 'error' && 'text-red-400',
            log.status === 'pending' && 'text-yellow-400 animate-pulse'
          ]"
        >
          <span class="mr-2">
            {{ log.status === 'success' ? '✅' : log.status === 'error' ? '❌' : '⏳' }}
          </span>
          <span>ID:{{ log.id }}</span>
          <span class="ml-2">- {{ log.message }}</span>
        </div>
      </div>
    </div>

    <!-- 결과 요약 (완료 후) -->
    <div v-if="isCompleted" class="mt-4 rounded bg-gray-100 p-4 dark:bg-gray-800">
      <div class="text-center">
        <div class="text-lg font-bold">처리 완료</div>
        <div class="mt-2 flex justify-center gap-4">
          <div class="text-green-600">
            성공: {{ successCount }}건
          </div>
          <div v-if="errorCount > 0" class="text-red-600">
            실패: {{ errorCount }}건
          </div>
        </div>
      </div>
    </div>

    <!-- 푸터 -->
    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button
          v-if="!isCompleted"
          variant="outline"
          :disabled="isProcessing"
          @click="handleClose"
        >
          취소
        </u-button>
        <u-button
          v-if="isCompleted"
          color="primary"
          @click="handleComplete"
        >
          확인
        </u-button>
      </div>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { ref, computed, watch, nextTick } from 'vue';

// Props & Emits
const props = defineProps<{
  open: boolean;
  items: any[];             // 처리할 항목들
  action: string;           // 처리 액션 ('updateStatus' | 'delete' | ...)
  actionParams?: any;       // 추가 파라미터
}>();

const emit = defineEmits<{
  'update:open': [value: boolean];
  complete: [result: { success: number; error: number }];
}>();

// Store
const store = use[ModuleName]Store();

// 상태
const isProcessing = ref(false);
const isCompleted = ref(false);
const logs = ref<{ id: number; status: string; message: string }[]>([]);
const logContainer = ref<HTMLElement | null>(null);

// 계산된 값
const totalCount = computed(() => props.items.length);
const processedCount = computed(
  () => logs.value.filter((l) => l.status !== 'pending').length
);
const successCount = computed(
  () => logs.value.filter((l) => l.status === 'success').length
);
const errorCount = computed(
  () => logs.value.filter((l) => l.status === 'error').length
);
const hasErrors = computed(() => errorCount.value > 0);
const progressPercent = computed(() =>
  Math.round((processedCount.value / totalCount.value) * 100)
);

// 타이틀
const title = computed(() => {
  if (isCompleted.value) return '처리 완료';
  if (isProcessing.value) return '처리 중...';
  return '일괄 처리';
});

// v-model:open
const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

// 로그 스크롤
const scrollToBottom = () => {
  nextTick(() => {
    if (logContainer.value) {
      logContainer.value.scrollTop = logContainer.value.scrollHeight;
    }
  });
};

// 순차 처리 실행
const startProcess = async () => {
  isProcessing.value = true;
  isCompleted.value = false;
  logs.value = [];

  // 초기 pending 로그 생성
  props.items.forEach((item) => {
    logs.value.push({
      id: item.[pk]Seq || item.id,
      status: 'pending',
      message: '대기 중...'
    });
  });

  // 순차 처리 (Promise.all 금지!)
  for (let i = 0; i < props.items.length; i++) {
    const item = props.items[i];
    const logIndex = i;

    // 현재 처리 중 표시
    logs.value[logIndex].message = '처리 중...';
    scrollToBottom();

    try {
      // 액션 실행
      await executeAction(item);

      // 성공
      logs.value[logIndex].status = 'success';
      logs.value[logIndex].message = '처리 완료';
    } catch (error: any) {
      // 실패 (계속 진행)
      logs.value[logIndex].status = 'error';
      logs.value[logIndex].message = `실패: ${error.message || '알 수 없는 오류'}`;
    }

    scrollToBottom();

    // 너무 빠른 처리 방지 (UX)
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  isProcessing.value = false;
  isCompleted.value = true;
};

// 액션 실행
const executeAction = async (item: any) => {
  switch (props.action) {
    case 'updateStatus':
      await store.updateStatus(item.[pk]Seq, props.actionParams?.status);
      break;
    case 'delete':
      await store.softDelete(item.[pk]Seq);
      break;
    case 'updateUse':
      await store.updateUse(item.[pk]Seq, props.actionParams?.isUse);
      break;
    default:
      throw new Error(`Unknown action: ${props.action}`);
  }
};

// 닫기
const handleClose = () => {
  if (isProcessing.value) return;
  emit('update:open', false);
};

// 완료
const handleComplete = () => {
  emit('complete', {
    success: successCount.value,
    error: errorCount.value
  });
  emit('update:open', false);
};

// 모달 열릴 때 처리 시작
watch(
  () => props.open,
  (newVal) => {
    if (newVal && props.items.length > 0) {
      startProcess();
    }
  }
);
</script>
```

---

## 호출하는 쪽 사용법

### list-table.vue

```vue
<template>
  <div>
    <!-- 일괄 처리 버튼들 -->
    <div class="flex gap-2 mb-4">
      <u-button
        :disabled="selectedItems.length === 0"
        @click="openBatchProcess('updateUse', { isUse: 'Y' })"
      >
        선택 사용처리 ({{ selectedItems.length }})
      </u-button>
      <u-button
        color="error"
        :disabled="selectedItems.length === 0"
        @click="openBatchProcess('delete')"
      >
        선택 삭제 ({{ selectedItems.length }})
      </u-button>
    </div>

    <!-- 테이블 (체크박스 선택) -->
    <easy-data-table
      v-model:items-selected="selectedItems"
      :headers="headers"
      :items="listData"
    />

    <!-- 일괄 처리 모달 -->
    <batch-process-modal
      v-model:open="isBatchProcessOpen"
      :items="selectedItems"
      :action="batchAction"
      :action-params="batchParams"
      @complete="onBatchComplete"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import BatchProcessModal from '../modals/[모듈명]-batch-process.modal.vue';

const selectedItems = ref([]);
const isBatchProcessOpen = ref(false);
const batchAction = ref('');
const batchParams = ref({});

const openBatchProcess = (action: string, params?: any) => {
  if (selectedItems.value.length === 0) return;

  batchAction.value = action;
  batchParams.value = params || {};
  isBatchProcessOpen.value = true;
};

const onBatchComplete = (result: { success: number; error: number }) => {
  useToast().add({
    title: '처리 완료',
    description: `성공: ${result.success}건, 실패: ${result.error}건`,
    color: result.error > 0 ? 'warning' : 'success'
  });

  // 선택 초기화 및 목록 새로고침
  selectedItems.value = [];
  listAction();
};
</script>
```

---

## useBatchProcess.ts (Composable)

```typescript
// composables/useBatchProcess.ts
import { ref, computed } from 'vue';

interface BatchLog {
  id: number;
  status: 'pending' | 'success' | 'error';
  message: string;
}

export function useBatchProcess<T extends { [key: string]: any }>(
  idKey: string = 'seq'
) {
  const isProcessing = ref(false);
  const isCompleted = ref(false);
  const logs = ref<BatchLog[]>([]);

  const totalCount = computed(() => logs.value.length);
  const processedCount = computed(
    () => logs.value.filter((l) => l.status !== 'pending').length
  );
  const successCount = computed(
    () => logs.value.filter((l) => l.status === 'success').length
  );
  const errorCount = computed(
    () => logs.value.filter((l) => l.status === 'error').length
  );
  const progressPercent = computed(() =>
    totalCount.value > 0
      ? Math.round((processedCount.value / totalCount.value) * 100)
      : 0
  );

  const process = async (
    items: T[],
    action: (item: T) => Promise<void>,
    options?: { delay?: number }
  ) => {
    isProcessing.value = true;
    isCompleted.value = false;
    logs.value = items.map((item) => ({
      id: item[idKey],
      status: 'pending' as const,
      message: '대기 중...'
    }));

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      logs.value[i].message = '처리 중...';

      try {
        await action(item);
        logs.value[i].status = 'success';
        logs.value[i].message = '완료';
      } catch (error: any) {
        logs.value[i].status = 'error';
        logs.value[i].message = error.message || '실패';
      }

      if (options?.delay) {
        await new Promise((r) => setTimeout(r, options.delay));
      }
    }

    isProcessing.value = false;
    isCompleted.value = true;
  };

  const reset = () => {
    isProcessing.value = false;
    isCompleted.value = false;
    logs.value = [];
  };

  return {
    isProcessing,
    isCompleted,
    logs,
    totalCount,
    processedCount,
    successCount,
    errorCount,
    progressPercent,
    process,
    reset
  };
}
```

---

## 핵심 포인트

### 1. for...of + await 순차 처리

```typescript
// ❌ 잘못된 방법 (병렬 실행)
await Promise.all(items.map((item) => action(item)));

// ✅ 올바른 방법 (순차 실행)
for (const item of items) {
  await action(item);
}
```

### 2. 실패해도 계속 진행

```typescript
try {
  await action(item);
  // 성공 처리
} catch (error) {
  // 실패 기록만 하고 계속 진행
  logs.value[i].status = 'error';
}
// 다음 항목으로 계속
```

### 3. 처리 중 모달 닫기 방지

```vue
<u-modal :prevent-close="isProcessing">
```

### 4. 실시간 로그 스크롤

```typescript
const scrollToBottom = () => {
  nextTick(() => {
    logContainer.scrollTop = logContainer.scrollHeight;
  });
};
```
