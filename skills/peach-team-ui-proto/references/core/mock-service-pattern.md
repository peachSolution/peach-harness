# Mock 서비스 패턴 가이드

> 프로토타입 전용 Mock 데이터 정의 패턴
> Backend API 없이 동작하는 프로토타입을 위한 Mock 데이터 레이어

---

## 개요

Mock 서비스는 프로토타입에서 실제 API 응답을 시뮬레이션합니다.
**핵심 원칙**: API 시그니처를 프로덕션과 동일하게 유지하여, 전환 시 Mock만 제거하면 됩니다.

---

## 파일 위치

```
front/src/modules/[모듈명]/mock/[모듈명].mock.ts
```

---

## Mock 데이터 정의 패턴

### 기본 구조

```typescript
// front/src/modules/[모듈명]/mock/[모듈명].mock.ts
import type {
  [ModuleName],
  [ModuleName]Detail,
  [ModuleName]InsertDto,
  [ModuleName]UpdateDto,
  [ModuleName]PagingDto
} from '../type/[모듈명].type';

// ===== Mock 데이터 (5~10건) =====
// 도메인에 맞는 현실적인 샘플 데이터를 정의합니다.

let mockSeqCounter = 100; // 시퀀스 카운터

const mock[ModuleName]List: [ModuleName]Detail[] = [
  {
    [pk]Seq: 1,
    subject: '첫 번째 테스트 데이터',
    value: 'value-001',
    contents: '<p>첫 번째 테스트 내용입니다.</p>',
    bigint: 1000,
    isUse: 'Y',
    isDelete: 'N',
    insertSeq: 1,
    insertDate: '2024-01-15 10:30:00',
    updateSeq: 1,
    updateDate: '2024-01-15 10:30:00',
    fileList: [],
    imageList: [],
  },
  {
    [pk]Seq: 2,
    subject: '두 번째 테스트 데이터',
    value: 'value-002',
    contents: '<p>두 번째 테스트 내용입니다.</p>',
    bigint: 2000,
    isUse: 'Y',
    isDelete: 'N',
    insertSeq: 1,
    insertDate: '2024-02-20 14:00:00',
    updateSeq: 1,
    updateDate: '2024-02-20 14:00:00',
    fileList: [],
    imageList: [],
  },
  // ... 도메인에 맞게 5~10건 정의
];
```

---

## 동적 데이터 생성 함수

### generateMock[ModuleName]

```typescript
/**
 * Mock 데이터 동적 생성
 * Insert 시 호출하여 새 데이터를 추가합니다.
 */
const generateMock[ModuleName] = (dto: [ModuleName]InsertDto): [ModuleName]Detail => {
  mockSeqCounter++;
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

  return {
    [pk]Seq: mockSeqCounter,
    subject: dto.subject,
    value: dto.value,
    contents: dto.contents,
    bigint: dto.bigint,
    isUse: 'Y',
    isDelete: 'N',
    insertSeq: 1,
    insertDate: now,
    updateSeq: 1,
    updateDate: now,
    fileList: [],
    imageList: [],
  };
};
```

---

## Mock API 함수 (Store에서 호출)

### 페이징 조회

```typescript
/**
 * Mock 페이징 조회
 * 검색 조건 필터링 + 페이지네이션 시뮬레이션
 */
export const mockPaging = (params: [ModuleName]PagingDto): {
  totalRow: number;
  data: [ModuleName]Detail[];
} => {
  console.log('[Mock] paging:', params);

  let filtered = mock[ModuleName]List.filter(item => item.isDelete !== 'Y');

  // 검색 필터
  if (params.keyword) {
    const keyword = params.keyword.toLowerCase();
    filtered = filtered.filter(item =>
      item.subject.toLowerCase().includes(keyword) ||
      item.value.toLowerCase().includes(keyword)
    );
  }

  // 사용여부 필터
  if (params.isUse) {
    filtered = filtered.filter(item => item.isUse === params.isUse);
  }

  // 날짜 필터
  if (params.startDate && params.endDate) {
    filtered = filtered.filter(item => {
      const date = item.insertDate.slice(0, 10);
      return date >= params.startDate && date <= params.endDate;
    });
  }

  // 정렬
  const sortBy = params.sortBy || 'insertDate';
  const sortType = params.sortType || 'desc';
  filtered.sort((a: any, b: any) => {
    const aVal = a[sortBy];
    const bVal = b[sortBy];
    if (sortType === 'asc') return aVal > bVal ? 1 : -1;
    return aVal < bVal ? 1 : -1;
  });

  const totalRow = filtered.length;

  // 페이지네이션
  const page = params.page || 1;
  const row = params.row || 10;
  const start = (page - 1) * row;
  const data = filtered.slice(start, start + row);

  return { totalRow, data };
};
```

