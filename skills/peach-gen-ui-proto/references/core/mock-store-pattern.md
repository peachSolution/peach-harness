# Mock Store 패턴 가이드 (프로토타입 전용)

> Backend API 없이 Mock 데이터로 동작하는 Pinia Option API Store 패턴
> useApi() 경유 패턴을 유지하여 프로덕션 전환 시 코드 변경 최소화

---

## 개요

프로토타입 Store는 두 가지 방식으로 구현할 수 있습니다:

1. **Mock 함수 직접 호출** (권장): Store에서 mock 파일의 함수를 직접 호출
2. **Mock interceptor 경유**: useApi()를 호출하되, interceptor가 Mock 데이터 반환

프로젝트에 Mock interceptor가 설정되어 있으면 방식 2를, 없으면 방식 1을 사용합니다.

---

## 방식 1: Mock 함수 직접 호출 (권장)

### Store 전체 구조

```typescript
// front/src/modules/[모듈명]/store/[모듈명].store.ts
import { defineStore } from 'pinia';
import type {
  [ModuleName]Detail,
  [ModuleName]PagingDto,
  [ModuleName]InsertDto,
  [ModuleName]UpdateDto,
} from '../type/[모듈명].type';
import {
  mockPaging,
  mockDetail,
  mockInsert,
  mockUpdate,
  mockSoftDelete,
  mockUpdateUse,
} from '../mock/[모듈명].mock';

/**
 * [ModuleName] Store (Option API - Mock 전용)
 *
 * 프로덕션 전환 시:
 * 1. mock import를 useApi() import로 교체
 * 2. 각 action에서 mock 함수를 useApi() 호출로 교체
 * 3. mock/ 디렉토리 삭제
 */
export const use[ModuleName]Store = defineStore('[moduleName]', {
  state: () => ({
    // ===== LIST DATA =====
    listData: [] as [ModuleName]Detail[],
    listTotalRow: 0,

    // ===== SEARCH PARAMS =====
    listParams: {
      startDate: '',
      endDate: '',
      keyword: '',
      opt: 'all',
      isUse: '',
      sortBy: 'insertDate',
      sortType: 'desc',
      sortData: 'insertDate,desc',
      row: 20,
      page: 1,
      time: '',
    } as [ModuleName]PagingDto,

    // ===== DETAIL DATA =====
    detailData: {} as [ModuleName]Detail,
    selectedKey: 0,
  }),

  actions: {
    // ===== 초기화 =====

    listParamsInit(): void {
      this.listParams = {
        startDate: '',
        endDate: '',
        keyword: '',
        opt: 'all',
        isUse: '',
        sortBy: 'insertDate',
        sortType: 'desc',
        sortData: 'insertDate,desc',
        row: 20,
        page: 1,
        time: '',
      } as [ModuleName]PagingDto;
    },

    detailDataInit(): void {
      this.detailData = {} as [ModuleName]Detail;
      this.selectedKey = 0;
    },

    // ===== 조회 =====

    /**
     * 페이징 목록 조회 (Mock)
     * 프로덕션 전환 시:
     * const result = await useApi().get<{totalRow: number; data: [ModuleName]Detail[]}>('/[모듈명]', { params });
     */
    async paging(params: [ModuleName]PagingDto): Promise<void> {
      const result = mockPaging(params);

      this.listData = result.data.map((item, nIndex: number) => ({
        ...item,
        nIndex,
        chk: false,
      }));

      this.listTotalRow = Number(result.totalRow);
    },

    /**
     * 상세 조회 (Mock)
     * 프로덕션 전환 시:
     * this.detailData = await useApi().get<[ModuleName]Detail>(`/[모듈명]/${[pk]Seq}`);
     */
    async detail([pk]Seq: number): Promise<void> {
      const result = mockDetail([pk]Seq);
      this.detailData = result;
      this.selectedKey = [pk]Seq;
    },

    // ===== CRUD =====

    /**
     * 등록 (Mock)
     * 프로덕션 전환 시:
     * return useApi().post<{isSuccess: boolean; [pk]Seq: number}>('/[모듈명]', params);
     */
    insert(params: [ModuleName]InsertDto): Promise<{
      isSuccess: boolean;
      [pk]Seq: number;
    }> {
      const result = mockInsert(params);
      return Promise.resolve(result);
    },

    /**
     * 수정 (Mock)
     * 프로덕션 전환 시:
     * return useApi().put<{isSuccess: boolean}>(`/[모듈명]/${[pk]Seq}`, params);
     */
    update([pk]Seq: number, params: [ModuleName]UpdateDto): Promise<{
      isSuccess: boolean;
    }> {
      const result = mockUpdate([pk]Seq, params);
      return Promise.resolve(result);
    },

    /**
     * 논리 삭제 (Mock)
     * 프로덕션 전환 시:
     * return useApi().patch<{isSuccess: boolean}>('/[모듈명]/delete', { [pk]Seq });
     */
    softDelete([pk]Seq: number | number[]): Promise<{
      isSuccess: boolean;
    }> {
      const result = mockSoftDelete([pk]Seq);
      return Promise.resolve(result);
    },

    /**
     * 사용여부 변경 (Mock)
     * 프로덕션 전환 시:
     * return useApi().patch<{isSuccess: boolean}>('/[모듈명]/use', { [pk]Seq, isUse });
     */
    updateUse([pk]Seq: number | number[], isUse: string): Promise<{
      isSuccess: boolean;
    }> {
      const result = mockUpdateUse([pk]Seq, isUse);
      return Promise.resolve(result);
    },
  },
});
```

