# Validator 패턴 (Yup)

> test-data/modals/_crud.validator.ts 기반 Yup 검증 패턴

---

## 파일 구조

```
front/src/modules/[모듈명]/modals/_[모듈명].validator.ts
```

---

## 기본 구조

```typescript
import * as yup from 'yup';

// 파일 객체 스키마 정의 (file=Y인 경우)
const fileSchema = yup.object({
  fileSeq: yup.mixed().nullable(),
  parentCode: yup.mixed().nullable(),
  storageType: yup.string(),
  fileAuth: yup.string(),
  fileUuid: yup.string(),
  fileFolder: yup.string(),
  filePath: yup.string(),
  fileName: yup.string(),
  fileSize: yup.number(),
  fileType: yup.string(),
  downloadCnt: yup.number(),
  orderValue: yup.number(),
  insertSeq: yup.mixed().nullable(),
  insertDate: yup.string(),
  updateSeq: yup.mixed().nullable(),
  updateDate: yup.string()
});

export const [모듈명PascalCase]InsertValidator = yup.object({
  subject: yup
    .string()
    .required('subject는 필수 입력 항목입니다.')
    .min(2, 'subject는 최소 2자 이상 입력해주세요.'),
  value: yup
    .string()
    .required('value는 필수 입력 항목입니다.')
    .min(2, 'value는 최소 2자 이상 입력해주세요.'),
  imageList: yup
    .array()
    .of(fileSchema)
    .min(1, '이미지는 최소 1개 이상 선택해주세요.')
    .required('이미지는 최소 1개 이상 선택해주세요.'),
  contents: yup
    .string()
    .required('contents는 필수 입력 항목입니다.')
    .min(10, 'contents는 최소 10자 이상 입력해주세요.')
});

export const [모듈명PascalCase]UpdateValidator = yup.object({
  subject: yup
    .string()
    .required('subject는 필수 입력 항목입니다.')
    .min(2, 'subject는 최소 2자 이상 입력해주세요.'),
  value: yup
    .string()
    .required('value는 필수 입력 항목입니다.')
    .min(2, 'value는 최소 2자 이상 입력해주세요.'),
  imageList: yup
    .array()
    .of(fileSchema)
    .min(1, '이미지는 최소 1개 이상 선택해주세요.')
    .required('이미지는 최소 1개 이상 선택해주세요.'),
  contents: yup
    .string()
    .required('contents는 필수 입력 항목입니다.')
    .min(10, 'contents는 최소 10자 이상 입력해주세요.')
});
```

---

## 검증 규칙 종류

### 필수값 검증

```typescript
yup.string().required('필수 입력 항목입니다.')
yup.number().required('필수 입력 항목입니다.')
yup.array().required('필수 선택 항목입니다.')
```

### 길이 검증

```typescript
yup.string().min(2, '최소 2자 이상 입력해주세요.')
yup.string().max(100, '최대 100자까지 입력 가능합니다.')
yup.array().min(1, '최소 1개 이상 선택해주세요.')
```

### 형식 검증

```typescript
yup.string().email('올바른 이메일 형식이 아닙니다.')
yup.string().url('올바른 URL 형식이 아닙니다.')
yup.string().matches(/^[0-9]+$/, '숫자만 입력 가능합니다.')
```

### 숫자 검증

```typescript
yup.number().positive('양수만 입력 가능합니다.')
yup.number().integer('정수만 입력 가능합니다.')
yup.number().min(0, '0 이상이어야 합니다.')
yup.number().max(100, '100 이하여야 합니다.')
```

### 배열 검증

```typescript
// 배열 요소 스키마 정의
yup.array().of(fileSchema)

// 배열 최소 길이
yup.array().min(1, '최소 1개 이상 선택해주세요.')

// 배열 필수
yup.array().required('필수 선택 항목입니다.')
```

---

## 파일 스키마 (file=Y)

```typescript
const fileSchema = yup.object({
  fileSeq: yup.mixed().nullable(),
  parentCode: yup.mixed().nullable(),
  storageType: yup.string(),
  fileAuth: yup.string(),
  fileUuid: yup.string(),
  fileFolder: yup.string(),
  filePath: yup.string(),
  fileName: yup.string(),
  fileSize: yup.number(),
  fileType: yup.string(),
  downloadCnt: yup.number(),
  orderValue: yup.number(),
  insertSeq: yup.mixed().nullable(),
  insertDate: yup.string(),
  updateSeq: yup.mixed().nullable(),
  updateDate: yup.string()
});
```

---

## 모달에서 사용

### u-form과 연동

```vue
<template>
  <u-form
    ref="formRef"
    :schema="[모듈명PascalCase]InsertValidator"
    :state="detailData"
    @submit="register"
    @error="handleFormError"
  >
    <u-form-field label="제목" name="subject">
      <p-input-box v-model="detailData.subject" />
    </u-form-field>
    <!-- ... -->
  </u-form>
</template>

<script setup lang="ts">
import { [모듈명PascalCase]InsertValidator } from './_[모듈명].validator.ts';
import type { FormErrorEvent } from '@nuxt/ui';

const handleFormError = (event: FormErrorEvent) => {
  FormService.onError(event);
};
</script>
```

### name 속성 매칭

```vue
<!-- name 속성이 validator의 필드와 일치해야 함 -->
<u-form-field label="제목" name="subject">
  <p-input-box v-model="detailData.subject" />
</u-form-field>

<u-form-field label="이미지" name="imageList">
  <p-file-upload :file-list="detailData.imageList" @set-files="setImages" />
</u-form-field>
```

---

## 엑셀 업로드 Validator

```typescript
// _[모듈명]-excel.validator.ts

import * as yup from 'yup';

export const ExcelUploadValidator = yup.object({
  selectedRows: yup
    .array()
    .min(1, '업로드할 행을 선택해주세요.')
    .required('업로드할 행을 선택해주세요.'),
  columnSelections: yup
    .object()
    .test('required-columns', '필수 컬럼을 모두 매핑해주세요.', (value) => {
      const required = ['subject', 'value', 'contents', 'bigint'];
      const mapped = Object.values(value || {});
      return required.every(r => mapped.includes(r));
    })
});
```

---

## 핵심 패턴

### 1. Insert/Update 분리

```typescript
// Insert: 초기 등록용
export const InsertValidator = yup.object({ ... });

// Update: 수정용 (동일한 경우가 많음)
export const UpdateValidator = yup.object({ ... });
```

### 2. 파일 필드 검증

```typescript
// file=Y인 경우
imageList: yup
  .array()
  .of(fileSchema)
  .min(1, '이미지는 최소 1개 이상 선택해주세요.')
  .required('이미지는 최소 1개 이상 선택해주세요.')

// file=N인 경우
// imageList 필드 제외
```

### 3. 선택적 필드

```typescript
// 필수 아닌 필드
optionalField: yup.string().nullable()

// 조건부 필수
conditionalField: yup.string().when('isRequired', {
  is: true,
  then: yup.string().required('필수 입력입니다.'),
  otherwise: yup.string().nullable()
})
```

---

## file 옵션별 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| fileSchema | ❌ | ✅ |
| imageList 검증 | ❌ | ✅ |
| fileList 검증 | ❌ | ✅ (필요 시) |
