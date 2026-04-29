# 달력 (Calendar) 패턴 가이드

> 이 패턴은 test-data에 가이드 코드가 없습니다. MCP(Context7)를 활용하세요.

---

## 개요

리스트 대신 달력 형태의 UI를 메인으로 사용하는 패턴입니다.

**사용 시기**:
- 일정/예약 관리
- 이벤트 관리
- 날짜 기반 데이터 시각화

**MCP 활용**: Context7 (v-calendar 문서) + Sequential Thinking

---

## 라이브러리

```bash
# v-calendar 설치
bun add v-calendar@next
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   └── calendar.vue           ← 달력 메인 화면
├── components/
│   ├── calendar-header.vue    ← 년/월 이동 헤더
│   └── calendar-event-chip.vue
├── modals/
│   ├── [모듈명]-insert.modal.vue
│   └── [모듈명]-detail.modal.vue
└── composables/
    └── useCalendar.ts
```

---

## calendar.vue 패턴

```vue
<template>
  <div class="p-6">
    <!-- 달력 헤더 -->
    <calendar-header
      v-model:current-date="currentDate"
      @today="goToday"
      @prev="prevMonth"
      @next="nextMonth"
    />

    <!-- 달력 바디 -->
    <v-calendar
      ref="calendarRef"
      :attributes="calendarAttributes"
      :masks="{ weekdays: 'WWW' }"
      class="w-full"
      @dayclick="onDayClick"
    >
      <template #day-content="{ day, attributes }">
        <div class="min-h-20 p-1">
          <div class="mb-1 text-sm font-medium">{{ day.day }}</div>
          <!-- 일정 칩들 -->
          <div class="space-y-1">
            <calendar-event-chip
              v-for="attr in attributes"
              :key="attr.key"
              :event="attr.customData"
              @click.stop="onEventClick(attr.customData)"
            />
          </div>
        </div>
      </template>
    </v-calendar>

    <!-- 등록 모달 -->
    <insert-modal
      v-model:open="isOpenInsert"
      :initial-date="selectedDate"
      @insert-ok="onInsertOk"
    />

    <!-- 상세 모달 -->
    <detail-modal
      v-model:open="isOpenDetail"
      :[pk]-seq="selectedSeq"
      @update-ok="onUpdateOk"
      @remove-ok="onRemoveOk"
    />
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [ModuleName]Detail } from '@/modules/[모듈명]/type/[모듈명].type';
import { ref, computed, watch, onMounted } from 'vue';
import dayjs from 'dayjs';

import CalendarHeader from '../components/calendar-header.vue';
import CalendarEventChip from '../components/calendar-event-chip.vue';
import InsertModal from '../modals/[모듈명]-insert.modal.vue';
import DetailModal from '../modals/[모듈명]-detail.modal.vue';

const store = use[ModuleName]Store();
const calendarRef = ref();

// 현재 표시 월
const currentDate = ref(new Date());

// 모달 상태
const isOpenInsert = ref(false);
const isOpenDetail = ref(false);
const selectedDate = ref<string | null>(null);
const selectedSeq = ref(0);

// 일정 데이터
const events = computed(() => store.listData);

// v-calendar 속성으로 변환
const calendarAttributes = computed(() => {
  return events.value.map((event) => ({
    key: event.[pk]Seq,
    customData: event,
    dates: new Date(event.startDate),
    // 기간 일정인 경우
    // dates: { start: new Date(event.startDate), end: new Date(event.endDate) },
    dot: {
      color: getEventColor(event.status)
    }
  }));
});

// 상태별 색상
const getEventColor = (status: string) => {
  switch (status) {
    case 'DONE':
      return 'green';
    case 'PROGRESS':
      return 'blue';
    case 'WAIT':
      return 'gray';
    default:
      return 'primary';
  }
};

// 날짜 클릭 → 등록
const onDayClick = (day: any) => {
  selectedDate.value = dayjs(day.date).format('YYYY-MM-DD');
  isOpenInsert.value = true;
};

// 일정 클릭 → 상세
const onEventClick = (event: [ModuleName]Detail) => {
  selectedSeq.value = event.[pk]Seq;
  isOpenDetail.value = true;
};

// 오늘로 이동
const goToday = () => {
  currentDate.value = new Date();
};

// 이전 달
const prevMonth = () => {
  currentDate.value = dayjs(currentDate.value).subtract(1, 'month').toDate();
};

// 다음 달
const nextMonth = () => {
  currentDate.value = dayjs(currentDate.value).add(1, 'month').toDate();
};

// 데이터 조회
const fetchEvents = async () => {
  const startOfMonth = dayjs(currentDate.value).startOf('month').format('YYYY-MM-DD');
  const endOfMonth = dayjs(currentDate.value).endOf('month').format('YYYY-MM-DD');

  await store.list({
    startDate: startOfMonth,
    endDate: endOfMonth
  });
};

// 월 변경 시 데이터 재조회
watch(currentDate, () => {
  fetchEvents();
});

// 이벤트 콜백
const onInsertOk = () => {
  fetchEvents();
};

const onUpdateOk = () => {
  fetchEvents();
};

const onRemoveOk = () => {
  fetchEvents();
};

onMounted(() => {
  fetchEvents();
});
</script>
```

---

## calendar-header.vue

