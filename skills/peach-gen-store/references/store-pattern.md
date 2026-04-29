# Store 패턴 (Pinia Option API)

> test-data.store.ts 기반 Pinia Option API 스타일

---

## 파일 구조

```
front/src/modules/[모듈명]/store/[모듈명].store.ts
```

---

## Import 패턴

```typescript
import { useApi } from '@/modules/_common/services/api.service.ts';
import { defineStore } from 'pinia';
import axios from 'axios';
import type { AxiosProgressEvent } from 'axios';
import { ExcelTemplateUtil } from '@/utils/excel-template.util.ts';
import type {
  [모듈명PascalCase]Detail,
  [모듈명PascalCase]File,
  [모듈명PascalCase]FileLocalUploadResult,
  [모듈명PascalCase]FileS3UploadResult,
  [모듈명PascalCase]InsertDto,
  [모듈명PascalCase]PagingDto,
  [모듈명PascalCase]SearchDto,
  [모듈명PascalCase]UpdateDto,
  [모듈명PascalCase]ExcelUploadDto
} from '../type/[모듈명].type';
```

---

## 기본 구조 (file=N)

```typescript
type ProgressCallback = (progress: number) => void;

/**
 * [모듈명] 통합 관리 스토어
 */
export const use[모듈명PascalCase]Store = defineStore('[모듈명]', {
  state: () => ({
    // ===== LIST/DETAIL STATE =====
    listData: [] as [모듈명PascalCase]Detail[],
    listTotalRow: 0,
    detailData: {} as [모듈명PascalCase]Detail
  }),

  getters: {
  },

  actions: {
    // ===== CRUD OPERATIONS =====

    /**
     * 상세 데이터 초기화
     */
    detailDataInit(): void {
      this.detailData = {} as [모듈명PascalCase]Detail;
    },

    /**
     * 페이징 목록 조회
     * @route GET /[모듈명]
     */
    async paging(params: [모듈명PascalCase]PagingDto): Promise<void> {
      const result = await useApi().get<{ totalRow: number; data: [모듈명PascalCase]Detail[] }>(
        '/[모듈명]',
        { params }
      );

      // 테이블 표시용 부가 정보 추가 (nIndex: 순번, chk: 체크박스)
      this.listData = result.data.map((item, nIndex: number) => {
        return { ...item, nIndex, chk: false };
      });

      this.listTotalRow = Number(result.totalRow);
    },

    /**
     * 전체 목록 조회 (페이징 없음)
     * @route GET /[모듈명]/list
     */
    list(params: [모듈명PascalCase]SearchDto): Promise<[모듈명PascalCase]Detail[]> {
      return useApi().get<[모듈명PascalCase]Detail[]>(`/[모듈명]/list`, { params });
    },

    /**
     * 상세 조회
     * @route GET /[모듈명]/:seq
     */
    async detail([pk]Seq: number): Promise<void> {
      this.detailData = await useApi().get<[모듈명PascalCase]Detail>(`/[모듈명]/${[pk]Seq}`);
    },

    /**
     * 커서 기반 목록 조회 (무한 스크롤)
     * @route GET /[모듈명]/cursor-list
     */
    async cursorList(params: {
      limit?: number;
      cursor?: string;
      keyword?: string;
    }): Promise<{ data: [모듈명PascalCase]Detail[]; nextCursor: string | null }> {
      return useApi().get<{ data: [모듈명PascalCase]Detail[]; nextCursor: string | null }>(
        '/[모듈명]/cursor-list',
        { params }
      );
    },

    /**
     * 신규 등록
     * @route POST /[모듈명]
     */
    insert(params: [모듈명PascalCase]InsertDto): Promise<{ isSuccess: boolean; [pk]Seq: number }> {
      return useApi().post<{ isSuccess: boolean; [pk]Seq: number }>('/[모듈명]', params);
    },

    /**
     * 데이터 수정
     * @route PUT /[모듈명]/:seq
     */
    update([pk]Seq: number, params: [모듈명PascalCase]UpdateDto): Promise<{ isSuccess: boolean }> {
      return useApi().put<{ isSuccess: boolean }>(`/[모듈명]/${[pk]Seq}`, params);
    },

    /**
     * 사용여부 변경 (단일/다중)
     * @route PATCH /[모듈명]/use
     */
    updateUse([pk]Seq: number | number[], isUse: string): Promise<{ isSuccess: boolean }> {
      return useApi().patch<{ isSuccess: boolean }>(`/[모듈명]/use`, { [pk]Seq, isUse });
    },

    /**
     * 논리 삭제 (단일/다중)
     * @route PATCH /[모듈명]/delete
     */
    softDelete([pk]Seq: number | number[]): Promise<{ isSuccess: boolean }> {
      return useApi().patch<{ isSuccess: boolean }>(`/[모듈명]/delete`, { [pk]Seq });
    },

    /**
     * 물리 삭제 (테스트 환경 전용)
     * @route DELETE /[모듈명]/:seq
     */
    hardDelete([pk]Seq: number): Promise<{ isSuccess: boolean }> {
      const env = import.meta.env.MODE;
      if (env !== 'local' && env !== 'test') {
        throw new Error('hardDelete는 테스트 환경에서만 사용 가능합니다.');
      }
      return useApi().delete<{ isSuccess: boolean }>(`/[모듈명]/${[pk]Seq}`);
    },

    // ===== TDD OPERATIONS (storeTdd=Y인 경우만) =====
    // ⚠️ 전제조건: Backend controllerTdd=Y 필요
    // Store TDD 테스트를 위해 Backend에 TDD API가 노출되어야 합니다.
    //
    // 기본적으로 생성하지 않음:
    // - 대부분의 Store는 API Wrapper이므로 Backend TDD로 충분
    // - 복잡한 클라이언트 로직이 있을 때만 storeTdd=Y 사용

    /**
     * TDD 데이터 초기화 (storeTdd=Y)
     * @route POST /[모듈명]/tdd/init
     */
    initTdd(params: {
      value: string;
      subject: string;
      contents: string;
    }): Promise<{ [pk]Seq: number; fileUuidList: string[]; imageUuidList: string[] }> {
      return useApi().post<{ [pk]Seq: number; fileUuidList: string[]; imageUuidList: string[] }>(
        '/[모듈명]/tdd/init',
        params
      );
    },

    /**
     * TDD 데이터 정리 (storeTdd=Y)
     * @route DELETE /[모듈명]/tdd/cleanup/:seq
     */
    cleanupTdd([pk]Seq: number): Promise<{ isSuccess: boolean }> {
      return useApi().delete<{ isSuccess: boolean }>(`/[모듈명]/tdd/cleanup/${[pk]Seq}`);
    }
  }
});
```

