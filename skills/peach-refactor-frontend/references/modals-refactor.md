# Modals & Validator Architect (모달 & 검증 아키텍트)

## 페르소나

당신은 Vue3 모달 UI와 폼 검증 최고 전문가입니다.
- NuxtUI v3 모달 패턴 마스터
- yup 스키마 기반 검증 전문가
- test-data modals 패턴의 완벽한 구현

---

## 입력

- 기존 모달/폼 컴포넌트 파일
- 리팩토링된 Type, Store 파일

## 참조 템플릿

- `front/src/modules/test-data/modals/insert.modal.vue`
- `front/src/modules/test-data/modals/update.modal.vue`
- `front/src/modules/test-data/modals/detail.modal.vue`
- `front/src/modules/test-data/modals/_crud.validator.ts`

## 출력

- `front/src/modules/[모듈명]/modals/[모듈명]-insert.modal.vue`
- `front/src/modules/[모듈명]/modals/[모듈명]-update.modal.vue`
- `front/src/modules/[모듈명]/modals/[모듈명]-detail.modal.vue`
- `front/src/modules/[모듈명]/modals/_[모듈명].validator.ts`

---

## 리팩토링 체크리스트

### insert.modal.vue
- [ ] `defineModel('open')` 패턴
- [ ] `defineEmits(['insert-ok'])`
- [ ] 로컬 상태: `formData` (ref\<InsertDto\>)
- [ ] 로컬 상태: `validationErrors` (에러 메시지)
- [ ] UModal + UCard 구조
- [ ] UForm + UFormField 구조
- [ ] 검증: `InsertValidator.validate(formData)`
- [ ] 저장: `store.insert(formData)`
- [ ] 성공 시: emit('insert-ok'), open.value = false
- [ ] useToast() 알림

### update.modal.vue
- [ ] `defineProps: open, [pk]Seq (number)`
- [ ] 데이터 로드: watch([pk]Seq, getDetail)
- [ ] 수정 저장: store.update([pk]Seq, formData)
- [ ] 나머지는 insert.modal과 동일

### detail.modal.vue
- [ ] `defineProps: open, [pk]Seq (number)`
- [ ] `defineEmits: ['remove-ok', 'go-update']`
- [ ] 데이터 로드: watch([pk]Seq, getDetail)
- [ ] 읽기 전용 표시
- [ ] 수정 버튼: emit('go-update', [pk]Seq)
- [ ] 삭제 버튼: store.softDelete([pk]Seq)

### _[모듈].validator.ts
- [ ] yup import
- [ ] fileSchema (file=Y인 경우)
- [ ] InsertValidator = yup.object({ ... })
- [ ] UpdateValidator = yup.object({ ... })

---

## insert.modal.vue 패턴

```vue
<script setup lang="ts">
import { ref, watch } from 'vue';
import * as yup from 'yup';
import { use[모듈명PascalCase]Store } from '../store/[모듈명].store';
import { InsertValidator } from './_[모듈명].validator';
import type { [모듈명PascalCase]InsertDto } from '../type/[모듈명].type';

const toast = useToast();
const store = use[모듈명PascalCase]Store();

// v-model:open 패턴
const open = defineModel('open', { type: Boolean, default: false });
const emit = defineEmits(['insert-ok']);

// 폼 데이터
const formData = ref<[모듈명PascalCase]InsertDto>({
  subject: '',
  value: '',
  contents: '',
  fileUuidList: [],
  imageUuidList: []
});

// 검증 에러
const validationErrors = ref<Record<string, string>>({});

// 모달 열릴 때 초기화
watch(open, (newVal) => {
  if (newVal) {
    formData.value = {
      subject: '',
      value: '',
      contents: '',
      fileUuidList: [],
      imageUuidList: []
    };
    validationErrors.value = {};
  }
});

// 저장
const save = async () => {
  try {
    validationErrors.value = {};
    await InsertValidator.validate(formData.value, { abortEarly: false });

    const result = await store.insert(formData.value);
    if (result.isSuccess) {
      toast.add({ title: '등록되었습니다.', color: 'success' });
      emit('insert-ok');
      open.value = false;
    }
  } catch (e: any) {
    if (e instanceof yup.ValidationError) {
      e.inner.forEach((err: yup.ValidationError) => {
        if (err.path) {
          validationErrors.value[err.path] = err.message;
        }
      });
    }
  }
};

// 닫기
const close = () => {
  open.value = false;
};
</script>

<template>
  <UModal v-model:open="open">
    <UCard>
      <template #header>
        <h3>등록</h3>
      </template>

      <UForm>
        <UFormField label="제목" :error="validationErrors.subject">
          <UInput v-model="formData.subject" />
        </UFormField>

        <UFormField label="값" :error="validationErrors.value">
          <UInput v-model="formData.value" />
        </UFormField>

        <UFormField label="내용" :error="validationErrors.contents">
          <UTextarea v-model="formData.contents" />
        </UFormField>
      </UForm>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton color="neutral" variant="outline" @click="close">취소</UButton>
          <UButton @click="save">등록</UButton>
        </div>
      </template>
    </UCard>
  </UModal>
</template>
```

