# Modal 패턴

> test-data/modals 기반 모달 컴포넌트 패턴

---

## 파일 구조

```
front/src/modules/[모듈명]/modals/
├── insert.modal.vue    ← 등록 모달
├── update.modal.vue    ← 수정 모달
├── detail.modal.vue    ← 상세 모달
└── _[모듈명].validator.ts  ← yup 검증
```

---

## insert.modal.vue

```vue
<template>
  <!-- 오버레이 -->
  <div v-if="isOpen" class="fixed inset-0 z-[10] bg-black/50 dark:bg-black/80" @click.stop></div>

  <!-- 모달 -->
  <u-modal
    v-model:open="isOpen"
    :dismissible="false"
    :ui="{
      content: 'min-w-sm max-w-[900px]',
      footer: 'justify-end'
    }"
    :modal="false"
    title="등록"
  >
    <template #body>
      <u-form
        ref="formRef"
        :schema="[모듈명PascalCase]InsertValidator"
        :state="detailData"
        @submit="register"
        @error="handleFormError"
      >
        <p-form-group title="기본 정보">
          <div class="space-y-4">
            <u-form-field label="제목" name="subject">
              <p-input-box v-model="detailData.subject" placeholder="제목을 입력하세요." />
            </u-form-field>

            <u-form-field label="이미지" name="imageList">
              <p-[모듈명]-file-upload
                :file-list="detailData.imageList"
                :max-files="1"
                accept="image/*"
                @set-files="setImages"
              />
            </u-form-field>

            <u-form-field label="내용" name="contents">
              <p-[모듈명]-editor-tinymce
                v-model="detailData.contents"
                @set-files="setFiles"
                :file-list="detailData.fileList"
                is-file
              />
            </u-form-field>
          </div>

          <u-button type="submit" class="hidden">저장</u-button>
        </p-form-group>
      </u-form>
    </template>

    <template #footer>
      <u-button color="neutral" variant="outline" @click="close">닫기</u-button>
      <u-button @click="formSubmit">저장</u-button>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { FormService } from '@/modules/_common/services/form.service.ts';
import type { FormErrorEvent } from '@nuxt/ui';
import { use[모듈명PascalCase]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import P[모듈명PascalCase]FileUpload from '../components/file/p-[모듈명]-file-upload.vue';
import { [모듈명PascalCase]InsertValidator } from './_[모듈명].validator.ts';
import type { [모듈명PascalCase]File } from '@/modules/[모듈명]/type/[모듈명].type.ts';

// Props 정의
interface Props {
  open: boolean;
}
const props = defineProps<Props>();

const [모듈명]Store = use[모듈명PascalCase]Store();
const { detailData } = storeToRefs([모듈명]Store);
const formRef = ref();

// 모달 열림/닫힘 상태 관리
const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

const emit = defineEmits(['update:open', 'close', 'insert-ok']);

// 파일 추가
const setFiles = (files: [모듈명PascalCase]File[]) => {
  detailData.value.fileList = files;
};

// 이미지 추가
const setImages = (files: [모듈명PascalCase]File[]) => {
  detailData.value.imageList = files;
};

// 폼 에러 핸들링
const handleFormError = (event: FormErrorEvent) => {
  FormService.onError(event);
};

const formSubmit = () => {
  if (formRef.value) {
    formRef.value.submit();
  }
};

const register = async () => {
  await FormService.loading(async () => {
    // 파일 리스트를 UUID 배열로 변환
    const { fileList, imageList, ...rest } = detailData.value;
    const insertData = {
      ...rest,
      fileUuidList: fileList?.map((f) => f.fileUuid).filter(Boolean) ?? [],
      imageUuidList: imageList?.map((f) => f.fileUuid).filter(Boolean) ?? []
    };
    const result = await [모듈명]Store.insert(insertData);
    if (result.isSuccess) {
      useToast().add({
        title: '등록 완료',
        description: '등록이 완료되었습니다.',
        color: 'success'
      });
      emit('insert-ok');
      close();
    }
  });
};

const close = () => {
  isOpen.value = false;
  emit('close');
};

const initOnCreated = () => {
  [모듈명]Store.detailDataInit();
};

// 모달이 열릴 때 초기화
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      initOnCreated();
    }
  }
);

onUnmounted(() => {
  [모듈명]Store.detailDataInit();
});
</script>
```

