# Excel 처리 패턴 (Mock 프로토타입)

> Mock 환경에서의 엑셀 다운로드/업로드 패턴
> 서버 없이 로컬에서 CSV/Excel Blob 생성

---

## 파일 구조

```
front/src/modules/[모듈명]/modals/
├── excel-upload.modal.vue        ← 엑셀 업로드 모달
└── _[모듈명]-excel.validator.ts  ← 엑셀 검증 스키마
```

---

## Mock 엑셀 다운로드

### Store Action (Mock)

```typescript
// store/[모듈명].store.ts
import { mockDownloadExcel } from '../mock/[모듈명].mock';

// actions:
async downloadExcel(params: [ModuleName]PagingDto): Promise<Blob> {
  console.log('[Mock] downloadExcel:', params);
  return mockDownloadExcel(params);
},
```

### Mock 함수 (mock/[모듈명].mock.ts)

```typescript
/**
 * Mock 엑셀 다운로드
 * CSV 형태의 Blob을 생성합니다.
 * ExcelTemplateUtil이 있는 프로젝트는 템플릿 기반 생성도 가능합니다.
 */
export const mockDownloadExcel = (params: [ModuleName]PagingDto): Blob => {
  console.log('[Mock] downloadExcel:', params);

  const headers = ['번호', '제목', '값', '사용여부', '등록일'];
  const rows = mock[ModuleName]List
    .filter(item => item.isDelete !== 'Y')
    .map(item => [
      item.[pk]Seq,
      item.subject,
      item.value,
      item.isUse,
      item.insertDate
    ].join(','));

  const csvContent = [headers.join(','), ...rows].join('\n');
  const bom = '\uFEFF'; // UTF-8 BOM (한글 깨짐 방지)

  return new Blob([bom + csvContent], { type: 'text/csv;charset=utf-8;' });
};
```

### 페이지에서 사용

```vue
<template>
  <u-button variant="outline" @click="downloadExcel">
    엑셀 다운로드
  </u-button>
</template>

<script setup lang="ts">
import dayjs from 'dayjs';

const downloadExcel = async () => {
  await FormService.loading(async () => {
    try {
      const blob = await store.downloadExcel(listParams.value);

      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `[모듈명]-${dayjs().format('YYYY-MM-DD')}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      useToast().add({
        title: '다운로드 완료',
        description: '엑셀 파일이 다운로드되었습니다.',
        color: 'success'
      });
    } catch (error) {
      useToast().add({
        title: '다운로드 오류',
        description: '다운로드 중 오류가 발생했습니다.',
        color: 'error'
      });
    }
  });
};
</script>
```

---

## Mock 엑셀 업로드

엑셀 업로드 모달은 프로덕션과 동일한 구조를 사용합니다.
차이점은 Store의 `excelUpload` action이 Mock 응답을 반환하는 것뿐입니다.

### Store Action (Mock)

```typescript
async excelUpload(dto: any): Promise<{
  isSuccess: boolean;
  method: 'insert' | 'update';
}> {
  console.log('[Mock] excelUpload:', dto);
  return { isSuccess: true, method: 'insert' };
},
```

---

## ExcelTemplateUtil 사용 (프로젝트에 존재하는 경우)

프로젝트에 ExcelTemplateUtil이 있으면 더 정교한 엑셀 파일을 생성할 수 있습니다:

```typescript
import { ExcelTemplateUtil } from '@/modules/_common/utils/excel-template.util';

export const mockDownloadExcel = async (params: [ModuleName]PagingDto): Promise<Blob> => {
  const data = mock[ModuleName]List.filter(item => item.isDelete !== 'Y');

  const fieldMappings = [
    { field: '[pk]Seq', column: 1, defaultValue: '' },
    { field: 'subject', column: 2, defaultValue: '' },
    { field: 'value', column: 3, defaultValue: '' },
    { field: 'isUse', column: 4, defaultValue: '' },
    { field: 'insertDate', column: 5, defaultValue: '' },
  ];

  const templateFileUrl = '/template/[모듈명]/[모듈명]_template.xlsx';

  const buffer = await ExcelTemplateUtil.generateFromTemplate(data, {
    templateUrl: templateFileUrl,
    fileName: '[모듈명]_export',
    startRowNum: 4,
    fieldMappings,
    preserveTemplateStyles: true,
  });

  return new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
};
```

---

## 프로덕션 전환

1. Mock `downloadExcel`을 실제 API 호출로 교체
2. Mock `excelUpload`를 실제 API 호출로 교체
3. 엑셀 업로드 모달 코드는 변경 불필요

---

## 참조

- **Mock Store**: [mock-store-pattern.md](../core/mock-store-pattern.md)
- **프로덕션 패턴**: peach-gen-ui의 excel-pattern.md 참조
