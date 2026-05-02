# 대량 입력 폼 (Mega Form) 패턴 가이드

> 이 패턴은 test-data에 가이드 코드가 없습니다. MCP(Context7)를 활용하세요.

---

## 개요

입력 항목이 50개 이상인 복잡한 폼을 섹션별로 분리하고 네비게이션을 제공하는 패턴입니다.

**사용 시기**:
- 입력 항목 50개 이상
- 복잡한 등록/수정 화면
- 섹션별 구분이 필요한 폼

**MCP 활용**: Context7 (Nuxt UI 공식 문서 참조)

---

## UI 구조

```
┌────────────────┬────────────────────────────────────────────────┐
│  네비게이션     │  메인 폼 영역                                   │
│  (Sticky)      │                                                │
│                │  ┌─────────────────────────────────────────┐   │
│  ● 기본정보    │  │  기본정보                               │   │
│  ○ 상세정보    │  │  ┌─────────────┬─────────────┐          │   │
│  ○ 파일첨부    │  │  │ 필드1       │ 필드2       │          │   │
│  ○ 기타정보    │  │  ├─────────────┼─────────────┤          │   │
│                │  │  │ 필드3       │ 필드4       │          │   │
│                │  │  └─────────────┴─────────────┘          │   │
│                │  └─────────────────────────────────────────┘   │
│                │                                                │
│                │  ┌─────────────────────────────────────────┐   │
│                │  │  상세정보                               │   │
│                │  │  ...                                    │   │
│                │  └─────────────────────────────────────────┘   │
│                │                                                │
└────────────────┴────────────────────────────────────────────────┘
```

---

## 생성 파일 구조

```
front/src/modules/[모듈명]/
├── pages/[페이지명]/
│   └── detail.vue             ← 메인 레이아웃
├── components/forms/
│   ├── section-basic.vue      ← 기본정보 섹션
│   ├── section-detail.vue     ← 상세정보 섹션
│   ├── section-file.vue       ← 파일첨부 섹션
│   └── section-etc.vue        ← 기타정보 섹션
└── composables/
    └── useScrollSpy.ts        ← 스크롤 위치 감지
```

---

## detail.vue 패턴

