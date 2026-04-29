# File Upload 컴포넌트 패턴 (Mock 프로토타입)

> Mock 환경에서의 파일 업로드 패턴
> 실제 서버 없이 FormData 로깅 + 가짜 UUID 반환

---

## 파일 구조

```
front/src/modules/[모듈명]/components/file/
└── p-[모듈명]-file-upload.vue  ← 모듈별 파일 업로드 래퍼
```

---

## Mock 파일 업로드 핵심

프로토타입에서 파일 업로드는 실제 서버에 전송하지 않습니다.
대신 FormData를 로깅하고 가짜 UUID를 반환합니다.

### Store의 Mock 업로드 함수

```typescript
// store/[모듈명].store.ts
import { mockUploadFile } from '../mock/[모듈명].mock';

// actions:
uploadFileLocal(
  isPrivate: boolean,
  file: File,
  callback: (progress: number) => void
): Promise<{
  fileSeq: number;
  fileUuid: string;
  fileName: string;
  fileSize: number;
  filePath: string;
}> {
  // Mock: 진행률 시뮬레이션
  let progress = 0;
  const interval = setInterval(() => {
    progress += 20;
    callback(Math.min(progress, 100));
    if (progress >= 100) clearInterval(interval);
  }, 100);

  const formData = new FormData();
  formData.append('file', file);

  return new Promise((resolve) => {
    setTimeout(() => {
      clearInterval(interval);
      callback(100);
      resolve(mockUploadFile(formData));
    }, 600);
  });
},

getDownloadUrl(file: any): string {
  console.log('[Mock] getDownloadUrl:', file.fileName);
  return '#';
},
```

---

## 기본 구조 (프로덕션과 동일)

> 프로덕션 file-upload-pattern.md와 동일한 컴포넌트 구조를 사용합니다.
> 차이점은 Store의 uploadFileLocal/uploadFileS3가 Mock 함수를 호출하는 것뿐입니다.

```vue
<template>
  <p-file-upload
    ref="uploadLocalRef"
    v-model="files"
    :storage-type="storageType"
    :max-files="maxFiles"
    :upload-handler="uploadHandler"
    :down-url-resolver="downUrlResolver"
    @update:modelValue="handleUpdate"
    @file-delete="handleFileDelete"
  />
</template>

<script setup lang="ts">
import PFileUpload from '@/modules/_common/components/file/p-file-upload.vue';
import { use[ModuleName]Store } from '../../store/[모듈명].store';

const store = use[ModuleName]Store();

// Mock 업로드 핸들러 (Store의 Mock 함수 경유)
const uploadHandler = (file: File, progressCallback: (progress: number) => void) => {
  return store.uploadFileLocal(false, file, progressCallback);
};

// Mock 다운로드 URL (항상 '#' 반환)
const downUrlResolver = (file: any): string => {
  return store.getDownloadUrl(file);
};
</script>
```

---

## _common 래퍼 없는 프로젝트

_common/components/file/ 디렉토리가 없는 프로젝트에서는 간단한 파일 입력으로 대체:

```vue
<template>
  <div>
    <input
      ref="fileInput"
      type="file"
      :accept="accept"
      :multiple="maxFiles > 1"
      class="hidden"
      @change="handleFileChange"
    />
    <u-button size="sm" variant="outline" @click="triggerFileSelect">
      파일 선택
    </u-button>
    <div v-if="fileList.length > 0" class="mt-2 space-y-1">
      <div v-for="file in fileList" :key="file.fileUuid" class="flex items-center gap-2 text-sm">
        <span>{{ file.fileName }}</span>
        <u-button size="xs" color="error" variant="ghost" @click="removeFile(file)">삭제</u-button>
      </div>
    </div>
  </div>
</template>
```

---

## 프로덕션 전환

1. Store의 `uploadFileLocal`을 실제 API 호출로 교체
2. Store의 `getDownloadUrl`을 실제 URL 생성 로직으로 교체
3. 컴포넌트 코드는 변경 불필요 (Store 인터페이스 동일)

---

## 참조

- **Mock Store**: [mock-store-pattern.md](../core/mock-store-pattern.md) (Mock 업로드 함수)
- **프로덕션 패턴**: peach-gen-ui의 file-upload-pattern.md 참조