### 상세 조회

```typescript
/**
 * Mock 상세 조회
 */
export const mockDetail = ([pk]Seq: number): [ModuleName]Detail => {
  console.log('[Mock] detail:', [pk]Seq);

  const item = mock[ModuleName]List.find(d => d.[pk]Seq === [pk]Seq);
  if (!item) {
    throw new Error(`[Mock] ${[pk]Seq}번 데이터를 찾을 수 없습니다.`);
  }
  return { ...item };
};
```

### 등록

```typescript
/**
 * Mock 등록
 * 새 데이터를 생성하여 목록에 추가합니다.
 */
export const mockInsert = (dto: [ModuleName]InsertDto): {
  isSuccess: boolean;
  [pk]Seq: number;
} => {
  console.log('[Mock] insert:', dto);

  const newItem = generateMock[ModuleName](dto);
  mock[ModuleName]List.unshift(newItem);

  return { isSuccess: true, [pk]Seq: newItem.[pk]Seq };
};
```

### 수정

```typescript
/**
 * Mock 수정
 */
export const mockUpdate = ([pk]Seq: number, dto: [ModuleName]UpdateDto): {
  isSuccess: boolean;
} => {
  console.log('[Mock] update:', [pk]Seq, dto);

  const index = mock[ModuleName]List.findIndex(d => d.[pk]Seq === [pk]Seq);
  if (index === -1) {
    return { isSuccess: false };
  }

  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  mock[ModuleName]List[index] = {
    ...mock[ModuleName]List[index],
    ...dto,
    updateDate: now,
  };

  return { isSuccess: true };
};
```

### 논리 삭제

```typescript
/**
 * Mock 논리 삭제 (단일/다중)
 */
export const mockSoftDelete = ([pk]Seq: number | number[]): {
  isSuccess: boolean;
} => {
  console.log('[Mock] softDelete:', [pk]Seq);

  const seqList = Array.isArray([pk]Seq) ? [pk]Seq : [[pk]Seq];
  seqList.forEach(seq => {
    const item = mock[ModuleName]List.find(d => d.[pk]Seq === seq);
    if (item) {
      item.isDelete = 'Y';
    }
  });

  return { isSuccess: true };
};
```

### 사용여부 변경

```typescript
/**
 * Mock 사용여부 변경 (단일/다중)
 */
export const mockUpdateUse = ([pk]Seq: number | number[], isUse: string): {
  isSuccess: boolean;
} => {
  console.log('[Mock] updateUse:', [pk]Seq, isUse);

  const seqList = Array.isArray([pk]Seq) ? [pk]Seq : [[pk]Seq];
  seqList.forEach(seq => {
    const item = mock[ModuleName]List.find(d => d.[pk]Seq === seq);
    if (item) {
      item.isUse = isUse;
    }
  });

  return { isSuccess: true };
};
```

---

## Mock 파일 업로드

```typescript
/**
 * Mock 파일 업로드
 * FormData를 받아 가짜 UUID를 반환합니다.
 */
export const mockUploadFile = (formData: FormData): {
  fileSeq: number;
  fileUuid: string;
  fileName: string;
  fileSize: number;
  filePath: string;
} => {
  const file = formData.get('file') as File;
  console.log('[Mock] uploadFile:', file?.name, file?.size);

  const uuid = `mock-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;

  return {
    fileSeq: Date.now(),
    fileUuid: uuid,
    fileName: file?.name || 'unknown',
    fileSize: file?.size || 0,
    filePath: `mock/uploads/${uuid}`,
  };
};
```

---

## Mock 커서 기반 조회 (무한 스크롤용)

```typescript
/**
 * Mock 커서 기반 조회
 * infinite-scroll 패턴에서 사용합니다.
 */