```vue
<template>
  <div class="mb-6 flex items-center justify-between">
    <div class="flex items-center gap-4">
      <u-button variant="ghost" icon="i-lucide-chevron-left" @click="$emit('prev')" />
      <h2 class="text-xl font-bold">
        {{ dayjs(currentDate).format('YYYY년 M월') }}
      </h2>
      <u-button variant="ghost" icon="i-lucide-chevron-right" @click="$emit('next')" />
    </div>
    <div class="flex gap-2">
      <u-button variant="outline" @click="$emit('today')">오늘</u-button>
      <u-button color="primary" @click="$emit('add')">일정 추가</u-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import dayjs from 'dayjs';

defineProps<{
  currentDate: Date;
}>();

defineEmits(['prev', 'next', 'today', 'add']);
</script>
```

---

## calendar-event-chip.vue

```vue
<template>
  <div
    :class="[
      'cursor-pointer rounded px-2 py-1 text-xs truncate',
      colorClass
    ]"
    :title="event.subject"
    @click="$emit('click')"
  >
    {{ event.subject }}
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  event: {
    subject: string;
    status?: string;
  };
}>();

defineEmits(['click']);

const colorClass = computed(() => {
  switch (props.event.status) {
    case 'DONE':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
    case 'PROGRESS':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
    case 'WAIT':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';
    default:
      return 'bg-primary-100 text-primary-800';
  }
});
</script>
```

---

## insert.modal.vue (일정 등록)

```vue
<template>
  <u-modal v-model:open="isOpen" title="일정 등록">
    <u-form ref="formRef" :state="formData" :schema="schema" @submit="handleSubmit">
      <u-form-field label="제목" name="subject" required>
        <u-input v-model="formData.subject" />
      </u-form-field>

      <u-form-field label="시작일" name="startDate" required>
        <u-input v-model="formData.startDate" type="date" />
      </u-form-field>

      <u-form-field label="종료일" name="endDate">
        <u-input v-model="formData.endDate" type="date" />
      </u-form-field>

      <u-form-field label="설명" name="description">
        <u-textarea v-model="formData.description" />
      </u-form-field>
    </u-form>

    <template #footer>
      <div class="flex justify-end gap-2">
        <u-button variant="outline" @click="isOpen = false">취소</u-button>
        <u-button color="primary" @click="formSubmit">등록</u-button>
      </div>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { ref, computed, watch } from 'vue';
import * as yup from 'yup';

const props = defineProps<{
  open: boolean;
  initialDate?: string | null;
}>();

const emit = defineEmits(['update:open', 'insert-ok']);

const store = use[ModuleName]Store();
const formRef = ref();

const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

const formData = ref({
  subject: '',
  startDate: '',
  endDate: '',
  description: ''
});

const schema = yup.object({
  subject: yup.string().required('제목을 입력하세요'),
  startDate: yup.string().required('시작일을 선택하세요')
});

const formSubmit = () => {
  formRef.value?.submit();
};

const handleSubmit = async () => {
  await store.insert(formData.value);
  emit('insert-ok');
  isOpen.value = false;
};

watch(
  () => props.open,
  (newVal) => {
    if (newVal) {
      formData.value = {
        subject: '',
        startDate: props.initialDate || '',
        endDate: '',
        description: ''
      };
    }
  }
);
</script>
```

---

## useCalendar.ts (Composable)

```typescript
// composables/useCalendar.ts
import { ref, computed } from 'vue';
import dayjs from 'dayjs';

export function useCalendar() {
  const currentDate = ref(new Date());

  const currentYear = computed(() => dayjs(currentDate.value).year());
  const currentMonth = computed(() => dayjs(currentDate.value).month() + 1);

  const monthStart = computed(() =>
    dayjs(currentDate.value).startOf('month').format('YYYY-MM-DD')
  );
  const monthEnd = computed(() =>
    dayjs(currentDate.value).endOf('month').format('YYYY-MM-DD')
  );

  const goToday = () => {
    currentDate.value = new Date();
  };

  const prevMonth = () => {
    currentDate.value = dayjs(currentDate.value).subtract(1, 'month').toDate();
  };

  const nextMonth = () => {
    currentDate.value = dayjs(currentDate.value).add(1, 'month').toDate();
  };

  const goToDate = (date: Date | string) => {
    currentDate.value = dayjs(date).toDate();
  };

  return {
    currentDate,
    currentYear,
    currentMonth,
    monthStart,
    monthEnd,
    goToday,
    prevMonth,
    nextMonth,
    goToDate
  };
}
```

---

## 타입 추가

```typescript
// [모듈명].type.ts
export interface [ModuleName]Schedule {
  [pk]Seq: number;
  subject: string;
  startDate: string;
  endDate: string;
  status: 'WAIT' | 'PROGRESS' | 'DONE';
  description: string;
  // ...
}
```

---

## 핵심 포인트

### 1. 월별 데이터 조회

```typescript
watch(currentDate, () => {
  const start = dayjs(currentDate.value).startOf('month').format('YYYY-MM-DD');
  const end = dayjs(currentDate.value).endOf('month').format('YYYY-MM-DD');
  fetchEvents({ startDate: start, endDate: end });
});
```

### 2. v-calendar attributes

```typescript
const attributes = events.map((event) => ({
  key: event.seq,
  customData: event,
  dates: new Date(event.startDate),
  dot: { color: 'blue' }
}));
```

### 3. 기간 일정 표시

```typescript
dates: {
  start: new Date(event.startDate),
  end: new Date(event.endDate)
}
```
