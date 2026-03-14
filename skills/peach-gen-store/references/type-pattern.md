# Frontend Type 패턴

> test-data.type.ts 기반 Frontend 타입 정의

---

## 파일 구조

```
front/src/modules/[모듈명]/type/[모듈명].type.ts
```

---

## Entity Interface

```typescript
/**
 * [모듈명 한글]
 */
export interface [모듈명PascalCase] {
  [pk]Seq: number; // [모듈명]번호
  value: string; // 값
  subject: string; // 제목
  contents: string; // 내용
  bigint: number; // 숫자(bigint)

  // 감사(audit) 필드
  isUse: string; // 사용여부
  isDelete: string; // 삭제여부
  insertSeq: number; // 등록자
  insertDate: string; // 등록일
  updateSeq: number; // 수정자
  updateDate: string; // 수정일
}
```

---

## EntityDetail Interface (file=Y)

```typescript
export interface [모듈명PascalCase]Detail extends [모듈명PascalCase] {
  // 파일
  fileList: [모듈명PascalCase]File[]; // 파일 목록
  imageList: [모듈명PascalCase]File[]; // 이미지 목록
}
```

---

## ListItem Interface (테이블용)

```typescript
/**
 * [모듈명] 리스트 아이템 (체크박스 상태 관리용)
 */
export interface [모듈명PascalCase]ListItem extends [모듈명PascalCase]Detail {
  chk: boolean; // 체크박스 선택 상태
  nIndex: number; // 인덱스 번호
}
```

---

## SearchDto Interface

```typescript
/**
 * [모듈명] 검색
 */
export interface [모듈명PascalCase]SearchDto {
  startDate: string; // 시작일
  endDate: string; // 종료일
  keyword: string; // 검색어
  opt: string; // 검색 옵션
  isUse: string; // 사용 여부
  selected: string; // 선택된 항목
}
```

---

## PagingDto Interface

```typescript
/**
 * [모듈명] 페이징 (검색 + 페이징)
 */
export interface [모듈명PascalCase]PagingDto extends [모듈명PascalCase]SearchDto {
  sortBy: string; // 정렬 기준 필드
  sortType: string; // 정렬 방식(오름차순(asc)/내림차순(desc))
  sortData: string; // 정렬 데이터 (sortBy,sortType)
  row: number; // 페이지당 행 수
  page: number; // 현재 페이지
  time: string; // 타임스탬프
}
```

---

## CursorSearchDto Interface (무한 스크롤용)

```typescript
/**
 * [모듈명] 커서 기반 검색 Dto (무한 스크롤용)
 */
export interface [모듈명PascalCase]CursorSearchDto extends [모듈명PascalCase]SearchDto {
  limit: number; // 페이지당 로드할 항목 수
  cursor?: string; // 커서 값 (다음 페이지용)
}
```

---

## InsertDto Interface

```typescript
/**
 * [모듈명] Insert Dto
 */
export interface [모듈명PascalCase]InsertDto {
  value: string; // 테스트값
  subject: string; // 제목
  contents: string; // 내용
  bigint: number; // 숫자(bigint)

  // 파일(백엔드에서는 fileUuid만 필요)
  fileUuidList: string[]; // 파일 UUID 목록
  imageUuidList: string[]; // 이미지 UUID 목록
}
```

---

## UpdateDto Interface

```typescript
/**
 * [모듈명] Update Dto
 */
export interface [모듈명PascalCase]UpdateDto {
  value: string; // 테스트값
  subject: string; // 제목
  contents: string; // 내용
  bigint: number; // 숫자(bigint)

  // 파일(백엔드에서는 fileUuid만 필요)
  fileUuidList: string[]; // 파일 UUID 목록
  imageUuidList: string[]; // 이미지 UUID 목록
}
```

---

## File Interface (file=Y)

```typescript
/**
 * [모듈명] 파일
 */
export interface [모듈명PascalCase]File {
  fileSeq: number; // 파일번호
  parentCode: string | null; // 부모코드
  storageType: string | 'S3' | 'LOCAL'; // 저장소타입
  fileAuth: string | 'PUBLIC' | 'PRIVATE'; // 접근권한
  fileUuid: string; // 파일UUID
  fileFolder: string; // 파일폴더
  filePath: string; // 파일패스
  fileName: string; // 파일이름
  fileSize: number; // 파일크기
  fileType: string; // 파일종류
  downloadCnt: number; // 다운로드횟수
  orderValue: number; // 순번

  // 감사 필드
  insertSeq: number; // 등록자
  insertDate: string; // 등록일
  updateSeq: number; // 수정자
  updateDate: string; // 수정일
}
```

---

## File Upload Result Interfaces

```typescript
/**
 * Local 파일 업로드 결과
 */
export interface [모듈명PascalCase]FileLocalUploadResult {
  fileSeq: number; // 파일 순번
  storageType: string; // 저장소 타입 (local)
  fileAuth: string; // 파일 권한 (PUBLIC/PRIVATE)
  fileUuid: string; // 파일 UUID
  fileFolder: string; // 파일 폴더 경로
  filePath: string; // 파일 저장 경로
  fileName: string; // 원본 파일명
  fileSize: number; // 파일 크기
  fileType: string; // 파일 MIME 타입
}

/**
 * S3 파일 업로드 결과
 */
export interface [모듈명PascalCase]FileS3UploadResult {
  uploadUrl: string; // S3 업로드 URL
  fileSeq: number; // 파일 순번
  storageType: string; // 저장소 타입 (s3)
  fileAuth: string; // 파일 권한 (PUBLIC/PRIVATE)
  fileUuid: string; // 파일 UUID
  fileFolder: string; // 파일 폴더 경로
  filePath: string; // 파일 저장 경로
  fileName: string; // 원본 파일명
  fileSize: number; // 파일 크기
  fileType: string; // 파일 MIME 타입
}
```

---

## Excel Upload DTO

```typescript
/**
 * [모듈명] 엑셀 업로드 DTO
 */
export interface [모듈명PascalCase]ExcelUploadDto {
  bigint: number; // 숫자(bigint)
  value: string; // 테스트값
  subject: string; // 제목
  contents: string; // 내용
  userSeq?: number; // 사용자번호 (옵션)
}
```

---

## file 옵션별 차이

| 타입 | file=N | file=Y |
|------|--------|--------|
| EntityDetail | Entity만 | Entity + fileList, imageList |
| File | ❌ | ✅ |
| FileLocalUploadResult | ❌ | ✅ |
| FileS3UploadResult | ❌ | ✅ |
| InsertDto.fileUuidList | ❌ | ✅ |
| InsertDto.imageUuidList | ❌ | ✅ |