---

## update.modal.vue

```vue
<template>
  <div v-if="isOpen" class="fixed inset-0 z-[10] bg-black/50 dark:bg-black/80" @click.stop></div>

  <u-modal
    v-model:open="isOpen"
    :dismissible="false"
    :ui="{ content: 'min-w-sm max-w-[900px]', footer: 'justify-end' }"
    :modal="false"
    title="수정"
  >
    <template #body>
      <u-form
        ref="formRef"
        :schema="[모듈명PascalCase]UpdateValidator"
        :state="detailData"
        @submit="save"
        @error="handleFormError"
      >
        <!-- insert.modal.vue와 동일한 폼 필드 -->
      </u-form>
    </template>

    <template #footer>
      <u-button color="neutral" variant="outline" @click="close">닫기</u-button>
      <u-button @click="formSubmit">저장</u-button>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { FormService } from '@/modules/_common/services/form.service.ts';
import type { FormErrorEvent } from '@nuxt/ui';
import { use[모듈명PascalCase]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import { [모듈명PascalCase]UpdateValidator } from './_[모듈명].validator.ts';

interface Props {
  open: boolean;
  [pk]Seq: number;  // 수정할 데이터 PK
}
const props = defineProps<Props>();

const [모듈명]Store = use[모듈명PascalCase]Store();
const { detailData } = storeToRefs([모듈명]Store);
const formRef = ref();

const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

const emit = defineEmits(['update:open', 'close', 'update-ok']);

const handleFormError = (event: FormErrorEvent) => {
  FormService.onError(event);
};

const formSubmit = () => {
  if (formRef.value) {
    formRef.value.submit();
  }
};

const save = async () => {
  await FormService.loading(async () => {
    const { fileList, imageList, ...rest } = detailData.value;
    const updateData = {
      ...rest,
      fileUuidList: fileList?.map((f) => f.fileUuid).filter(Boolean) ?? [],
      imageUuidList: imageList?.map((f) => f.fileUuid).filter(Boolean) ?? []
    };
    const result = await [모듈명]Store.update(props.[pk]Seq, updateData);
    if (result.isSuccess) {
      useToast().add({
        title: '수정 완료',
        description: '수정이 완료되었습니다.',
        color: 'success'
      });
      emit('update-ok');
      close();
    }
  });
};

const close = () => {
  isOpen.value = false;
  emit('close');
};

const getDetail = async () => {
  await FormService.loading(async () => {
    await [모듈명]Store.detail(props.[pk]Seq);
  });
};

// 모달이 열릴 때 데이터 로드
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      getDetail();
    }
  }
);
</script>
```

---

## detail.modal.vue

```vue
<template>
  <div v-if="isOpen" class="fixed inset-0 z-[10] bg-black/50 dark:bg-black/80" @click.stop></div>

  <u-modal
    v-model:open="isOpen"
    :dismissible="false"
    :ui="{ content: 'min-w-sm max-w-[900px]', footer: 'justify-end' }"
    :modal="false"
    title="상세"
  >
    <template #body>
      <p-form-group title="기본 정보">
        <div class="space-y-4">
          <u-form-field label="제목">
            <div class="p-2 bg-gray-50 rounded">{{ detailData.subject }}</div>
          </u-form-field>

          <u-form-field label="내용">
            <div class="p-2 bg-gray-50 rounded" v-html="detailData.contents"></div>
          </u-form-field>
        </div>
      </p-form-group>
    </template>

    <template #footer>
      <u-button color="error" variant="outline" @click="remove">삭제</u-button>
      <u-button color="neutral" variant="outline" @click="close">닫기</u-button>
      <u-button @click="goUpdate">수정</u-button>
    </template>
  </u-modal>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { FormService } from '@/modules/_common/services/form.service.ts';
import { use[모듈명PascalCase]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';

interface Props {
  open: boolean;
  [pk]Seq: number;
}
const props = defineProps<Props>();

const [모듈명]Store = use[모듈명PascalCase]Store();
const { detailData } = storeToRefs([모듈명]Store);

const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});

const emit = defineEmits(['update:open', 'close', 'remove-ok', 'go-update']);

const close = () => {
  isOpen.value = false;
  emit('close');
};

const goUpdate = () => {
  emit('go-update', props.[pk]Seq);
};

const remove = async () => {
  if (!confirm('삭제하시겠습니까?')) return;

  await FormService.loading(async () => {
    const result = await [모듈명]Store.softDelete(props.[pk]Seq);
    if (result.isSuccess) {
      useToast().add({
        title: '삭제 완료',
        description: '삭제가 완료되었습니다.',
        color: 'success'
      });
      emit('remove-ok');
      close();
    }
  });
};

const getDetail = async () => {
  await FormService.loading(async () => {
    await [모듈명]Store.detail(props.[pk]Seq);
  });
};

// 모달이 열릴 때 데이터 로드
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      getDetail();
    }
  }
);
</script>
```

