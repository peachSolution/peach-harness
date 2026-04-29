# File Upload 컴포넌트 패턴

> test-data/components/file/p-test-data-file-upload.vue 기반 파일 업로드 패턴

---

## 파일 구조

```
front/src/modules/[모듈명]/components/file/
└── p-[모듈명]-file-upload.vue  ← 모듈별 파일 업로드 래퍼
```

---

## 기본 구조

```vue
<template>
  <p-file-upload
    ref="uploadLocalRef"
    v-model="files"
    :storage-type="storageType"
    :max-files="maxFiles"
    :max-file-size="maxFileSize"
    :accept="accept"
    :allowed-extensions="allowedExtensions"
    :allowed-mime-types="allowedMimeTypes"
    :upload-handler="uploadHandler"
    :down-url-resolver="downUrlResolver"
    :is-editor-add="isEditorAdd"
    :is-private="isPrivate"
    :max-concurrent-uploads="maxConcurrentUploads"
    @update:modelValue="handleUpdate"
    @file-delete="handleFileDelete"
    @editor-add="handleEditorAdd"
  >
    <template #actions="{ file }">
      <slot name="actions" :file="file" />
    </template>
  </p-file-upload>
</template>

<script setup lang="ts">
import { computed, defineComponent, ref } from 'vue';
import PFileUpload from '@/modules/_common/components/file/p-file-upload.vue';
import { use[모듈명PascalCase]Store } from '../../store/[모듈명].store';
import type { FileInfo } from '@/modules/_common/type/file.type.ts';
import type { [모듈명PascalCase]File } from '@/modules/[모듈명]/type/[모듈명].type.ts';

defineComponent({
  name: 'P[모듈명PascalCase]Upload'
});

const store = use[모듈명PascalCase]Store();
const uploadLocalRef = ref<InstanceType<typeof PFileUpload> | null>(null);

const props = defineProps({
  fileList: {
    type: Array as () => [모듈명PascalCase]File[],
    default: () => []
  },
  storageType: {
    type: String as () => 'LOCAL' | 'S3',
    default: 'LOCAL'
  },
  maxFiles: {
    type: Number,
    default: 5
  },
  maxFileSize: {
    type: Number,
    default: 100 * 1024 * 1024 // 100MB
  },
  accept: {
    type: String,
    default: ''
  },
  allowedExtensions: {
    type: Array as () => string[],
    default: () => ['xlsx', 'xls', 'csv', 'pdf', 'jpg', 'png', 'gif', 'jpeg', 'txt', 'zip']
  },
  allowedMimeTypes: {
    type: Array as () => string[],
    default: () => [
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv',
      'application/csv',
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'text/plain',
      'application/zip',
      'application/x-zip-compressed'
    ]
  },
  isEditorAdd: {
    type: Boolean,
    default: false
  },
  isPrivate: {
    type: Boolean,
    default: false
  },
  maxConcurrentUploads: {
    type: Number,
    default: 3
  }
});

const emit = defineEmits<{
  (e: 'setFiles', files: [모듈명PascalCase]File[]): void;
  (e: 'fileDelete', downUrl: string): void;
  (e: 'editorAdd', html: string): void;
}>();

// ... 타입 변환 및 핸들러
</script>
```

---

## 타입 변환 패턴

### FileInfo → ModuleFile

```typescript
/**
 * FileInfo를 모듈 파일 타입으로 변환
 * _common 컴포넌트에서 받은 데이터를 모듈 형식으로 변환
 */
const toModuleFile = (fileInfo: FileInfo): [모듈명PascalCase]File => {
  return {
    // FileInfo에서 제공되는 필드
    fileUuid: fileInfo.fileUuid,
    fileName: fileInfo.fileName,
    fileSize: fileInfo.fileSize,
    fileType: fileInfo.fileType,
    storageType: fileInfo.storageType,
    fileAuth: fileInfo.fileAuth,
    filePath: fileInfo.filePath,

    // 모듈 전용 필드 (기본값)
    fileFolder: '',
    fileSeq: 0,
    downloadCnt: 0,
    orderValue: 0,
    parentCode: null,
    insertSeq: 0,
    insertDate: '',
    updateSeq: 0,
    updateDate: ''
  };
};
```

### ModuleFile → FileInfo

```typescript
/**
 * 모듈 파일을 FileInfo로 변환
 * 디버깅 시 각 속성의 매핑을 명확히 확인할 수 있도록 명시적 설정
 */
const toFileInfo = (moduleFile: [모듈명PascalCase]File): FileInfo => {
  return {
    fileUuid: moduleFile.fileUuid,
    fileName: moduleFile.fileName,
    fileSize: moduleFile.fileSize,
    fileType: moduleFile.fileType,
    storageType: moduleFile.storageType as 'LOCAL' | 'S3',
    fileAuth: moduleFile.fileAuth as 'PUBLIC' | 'PRIVATE',
    filePath: moduleFile.filePath
  };
};
```

---

## 핸들러 패턴

### Upload Handler (Local/S3 분기)

```typescript
// Store의 uploadFile 메서드를 래핑 (storageType에 따라 분기)
const uploadHandler = (file: File, progressCallback: (progress: number) => void) => {
  if (props.storageType === 'S3') {
    return store.uploadFileS3(props.isPrivate, file, progressCallback);
  } else {
    return store.uploadFileLocal(false, file, progressCallback);
  }
};
```