---

## 파일 기능 추가 (file=Y)

```typescript
// actions에 추가

// ===== FILE OPERATIONS =====

/**
 * Local 파일 업로드
 * @route POST /[모듈명]/file/upload/local
 */
uploadFileLocal(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<[모듈명PascalCase]FileLocalUploadResult> {
  const metadata = { isPrivate };
  const formData = new FormData();
  formData.append('metadata', JSON.stringify(metadata));
  formData.append('file', file);

  return useApi().post<[모듈명PascalCase]FileLocalUploadResult>(
    '/[모듈명]/file/upload/local',
    formData,
    {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (progressEvent: AxiosProgressEvent) => {
        if (progressEvent.total) {
          const progress = (progressEvent.loaded * 100) / progressEvent.total;
          callback(progress);
        }
      }
    }
  );
},

/**
 * S3 파일 업로드 (Presigned URL 방식)
 * @route POST /[모듈명]/file/upload/s3
 */
async uploadFileS3(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<[모듈명PascalCase]FileS3UploadResult> {
  const res = await useApi().post<[모듈명PascalCase]FileS3UploadResult>('/[모듈명]/file/upload/s3', {
    isPrivate,
    fileName: file.name,
    fileSize: file.size,
    fileType: file.type
  });

  if (!res?.uploadUrl) throw new Error('Upload URL not received from server');

  await this.uploadFileToS3(res.uploadUrl, file, callback);
  return res;
},

/**
 * S3 직접 업로드 (내부 헬퍼)
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
},

/**
 * 다운로드 URL 생성
 */
getDownloadUrl(file: [모듈명PascalCase]File): string {
  if (file.fileAuth === 'PRIVATE') throw new Error('비공개 파일은 직접 다운로드 불가');

  if (file.storageType === 'S3') {
    return `${import.meta.env.VITE_CF_ORIGIN_URL}/${file.filePath}`;
  }

  if (import.meta.env.MODE === 'localhost') {
    return `${import.meta.env.VITE_API}/[모듈명]/file/download/local/${file.fileUuid}`;
  }

  if (!import.meta.env.VITE_FILE_HOST) throw new Error('VITE_FILE_HOST 환경변수 필수');
  return `${import.meta.env.VITE_FILE_HOST}/${file.filePath}`;
},

/**
 * S3 PRIVATE 파일 Presigned URL 획득
 * @route GET /[모듈명]/file/download/s3/:fileUuid
 */
async getS3PresignedUrl(file: [모듈명PascalCase]File): Promise<string> {
  if (file.storageType !== 'S3') throw new Error('S3 파일만 지원합니다.');
  if (file.fileAuth !== 'PRIVATE') throw new Error('PRIVATE 파일만 지원합니다.');

  const response = await useApi().get<{ url: string; expiresIn: number }>(
    `/[모듈명]/file/download/s3/${file.fileUuid}`
  );
  return response.url;
},
```

