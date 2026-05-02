# 타입 생성 패턴 가이드

## 개요

Store와 UI 개발 전에 타입을 먼저 정의합니다.
test-data 타입 구조를 복사하여 모듈명만 치환합니다.

---

## test-data 타입 구조 복사

```typescript
// front/src/modules/[모듈명]/type/[모듈명].type.ts

// 기본 타입
export interface [ModuleName] {
  [pk]Seq: number;
  subject: string;
  value: string;
  isUse: 'Y' | 'N';
  isDelete: 'Y' | 'N';
  insertSeq: number;
  insertDate: string;
  updateSeq: number;
  updateDate: string;
}

// 상세 타입 (파일 포함)
export interface [ModuleName]Detail extends [ModuleName] {
  fileList: [ModuleName]File[];
  imageList: [ModuleName]File[];
}

// 파일 타입
export interface [ModuleName]File {
  [pk]Seq: number;
  fileSeq: number;
  uuid: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
  url: string;
}

// 검색 DTO
export interface [ModuleName]SearchDto {
  startDate: string;
  endDate: string;
  keyword: string;
  opt: string;
  isUse: string;
}

// 페이징 DTO
export interface [ModuleName]PagingDto extends [ModuleName]SearchDto {
  page: number;
  row: number;
  sortBy: string;
  sortType: string;
}

// Insert DTO
export interface [ModuleName]InsertDto {
  subject: string;
  value: string;
  fileUuidList: string[];
  imageUuidList: string[];
}

// Update DTO
export interface [ModuleName]UpdateDto extends [ModuleName]InsertDto {
  [pk]Seq: number;
}
```

---

## 네이밍 규칙

| 테이블명 | 모듈명 | 타입명 | PK |
|---------|--------|--------|-----|
| `user_info` | `user-info` | `UserInfo` | `userInfoSeq` |
| `product` | `product` | `Product` | `productSeq` |
| `order_item` | `order-item` | `OrderItem` | `orderItemSeq` |

---

## 참조

실제 타입 예시: `front/src/modules/test-data/type/test-data.type.ts`
