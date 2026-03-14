# Service 레이어 패턴

> test-data 가이드코드 기반 Service 패턴

---

## Service 에러 처리 원칙

### 기본 방침

```
┌─────────────────────────────────────────────────────────────────┐
│  에러 처리 전략                                                  │
│                                                                 │
│  ✅ throw Error 방식: 프론트에서 인식 가능                      │
│  ✅ 최소 검증: 백엔드만 확인 가능한 오류                        │
│  ❌ 불필요: 프론트 검증 가능한 항목                             │
│                                                                 │
│  - 논리 오류는 프론트에서 대부분 걸러짐                         │
│  - 특수한 오류(존재 여부, 중복, 관계 무결성)만 처리             │
└─────────────────────────────────────────────────────────────────┘
```

### 필수 에러 처리 시점

#### 1. 데이터 미존재
```typescript
const data = await Dao.findOne(seq);
if (!data) throw new Error('[모듈명]을 찾을 수 없습니다.');
```

#### 2. 파일 검증 (file=Y)
```typescript
const file = await Dao.findFileUuidOne(fileUuid);
if (!file) throw new Error('파일이 존재하지 않습니다.');
if (file.parentCode) throw new Error('이미 사용 중인 파일입니다.');
```

#### 3. 중복 검증 (비즈니스 규칙)
```typescript
const exists = await Dao.findOneBySubject(subject);
if (exists) throw new Error('이미 존재하는 제목입니다.');
```

#### 4. 관계 무결성
```typescript
const hasChild = await Dao.findChildCount(seq);
if (hasChild > 0) throw new Error('하위 데이터가 존재하여 삭제할 수 없습니다.');
```

### 불필요한 검증 (프론트 처리)

```
❌ 입력값 형식 검증 (이메일, 전화번호 등)
❌ 필수값 체크
❌ 길이/범위 체크
❌ 날짜 유효성
```

---

## 파일 구조

```
api/src/modules/[모듈명]/service/[모듈명].service.ts
```

---

## Import 패턴

```typescript
import { [모듈명PascalCase]Dao } from '../dao/[모듈명].dao';
import type {
  [모듈명PascalCase],
  [모듈명PascalCase]Detail,
  [모듈명PascalCase]InsertDto,
  [모듈명PascalCase]PagingDto,
  [모듈명PascalCase]UpdateDto,
} from '../type/[모듈명].type';
```

---

## 기본 Service 구조 (file=N)

```typescript
export class [모듈명PascalCase]Service {
  static findPaging(
    params: [모듈명PascalCase]PagingDto,
  ): Promise<{ data: [모듈명PascalCase][]; totalRow: number }> {
    return [모듈명PascalCase]Dao.findPaging(params);
  }

  static findList(keyword: string): Promise<[모듈명PascalCase][]> {
    return [모듈명PascalCase]Dao.findList(keyword);
  }

  static findOne([pk]Seq: number): Promise<[모듈명PascalCase] | undefined> {
    return [모듈명PascalCase]Dao.findOne([pk]Seq);
  }

  static async insert(params: [모듈명PascalCase]InsertDto): Promise<number> {
    return await [모듈명PascalCase]Dao.insert(params);
  }

  static async update([pk]Seq: number, params: [모듈명PascalCase]UpdateDto): Promise<boolean> {
    const exists = await [모듈명PascalCase]Dao.findOne([pk]Seq);
    if (!exists) throw new Error('[모듈명]을 찾을 수 없습니다.');

    await [모듈명PascalCase]Dao.update([pk]Seq, params);
    return true;
  }

  static async updateUse([pk]Seq: number | number[], isUse: string, updateSeq: number) {
    if (Array.isArray([pk]Seq)) {
      await Promise.all(
        [pk]Seq.map((seq) => [모듈명PascalCase]Dao.updateUse(seq, isUse, updateSeq)),
      );
    } else {
      await [모듈명PascalCase]Dao.updateUse([pk]Seq, isUse, updateSeq);
    }
    return true;
  }

  static async softDelete([pk]Seq: number | number[], isDelete: string, updateSeq: number) {
    if (Array.isArray([pk]Seq)) {
      await Promise.all(
        [pk]Seq.map((seq) => [모듈명PascalCase]Dao.softDelete(seq, isDelete, updateSeq)),
      );
    } else {
      await [모듈명PascalCase]Dao.softDelete([pk]Seq, isDelete, updateSeq);
    }
    return true;
  }

  static async hardDelete([pk]Seq: number): Promise<boolean> {
    await [모듈명PascalCase]Dao.hardDelete([pk]Seq);
    return true;
  }
}
```

