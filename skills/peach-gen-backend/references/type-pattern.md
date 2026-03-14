# Type 레이어 패턴

> test-data 가이드코드 기반 Type 패턴

---

## 파일 구조

```
api/src/modules/[모듈명]/type/[모듈명].type.ts
```

---

## Entity Interface

테이블과 1:1 매핑되는 기본 인터페이스

```typescript
/**
 * [모듈명 한글]
 */
export interface [모듈명PascalCase] {
  [pk]Seq: number; // [모듈명]번호

  // 비즈니스 필드
  value: string; // 값
  subject: string; // 제목
  contents: string; // 내용

  // 숫자 필드 (bigint, decimal은 string으로)
  amount: string; // 금액(bigint)
  price: string; // 가격(decimal)

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

Entity + 파일 목록

```typescript
export interface [모듈명PascalCase]Detail extends [모듈명PascalCase] {
  fileList: [모듈명PascalCase]File[]; // 파일 목록
  imageList: [모듈명PascalCase]File[]; // 이미지 목록
}
```

---

## SearchDto Interface

검색 파라미터

```typescript
/**
 * [모듈명] 검색
 */
export interface [모듈명PascalCase]SearchDto {
  startDate?: string; // 시작일 (YYYY-MM-DD)
  endDate?: string; // 종료일 (YYYY-MM-DD)
  keyword: string; // 검색 키워드
  isUse: string; // 사용 여부 (Y/N)
}
```

---

## PagingDto Interface

페이징 파라미터 (SearchDto 확장)

```typescript
/**
 * [모듈명] 페이징
 */
export interface [모듈명PascalCase]PagingDto extends [모듈명PascalCase]SearchDto {
  // 정렬 기준 컬럼 (union type으로 허용값 명시)
  sortBy: string | '[pk]Seq' | 'insertDate' | 'value';
  sortType: string | 'asc' | 'desc'; // 정렬 방식
  row: number; // 페이지당 행 수
  page: number; // 페이지 번호
}
```

---

## CursorDto Interface (선택)

커서 기반 페이징 파라미터

```typescript
/**
 * [모듈명] 커서 페이징
 */
export interface [모듈명PascalCase]CursorDto extends [모듈명PascalCase]SearchDto {
  sortBy: string | '[pk]Seq' | 'insertDate' | 'value';
  sortType: string | 'asc' | 'desc';
  cursor: string; // 커서 값
  limit: number; // 조회할 항목 수
}
```

---

## InsertDto Interface

등록용 DTO

```typescript
/**
 * [모듈명] Insert Dto
 */
export interface [모듈명PascalCase]InsertDto {
  // 비즈니스 필드 (PK 제외)
  value: string;
  subject: string;
  contents: string;

  // 감사(audit) 필드
  insertSeq: number; // 등록자

  // 파일 (백엔드에서는 fileUuid만 필요)
  fileUuidList: string[]; // 파일 UUID 목록
  imageUuidList: string[]; // 이미지 UUID 목록
}
```

---

## UpdateDto Interface

수정용 DTO

```typescript
/**
 * [모듈명] Update Dto
 */
export interface [모듈명PascalCase]UpdateDto {
  // 비즈니스 필드 (PK 제외)
  value: string;
  subject: string;
  contents: string;

  // 감사(audit) 필드
  updateSeq: number; // 수정자

  // 파일 (백엔드에서는 fileUuid만 필요)
  fileUuidList: string[]; // 파일 UUID 목록
  imageUuidList: string[]; // 이미지 UUID 목록
}
```

---

## File Interface (file=Y)

파일 정보

```typescript
/**
 * 파일 정보
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

  // 감사(audit) 필드
  insertSeq: number; // 등록자
  insertDate: string; // 등록일
  updateSeq: number; // 수정자
  updateDate: string; // 수정일
}
```

---

## 네이밍 규칙

| DB 컬럼 (snake_case) | TypeScript (camelCase) |
|---------------------|------------------------|
| test_seq | testSeq |
| is_use | isUse |
| insert_date | insertDate |
| file_uuid | fileUuid |

---

## 타입 변환 규칙

| DB 타입 | TypeScript 타입 | 비고 |
|--------|----------------|------|
| INTEGER, INT | number | 일반 정수 |
| BIGINT | string | 큰 정수 (정밀도 유지) |
| NUMERIC, DECIMAL | string | 소수 (정밀도 유지) |
| VARCHAR, TEXT | string | 문자열 |
| CHAR(1) | string | 상태/여부 코드 |
| TIMESTAMP, DATETIME | string | ISO 형식 문자열 |
| JSONB, JSON | object 또는 string | 상황에 따라 |
