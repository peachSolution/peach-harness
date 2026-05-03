# Store 패턴 가이드 (Option API)

> test-data 모듈의 검증된 Store 패턴 (실제 운영 코드 기반)

---

## 📋 목차

1. [전체 구조 개요](#1-전체-구조-개요)
2. [State 정의 패턴](#2-state-정의-패턴)
3. [Actions 표준 구조 (16가지)](#3-actions-표준-구조-16가지)
4. [환경 분기 패턴](#4-환경-분기-패턴)
5. [API 응답 타입 정의](#5-api-응답-타입-정의)
6. [실제 사용 예시](#6-실제-사용-예시)
7. [핵심 개념 정리](#7-핵심-개념-정리)
8. [Actions 분류 요약 테이블](#8-actions-분류-요약-테이블)

---

## 1. 전체 구조 개요

### 1.1 Store 파일 위치 및 명명 규칙

```
src/modules/[모듈명]/store/[모듈명].store.ts
src/modules-domain/[도메인명]/[서브모듈]/store/[모듈명].store.ts
```

**예시:**
```
src/modules/test-data/store/test-data.store.ts
src/modules-domain/unpaid/unpaid-payment/store/unpaid-payment.store.ts
```

---

### 1.2 기본 골격 (Option API)

```typescript
import { defineStore } from 'pinia';
import { useApi } from '@/modules/_common/services/api.service.ts';

/**
 * TestData Store (Option API 방식)
 */
export const useTestDataStore = defineStore('testData', {
  // 상태 정의
  state: () => ({ ... }),

  // Getter (필요시)
  getters: { ... },

  // 액션 (비동기 작업 포함)
  actions: { ... }
});
```

---

### 1.3 주요 특징

| 특징 | 설명 |
|-----|------|
| **Option API 방식만 사용** | Composition API 절대 금지 (컴포넌트와 구분) |
| **모든 API 통신은 Store를 통해** | 컴포넌트에서 직접 API 호출 금지 |
| **상태는 단순하고 명확하게** | 복잡한 로직은 actions에서 처리 |
| **타입 안전성 보장** | TypeScript 타입 명시적 정의 |

---

## 2. State 정의 패턴

### 2.1 표준 State 구조

**파일**: `front/src/modules/test-data/store/test-data.store.ts`

```typescript
state: () => ({
  // ===== LIST DATA =====
  listData: [] as TestDataDetail[],           // 목록 데이터
  listTotalRow: 0,                            // 전체 행 수

  // ===== SEARCH PARAMS =====
  listParams: {
    // 기본 검색 필드
    startDate: '',
    endDate: '',
    keyword: '',
    opt: 'all',
    isUse: '',

    // 정렬
    sortBy: 'insertDate',
    sortType: 'desc',
    sortData: 'insertDate,desc',

    // 페이징
    row: 20,
    page: 1,

    // 캐시 방지
    time: '',
  } as TestDataPagingDto,

  // ===== DETAIL DATA =====
  detailData: {} as TestDataDetail,           // 상세 조회 데이터
  selectedKey: 0,                             // 선택된 ID (pk)
})
```

---

### 2.2 필드별 특징

| 필드 | 타입 | 설명 | 초기값 |
|-----|------|------|--------|
| `listData` | `T[]` | 목록 데이터 배열 | `[]` |
| `listTotalRow` | `number` | 페이징 전체 행 수 | `0` |
| `listParams` | `SearchDto` | 검색/페이징 파라미터 | 모두 공백/0 |
| `detailData` | `T` | 상세 조회 데이터 | `{}` |
| `selectedKey` | `number` | 선택된 ID (pk) | `0` |

---

### 2.3 실제 예시 (복잡한 검색 조건)

**파일**: `front/src/modules-domain/unpaid/unpaid-payment/store/unpaid-payment.store.ts`

```typescript
state: () => ({
  // 목록 데이터
  listData: [] as (ItaxPaymentPagingItem & {
    chk: boolean;
    nIndex: number;
    pagingIndex: number;
  })[],
  listTotalRow: 0,

  // 검색 조건 (모든 필드 명시적 정의)
  listParams: {
    // 기본 검색
    startDate: '',
    endDate: '',
    keyword: '',
    payState: '',
    insertSeq: 0,

    // 추가 필터 (20개 필드)
    teamSeq: 0,
    empSeq: 0,
    taxEmpSeq: 0,
    bizType: '',
    clientDivision: 0,
    groupSeq: 0,
    clientState: 0,
    acceptState: 0,
    clientCharge: 0,
    payDivision: 0,
    insuranceDivision: 0,
    gwaseDivision: 0,
    isBizAccount: '',
    isBizAccountSingo: '',
    isBizCard: '',
    clientSeq: 0,
    clientName: '',

    // 페이징
    sortBy: 'paymentSeq',
    sortType: 'desc',
    row: 50,
    page: 1,
  } as ItaxPaymentPagingDto,

  // 상세 데이터
  selectedKey: 0,
  detailData: {} as ItaxPaymentDetail,
})
```

**특징:**
- 복잡한 검색 조건도 모두 명시적으로 정의
- 옵셔널 타입(`?`) 사용 금지
- 모든 필드에 초기값 설정

---

### 2.4 State 초기화 전략

**listParams 초기값 설정:**

| 필드 타입 | 초기값 |
|----------|--------|
| 날짜 | 공백 문자열 ('') |
| 숫자 | 0 |
| 문자열 | 공백 또는 'all' |
| 정렬 | 'insertDate' 또는 'id' + 'desc' |
| 페이징 | row=20, page=1 |
| time | '' (요청 시점에 생성) |

---

## 3. Actions 표준 구조 (16가지)

### 3.1 초기화 함수 (2개)

#### (1) listParamsInit() - 검색 조건 초기화

```typescript
/**
 * 검색 조건 초기화
 * 검색창 '초기화' 버튼에서 호출
 */
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
  } as TestDataPagingDto;
}
```

**호출 시점:**
- 사용자가 검색창 "초기화" 버튼 클릭
- 리스트 페이지 진입 시 (필요시)

**특징:**
- detailData는 건드리지 않음
- listData도 건드리지 않음 (상태 유지)

---

#### (2) detailDataInit() - 상세 데이터 초기화

```typescript
/**
 * 상세 데이터 초기화
 * 신규 등록 또는 상세 조회 전 호출
 */
detailDataInit(): void {
  this.detailData = {} as TestDataDetail;
  this.selectedKey = 0;
}
```

**호출 시점:**
- 모달 열기 전
- 상세 조회 전
- 폼 리셋할 때

---

### 3.2 목록 조회 함수 (3개)

#### (3) paging() - 페이징 목록 조회 (⭐ 가장 일반적)

```typescript
/**
 * 페이징 목록 조회 (기본 패턴)
 * @route GET /test-data
 * @param params 페이징 조건
 * @updates listData, listTotalRow
 */
async paging(params: TestDataPagingDto): Promise<void> {
  // API 호출
  const result = await useApi().get<{
    totalRow: number;
    data: TestDataDetail[];
  }>('/test-data', { params });

  // 테이블 표시용 부가 정보 추가
  this.listData = result.data.map((item, nIndex: number) => {
    return {
      ...item,
      nIndex,        // 순번
      chk: false,    // 체크박스
    };
  });

  this.listTotalRow = Number(result.totalRow);
}
```

**특징:**
- listParams를 유지하고 새로운 params로 덮어쓰지 않음
- nIndex, chk 필드 자동 추가 (테이블 구현용)
- totalRow는 Number로 형변환

**호출 패턴:**
```typescript
// 컴포넌트에서 호출
const listAction = async () => {
  await FormService.loading(async () => {
    await testDataStore.paging(listParams.value);
  });
};
```

---

#### (4) list() - 전체 목록 조회 (페이징 없음)

```typescript
/**
 * 전체 목록 조회 (페이징 없음)
 * Select Box, Auto Complete 등에서 사용
 * @route GET /test-data/list
 * @param params 검색 조건
 * @returns 목록 데이터
 */
list(params: TestDataSearchDto): Promise<TestDataDetail[]> {
  return useApi().get<TestDataDetail[]>(`/test-data/list`, { params });
}
```

**특징:**
- 페이징 파라미터 없음 (row, page 불필요)
- SearchDto 사용
- 드롭다운, 자동완성에서 사용
- Promise 반환 (state 수정 안 함)

**사용 예시:**
```typescript
// 드롭다운용 데이터 조회
const optionList = await testDataStore.list({ keyword: 'test' });
```

---

#### (5) cursorList() - 커서 기반 목록 조회 (무한 스크롤)

```typescript
/**
 * 커서 기반 목록 조회 (무한 스크롤용)
 * @route GET /test-data/cursor-list
 * @param params limit, cursor, keyword
 * @returns {list, nextCursor}
 */
async cursorList(params: {
  limit?: number;
  cursor?: string;
  keyword?: string;
}): Promise<{
  list: TestDataDetail[];
  nextCursor: string | null;
}> {
  return useApi().get<{
    list: TestDataDetail[];
    nextCursor: string | null;
  }>('/test-data/cursor-list', { params });
}
```

**특징:**
- 무한 스크롤 전용
- nextCursor로 다음 페이지 여부 판단
- state 수정 안 함 (컴포넌트에서 결과 관리)

---

### 3.3 상세 조회 함수 (1개)

#### (6) detail() - 상세 조회

```typescript
/**
 * 상세 조회 (파일 포함)
 * @route GET /test-data/:testSeq
 * @param testSeq 조회할 ID
 * @updates detailData, selectedKey
 */
async detail(testSeq: number): Promise<void> {
  this.detailData = await useApi().get<TestDataDetail>(
    `/test-data/${testSeq}`
  );
  this.selectedKey = testSeq;
}
```

**특징:**
- 항상 detailData에 저장
- selectedKey도 동시에 설정
- 파일 정보도 함께 조회됨

**호출 시점:**
- 모달이 열릴 때
- 상세 페이지 진입 시

---

### 3.4 CRUD 함수 (4개)

#### (7) insert() - 신규 등록

```typescript
/**
 * 신규 등록 (파일 포함)
 * @route POST /test-data
 * @param params 등록 데이터
 * @returns {isSuccess, testSeq}
 */
insert(params: TestDataInsertDto): Promise<{
  isSuccess: boolean;
  testSeq: number;
}> {
  return useApi().post<{
    isSuccess: boolean;
    testSeq: number;
  }>('/test-data', params);
}
```

**특징:**
- state 수정 안 함 (컴포넌트에서 성공 후 refresh)
- Promise 반환
- InsertDto 타입 사용

**호출 패턴:**
```typescript
const register = async () => {
  await FormService.loading(async () => {
    const result = await testDataStore.insert(detailData.value);
    if (result.isSuccess) {
      FormService.toastMessage('등록되었습니다.', 'success');
      emit('insert-ok');
    }
  });
};
```

---

#### (8) update() - 데이터 수정

```typescript
/**
 * 데이터 수정 (파일 포함)
 * @route PUT /test-data/:testSeq
 * @param testSeq 수정할 ID
 * @param params 수정 데이터
 * @returns {isSuccess}
 */
update(
  testSeq: number,
  params: TestDataUpdateDto
): Promise<{ isSuccess: boolean }> {
  return useApi().put<{ isSuccess: boolean }>(
    `/test-data/${testSeq}`,
    params
  );
}
```

**특징:**
- testSeq는 URL 경로에 포함
- state 수정 안 함
- Promise 반환

---

#### (9) softDelete() - 논리 삭제

```typescript
/**
 * 논리 삭제 (단일/다중)
 * is_delete를 'Y'로 변경
 * @route PATCH /test-data/delete
 * @param testSeq 삭제할 ID (배열 가능)
 * @returns {isSuccess}
 */
softDelete(
  testSeq: number | number[]
): Promise<{ isSuccess: boolean }> {
  return useApi().patch<{ isSuccess: boolean }>(
    `/test-data/delete`,
    { testSeq }
  );
}
```

**특징:**
- 배열도 지원 (다중 삭제)
- DB에서 물리적으로 삭제되지 않음 (is_delete='Y' 마크만)
- state 수정 안 함

**호출 예시:**
```typescript
// 단일 삭제
await testDataStore.softDelete(123);

// 다중 삭제
const seqList = [1, 2, 3];
await testDataStore.softDelete(seqList);
```

---

#### (10) updateUse() - 사용여부 변경

```typescript
/**
 * 사용여부 변경 (단일/다중)
 * @route PATCH /test-data/use
 * @param testSeq 변경할 ID (배열 가능)
 * @param isUse 사용여부 ('Y' | 'N')
 * @returns {isSuccess}
 */
updateUse(
  testSeq: number | number[],
  isUse: string
): Promise<{ isSuccess: boolean }> {
  return useApi().patch<{ isSuccess: boolean }>(
    `/test-data/use`,
    { testSeq, isUse }
  );
}
```

**특징:**
- is_use를 'Y' 또는 'N'으로 변경
- 배열도 지원 (다중 변경)
- state 수정 안 함

**호출 예시:**
```typescript
// 사용 설정
await testDataStore.updateUse(123, 'Y');

// 다중 사용 설정
await testDataStore.updateUse([1, 2, 3], 'Y');
```

---

### 3.5 고급 삭제 함수 (1개)

#### (11) hardDelete() - 물리 삭제 (테스트 전용)

```typescript
/**
 * 물리 삭제 (테스트 환경 전용)
 * 실제 DB에서 데이터 삭제, 운영 환경에서는 에러 발생
 * @route DELETE /test-data/:testSeq
 * @param testSeq 삭제할 ID
 * @access 로컬/테스트 환경만 허용
 * @returns {isSuccess}
 */
hardDelete(testSeq: number): Promise<{ isSuccess: boolean }> {
  // 테스트 환경(local, test)에서만 작동
  const env = import.meta.env.MODE;
  if (env !== 'local' && env !== 'test') {
    throw new Error('hardDelete는 테스트 환경에서만 사용 가능합니다.');
  }

  return useApi().delete<{ isSuccess: boolean }>(
    `/test-data/${testSeq}`
  );
}
```

**특징:**
- 환경 체크로 운영 환경에서 실수 방지
- TDD 목적으로만 사용
- 실제 프로덕션에서는 softDelete 사용

---

### 3.6 파일 업로드 함수 (4개)

#### (12) uploadFileLocal() - Local 파일 업로드

```typescript
/**
 * Local 파일 업로드
 * @route POST /test-data/file/upload/local
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
          callback(progress);
        }
      }
    }
  );
}
```

**특징:**
- FormData 사용 (multipart/form-data)
- 진행률 콜백 지원
- metadata에 메타정보 포함

**호출 패턴:**
```typescript
const uploadProgress = ref(0);
const result = await testDataStore.uploadFileLocal(
  false,  // 공개 파일
  file,   // File 객체
  (progress) => {
    uploadProgress.value = progress;  // UI 업데이트
  }
);
```

---

#### (13) uploadFileS3() - S3 파일 업로드

```typescript
/**
 * S3 파일 업로드 (Presigned URL 방식)
 * 1) 백엔드에서 Presigned URL 획득
 * 2) S3에 직접 업로드
 * @route POST /test-data/file/upload/s3
 * @param isPrivate 비공개 여부
 * @param file 업로드 파일
 * @param callback 진행률 콜백 (0-100)
 * @returns {fileSeq, fileUuid, uploadUrl, fileName, fileSize, filePath}
 */
async uploadFileS3(
  isPrivate: boolean,
  file: File,
  callback: ProgressCallback
): Promise<TestDataFileS3UploadResult> {
  // 1단계: Presigned URL 획득
  const res = await useApi().post<TestDataFileS3UploadResult>(
    '/test-data/file/upload/s3',
    {
      isPrivate,
      fileName: file.name,
      fileSize: file.size,
      fileType: file.type
    }
  );

  if (!res?.uploadUrl) {
    throw new Error('Upload URL not received from server');
  }

  // 2단계: S3에 직접 업로드
  await this.uploadFileToS3(res.uploadUrl, file, callback);
  return res;
}

/**
 * S3 직접 업로드 (내부 헬퍼)
 * uploadFileS3에서만 사용
 */
uploadFileToS3(
  uploadUrl: string,
  file: File,
  callback: ProgressCallback
) {
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

**특징:**
- 2단계 업로드 (Presigned URL 방식)
- 백엔드는 메타정보만 처리
- 실제 파일은 S3에 직접 업로드 (대역폭 절약)

---

#### (14) getDownloadUrl() - 다운로드 URL 생성

```typescript
/**
 * 다운로드 URL 생성
 * - S3 PUBLIC: CloudFront URL
 * - Local PUBLIC: 로컬 파일 서버 URL
 * - PRIVATE: getS3PresignedUrl 사용 필요
 */
getDownloadUrl(file: TestDataFile): string {
  // PRIVATE 파일은 직접 다운로드 불가
  if (file.fileAuth === 'PRIVATE') {
    throw new Error('비공개 파일은 직접 다운로드 불가');
  }

  // S3 PUBLIC 파일 → CloudFront URL
  if (file.storageType === 'S3') {
    return `${import.meta.env.VITE_CF_ORIGIN_URL}/${file.filePath}`;
  }

  // Local 파일 처리
  if (import.meta.env.MODE === 'localhost') {
    return `${import.meta.env.VITE_API}/test-data/file/download/local/${file.fileUuid}`;
  }

  // 개발/운영 환경 → FILE_HOST 필수
  if (!import.meta.env.VITE_FILE_HOST) {
    throw new Error('VITE_FILE_HOST 환경변수 필수');
  }

  return `${import.meta.env.VITE_FILE_HOST}/${file.filePath}`;
}
```

**특징:**
- 환경별 URL 분기 처리
- PUBLIC만 직접 다운로드 가능

---

#### (15) getS3PresignedUrl() - S3 PRIVATE 파일 Presigned URL

```typescript
/**
 * S3 PRIVATE 파일 Presigned URL 획득
 * 시간 제한이 있는 임시 다운로드 URL 발급
 * @route GET /test-data/file/download/s3/:fileUuid
 * @param file 파일 정보
 * @returns Presigned URL
 */
async getS3PresignedUrl(file: TestDataFile): Promise<string> {
  if (file.storageType !== 'S3') {
    throw new Error('S3 파일만 지원합니다.');
  }

  if (file.fileAuth !== 'PRIVATE') {
    throw new Error('PRIVATE 파일만 지원합니다.');
  }

  const response = await useApi().get<{
    url: string;
    expiresIn: number;
  }>(`/test-data/file/download/s3/${file.fileUuid}`);

  return response.url;
}
```

**특징:**
- PRIVATE 파일만 지원
- expiresIn으로 만료시간 제공

---

### 3.7 엑셀 함수 (2개)

#### (16) downloadExcel() - 엑셀 다운로드

```typescript
/**
 * Excel 템플릿 다운로드
 * 템플릿 스타일 유지하며 데이터만 채움
 * @param params 조회 조건
 * @returns Excel Blob
 */
async downloadExcel(params: TestDataPagingDto): Promise<Blob> {
  // 전체 데이터 조회
  const exportParams: TestDataPagingDto = {
    ...params,
    row: 999999,   // 전체 조회
    page: 1
  };

  const result = await useApi().get<{
    totalRow: number;
    data: TestDataDetail[];
  }>('/test-data', { params: exportParams });

  const data = result.data;

  if (!data || data.length === 0) {
    throw new Error('내보낼 데이터가 없습니다');
  }

  // 필드 매핑 정의
  const fieldMappings = [
    { field: 'testSeq', column: 1, defaultValue: '' },
    { field: 'value', column: 2, defaultValue: '' },
    { field: 'subject', column: 3, defaultValue: '' },
    { field: 'contents', column: 4, defaultValue: '' },
    { field: 'bigint', column: 5, defaultValue: '' },
    { field: 'isUse', column: 6, defaultValue: '' },
    { field: 'insertDate', column: 7, defaultValue: '' },
    { field: 'updateDate', column: 8, defaultValue: '' }
  ];

  const templateFileUrl = '/template/test-data/test_data_excel_template.xlsx';

  const buffer = await ExcelTemplateUtil.generateFromTemplate(data, {
    templateUrl: templateFileUrl,
    fileName: 'test_data_export',
    startRowNum: 4,  // 데이터 시작 행
    fieldMappings,
    preserveTemplateStyles: true
  });

  return new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  });
}
```

**특징:**
- ExcelTemplateUtil 사용
- 템플릿 스타일 유지
- 필드 매핑으로 유연한 구성

**호출 패턴:**
```typescript
const downloadExcelFile = async () => {
  const blob = await testDataStore.downloadExcel(listParams.value);

  // Blob을 다운로드 링크로 변환
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'test_data_export.xlsx';
  link.click();
};
```

---

#### (17) uploadExcel() - 엑셀 업로드

```typescript
/**
 * Excel 데이터 업로드 (subject 기준 upsert)
 * subject 존재 시 update, 없으면 insert
 * @route POST /test-data/excel/upload
 * @param params 업로드 데이터
 * @returns {isSuccess, method: 'insert' | 'update'}
 */
async excelUpload(
  params: TestDataExcelUploadDto
): Promise<{
  isSuccess: boolean;
  method: 'insert' | 'update';
}> {
  return useApi().post<{
    isSuccess: boolean;
    method: 'insert' | 'update';
  }>('/test-data/excel/upload', params);
}
```

**특징:**
- Upsert 로직 (기존이면 update, 없으면 insert)
- ExcelUploadDto 사용

---

## 4. 환경 분기 패턴

### 4.1 import.meta.env 사용

Store에서 환경 분기가 필요할 때:

```typescript
// 테스트 환경에서만 실행
const env = import.meta.env.MODE;
if (env !== 'local' && env !== 'test') {
  throw new Error('테스트 환경에서만 사용 가능합니다.');
}
```

---

### 4.2 환경 종류

| 값 | 설명 | 용도 |
|----|------|------|
| `local` | 로컬호스트 개발 | 로컬 파일 다운로드 경로 처리 |
| `test` | 테스트 환경 | TDD 함수 실행 허용 |
| `development` | 개발 환경 | - |
| `production` | 운영 환경 | - |

---

### 4.3 파일 다운로드 환경별 URL 분기

```typescript
// Local 파일 처리
if (import.meta.env.MODE === 'localhost') {
  return `${import.meta.env.VITE_API}/test-data/file/download/local/${file.fileUuid}`;
}

// S3 PUBLIC 파일
if (file.storageType === 'S3') {
  return `${import.meta.env.VITE_CF_ORIGIN_URL}/${file.filePath}`;
}

// 개발/운영 환경
return `${import.meta.env.VITE_FILE_HOST}/${file.filePath}`;
```

---

## 5. API 응답 타입 정의

### 5.1 표준 타입 정의 패턴

**파일**: `front/src/modules/test-data/type/test-data.type.ts`

```typescript
// ===== 기본 인터페이스 =====

export interface TestData {
  testSeq: number;           // 테스트번호
  value: string;             // 테스트값
  subject: string;           // 제목
  contents: string;          // 내용
  bigint: number;            // 숫자(bigint)

  // 감사(audit) 필드 (항상 마지막)
  isUse: string;             // 사용여부
  isDelete: string;          // 삭제여부
  insertSeq: number;         // 등록자
  insertDate: string;        // 등록일
  updateSeq: number;         // 수정자
  updateDate: string;        // 수정일
}

// ===== 상세 조회 (파일 포함) =====

export interface TestDataDetail extends TestData {
  fileList: TestDataFile[];    // 파일 목록
  imageList: TestDataFile[];   // 이미지 목록
}

// ===== 리스트 아이템 (체크박스 포함) =====

export interface TestDataListItem extends TestDataDetail {
  chk: boolean;              // 체크박스 선택 상태
  nIndex: number;            // 인덱스 번호
}

// ===== 검색 DTO =====

export interface TestDataSearchDto {
  startDate: string;
  endDate: string;
  keyword: string;
  opt: string;
  isUse: string;
  selected: string;
}

// ===== 페이징 DTO =====

export interface TestDataPagingDto extends TestDataSearchDto {
  sortBy: string;            // 정렬 필드
  sortType: string;          // 정렬 방향(asc/desc)
  sortData: string;          // 정렬 데이터 (field,type)
  row: number;               // 페이지당 행 수
  page: number;              // 현재 페이지
  time: string;              // 타임스탬프
}

// ===== Insert/Update DTO =====

export interface TestDataInsertDto {
  value: string;
  subject: string;
  contents: string;
  bigint: number;
  fileUuidList: string[];    // 파일 UUID 목록
  imageUuidList: string[];   // 이미지 UUID 목록
}

export interface TestDataUpdateDto {
  value: string;
  subject: string;
  contents: string;
  bigint: number;
  fileUuidList: string[];
  imageUuidList: string[];
}

// ===== 파일 타입 =====

export interface TestDataFile {
  fileSeq: number;
  storageType: 'S3' | 'LOCAL';
  fileAuth: 'PUBLIC' | 'PRIVATE';
  fileUuid: string;
  filePath: string;
  fileName: string;
  fileSize: number;
  // ... 기타 감사 필드
}

export interface TestDataFileLocalUploadResult {
  fileSeq: number;
  fileUuid: string;
  fileName: string;
  fileSize: number;
  // ...
}

export interface TestDataFileS3UploadResult {
  uploadUrl: string;
  fileSeq: number;
  fileUuid: string;
  // ...
}
```

---

### 5.2 타입 정의 핵심 규칙

#### 1. 옵셔널 타입(`?`) 절대 금지

```typescript
// ❌ 잘못된 패턴
interface TestData {
  testSeq?: number;  // 옵셔널 금지
  value?: string;    // 옵셔널 금지
}

// ✅ 올바른 패턴
interface TestData {
  testSeq: number;   // 명시적 정의
  value: string;     // 명시적 정의
}
```

#### 2. 감사 필드는 항상 마지막

```typescript
export interface TestData {
  // 비즈니스 필드
  testSeq: number;
  subject: string;
  contents: string;

  // 감사 필드 (항상 마지막)
  isUse: string;
  isDelete: string;
  insertSeq: number;
  insertDate: string;
  updateSeq: number;
  updateDate: string;
}
```

#### 3. 타입 상속 구조

```
TestData (기본)
  ↓ extends
TestDataDetail (파일 포함)
  ↓ extends
TestDataListItem (체크박스 포함)
```

#### 4. DTO는 필드만 포함

```typescript
// InsertDto는 pk와 감사 필드 제외
export interface TestDataInsertDto {
  value: string;
  subject: string;
  contents: string;
  bigint: number;
  fileUuidList: string[];
  imageUuidList: string[];
}
```

---

## 6. 실제 사용 예시

### 6.1 목록 조회

```typescript
// list-table.vue
<script setup lang="ts">
import { FormService } from '@/modules/_common/services/form.service.ts';
import { useTestDataStore } from '@/modules/test-data/store/test-data.store.ts';

const testDataStore = useTestDataStore();

const getList = async () => {
  // FormService.loading으로 로딩 상태 관리
  await FormService.loading(async () => {
    await testDataStore.paging(listParams.value);
  });
};
</script>
```

---

### 6.2 삽입/수정

```typescript
// insert.modal.vue
<script setup lang="ts">
const register = async () => {
  await FormService.loading(async () => {
    const result = await testDataStore.insert(detailData.value);
    if (result.isSuccess) {
      FormService.toastMessage('등록되었습니다.', 'success');
      emit('insert-ok');
    }
  });
};
</script>
```

---

### 6.3 사용여부 변경

```typescript
const changeIsUse = async (item: any, value: boolean) => {
  isUse.value[item.testSeq] = value;  // 즉시 UI 반영

  await FormService.loading(async () => {
    await testDataStore.updateUse(item.testSeq, value ? 'Y' : 'N');
    FormService.toastMessage('사용여부가 변경되었습니다.', 'success');
  });
};
```

---

### 6.4 파일 업로드

```typescript
const uploadFile = async (file: File) => {
  const progress = ref(0);

  try {
    const result = await testDataStore.uploadFileLocal(
      false,  // 공개 파일
      file,
      (p) => { progress.value = p; }
    );

    // result에서 fileUuid 추출하여 detailData에 추가
    detailData.value.fileUuidList.push(result.fileUuid);
  } catch (error) {
    FormService.toastMessage('파일 업로드 실패', 'error');
  }
};
```

---

## 7. 핵심 개념 정리

### 7.1 State 관리 원칙

```typescript
// ✅ 올바른 패턴
listParams.value = {...params};  // 전체 교체

// ❌ 잘못된 패턴
Object.assign(this.listParams, params);  // 부분 수정 (타입 안전성 문제)
```

---

### 7.2 Actions 호출 원칙

**모든 API 호출은 Store를 통해서만:**

```typescript
// ✅ 올바른 패턴
const result = await testDataStore.paging(params);

// ❌ 잘못된 패턴
const result = await useApi().get('/test-data', {params});  // 컴포넌트에서 직접 호출 금지
```

---

### 7.3 상태 수정 원칙

**Insert/Update/Delete는 state 수정 안 함:**

```typescript
// 컴포넌트에서 성공 후 list 새로고침
if (result.isSuccess) {
  await testDataStore.paging(listParams.value);  // 명시적으로 새로고침
}
```

---

### 7.4 Promise 반환 원칙

- **State 수정하는 함수**: async/await 사용 (Promise 자동 반환)
- **State 수정 안 하는 함수**: Promise 명시적 반환

```typescript
// ✅ State 수정
async paging(): Promise<void> {
  this.listData = ...
}

// ✅ State 수정 안 함
insert(params): Promise<Response> {
  return useApi().post(...)
}
```

---

### 7.5 타입 안전성

**Response 타입 명시:**

```typescript
// ✅ 타입 명시
const result = await useApi().get<{ totalRow: number; data: T[] }>(url);

// ❌ any 사용
const result = await useApi().get(url);  // any 타입 사용 금지
```

---

## 8. Actions 분류 요약 테이블

| 분류 | 함수명 | 특징 | State 수정 |
|-----|--------|------|-----------|
| **초기화** | listParamsInit | 검색조건 초기화 | O |
| | detailDataInit | 상세데이터 초기화 | O |
| **조회** | paging | 페이징 목록 | O |
| | list | 전체 목록 | X |
| | cursorList | 무한 스크롤 | X |
| | detail | 상세 조회 | O |
| **CRUD** | insert | 등록 | X |
| | update | 수정 | X |
| | softDelete | 논리 삭제 | X |
| | updateUse | 사용여부 변경 | X |
| **고급** | hardDelete | 물리 삭제 (TDD) | X |
| **파일** | uploadFileLocal | Local 업로드 | X |
| | uploadFileS3 | S3 업로드 | X |
| | getDownloadUrl | 다운로드 URL | X |
| | getS3PresignedUrl | S3 임시 URL | X |
| **엑셀** | downloadExcel | 엑셀 다운로드 | X |
| | uploadExcel | 엑셀 업로드 | X |

---

## 마이그레이션 체크리스트

새 모듈 개발 시 이 Store 패턴 적용:

- [ ] State: listData, listTotalRow, listParams, detailData, selectedKey 정의
- [ ] Actions: 초기화 함수 2개 작성
- [ ] Actions: 조회 함수 3-4개 작성
- [ ] Actions: CRUD 함수 4개 작성
- [ ] Actions: 파일 업로드 필요시 4개 추가
- [ ] Actions: 엑셀 필요시 2개 추가
- [ ] Type: SearchDto, PagingDto, InsertDto, UpdateDto 정의
- [ ] Type: 옵셔널 타입 제거, 감사필드는 마지막에
- [ ] API 응답 타입 명시적 정의
- [ ] FormService.loading/toastMessage 사용

---

**참고 파일:**
- `front/src/modules/test-data/store/test-data.store.ts`
- `front/src/modules/test-data/type/test-data.type.ts`
- `front/src/modules-domain/unpaid/unpaid-payment/store/unpaid-payment.store.ts`
- `front/src/modules/_common/services/api.service.ts`