---

## update.modal.vue 패턴

```vue
<script setup lang="ts">
import { ref, watch } from 'vue';
import * as yup from 'yup';
import { use[모듈명PascalCase]Store } from '../store/[모듈명].store';
import { UpdateValidator } from './_[모듈명].validator';
import type { [모듈명PascalCase]UpdateDto } from '../type/[모듈명].type';

const toast = useToast();
const store = use[모듈명PascalCase]Store();

// Props
const props = defineProps<{
  [pk]Seq: number;
}>();

const open = defineModel('open', { type: Boolean, default: false });
const emit = defineEmits(['update-ok']);

// 폼 데이터
const formData = ref<[모듈명PascalCase]UpdateDto>({
  subject: '',
  value: '',
  contents: '',
  fileUuidList: [],
  imageUuidList: []
});

const validationErrors = ref<Record<string, string>>({});

// 데이터 로드
watch(
  () => props.[pk]Seq,
  async (newSeq) => {
    if (newSeq && open.value) {
      await store.detail(newSeq);
      const data = store.detailData;
      formData.value = {
        subject: data.subject,
        value: data.value,
        contents: data.contents,
        fileUuidList: data.fileList?.map(f => f.fileUuid) || [],
        imageUuidList: data.imageList?.map(f => f.fileUuid) || []
      };
    }
  },
  { immediate: true }
);

// 저장
const save = async () => {
  try {
    validationErrors.value = {};
    await UpdateValidator.validate(formData.value, { abortEarly: false });

    const result = await store.update(props.[pk]Seq, formData.value);
    if (result.isSuccess) {
      toast.add({ title: '수정되었습니다.', color: 'success' });
      emit('update-ok');
      open.value = false;
    }
  } catch (e: any) {
    if (e instanceof yup.ValidationError) {
      e.inner.forEach((err: yup.ValidationError) => {
        if (err.path) {
          validationErrors.value[err.path] = err.message;
        }
      });
    }
  }
};
</script>
```

---

## _[모듈].validator.ts 패턴

```typescript
import * as yup from 'yup';

// 파일 스키마 (file=Y인 경우)
const fileSchema = yup.object({
  fileUuid: yup.string().required(),
  fileName: yup.string().required()
});

/**
 * 등록 검증
 */
export const InsertValidator = yup.object({
  subject: yup.string()
    .required('제목은 필수 입력 항목입니다.')
    .min(2, '제목은 최소 2자 이상 입력해주세요.'),

  value: yup.string()
    .required('값은 필수 입력 항목입니다.'),

  contents: yup.string()
    .required('내용은 필수 입력 항목입니다.'),

  // file=Y인 경우
  imageUuidList: yup.array()
    .of(yup.string())
    .min(1, '이미지는 최소 1개 이상 선택해주세요.')
});

/**
 * 수정 검증
 */
export const UpdateValidator = yup.object({
  subject: yup.string()
    .required('제목은 필수 입력 항목입니다.')
    .min(2, '제목은 최소 2자 이상 입력해주세요.'),

  value: yup.string()
    .required('값은 필수 입력 항목입니다.'),

  contents: yup.string()
    .required('내용은 필수 입력 항목입니다.')
});
```

---

## 주요 yup 검증 데코레이터

| 메서드 | 용도 | 예시 |
|-------|------|------|
| `.required(msg)` | 필수값 | `.required('필수입니다')` |
| `.min(n, msg)` | 최소 길이 | `.min(2, '2자 이상')` |
| `.max(n, msg)` | 최대 길이 | `.max(100, '100자 이하')` |
| `.email(msg)` | 이메일 형식 | `.email('이메일 형식')` |
| `.matches(regex, msg)` | 정규식 | `.matches(/^[0-9]+$/, '숫자만')` |
| `.array().of(schema)` | 배열 검증 | `.array().of(yup.string())` |
| `.array().min(n, msg)` | 배열 최소 개수 | `.array().min(1, '1개 이상')` |

---

## file 옵션별 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| formData | 기본 필드만 | + fileUuidList, imageUuidList |
| Validator | 기본 검증만 | + 파일 배열 검증 |
| 모달 UI | 기본 폼 | + 파일 업로드 컴포넌트 |

---

## 검증

```bash
cd front && npx vue-tsc --noEmit
cd front && bun run lint:fix
```