---

## 엑셀 기능 추가

```typescript
// actions에 추가

// ===== EXCEL DOWNLOAD OPERATIONS =====

/**
 * Excel 템플릿 다운로드
 * @returns Excel Blob
 */
async downloadExcel(params: [모듈명PascalCase]PagingDto): Promise<Blob> {
  const exportParams: [모듈명PascalCase]PagingDto = {
    ...params,
    row: 999999,
    page: 1
  };

  const result = await useApi().get<{ totalRow: number; data: [모듈명PascalCase]Detail[] }>(
    '/[모듈명]',
    { params: exportParams }
  );
  const data = result.data;

  if (!data || data.length === 0) {
    throw new Error('내보낼 데이터가 없습니다');
  }

  const fieldMappings = [
    { field: '[pk]Seq', column: 1, defaultValue: '' },
    { field: 'value', column: 2, defaultValue: '' },
    // ... 필드 매핑 추가
  ];

  const templateFileUrl = '/template/[모듈명]/[모듈명]_excel_template.xlsx';

  const buffer = await ExcelTemplateUtil.generateFromTemplate(data, {
    templateUrl: templateFileUrl,
    fileName: '[모듈명]_export',
    startRowNum: 4,
    fieldMappings,
    preserveTemplateStyles: true
  });

  return new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  });
},

// ===== EXCEL UPLOAD OPERATIONS =====

/**
 * Excel 데이터 업로드
 * @route POST /[모듈명]/excel/upload
 */
async excelUpload(
  params: [모듈명PascalCase]ExcelUploadDto
): Promise<{ isSuccess: boolean; method: 'insert' | 'update' }> {
  return useApi().post<{ isSuccess: boolean; method: 'insert' | 'update' }>(
    '/[모듈명]/excel/upload',
    params
  );
},
```

---

## 핵심 패턴

### 1. Option API 스타일 (필수)

```typescript
// ✅ Option API (권장)
export const useStore = defineStore('name', {
  state: () => ({ ... }),
  getters: { ... },
  actions: { ... }
});

// ❌ Setup 스타일 (사용 금지)
export const useStore = defineStore('name', () => { ... });
```

### 2. State 구조

```typescript
state: () => ({
  listData: [] as EntityDetail[],    // 목록 데이터
  listTotalRow: 0,                   // 전체 개수
  detailData: {} as EntityDetail     // 상세 데이터
})
```

### 3. nIndex/chk 패턴

```typescript
// 페이징 조회 시 테이블용 부가 정보 추가
this.listData = result.data.map((item, nIndex: number) => {
  return { ...item, nIndex, chk: false };
});
```

### 4. TDD 연동 패턴 (storeTdd=Y인 경우만)

> ⚠️ **전제조건**: Backend controllerTdd=Y 필요
> Backend TDD API가 없으면 런타임 에러 발생

```typescript
// initTdd: 테스트 데이터 + 파일 생성
initTdd(params): Promise<{ [pk]Seq, fileUuidList, imageUuidList }>

// cleanupTdd: 데이터 + 파일 물리 삭제
cleanupTdd([pk]Seq): Promise<{ isSuccess }>
```

---

## file 옵션별 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| uploadFileLocal | ❌ | ✅ |
| uploadFileS3 | ❌ | ✅ |
| getDownloadUrl | ❌ | ✅ |
| getS3PresignedUrl | ❌ | ✅ |
| File 타입 | ❌ | ✅ |
