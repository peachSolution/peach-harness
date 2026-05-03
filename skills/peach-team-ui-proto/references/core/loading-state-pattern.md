# Loading State 패턴 가이드

> test-data 모듈의 검증된 로딩 상태 관리 패턴 (실제 운영 코드 기반)

---

## 📋 목차

1. [패턴 1: FormService.loading() (80% 케이스)](#1-패턴-1-formserviceloading-80-케이스)
2. [패턴 2: isLoading ref (20% 케이스)](#2-패턴-2-isloading-ref-20-케이스)
3. [패턴 3: ProgressCallback (파일 업로드)](#3-패턴-3-progresscallback-파일-업로드)
4. [Decision Tree](#4-decision-tree)
5. [코드 예시 비교](#5-코드-예시-비교)
6. [UI 컴포넌트 통합](#6-ui-컴포넌트-통합)

---

## 1. 패턴 1: FormService.loading() (80% 케이스)

### 1.1 개념

**가장 일반적이고 추천되는 패턴**으로, 모든 비동기 작업에 사용합니다.

FormService의 `loading()` 메서드는 콜백 함수를 받아 자동으로:
1. 로딩 시작 (스피너 표시)
2. 비동기 작업 실행
3. 로딩 종료 (스피너 숨김)

을 관리하는 고수준 API입니다.

---

### 1.2 구현 상세

**파일**: `front/src/modules/_common/services/form.service.ts:17-29`

```typescript
/**
 * 비동기 작업 로딩 상태 자동 관리
 * @param callback 비동기 작업 콜백
 * @param isUse 로딩 스피너 사용 여부 (기본: true)
 */
static async loading(callback: any, isUse: boolean = true): Promise<void> {
  const defaultLayoutStore = useDefaultLayoutStore();
  try {
    defaultLayoutStore.loading(true, isUse);  // 로딩 시작
    await callback();
  } catch (error) {
    throw error;  // 에러 재발생
  } finally {
    defaultLayoutStore.loading(false, isUse);  // 로딩 종료 (항상 실행)
  }
}
```

**DefaultLayoutStore 연동**:

**파일**: `front/src/modules/_common/store/default-layout.store.ts:40-46`

```typescript
/**
 * 로딩 상태 관리 (전역)
 * @param isLoading 로딩 중 여부
 * @param isUse 로딩 스피너 표시 여부
 */
loading(isLoading: boolean, isUse: boolean = false) {
  if (isUse) {
    this.isLoading = isLoading;  // 전역 로딩 플래그 설정
  }
}
```

---

### 1.3 사용 예시

#### 예시 1: 수정/등록 작업 (modal)

**파일**: `front/src/modules/test-data/modals/update.modal.vue:175-192`

```vue
<script setup lang="ts">
import { FormService } from '@/modules/_common/services/form.service.ts';
import { useTestDataStore } from '@/modules/test-data/store/test-data.store.ts';

const testDataStore = useTestDataStore();
const emit = defineEmits(['update-ok']);

/**
 * 수정 처리
 * FormService.loading()으로 로딩 상태 자동 관리
 */
const register = async () => {
  await FormService.loading(async () => {
    // 파일 리스트를 UUID 배열로 변환
    const { fileList, imageList, ...rest } = updateData.value;
    const updateDto = {
      ...rest,
      fileUuidList: fileList?.map(f => f.fileUuid).filter(Boolean) ?? [],
      imageUuidList: imageList?.map(f => f.fileUuid).filter(Boolean) ?? []
    };

    await testDataStore.update(props.testSeq, updateDto);

    useToast().add({
      title: '수정 완료',
      description: '수정이 완료되었습니다.',
      color: 'success'
    });

    emit('update-ok');
    close();
  });
};
</script>
```

**특징:**
- ✅ API 호출 ≈ 1-3초 소요되는 작업
- ✅ 사용자 입력 검증 후 즉시 로딩 표시
- ✅ 성공 토스트 메시지 표시

---

#### 예시 2: 목록 조회

**파일**: `front/src/modules/test-data/pages/crud/list-table.vue:341-350`

```typescript
/**
 * 목록 조회
 * 페이징 데이터 fetch
 */
const getList = async () => {
  await FormService.loading(async () => {
    await testDataStore.paging(listParams.value);

    // 데이터가 없으면 첫 페이지로 이동
    if (listData.value.length === 0 && listParams.value.page > 1) {
      await router.push({ query: { ...route.query, page: 1 } });
      return;
    }
  });
};
```

---

### 1.4 장점

| 장점 | 설명 |
|-----|------|
| **Try-Finally 자동 처리** | 에러 발생 시에도 로딩 상태가 반드시 종료됨 |
| **간결한 코드** | 로딩 시작/종료 로직 제거 |
| **일관된 UX** | 모든 API 호출에 동일한 로딩 UI 표시 |
| **재사용 가능** | 어디서나 동일한 패턴 적용 |

---

### 1.5 언제 사용?

- ✅ API 호출이 주 목적인 비동기 작업
- ✅ 작업 시간이 예측 가능한 경우 (1-5초)
- ✅ 동시에 여러 작업이 아닌 순차 작업
- ✅ **대부분의 CRUD 작업 (80% 이상)**

---

## 2. 패턴 2: isLoading ref (20% 케이스)

### 2.1 개념

개별 `ref<boolean>` 상태로 로딩을 **수동 관리**하는 패턴입니다.

복잡한 로직이나 **부분 로딩**이 필요할 때 사용합니다.

---

### 2.2 Excel 업로드 예시

**파일**: `front/src/modules/test-data/modals/excel-upload.modal.vue:357-566`

```typescript
// ===== 타입 정의 =====

type UploadStatus = 'pending' | 'loading' | 'success' | 'failure';

// ===== 상태 관리 =====

// 행별 업로드 상태
const rowUploadStatus = ref<Record<number, UploadStatus>>({});

// 행별 메서드 (insert/update)
const rowUploadMethod = ref<Record<number, string>>({});

// ===== 계산된 값 =====

// 업로드 중 여부
const isUploading = computed(() =>
  Object.values(rowUploadStatus.value).some(s => s === 'loading')
);

// 진행률 계산
const uploadProgress = computed(() => {
  if (totalRowsToUpload.value === 0) return 0;
  return Math.round((completedRowsCount.value / totalRowsToUpload.value) * 100);
});

// 완료된 행 수
const completedRowsCount = computed(() =>
  Object.values(rowUploadStatus.value).filter(
    s => s === 'success' || s === 'failure'
  ).length
);

// ===== 업로드 로직 =====

/**
 * Excel 데이터 업로드
 * 행별로 상태를 개별 관리
 */
const uploadData = async () => {
  try {
    // 선택된 행들을 순차적으로 업로드
    for (const rowIndex of selectedRows.value) {
      const adjustedIndex = rowIndex - 1;

      // 업로드 시작
      rowUploadStatus.value[adjustedIndex] = 'loading';
      rowUploadMethod.value[adjustedIndex] = '';

      try {
        // DTO 생성 및 API 호출
        const dto = createUploadDto(
          excelData.value[adjustedIndex],
          columnSelections.value
        );
        const result = await uploadApi(dto);

        // 성공 처리
        rowUploadStatus.value[adjustedIndex] = 'success';
        rowUploadMethod.value[adjustedIndex] = result.method;
      } catch (error) {
        // 실패 처리
        rowUploadStatus.value[adjustedIndex] = 'failure';
        console.error(`Row ${rowIndex} upload failed:`, error);
      }
    }

    emits('upload-ok');
  } catch (error) {
    console.error('Upload process failed:', error);

    // 처리 중이던 행들을 실패로 설정
    selectedRows.value.forEach(rowIndex => {
      const adjustedIndex = rowIndex - 1;
      if (rowUploadStatus.value[adjustedIndex] === 'loading') {
        rowUploadStatus.value[adjustedIndex] = 'failure';
      }
    });
  }
};
```

---

### 2.3 UI 표시

#### 행별 상태 배지

```vue
<template>
  <table>
    <tr v-for="(row, rowIndex) in excelData" :key="rowIndex">
      <!-- 데이터 셀들 -->
      <td>{{ row.name }}</td>
      <td>{{ row.email }}</td>

      <!-- 상태 배지 -->
      <td>
        <!-- 로딩중 -->
        <u-badge v-if="rowUploadStatus[rowIndex] === 'loading'" color="warning" variant="soft">
          <u-icon name="i-lucide-loader-2" class="w-3 h-3 animate-spin" />
          로딩중
        </u-badge>

        <!-- 성공 -->
        <u-badge v-else-if="rowUploadStatus[rowIndex] === 'success'" color="success" variant="soft">
          <u-icon name="i-lucide-check" class="w-3 h-3" />
          성공 ({{ rowUploadMethod[rowIndex] }})
        </u-badge>

        <!-- 실패 -->
        <u-badge v-else-if="rowUploadStatus[rowIndex] === 'failure'" color="error" variant="soft">
          <u-icon name="i-lucide-x" class="w-3 h-3" />
          실패
        </u-badge>

        <!-- 대기 -->
        <u-badge v-else color="gray" variant="soft">
          대기
        </u-badge>
      </td>
    </tr>
  </table>
</template>
```

#### 진행률 바

```vue
<template>
  <div v-show="isUploading || uploadProgress === 100" class="w-full mt-4">
    <!-- 진행 상황 텍스트 -->
    <div class="mb-2 text-sm font-medium">
      업로드 진행중... {{ completedRowsCount }}/{{ totalRowsToUpload }}
    </div>

    <!-- 진행률 바 -->
    <div class="w-full rounded bg-gray-200 dark:bg-gray-700">
      <div
        class="w-full rounded bg-blue-500 p-0.5 text-center text-xs leading-none font-medium text-blue-100"
        :style="{ width: progressBarWidth }"
      >
        {{ uploadProgress }}%
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// 진행률 바 너비 계산
const progressBarWidth = computed(() => `${uploadProgress.value}%`);
</script>
```

---

### 2.4 언제 사용?

| 사용 시점 | 설명 |
|----------|------|
| **다중 항목 개별 처리** | Excel 행 단위 업로드처럼 여러 항목을 독립적으로 처리 |
| **행별/항목별 진행 상황 표시** | 사용자에게 각 항목의 진행 상황을 실시간으로 알려줄 때 |
| **조건부 로딩** | 특정 조건에만 로딩 표시 필요 |
| **부분 로딩** | 전체가 아닌 일부만 로딩 표시 |

---

## 3. 패턴 3: ProgressCallback (파일 업로드)

### 3.1 개념

Axios의 `onUploadProgress` 이벤트를 활용하여 **파일 업로드 진행률**을 콜백으로 전달하는 패턴입니다.

---

### 3.2 Store 구현

**파일**: `front/src/modules/test-data/store/test-data.store.ts:165-235`

```typescript
// ===== 타입 정의 =====

type ProgressCallback = (progress: number) => void;

// ===== Local 파일 업로드 =====

/**
 * Local 파일 업로드
 * @param isPrivate 비공개 여부
 * @param file 업로드 파일
 * @param callback 진행률 콜백 (0-100)
 * @returns {fileSeq, fileUuid, fileName, fileSize, filePath}
 */
uploadFileLocal(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<TestDataFileLocalUploadResult> {
  const metadata = { isPrivate };
  const formData = new FormData();
  formData.append('metadata', JSON.stringify(metadata));
  formData.append('file', file);

  return useApi().post<TestDataFileLocalUploadResult>(
    '/test-data/file/upload/local',
    formData,
    {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (progressEvent: AxiosProgressEvent) => {
        if (progressEvent.total) {
          const progress = (progressEvent.loaded * 100) / progressEvent.total;
          callback(progress);  // 0-100 진행률 전달
        }
      }
    }
  );
}

// ===== S3 파일 업로드 =====

/**
 * S3 파일 업로드 (Presigned URL 방식)
 * 1단계: Presigned URL 획득
 * 2단계: S3에 직접 업로드
 */
async uploadFileS3(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<TestDataFileS3UploadResult> {
  // 1단계: Presigned URL 획득
  const res = await useApi().post<TestDataFileS3UploadResult>(
    '/test-data/file/upload/s3',
    { isPrivate, fileName: file.name, fileSize: file.size, fileType: file.type }
  );

  if (!res?.uploadUrl) throw new Error('Upload URL not received from server');

  // 2단계: S3에 직접 업로드
  await this.uploadFileToS3(res.uploadUrl, file, callback);
  return res;
}

/**
 * S3 직접 업로드 (내부 헬퍼)
 * uploadFileS3에서만 사용
 */
uploadFileToS3(uploadUrl: string, file: File, callback: ProgressCallback) {
  return axios.put(uploadUrl, file, {
    onUploadProgress: (progressEvent: AxiosProgressEvent) => {
      if (progressEvent.total) {
        const progress = (progressEvent.loaded * 100) / progressEvent.total;
        callback(progress);
      }
    }
  });
}
```

---

### 3.3 컴포넌트 호출

**파일**: `front/src/modules/test-data/components/file/p-test-data-file-upload.vue:165-171`

```vue
<template>
  <div>
    <!-- 파일 선택 -->
    <input type="file" @change="handleFileChange" />

    <!-- 진행률 표시 -->
    <div v-if="uploadProgress > 0" class="mt-2">
      <div class="text-sm">업로드 중... {{ uploadProgress }}%</div>
      <div class="w-full bg-gray-200 rounded">
        <div
          class="bg-blue-500 p-0.5 rounded text-xs text-white text-center"
          :style="{ width: `${uploadProgress}%` }"
        >
          {{ uploadProgress }}%
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useTestDataStore } from '@/modules/test-data/store/test-data.store';

const testDataStore = useTestDataStore();
const uploadProgress = ref(0);

/**
 * 파일 업로드 핸들러
 * Store의 uploadFile 메서드를 래핑 (storageType에 따라 분기)
 */
const handleFileChange = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;

  // 진행률 초기화
  uploadProgress.value = 0;

  try {
    let result;

    // Storage Type에 따라 분기
    if (props.storageType === 'S3') {
      result = await testDataStore.uploadFileS3(
        props.isPrivate,
        file,
        (progress) => {
          uploadProgress.value = Math.round(progress);
        }
      );
    } else {
      result = await testDataStore.uploadFileLocal(
        false,
        file,
        (progress) => {
          uploadProgress.value = Math.round(progress);
        }
      );
    }

    // 업로드 완료 이벤트
    emit('upload-success', result);
  } catch (error) {
    emit('upload-error', error);
  }
};
</script>
```

---

### 3.4 언제 사용?

- ✅ 대용량 파일 업로드 (10MB 이상)
- ✅ 사용자가 업로드 진행 상황을 알아야 하는 경우
- ✅ 느린 네트워크 환경에서 UX 향상
- ✅ LOCAL/S3 스토리지 모두에서 일관된 진행률 표시

---

## 4. Decision Tree

```
로딩 상태 처리 필요?
│
├─→ 간단한 CRUD 작업 (Insert, Update, Delete, Fetch)
│   └─→ FormService.loading() ✅
│       • insert() 호출 전후
│       • update() 호출 전후
│       • softDelete() 호출 전후
│       • paging() 호출 전후
│
├─→ 파일 업로드/다운로드
│   ├─→ 단일 파일: p-file-upload 컴포넌트 (내부 progressCallback 처리) ✅
│   └─→ 여러 파일: isLoading ref + ProgressCallback ✅
│
├─→ 여러 항목 동시 처리 (배치 작업)
│   ├─→ 각 항목별 상태 표시 필요? → isLoading ref (행별 상태) ✅
│   │   • Excel 업로드: 행별 pending/loading/success/failure
│   │   • 다중 삭제: 항목별 진행 상황
│   │
│   └─→ 단순 진행률만 필요? → ProgressCallback + 진행률 바 ✅
│       • 파일 다운로드
│       • 데이터 내보내기
│
└─→ 복잡한 다단계 작업
    └─→ isLoading ref (세부 상태 관리) ✅
        • 단계별 상태: validating → uploading → processing
        • 취소 기능 필요
```

---

## 5. 코드 예시 비교

### 5.1 가장 일반적 (80%): FormService.loading()

```typescript
// ✅ 권장: 가장 많이 사용되는 패턴
const handleSave = async () => {
  await FormService.loading(async () => {
    await store.update(id, formData);
    showSuccessMessage('저장되었습니다');
  });
};
```

**특징:**
- ⭐ 가장 간단하고 추천되는 패턴
- ⭐ 80% 이상의 케이스에 사용
- 로딩 상태 자동 관리
- 에러 발생 시에도 안전하게 종료

---

### 5.2 Excel 업로드 (특수): isLoading ref + 행별 상태

```typescript
// Excel 행별로 다른 상태 표시
const uploadExcelData = async () => {
  for (const rowIndex of selectedRows.value) {
    // 행별 상태 변경
    rowUploadStatus.value[rowIndex] = 'loading';

    try {
      await uploadApi(row);
      rowUploadStatus.value[rowIndex] = 'success';
    } catch (e) {
      rowUploadStatus.value[rowIndex] = 'failure';
    }
  }
};
```

**특징:**
- 행별 상태 개별 관리
- 부분 실패에도 계속 처리
- UI에서 각 행의 상태 실시간 표시

---

### 5.3 파일 업로드 (대용량): ProgressCallback

```typescript
// Store에서 진행률 콜백으로 처리
const uploadFile = async (file: File) => {
  const progress = ref(0);

  try {
    const result = await testDataStore.uploadFileLocal(
      false,  // 공개 파일
      file,
      (p) => {
        progress.value = p;  // UI에서 진행률 표시
      }
    );

    // 업로드 완료 처리
    console.log('Upload completed:', result);
  } catch (error) {
    console.error('Upload failed:', error);
  }
};
```

**특징:**
- 진행률 실시간 표시 (0-100%)
- 대용량 파일에 적합
- 사용자 경험 개선

---

## 6. UI 컴포넌트 통합

### 6.1 전역 로딩 스피너 (FormService.loading 사용)

**위치**: 페이지 상단 또는 중앙

**제어**: default-layout.store의 `isLoading` 플래그

```vue
<template>
  <div v-if="defaultLayoutStore.isLoading" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
    <div class="animate-spin rounded-full h-16 w-16 border-t-4 border-blue-500"></div>
  </div>
</template>

<script setup lang="ts">
import { useDefaultLayoutStore } from '@/modules/_common/store/default-layout.store';

const defaultLayoutStore = useDefaultLayoutStore();
</script>
```

---

### 6.2 행별 상태 배지 (isLoading ref 사용)

**위치**: 각 행의 우측

**상태**: pending → loading → success/failure

```vue
<template>
  <td>
    <!-- 대기 -->
    <u-badge v-if="!rowStatus[index]" color="gray" variant="soft">
      대기
    </u-badge>

    <!-- 로딩중 -->
    <u-badge v-else-if="rowStatus[index] === 'loading'" color="warning" variant="soft">
      <u-icon name="i-lucide-loader-2" class="animate-spin" />
      로딩중
    </u-badge>

    <!-- 성공 -->
    <u-badge v-else-if="rowStatus[index] === 'success'" color="success" variant="soft">
      <u-icon name="i-lucide-check" />
      성공
    </u-badge>

    <!-- 실패 -->
    <u-badge v-else-if="rowStatus[index] === 'failure'" color="error" variant="soft">
      <u-icon name="i-lucide-x" />
      실패
    </u-badge>
  </td>
</template>
```

---

### 6.3 진행률 바 (ProgressCallback 사용)

**위치**: 모달 하단 또는 중앙

**형식**: `{{ progress }}%` 텍스트 + 색상 바

```vue
<template>
  <div class="w-full">
    <!-- 텍스트 -->
    <div class="mb-2 text-sm font-medium">
      업로드 중... {{ progress }}%
    </div>

    <!-- 진행률 바 -->
    <div class="w-full bg-gray-200 rounded-full h-2.5">
      <div
        class="bg-blue-600 h-2.5 rounded-full transition-all"
        :style="{ width: `${progress}%` }"
      ></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const progress = ref(0);  // 0-100
</script>
```

---

## 핵심 요약

### 80% 케이스 (대부분의 작업)

```typescript
// ⭐ 가장 간단하고 추천되는 패턴
await FormService.loading(async () => {
  await store.updateData(params);
});
```

### 20% 케이스 (특수한 작업)

```typescript
// Excel 업로드처럼 항목별 진행 상황 표시 필요
rowStatus.value[index] = 'loading';
try {
  await uploadApi(row);
  rowStatus.value[index] = 'success';
} catch (e) {
  rowStatus.value[index] = 'failure';
}
```

### 파일 업로드 (독립적)

```typescript
// Store에서 자동 진행률 처리
store.uploadFile(file, (progress) => {
  progressBar.value = progress;
});
```

---

**이 3가지 패턴으로 프로젝트의 모든 로딩 상태 관리 요구사항을 충족합니다.**

---

**참고 파일:**
- `front/src/modules/_common/services/form.service.ts`
- `front/src/modules/_common/store/default-layout.store.ts`
- `front/src/modules/test-data/modals/update.modal.vue`
- `front/src/modules/test-data/modals/excel-upload.modal.vue`
- `front/src/modules/test-data/store/test-data.store.ts`
- `front/src/modules/test-data/components/file/p-test-data-file-upload.vue`
