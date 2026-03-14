# file 옵션 처리 가이드

## file=N (기본)

### Type
- `Entity` Interface만 생성
- `EntityDetail` 없음
- `InsertDto`, `UpdateDto`에서 fileUuidList, imageUuidList 제외 가능

### DAO
- 파일 관련 메서드 제외:
  - `findFileUuidOne` ❌
  - `findFileParentList` ❌
  - `updateFileParent` ❌
  - `reSetFileParent` ❌

### Service
- `findOne` 메서드 사용 (파일 없이 단순 조회)
- `detailOne`, `detailList`, `detailPaging` 없음
- Private 메서드 없음:
  - `#parentCode` ❌
  - `#parentCodeImage` ❌
  - `#fileSetting` ❌

### Controller
- `service.findOne` 호출

### Validator
- fileUuidList, imageUuidList 검증 제외

---

## file=Y

### Type

```typescript
// Entity + 파일 목록
export interface [모듈명]Detail extends [모듈명] {
  fileList: [모듈명]File[];
  imageList: [모듈명]File[];
}

// 파일 인터페이스
export interface [모듈명]File {
  fileSeq: number;
  parentCode: string | null;
  storageType: string | 'S3' | 'LOCAL';
  fileAuth: string | 'PUBLIC' | 'PRIVATE';
  fileUuid: string;
  fileFolder: string;
  filePath: string;
  fileName: string;
  fileSize: number;
  fileType: string;
  downloadCnt: number;
  orderValue: number;
  insertSeq: number;
  insertDate: string;
  updateSeq: number;
  updateDate: string;
}

// InsertDto에 파일 UUID 추가
export interface [모듈명]InsertDto {
  // ... 비즈니스 필드
  fileUuidList: string[];
  imageUuidList: string[];
}

// UpdateDto에 파일 UUID 추가
export interface [모듈명]UpdateDto {
  // ... 비즈니스 필드
  fileUuidList: string[];
  imageUuidList: string[];
}
```

### DAO

```typescript
// 파일 관련 메서드 추가
static findFileUuidOne(fileUuid: string): Promise<[모듈명]File | undefined>
static findFileParentList(parentCode: string): Promise<[모듈명]File[]>
static updateFileParent(fileSeq: number, parentCode: string, orderValue: number, updateSeq: number): Promise<number>
static reSetFileParent(parentCode: string, updateSeq: number): Promise<number>
```

### Service

```typescript
// Private 헬퍼 메서드
static #parentCode([pk]Seq: number): string {
  return `[모듈명]-${[pk]Seq}`;
}

static #parentCodeImage([pk]Seq: number): string {
  return `[모듈명]-${[pk]Seq}-image`;
}

static async #fileSetting(
  [pk]Seq: number,
  fileUuidList: string[],
  imageUuidList: string[],
  updateSeq: number,
): Promise<void> {
  // 기존 파일 초기화 + 새 파일 연결
}

// 상세 조회 (파일 포함)
static async detailOne([pk]Seq: number): Promise<[모듈명]Detail>
static async detailList(keyword: string): Promise<[모듈명]Detail[]>
static async detailPaging(params: PagingDto): Promise<{ data: [모듈명]Detail[]; totalRow: number }>
```

### Controller

```typescript
// findOne 대신 detailOne 호출
@Get('/:seq')
async getOne(@Param('seq') seq: number) {
  return await [모듈명]Service.detailOne(seq);
}
```

### Validator

```typescript
@IsOptional()
@IsArray()
fileUuidList: string[];

@IsOptional()
@IsArray()
imageUuidList: string[];
```

---

## 파일 처리 흐름

### 등록 시

```
1. DAO.insert() → PK 반환
2. #fileSetting(PK, fileUuidList, imageUuidList, insertSeq)
   - common_file 테이블의 parent_code 업데이트
   - 파일: "[모듈명]-{PK}"
   - 이미지: "[모듈명]-{PK}-image"
```

### 수정 시

```
1. #fileSetting() 호출
   - 기존 파일 parent_code NULL로 초기화
   - 새 파일 parent_code 설정
2. DAO.update() 호출
```

### 삭제 시 (hardDelete)

```
1. reSetFileParent() 호출 (파일/이미지)
   - 연결된 파일들의 parent_code NULL로 초기화
2. DAO.hardDelete() 호출
```

---

## parentCode 규칙

| 타입 | parentCode 형식 | 예시 |
|------|----------------|------|
| 일반 파일 | `[모듈명]-{PK}` | `notice-123` |
| 이미지 파일 | `[모듈명]-{PK}-image` | `notice-123-image` |