---

## 파일 포함 Service 구조 (file=Y)

```typescript
export class [모듈명PascalCase]Service {
  // ==================== Private 헬퍼 메서드 ====================

  /**
   * 일반 파일의 부모 코드 생성
   * @param [pk]Seq - PK 순번
   * @returns 파일 부모 코드 (형식: "[모듈명]-{seq}")
   */
  static #parentCode([pk]Seq: number): string {
    return `[모듈명]-${[pk]Seq}`;
  }

  /**
   * 이미지 파일의 부모 코드 생성
   * @param [pk]Seq - PK 순번
   * @returns 이미지 부모 코드 (형식: "[모듈명]-{seq}-image")
   */
  static #parentCodeImage([pk]Seq: number): string {
    return `[모듈명]-${[pk]Seq}-image`;
  }

  /**
   * 파일 설정: 기존 파일 초기화 후 새 파일 연결
   */
  static async #fileSetting(
    [pk]Seq: number,
    fileUuidList: string[],
    imageUuidList: string[],
    updateSeq: number,
  ): Promise<void> {
    // 기존 파일 부모 코드 초기화
    await Promise.all([
      [모듈명PascalCase]Dao.reSetFileParent([모듈명PascalCase]Service.#parentCode([pk]Seq), updateSeq),
      [모듈명PascalCase]Dao.reSetFileParent([모듈명PascalCase]Service.#parentCodeImage([pk]Seq), updateSeq),
    ]);

    // 파일 부모 코드 등록
    await Promise.all([
      ...fileUuidList.map(async (fileUuid, idx) => {
        const file = await [모듈명PascalCase]Dao.findFileUuidOne(fileUuid);
        if (!file) throw new Error('파일이 존재하지 않습니다.');
        if (file.parentCode) throw new Error('이미 사용 중인 파일입니다.');
        await [모듈명PascalCase]Dao.updateFileParent(
          file.fileSeq,
          [모듈명PascalCase]Service.#parentCode([pk]Seq),
          idx,
          updateSeq,
        );
      }),
      ...imageUuidList.map(async (fileUuid, idx) => {
        const file = await [모듈명PascalCase]Dao.findFileUuidOne(fileUuid);
        if (!file) throw new Error('파일이 존재하지 않습니다.');
        if (file.parentCode) throw new Error('이미 사용 중인 파일입니다.');
        await [모듈명PascalCase]Dao.updateFileParent(
          file.fileSeq,
          [모듈명PascalCase]Service.#parentCodeImage([pk]Seq),
          idx,
          updateSeq,
        );
      }),
    ]);
  }

  // ==================== 기본 CRUD ====================

  static findPaging(
    params: [모듈명PascalCase]PagingDto,
  ): Promise<{ data: [모듈명PascalCase][]; totalRow: number }> {
    return [모듈명PascalCase]Dao.findPaging(params);
  }

  static findList(keyword: string): Promise<[모듈명PascalCase][]> {
    return [모듈명PascalCase]Dao.findList(keyword);
  }

  // ==================== 상세 조회 (파일 포함) ====================

  /**
   * 상세 + 파일 리스트
   */
  static async detailOne([pk]Seq: number): Promise<[모듈명PascalCase]Detail> {
    const data = await [모듈명PascalCase]Dao.findOne([pk]Seq);
    if (!data) throw new Error('[모듈명]을 찾을 수 없습니다.');

    const fileList = await [모듈명PascalCase]Dao.findFileParentList(
      [모듈명PascalCase]Service.#parentCode([pk]Seq),
    );
    const imageList = await [모듈명PascalCase]Dao.findFileParentList(
      [모듈명PascalCase]Service.#parentCodeImage([pk]Seq),
    );
    return { ...data, fileList, imageList } as [모듈명PascalCase]Detail;
  }

  /**
   * 리스트 + 파일 리스트
   */
  static async detailList(keyword: string): Promise<[모듈명PascalCase]Detail[]> {
    const list = await [모듈명PascalCase]Dao.findList(keyword);
    return await Promise.all(
      list.map(async (item) => {
        const fileList = await [모듈명PascalCase]Dao.findFileParentList(
          [모듈명PascalCase]Service.#parentCode(item.[pk]Seq),
        );
        const imageList = await [모듈명PascalCase]Dao.findFileParentList(
          [모듈명PascalCase]Service.#parentCodeImage(item.[pk]Seq),
        );
        return { ...item, fileList, imageList } as [모듈명PascalCase]Detail;
      }),
    );
  }

  // ==================== 등록/수정 (파일 처리 포함) ====================

  static async insert(params: [모듈명PascalCase]InsertDto): Promise<number> {
    const [pk]Seq = await [모듈명PascalCase]Dao.insert(params);

    await [모듈명PascalCase]Service.#fileSetting(
      [pk]Seq,
      params.fileUuidList,
      params.imageUuidList,
      params.insertSeq,
    );
    return [pk]Seq;
  }

  static async update([pk]Seq: number, params: [모듈명PascalCase]UpdateDto): Promise<boolean> {
    const exists = await [모듈명PascalCase]Dao.findOne([pk]Seq);
    if (!exists) throw new Error('[모듈명]을 찾을 수 없습니다.');

    await [모듈명PascalCase]Dao.update([pk]Seq, params);

    await [모듈명PascalCase]Service.#fileSetting(
      [pk]Seq,
      params.fileUuidList,
      params.imageUuidList,
      params.updateSeq,
    );
    return true;
  }

  // ==================== 활성화/삭제 ====================

  static async updateUse([pk]Seq: number | number[], isUse: string, updateSeq: number) {
    if (Array.isArray([pk]Seq)) {
      await Promise.all(
        [pk]Seq.map((seq) => [모듈명PascalCase]Dao.updateUse(seq, isUse, updateSeq)),
      );
    } else {
      await [모듈명PascalCase]Dao.updateUse([pk]Seq, isUse, updateSeq);
    }
    return true;
  }

  static async softDelete([pk]Seq: number | number[], isDelete: string, updateSeq: number) {
    if (Array.isArray([pk]Seq)) {
      await Promise.all(
        [pk]Seq.map((seq) => [모듈명PascalCase]Dao.softDelete(seq, isDelete, updateSeq)),
      );
    } else {
      await [모듈명PascalCase]Dao.softDelete([pk]Seq, isDelete, updateSeq);
    }
    return true;
  }

  static async hardDelete([pk]Seq: number, updateSeq: number): Promise<boolean> {
    // 파일 삭제 전 파일 목록 초기화
    await Promise.all([
      [모듈명PascalCase]Dao.reSetFileParent([모듈명PascalCase]Service.#parentCode([pk]Seq), updateSeq),
      [모듈명PascalCase]Dao.reSetFileParent([모듈명PascalCase]Service.#parentCodeImage([pk]Seq), updateSeq),
    ]);

    await [모듈명PascalCase]Dao.hardDelete([pk]Seq);
    return true;
  }
}
```