### Download URL Resolver

```typescript
// 파일 다운로드 URL 생성 함수
const downUrlResolver = (file: FileInfo): string => {
  const moduleFile = toModuleFile(file);
  // getDownloadUrl은 S3 PRIVATE 파일에 대해 Error를 throw
  // 필요시 별도로 getS3PresignedUrl을 호출해야 함
  return store.getDownloadUrl(moduleFile);
};
```

---

## v-model 패턴

```typescript
// v-model 처리를 위한 computed
const files = computed({
  get: () => {
    // ModuleFile 배열을 FileInfo 배열로 변환
    return props.fileList.map(toFileInfo);
  },
  set: (val: FileInfo[]) => {
    // FileInfo 배열을 ModuleFile 배열로 변환하여 emit
    emit('setFiles', val.map(toModuleFile));
  }
});

const handleUpdate = (updatedFiles: FileInfo[]) => {
  const moduleFiles = updatedFiles.map(toModuleFile);
  emit('setFiles', moduleFiles);
};
```

---

## 외부 노출 메서드 (defineExpose)

```typescript
defineExpose({
  // 파일 업로드 트리거
  uploadFiles: (files: File[] | File) => {
    if (uploadLocalRef.value) {
      (uploadLocalRef.value as any).uploadFiles?.(files);
    }
  },
  // 파일 선택 대화상자 열기
  triggerFileSelect: () => {
    if (uploadLocalRef.value) {
      const fileInput = (uploadLocalRef.value as any).$refs?.fileInputRef;
      if (fileInput) {
        fileInput.click();
      }
    }
  }
});
```

---

## 모달에서 사용

### insert.modal.vue

```vue
<template>
  <u-form-field label="이미지" name="imageList">
    <p-[모듈명]-file-upload
      :file-list="detailData.imageList"
      :max-files="1"
      accept="image/*"
      @set-files="setImages"
    />
  </u-form-field>

  <u-form-field label="첨부파일" name="fileList">
    <p-[모듈명]-file-upload
      :file-list="detailData.fileList"
      :max-files="5"
      @set-files="setFiles"
    />
  </u-form-field>
</template>

<script setup lang="ts">
import P[모듈명PascalCase]FileUpload from '../components/file/p-[모듈명]-file-upload.vue';

// 파일 추가 핸들러
const setFiles = (files: [모듈명PascalCase]File[]) => {
  detailData.value.fileList = files;
};

// 이미지 추가 핸들러
const setImages = (files: [모듈명PascalCase]File[]) => {
  detailData.value.imageList = files;
};
```

### 파일 → UUID 변환 (저장 시)

```typescript
const register = async () => {
  await FormService.loading(async () => {
    // 파일 리스트를 UUID 배열로 변환
    const { fileList, imageList, ...rest } = detailData.value;
    const insertData = {
      ...rest,
      fileUuidList: fileList?.map((f) => f.fileUuid).filter(Boolean) ?? [],
      imageUuidList: imageList?.map((f) => f.fileUuid).filter(Boolean) ?? []
    };
    const result = await store.insert(insertData);
    // ...
  });
};
```

---

## Props 옵션

| Prop | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| fileList | File[] | [] | 파일 목록 |
| storageType | 'LOCAL' \| 'S3' | 'LOCAL' | 저장소 타입 |
| maxFiles | number | 5 | 최대 파일 개수 |
| maxFileSize | number | 100MB | 최대 파일 크기 |
| accept | string | '' | 허용 MIME 타입 |
| allowedExtensions | string[] | [...] | 허용 확장자 |
| allowedMimeTypes | string[] | [...] | 허용 MIME 타입 |
| isEditorAdd | boolean | false | 에디터 추가 모드 |
| isPrivate | boolean | false | 비공개 파일 여부 |
| maxConcurrentUploads | number | 3 | 동시 업로드 수 |

---

## Emits

| Event | Payload | 설명 |
|-------|---------|------|
| setFiles | File[] | 파일 목록 변경 |
| fileDelete | string | 파일 삭제 (downUrl) |
| editorAdd | string | 에디터에 HTML 추가 |

---

## 핵심 패턴

### 1. 래퍼 컴포넌트 구조

```
p-file-upload (_common)     ← 공통 파일 업로드 컴포넌트
    ↑
p-[모듈명]-file-upload      ← 모듈별 래퍼 (스토어 연결)
    ↑
insert.modal.vue            ← 실제 사용처
```

### 2. 스토어 연결

```typescript
// 모듈 스토어의 파일 관련 메서드 사용
const store = use[모듈명PascalCase]Store();

// 업로드
store.uploadFileLocal(isPrivate, file, progressCallback);
store.uploadFileS3(isPrivate, file, progressCallback);

// 다운로드 URL
store.getDownloadUrl(file);
store.getS3PresignedUrl(fileUuid);
```

### 3. 타입 안전성

```typescript
// 모듈별 File 타입 사용
import type { [모듈명PascalCase]File } from '@/modules/[모듈명]/type/[모듈명].type.ts';

// 공통 FileInfo 타입과 변환
import type { FileInfo } from '@/modules/_common/type/file.type.ts';
```
