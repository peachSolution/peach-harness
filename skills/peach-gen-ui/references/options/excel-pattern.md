# Excel 처리 패턴

> test-data/modals/excel-upload.modal.vue 기반 엑셀 다운로드/업로드 패턴

## 목차

- [파일 구조](#파일-구조)
- [엑셀 다운로드 (Store)](#엑셀-다운로드-store)
- [엑셀 업로드 모달 구조](#엑셀-업로드-모달-구조)
- [MODULE_CONFIG 패턴](#module_config-패턴)
- [인라인 타입 정의](#인라인-타입-정의)
- [상수 정의](#상수-정의)
- [상태 관리](#상태-관리)
- [엑셀 파일 처리](#엑셀-파일-처리)
- [행 선택 로직](#행-선택-로직)
- [업로드 로직](#업로드-로직)
- [Computed 속성](#computed-속성)
- [Validator 패턴](#validator-패턴)
- [Store 엑셀 업로드 Action](#store-엑셀-업로드-action)
- [페이지에서 사용](#페이지에서-사용)
- [핵심 패턴](#핵심-패턴)

---

## 파일 구조

```
front/src/modules/[모듈명]/modals/
├── excel-upload.modal.vue     ← 엑셀 업로드 모달
└── _[모듈명]-excel.validator.ts  ← 엑셀 검증 스키마
```

---

## 엑셀 다운로드 (Store)

### Store Action

```typescript
// store/[모듈명].store.ts
actions: {
  // 엑셀 다운로드
  async downloadExcel(fileName: string) {
    const { $api } = useNuxtApp();
    await $api.download('/[모듈명]/excel/download', fileName);
  }
}
```

### 페이지에서 사용

```vue
<template>
  <u-button variant="outline" @click="downloadExcel">
    <u-icon name="i-heroicons-arrow-down-tray" />
    엑셀 다운로드
  </u-button>
</template>

<script setup lang="ts">
const downloadExcel = async () => {
  await FormService.loading(async () => {
    await store.downloadExcel('[모듈명]_template.xlsx');
  });
};
</script>
```

---

## 엑셀 업로드 모달 구조

### excel-upload.modal.vue

```vue
<template>
  <u-modal class="max-w-[70vw] max-h-[80vh]" :dismissible="false">
    <template #header>
      <div class="w-full flex items-center justify-between">
        <h3>엑셀 업로드</h3>
        <u-button color="neutral" variant="ghost" icon="i-heroicons-x-mark-20-solid" @click="$emit('close')" />
      </div>
    </template>

    <template #body>
      <u-form ref="formRef" :schema="ExcelUploadValidator" :state="formState" @error="handleFormError" @submit="uploadData">
        <div class="flex flex-col gap-4">
          <!-- 파일 선택 버튼 -->
          <div class="flex items-center gap-3">
            <input ref="fileInput" type="file" @change="handleFileUpload" accept=".xlsx, .xls" class="hidden" />
            <u-button @click="triggerFileInput">엑셀 파일 선택</u-button>
            <span v-if="selectedFileName">{{ selectedFileName }}</span>

            <!-- 업로드 상태 뱃지 -->
            <div v-if="hasUploadStatus" class="flex items-center gap-2">
              <u-badge v-if="insertCount > 0" color="warning">등록: {{ insertCount }}</u-badge>
              <u-badge v-if="updateCount > 0" color="info">수정: {{ updateCount }}</u-badge>
              <u-badge v-if="failureCount > 0" color="error">실패: {{ failureCount }}</u-badge>
            </div>
          </div>

          <!-- 데이터 테이블 -->
          <div v-if="excelData.length > 0" class="overflow-auto h-[60vh] border rounded-md">
            <ul class="min-w-max divide-y">
              <!-- 헤더 행 (컬럼 매핑 셀렉트 포함) -->
              <li class="grid gap-4 py-3.5 px-4 bg-gray-50 sticky top-0">
                <div><!-- 체크박스 --></div>
                <div v-for="(header, index) in headerData" :key="index">
                  {{ header }}
                  <p-nuxt-select v-if="index > 1" v-model="columnSelections[index]" :options="selectOptions" />
                </div>
              </li>

              <!-- 데이터 행 -->
              <li v-for="(row, rowIndex) in excelData" :key="rowIndex" @click="handleRowClick(rowIndex + 1, $event)">
                <input type="checkbox" :checked="isRowSelected(rowIndex + 1)" @change="toggleRowSelection(rowIndex + 1)" />
                <div>{{ rowIndex + 1 }}</div>
                <div><!-- 업로드 상태 뱃지 --></div>
                <div v-for="(cell, cellIndex) in row" :key="cellIndex">{{ cell }}</div>
              </li>
            </ul>
          </div>
        </div>
      </u-form>
      <p v-if="excelData.length > 1">Shift + 클릭 하면 여러 행을 선택할 수 있습니다.</p>
    </template>

    <template #footer>
      <!-- 진행률 바 -->
      <div class="w-[450px]">
        <div v-show="isUploading || uploadProgress === 100">
          업로드 진행중... {{ completedRowsCount }}/{{ totalRowsToUpload }}
          <div class="w-full rounded bg-gray-200">
            <div :style="{ width: progressBarWidth }">{{ uploadProgress }}%</div>
          </div>
        </div>
      </div>

      <!-- 버튼 -->
      <div class="flex gap-2">
        <u-button color="neutral" @click="$emit('close')" :disabled="isUploading">취소</u-button>
        <u-button @click="formSubmit" :disabled="isUploading">업로드</u-button>
      </div>
    </template>
  </u-modal>
</template>
```

---

## MODULE_CONFIG 패턴

엑셀 업로드 모달은 **MODULE_CONFIG 섹션만 수정**하여 재사용:

```typescript
// ========================================================================
// ===== MODULE CONFIGURATION (수정 필요 부분) =====
// ========================================================================

// 1. 모듈별 스토어 import
import { use[모듈명PascalCase]Store } from '../store/[모듈명].store';
const store = use[모듈명PascalCase]Store();

// 2. 컬럼 설정 정의
const COLUMN_CONFIG = [
  { text: '내용(필수)', value: 'contents', required: true },
  { text: '제목(필수)', value: 'subject', required: true },
  { text: '값(필수)', value: 'value', required: true },
  { text: '숫자(필수)', value: 'bigint', required: true },
  { text: '사용여부', value: 'isUse', required: false }
];

// 3. 업로드 DTO 생성 함수
const createUploadDto = (row: ExcelRow, columnMap: Record<number, string>): [모듈명PascalCase]ExcelUploadDto => {
  const dto: [모듈명PascalCase]ExcelUploadDto = {
    value: '',
    subject: '',
    contents: '',
    bigint: 0
  };

  Object.entries(columnMap).forEach(([index, field]) => {
    const colIndex = parseInt(index) - COLUMN_OFFSET;
    const cellValue = row[colIndex];

    switch(field) {
      case 'subject': dto.subject = String(cellValue || ''); break;
      case 'value': dto.value = String(cellValue || ''); break;
      case 'contents': dto.contents = String(cellValue || ''); break;
      case 'bigint': dto.bigint = Number(cellValue || 0); break;
    }
  });

  return dto;
};

// 4. API 호출 함수
const uploadApi = async (dto: [모듈명PascalCase]ExcelUploadDto): Promise<UploadResult> => {
  return store.excelUpload(dto);
};
```

---

## 인라인 타입 정의

```typescript
// ===== INLINE TYPE DEFINITIONS =====
type ExcelRow = (string | number | null)[];
type UploadStatus = 'pending' | 'loading' | 'success' | 'failure';

interface SelectOption {
  text: string;
  value: string;
  required: boolean;
}

interface ProcessedExcelData {
  excelData: ExcelRow[];
  columnSelections: Record<number, string>;
  maxColumns: number;
}

interface UploadResult {
  isSuccess: boolean;
  method: 'insert' | 'update';
}
```

---

## 상수 정의

```typescript
// ===== CONSTANTS =====
const COLUMN_OFFSET = 2; // '번호', '비고' 컬럼 오프셋
const BASE_HEADERS = ['번호', '비고'];
```

---

## 상태 관리

```typescript
// ===== STATE MANAGEMENT =====

// File Management
const formRef = ref();
const fileInput = ref<HTMLInputElement>();
const selectedFileName = ref<string>('');

// Data Management
const excelData = ref<ExcelRow[]>([]);
const columnSelections = ref<Record<number, string>>({});
const selectOptions = ref<SelectOption[]>(COLUMN_CONFIG);

// Selection Management
const selectedRows = ref<number[]>([]);
const selectedRowsSet = ref<Set<number>>(new Set());
const lastSelectedRow = ref<number | null>(null);

// Upload Status
const rowUploadStatus = ref<Record<number, UploadStatus>>({});
const rowUploadMethod = ref<Record<number, string>>({});
```

---

## 엑셀 파일 처리

```typescript
const processExcelFile = async (file: File): Promise<ProcessedExcelData> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const firstSheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[firstSheetName];
        const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as ExcelRow[];

        // 필수 컬럼 자동 매핑
        const columnSelectionsData: Record<number, string> = {};
        const maxColumns = jsonData.length > 0 ? Math.max(...jsonData.map(row => row.length)) : 0;

        for (let i = COLUMN_OFFSET; i < Math.min(COLUMN_OFFSET + selectOptions.value.length, COLUMN_OFFSET + maxColumns); i++) {
          const optionIndex = i - COLUMN_OFFSET;
          if (selectOptions.value[optionIndex]?.required) {
            columnSelectionsData[i] = selectOptions.value[optionIndex].value;
          }
        }

        resolve({ excelData: jsonData, columnSelections: columnSelectionsData, maxColumns });
      } catch (error) {
        reject(error);
      }
    };

    reader.onerror = () => reject(new Error('파일 읽기 실패'));
    reader.readAsArrayBuffer(file);
  });
};
```

---

## 행 선택 로직

```typescript
// 단일 선택
const toggleRowSelection = (rowIndex: number) => {
  if (selectedRowsSet.value.has(rowIndex)) {
    selectedRows.value = selectedRows.value.filter(id => id !== rowIndex);
    selectedRowsSet.value.delete(rowIndex);
  } else {
    selectedRows.value.push(rowIndex);
    selectedRowsSet.value.add(rowIndex);
  }
  lastSelectedRow.value = rowIndex;
};

// Shift + 클릭 범위 선택
const handleRowClick = (rowIndex: number, event: MouseEvent) => {
  if (event.shiftKey) event.preventDefault();

  if (event.shiftKey && lastSelectedRow.value !== null) {
    const start = Math.min(lastSelectedRow.value, rowIndex);
    const end = Math.max(lastSelectedRow.value, rowIndex);
    for (let i = start; i <= end; i++) {
      if (!selectedRowsSet.value.has(i)) {
        selectedRows.value.push(i);
        selectedRowsSet.value.add(i);
      }
    }
    selectedRows.value.sort((a, b) => a - b);
  } else {
    toggleRowSelection(rowIndex);
  }
};

// 전체 선택/해제
const toggleAllRows = () => {
  if (allRowsSelected.value) {
    selectedRows.value = [];
    selectedRowsSet.value.clear();
  } else {
    selectedRows.value = Array.from({ length: excelData.value.length }, (_, i) => i + 1);
    selectedRowsSet.value = new Set(selectedRows.value);
  }
};
```

---

## 업로드 로직

```typescript
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
        const dto = createUploadDto(excelData.value[adjustedIndex], columnSelections.value);
        const result = await uploadApi(dto);

        // 성공 처리
        rowUploadStatus.value[adjustedIndex] = 'success';
        rowUploadMethod.value[adjustedIndex] = result.method;
      } catch (error) {
        // 실패 처리
        rowUploadStatus.value[adjustedIndex] = 'failure';
      }
    }

    emits('upload-ok');
  } catch (error) {
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

## Computed 속성

```typescript
// 헤더 데이터
const headerData = computed(() => {
  if (excelData.value.length === 0) return BASE_HEADERS;
  const maxColumns = Math.max(...excelData.value.map(row => row.length));
  const additionalHeaders = Array.from({ length: maxColumns }, (_, i) => `항목${i + 1}`);
  return [...BASE_HEADERS, ...additionalHeaders];
});

// 전체 선택 여부
const allRowsSelected = computed(() => {
  if (excelData.value.length === 0) return false;
  return selectedRows.value.length === excelData.value.length;
});

// 업로드 통계
const uploadStats = computed(() => {
  const methods = Object.values(rowUploadMethod.value);
  const statuses = Object.values(rowUploadStatus.value);
  return {
    insertCount: methods.filter(m => m === 'insert').length,
    updateCount: methods.filter(m => m === 'update').length,
    failureCount: statuses.filter(s => s === 'failure').length
  };
});

// 진행률
const uploadProgress = computed(() => {
  if (totalRowsToUpload.value === 0) return 0;
  return Math.round((completedRowsCount.value / totalRowsToUpload.value) * 100);
});
```

---

## Validator 패턴

### _[모듈명]-excel.validator.ts

```typescript
import * as yup from 'yup';

export const ExcelUploadValidator = yup.object({
  selectedRows: yup
    .array()
    .min(1, '업로드할 행을 선택해주세요.')
    .required('업로드할 행을 선택해주세요.'),
  columnSelections: yup
    .object()
    .test('required-columns', '필수 컬럼을 모두 매핑해주세요.', (value) => {
      // 모듈별 필수 컬럼 목록
      const required = ['subject', 'value', 'contents', 'bigint'];
      const mapped = Object.values(value || {});
      return required.every(r => mapped.includes(r));
    })
});
```

---

## Store 엑셀 업로드 Action

```typescript
// store/[모듈명].store.ts
actions: {
  async excelUpload(dto: [모듈명PascalCase]ExcelUploadDto): Promise<{ isSuccess: boolean; method: 'insert' | 'update' }> {
    const { $api } = useNuxtApp();
    const res = await $api.post('/[모듈명]/excel/upload', dto);
    return {
      isSuccess: res.value?.code === 200,
      method: res.value?.data?.method || 'insert'
    };
  }
}
```

---

## 페이지에서 사용

```vue
<template>
  <!-- 버튼 -->
  <u-button variant="outline" @click="openExcelUpload">엑셀 업로드</u-button>

  <!-- 모달 -->
  <excel-upload v-if="isOpenExcelUpload" @close="isOpenExcelUpload = false" @upload-ok="handleExcelUploadOk" />
</template>

<script setup lang="ts">
import ExcelUpload from '../../modals/excel-upload.modal.vue';

const isOpenExcelUpload = ref(false);

const openExcelUpload = () => {
  isOpenExcelUpload.value = true;
};

const handleExcelUploadOk = () => {
  isOpenExcelUpload.value = false;
  listAction(); // 목록 새로고침
};
</script>
```

---

## 핵심 패턴

### 1. MODULE_CONFIG 수정만으로 재사용

```
excel-upload.modal.vue (복사)
    ↓
MODULE_CONFIG 섹션만 수정:
- Store import
- COLUMN_CONFIG 정의
- createUploadDto 함수
- uploadApi 함수
```

### 2. 업로드 상태 관리

```
pending → loading → success/failure
```

### 3. 컬럼 매핑

```
엑셀 헤더 → 필드 매핑 셀렉트 → DTO 생성
```

### 4. 행 선택 UX

```
- 단일 클릭: 토글
- Shift + 클릭: 범위 선택
- 전체 선택 체크박스
```