---

## 핵심 패턴 정리

### 1. Private 메서드 (file=Y)

- `#parentCode([pk]Seq)`: 일반 파일 부모 코드 생성
- `#parentCodeImage([pk]Seq)`: 이미지 파일 부모 코드 생성
- `#fileSetting(...)`: 파일 연결 처리

### 2. 배열/단일 처리

```typescript
// updateUse, softDelete에서 배열과 단일 값 모두 처리
if (Array.isArray([pk]Seq)) {
  await Promise.all([pk]Seq.map((seq) => dao.method(seq, ...)));
} else {
  await dao.method([pk]Seq, ...);
}
```

### 3. 상세 조회 + 파일

```typescript
// findOne 대신 detailOne 사용 (file=Y)
const data = await Dao.findOne([pk]Seq);
const fileList = await Dao.findFileParentList(parentCode);
const imageList = await Dao.findFileParentList(parentCodeImage);
return { ...data, fileList, imageList };
```

---

## file 옵션에 따른 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| 상세 조회 | `findOne` | `detailOne` |
| 등록 | `dao.insert` | `dao.insert` + `#fileSetting` |
| 수정 | `dao.update` | `dao.update` + `#fileSetting` |
| 삭제 | `dao.hardDelete` | `reSetFileParent` + `dao.hardDelete` |
| Private 메서드 | 없음 | `#parentCode`, `#parentCodeImage`, `#fileSetting` |