export const mockCursorList = (params: {
  limit: number;
  cursor: string;
  keyword: string;
}): {
  data: [ModuleName]Detail[];
  nextCursor: string | null;
} => {
  console.log('[Mock] cursorList:', params);

  let filtered = mock[ModuleName]List.filter(item => item.isDelete !== 'Y');

  if (params.keyword) {
    const keyword = params.keyword.toLowerCase();
    filtered = filtered.filter(item =>
      item.subject.toLowerCase().includes(keyword)
    );
  }

  // 커서 위치 찾기
  let startIndex = 0;
  if (params.cursor) {
    const cursorSeq = Number(atob(params.cursor));
    startIndex = filtered.findIndex(item => item.[pk]Seq === cursorSeq) + 1;
  }

  const limit = params.limit || 10;
  const data = filtered.slice(startIndex, startIndex + limit);
  const hasMore = startIndex + limit < filtered.length;

  return {
    data,
    nextCursor: hasMore
      ? btoa(String(data[data.length - 1].[pk]Seq))
      : null,
  };
};
```

---

## Mock Excel 다운로드

```typescript
/**
 * Mock 엑셀 다운로드
 * ExcelTemplateUtil 또는 로컬 Blob 생성으로 처리합니다.
 */
export const mockDownloadExcel = (params: [ModuleName]PagingDto): Blob => {
  console.log('[Mock] downloadExcel:', params);

  // 간단한 CSV 형태의 Blob 생성
  const headers = ['번호', '제목', '값', '사용여부', '등록일'];
  const rows = mock[ModuleName]List
    .filter(item => item.isDelete !== 'Y')
    .map(item => [item.[pk]Seq, item.subject, item.value, item.isUse, item.insertDate].join(','));

  const csvContent = [headers.join(','), ...rows].join('\n');
  const bom = '\uFEFF'; // UTF-8 BOM

  return new Blob([bom + csvContent], { type: 'text/csv;charset=utf-8;' });
};
```

---

## 핵심 규칙

### 1. API 시그니처 유지 원칙

```typescript
// Store에서 호출하는 형태는 프로덕션과 동일하게 유지
// Mock ↔ 실서버 전환 시 Store 코드 변경 최소화

// 프로덕션:
// const result = await useApi().get<Response>('/endpoint', { params });

// 프로토타입:
// useApi()가 Mock interceptor를 거쳐 mockPaging() 등을 호출
```

### 2. console.log('[Mock]') 로깅 패턴

```typescript
// 모든 Mock 함수에 '[Mock]' 접두어 로깅 필수
// 디버깅 시 Mock 호출과 실제 API 호출을 구분하기 위함
console.log('[Mock] paging:', params);
console.log('[Mock] detail:', seq);
console.log('[Mock] insert:', dto);
```

### 3. 반환 형태: { data: {...} } 래핑

```typescript
// 프로덕션 API 응답과 동일한 구조로 반환
// useApi()가 자동으로 .data를 추출하는 경우를 대비

return { totalRow, data };           // 페이징
return { isSuccess: true, [pk]Seq }; // 등록
return { isSuccess: true };           // 수정/삭제
```

### 4. 상태 변경은 메모리 내 배열에서 직접 수행

```typescript
// Mock 데이터는 모듈 스코프 배열에서 관리
// 페이지 새로고침 시 초기 상태로 리셋됨 (의도된 동작)
let mock[ModuleName]List: [ModuleName]Detail[] = [...initialData];
```

---

## 도메인별 Mock 데이터 예시

### 게시판 (notice-board)

```typescript
const mockNoticeBoardList = [
  { noticeBoardSeq: 1, subject: '시스템 점검 안내', category: '공지', isUse: 'Y', ... },
  { noticeBoardSeq: 2, subject: '신규 기능 업데이트', category: '업데이트', isUse: 'Y', ... },
];
```

### 회원 관리 (member-manage)

```typescript
const mockMemberManageList = [
  { memberManageSeq: 1, name: '홍길동', email: 'hong@example.com', status: 'active', ... },
  { memberManageSeq: 2, name: '김철수', email: 'kim@example.com', status: 'inactive', ... },
];
```

### 상품 (product)

```typescript
const mockProductList = [
  { productSeq: 1, name: '프리미엄 패키지', price: 50000, stock: 100, isUse: 'Y', ... },
  { productSeq: 2, name: '베이직 플랜', price: 10000, stock: 500, isUse: 'Y', ... },
];
```

---

## 참조

- **Store 패턴**: [mock-store-pattern.md](mock-store-pattern.md) (Mock Store 구현)
- **타입 패턴**: [type-pattern.md](type-pattern.md) (타입 정의)
- **프로덕션 Store**: [store-pattern.md](store-pattern.md) (실서버 연결 참고)