```vue
<template>
  <div class="flex gap-6">
    <!-- 좌측: 네비게이션 (Sticky) -->
    <div class="w-48 flex-shrink-0">
      <div class="sticky top-4">
        <u-card>
          <nav class="space-y-1">
            <a
              v-for="section in sections"
              :key="section.id"
              :href="`#${section.id}`"
              :class="[
                'block rounded-md px-3 py-2 text-sm transition-colors',
                activeSection === section.id
                  ? 'bg-primary-100 text-primary-700 font-medium dark:bg-primary-900 dark:text-primary-300'
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800'
              ]"
              @click.prevent="scrollToSection(section.id)"
            >
              {{ section.label }}
            </a>
          </nav>
        </u-card>

        <!-- 저장 버튼 (Sticky) -->
        <div class="mt-4 space-y-2">
          <u-button color="primary" block @click="handleSubmit">
            저장
          </u-button>
          <u-button variant="outline" block @click="handleCancel">
            취소
          </u-button>
        </div>
      </div>
    </div>

    <!-- 우측: 폼 섹션들 -->
    <div ref="formContainer" class="flex-1 space-y-6">
      <u-form ref="formRef" :state="formData" :schema="schema">
        <!-- 기본정보 섹션 -->
        <u-card id="basic" class="scroll-mt-4">
          <template #header>
            <h3 class="text-lg font-semibold">기본정보</h3>
          </template>
          <section-basic v-model="formData" />
        </u-card>

        <!-- 상세정보 섹션 -->
        <u-card id="detail" class="scroll-mt-4">
          <template #header>
            <h3 class="text-lg font-semibold">상세정보</h3>
          </template>
          <section-detail v-model="formData" />
        </u-card>

        <!-- 파일첨부 섹션 -->
        <u-card id="file" class="scroll-mt-4">
          <template #header>
            <h3 class="text-lg font-semibold">파일첨부</h3>
          </template>
          <section-file v-model:file-list="formData.fileList" />
        </u-card>

        <!-- 기타정보 섹션 -->
        <u-card id="etc" class="scroll-mt-4">
          <template #header>
            <h3 class="text-lg font-semibold">기타정보</h3>
          </template>
          <section-etc v-model="formData" />
        </u-card>
      </u-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { use[ModuleName]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { ref, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import * as yup from 'yup';

import SectionBasic from '../components/forms/section-basic.vue';
import SectionDetail from '../components/forms/section-detail.vue';
import SectionFile from '../components/forms/section-file.vue';
import SectionEtc from '../components/forms/section-etc.vue';

const route = useRoute();
const router = useRouter();
const store = use[ModuleName]Store();

const formRef = ref();
const formContainer = ref<HTMLElement | null>(null);

// 섹션 정의
const sections = [
  { id: 'basic', label: '기본정보' },
  { id: 'detail', label: '상세정보' },
  { id: 'file', label: '파일첨부' },
  { id: 'etc', label: '기타정보' }
];

// 현재 활성 섹션 (ScrollSpy)
const activeSection = ref('basic');

// 폼 데이터
const formData = ref({
  // 기본정보
  subject: '',
  code: '',
  categorySeq: 0,
  isUse: 'Y',

  // 상세정보
  description: '',
  content: '',
  price: 0,
  stock: 0,

  // 파일
  fileList: [],

  // 기타
  memo: '',
  tags: []
});

// 유효성 검증 스키마
const schema = yup.object({
  subject: yup.string().required('제목을 입력하세요'),
  code: yup.string().required('코드를 입력하세요'),
  categorySeq: yup.number().min(1, '카테고리를 선택하세요')
});

// 섹션으로 스크롤
const scrollToSection = (sectionId: string) => {
  const element = document.getElementById(sectionId);
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
};

// ScrollSpy: 스크롤 위치에 따라 활성 섹션 변경
const handleScroll = () => {
  const scrollPosition = window.scrollY + 100; // offset

  for (let i = sections.length - 1; i >= 0; i--) {
    const section = document.getElementById(sections[i].id);
    if (section && section.offsetTop <= scrollPosition) {
      activeSection.value = sections[i].id;
      break;
    }
  }
};

// 저장
const handleSubmit = async () => {
  try {
    await formRef.value?.validate();

    const seq = Number(route.params.seq);
    if (seq) {
      await store.update(seq, formData.value);
      useToast().add({ title: '수정 완료', color: 'success' });
    } else {
      await store.insert(formData.value);
      useToast().add({ title: '등록 완료', color: 'success' });
    }

    router.push('/[모듈명]/list');
  } catch (error) {
    // 유효성 검증 실패 시 해당 섹션으로 이동
    const firstError = formRef.value?.errors?.[0];
    if (firstError) {
      const fieldSection = getFieldSection(firstError.path);
      if (fieldSection) {
        scrollToSection(fieldSection);
      }
    }
  }
};

// 필드별 섹션 매핑
const getFieldSection = (fieldPath: string): string | null => {
  const basicFields = ['subject', 'code', 'categorySeq', 'isUse'];
  const detailFields = ['description', 'content', 'price', 'stock'];

  if (basicFields.includes(fieldPath)) return 'basic';
  if (detailFields.includes(fieldPath)) return 'detail';
  if (fieldPath.startsWith('fileList')) return 'file';
  return 'etc';
};

// 취소
const handleCancel = () => {
  router.back();
};

// 데이터 로드 (수정 모드)
const loadData = async () => {
  const seq = Number(route.params.seq);
  if (seq) {
    await store.detail(seq);
    Object.assign(formData.value, store.detailData);
  }
};

onMounted(() => {
  loadData();
  window.addEventListener('scroll', handleScroll);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
});
</script>
```

---

## section-basic.vue (섹션 컴포넌트)

```vue
<template>
  <div class="grid grid-cols-2 gap-4">
    <u-form-field label="제목" name="subject" required>
      <u-input v-model="model.subject" />
    </u-form-field>

    <u-form-field label="코드" name="code" required>
      <u-input v-model="model.code" />
    </u-form-field>

    <u-form-field label="카테고리" name="categorySeq" required>
      <u-select
        v-model="model.categorySeq"
        :options="categoryOptions"
        placeholder="선택"
      />
    </u-form-field>

    <u-form-field label="사용여부" name="isUse">
      <u-switch
        :model-value="model.isUse === 'Y'"
        @update:model-value="(v) => (model.isUse = v ? 'Y' : 'N')"
      />
    </u-form-field>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const model = defineModel<{
  subject: string;
  code: string;
  categorySeq: number;
  isUse: string;
}>({ required: true });

const categoryOptions = ref([]);

onMounted(async () => {
  // 카테고리 옵션 로드
  // categoryOptions.value = await fetchCategories();
});
</script>
```

---

## useScrollSpy.ts (Composable)

```typescript
// composables/useScrollSpy.ts
import { ref, onMounted, onUnmounted } from 'vue';

export function useScrollSpy(sectionIds: string[], offset: number = 100) {
  const activeSection = ref(sectionIds[0]);

  const handleScroll = () => {
    const scrollPosition = window.scrollY + offset;

    for (let i = sectionIds.length - 1; i >= 0; i--) {
      const section = document.getElementById(sectionIds[i]);
      if (section && section.offsetTop <= scrollPosition) {
        activeSection.value = sectionIds[i];
        break;
      }
    }
  };

  const scrollToSection = (sectionId: string) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  onMounted(() => {
    window.addEventListener('scroll', handleScroll);
    handleScroll(); // 초기 실행
  });

  onUnmounted(() => {
    window.removeEventListener('scroll', handleScroll);
  });

  return {
    activeSection,
    scrollToSection
  };
}
```

### 사용 예시

```typescript
const sections = ['basic', 'detail', 'file', 'etc'];
const { activeSection, scrollToSection } = useScrollSpy(sections);
```

---

## 탭 방식 대안

섹션 대신 탭으로 구성하는 방식:

```vue
<template>
  <u-tabs v-model="activeTab" :items="tabItems">
    <template #basic>
      <section-basic v-model="formData" />
    </template>
    <template #detail>
      <section-detail v-model="formData" />
    </template>
    <!-- ... -->
  </u-tabs>
</template>

<script setup>
const tabItems = [
  { label: '기본정보', value: 'basic' },
  { label: '상세정보', value: 'detail' },
  { label: '파일첨부', value: 'file' },
  { label: '기타정보', value: 'etc' }
];
</script>
```

---

## 핵심 포인트

### 1. 섹션별 파일 분리

```
components/forms/
├── section-basic.vue
├── section-detail.vue
└── section-file.vue
```

### 2. ScrollSpy 네비게이션

```typescript
const handleScroll = () => {
  for (let i = sections.length - 1; i >= 0; i--) {
    const section = document.getElementById(sections[i].id);
    if (section.offsetTop <= scrollPosition) {
      activeSection.value = sections[i].id;
      break;
    }
  }
};
```

### 3. scroll-mt-* 클래스

Sticky 헤더가 있을 때 스크롤 위치 보정:

```html
<u-card id="basic" class="scroll-mt-4">
```

### 4. 검증 실패 시 해당 섹션으로 이동

```typescript
const firstError = formRef.value?.errors?.[0];
if (firstError) {
  scrollToSection(getFieldSection(firstError.path));
}
```

### 5. defineModel 사용

```vue
<script setup>
const model = defineModel<FormData>({ required: true });
</script>
```