---

## 방식 2: Mock interceptor 경유 (useApi() 유지)

프로젝트에 Mock interceptor가 설정되어 있는 경우:

```typescript
// front/src/modules/[모듈명]/store/[모듈명].store.ts
import { defineStore } from 'pinia';
import { useApi } from '@/modules/_common/services/api.service.ts';

export const use[ModuleName]Store = defineStore('[moduleName]', {
  // state는 동일...

  actions: {
    /**
     * 페이징 목록 조회
     * Mock interceptor가 '/[모듈명]' 경로를 가로채서 Mock 데이터 반환
     */
    async paging(params: [ModuleName]PagingDto): Promise<void> {
      const result = await useApi().get<{
        totalRow: number;
        data: [ModuleName]Detail[];
      }>('/[모듈명]', { params });

      this.listData = result.data.map((item, nIndex: number) => ({
        ...item,
        nIndex,
        chk: false,
      }));

      this.listTotalRow = Number(result.totalRow);
    },

    // 나머지 actions도 useApi() 그대로 사용
    // Mock interceptor가 자동으로 Mock 데이터 반환
  },
});
```

---

## Mock 파일 업로드 Store 패턴

```typescript
// file=Y인 경우 추가

import { mockUploadFile } from '../mock/[모듈명].mock';

// actions에 추가:

/**
 * Local 파일 업로드 (Mock)
 * FormData를 받아 가짜 UUID를 반환합니다.
 *
 * 프로덕션 전환 시:
 * return useApi().post('/[모듈명]/file/upload/local', formData, { headers: {...} });
 */
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

/**
 * 다운로드 URL 생성 (Mock)
 * Mock 환경에서는 빈 URL 반환
 */
getDownloadUrl(file: any): string {
  console.log('[Mock] getDownloadUrl:', file.fileName);
  return '#';
},
```

---

## Mock Excel Store 패턴

```typescript
// excel=Y인 경우 추가

import { mockDownloadExcel } from '../mock/[모듈명].mock';

// actions에 추가:

/**
 * 엑셀 다운로드 (Mock)
 * 로컬에서 CSV/Excel Blob을 생성합니다.
 *
 * 프로덕션 전환 시:
 * ExcelTemplateUtil.generateFromTemplate() 또는 useApi().get() 사용
 */
async downloadExcel(params: [ModuleName]PagingDto): Promise<Blob> {
  console.log('[Mock] downloadExcel:', params);
  return mockDownloadExcel(params);
},

/**
 * 엑셀 업로드 (Mock)
 *
 * 프로덕션 전환 시:
 * return useApi().post('/[모듈명]/excel/upload', dto);
 */
async excelUpload(dto: any): Promise<{
  isSuccess: boolean;
  method: 'insert' | 'update';
}> {
  console.log('[Mock] excelUpload:', dto);
  return { isSuccess: true, method: 'insert' };
},
```

---

## Mock 커서 기반 조회 (무한 스크롤)

```typescript
// infinite-scroll 패턴인 경우 추가

import { mockCursorList } from '../mock/[모듈명].mock';

// actions에 추가:

/**
 * 커서 기반 목록 조회 (Mock)
 *
 * 프로덕션 전환 시:
 * return useApi().get('/[모듈명]/cursor-list', { params });
 */
async cursorList(params: {
  limit: number;
  cursor: string;
  keyword: string;
}): Promise<{
  data: [ModuleName]Detail[];
  nextCursor: string | null;
}> {
  return mockCursorList(params);
},
```

---

## 프로덕션 전환 가이드

### Before (Mock)

```typescript
import { mockPaging, mockDetail, mockInsert } from '../mock/[모듈명].mock';

async paging(params) {
  const result = mockPaging(params);
  this.listData = result.data.map(...);
  this.listTotalRow = result.totalRow;
}
```

### After (프로덕션)

```typescript
import { useApi } from '@/modules/_common/services/api.service.ts';

async paging(params) {
  const result = await useApi().get<{totalRow: number; data: T[]}>('/[모듈명]', { params });
  this.listData = result.data.map(...);
  this.listTotalRow = result.totalRow;
}
```

### 전환 체크리스트

- [ ] `mock/[모듈명].mock.ts` import 제거
- [ ] `useApi()` import 추가
- [ ] 각 action에서 mock 함수를 `useApi()` 호출로 교체
- [ ] Mock 진행률 시뮬레이션 코드 제거 (파일 업로드)
- [ ] `mock/` 디렉토리 삭제
- [ ] 타입 체크 + 빌드 확인

---

## 참조

- **Mock 데이터 정의**: [mock-service-pattern.md](mock-service-pattern.md)
- **프로덕션 Store**: [store-pattern.md](store-pattern.md) (실서버 연결 참고)
- **타입 패턴**: [type-pattern.md](type-pattern.md)