---

## 모달 오픈 패턴 (list-table.vue)

```typescript
// 모달 상태 정의
const isOpenInsert = ref(false);
const isOpenDetail = ref(false);
const isOpenUpdate = ref(false);
const selectedKey = ref(0);

// 모달 오픈 메서드
const goDetail = ([pk]Seq: number) => {
  selectedKey.value = [pk]Seq;
  isOpenDetail.value = true;
};

const goInsert = () => {
  isOpenInsert.value = true;
};

const goUpdate = ([pk]Seq: number) => {
  if (isOpenDetail.value) {
    isOpenDetail.value = false;  // 상세 모달 닫기
  }
  selectedKey.value = [pk]Seq;
  isOpenUpdate.value = true;
};

// 템플릿에서 모달 사용
<insert v-model:open="isOpenInsert" @insert-ok="listAction" />
<detail :[pk]-seq="selectedKey" v-model:open="isOpenDetail" @remove-ok="listAction" @go-update="goUpdate" />
<update :[pk]-seq="selectedKey" v-model:open="isOpenUpdate" @update-ok="listAction" />
```

---

## 핵심 패턴

### 1. v-model:open 패턴

```typescript
// Props
interface Props {
  open: boolean;
}
const props = defineProps<Props>();

// Computed로 양방향 바인딩
const isOpen = computed({
  get: () => props.open,
  set: (value) => emit('update:open', value)
});
```

### 2. 파일 → UUID 변환

```typescript
const { fileList, imageList, ...rest } = detailData.value;
const insertData = {
  ...rest,
  fileUuidList: fileList?.map((f) => f.fileUuid).filter(Boolean) ?? [],
  imageUuidList: imageList?.map((f) => f.fileUuid).filter(Boolean) ?? []
};
```

### 3. 단순한 watch 패턴 (test-data 표준)

```typescript
// ✅ 올바른 패턴: props.open만 감시
watch(
  () => props.open,
  (newValue) => {
    if (newValue) {
      getDetail(); // 또는 initOnCreated()
    }
  }
);

// ❌ 잘못된 패턴: 복잡한 조건문 사용
watch(() => props.open, (newValue) => {
  if (newValue && props.[pk]Seq) {  // 불필요한 조건
    getDetail();
  }
});

watch(() => props.[pk]Seq, (newValue) => {
  if (newValue && props.open) {  // 중복 watch
    getDetail();
  }
});
```

**핵심 원칙**:
- `props.open`만 감시 (단순성)
- 부모 컴포넌트가 이미 [pk]Seq 관리 (책임 분리)
- 중복 watch 금지 (명확성)

### 4. FormService.loading 패턴

```typescript
await FormService.loading(async () => {
  // API 호출 로직
  const result = await store.insert(data);
  if (result.isSuccess) {
    useToast().add({ ... });
    emit('insert-ok');
    close();
  }
});
```

---

## 참조

실제 예시:
- insert: `front/src/modules/test-data/modals/insert.modal.vue` (라인 163-170)
- detail: `front/src/modules/test-data/modals/detail.modal.vue` (라인 140-147)
- update: `front/src/modules/test-data/modals/update.modal.vue` (라인 220-227)
