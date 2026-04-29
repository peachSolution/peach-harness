# TDD Service 패턴

> test-data-tdd.service.ts 기반 TDD 헬퍼 서비스 패턴

---

## 파일 구조

```
api/src/modules/[모듈명]/service/[모듈명]-tdd.service.ts
```

---

## Import 패턴

```typescript
import path from 'path';
import { FileService } from '../../common/file/service/file.service';
import { SystemId } from '../../../const';
import { [모듈명PascalCase]Service } from './[모듈명].service';
```

---

## 기본 구조 (file=Y)

```typescript
export class [모듈명PascalCase]TddService {
  // ==================== 테스트 파일 경로 ====================
  static readonly TEST_FILES = {
    FILE: path.join(import.meta.dir, '../test/test-file.txt'),
    IMAGE: path.join(import.meta.dir, '../test/test-image.png'),
  };

  // ==================== 초기화 ====================

  /**
   * TDD 초기화: 테스트 데이터 + 파일 생성
   * @param customParams - 커스텀 파라미터 (선택)
   * @returns 생성된 데이터 정보
   */
  static async init(customParams: Partial<[모듈명PascalCase]InsertDto> = {}): Promise<{
    [pk]Seq: number;
    fileUuidList: string[];
    imageUuidList: string[];
  }> {
    // 1. 테스트 파일 업로드
    const { fileUuidList, imageUuidList } = await [모듈명PascalCase]TddService.uploadTestFiles();

    // 2. 기본 파라미터 설정
    const insertParams: [모듈명PascalCase]InsertDto = {
      value: 'TDD 기본값',
      subject: 'TDD 제목',
      contents: 'TDD 내용',
      insertSeq: SystemId.MEM_TDD,
      fileUuidList,
      imageUuidList,
      ...customParams,
    };

    // 3. 데이터 등록
    const [pk]Seq = await [모듈명PascalCase]Service.insert(insertParams);

    return { [pk]Seq, fileUuidList, imageUuidList };
  }

  // ==================== 정리 ====================

  /**
   * TDD 정리: 데이터 삭제 + 업로드 파일 삭제
   * @param [pk]Seq - 삭제할 데이터 PK
   * @returns 성공 여부
   */
  static async cleanup([pk]Seq: number): Promise<boolean> {
    // 1. 연결된 파일 UUID 수집
    const detail = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    const fileUuids = [
      ...detail.fileList.map((f) => f.fileUuid),
      ...detail.imageList.map((f) => f.fileUuid),
    ];

    // 2. 데이터 하드 삭제
    await [모듈명PascalCase]Service.hardDelete([pk]Seq, SystemId.MEM_TDD);

    // 3. 업로드된 파일 삭제
    await [모듈명PascalCase]TddService.deleteUploadedFiles(fileUuids);

    return true;
  }

  // ==================== 파일 헬퍼 ====================

  /**
   * 테스트 파일 업로드
   * @returns 업로드된 파일 UUID 목록
   */
  static async uploadTestFiles(): Promise<{
    fileUuidList: string[];
    imageUuidList: string[];
  }> {
    const fileUuidList: string[] = [];
    const imageUuidList: string[] = [];

    // 일반 파일 업로드
    const fileResult = await FileService.uploadLocal(
      [모듈명PascalCase]TddService.TEST_FILES.FILE,
      '[모듈명]',
      SystemId.MEM_TDD,
    );
    if (fileResult.fileUuid) {
      fileUuidList.push(fileResult.fileUuid);
    }

    // 이미지 파일 업로드
    const imageResult = await FileService.uploadLocal(
      [모듈명PascalCase]TddService.TEST_FILES.IMAGE,
      '[모듈명]',
      SystemId.MEM_TDD,
    );
    if (imageResult.fileUuid) {
      imageUuidList.push(imageResult.fileUuid);
    }

    return { fileUuidList, imageUuidList };
  }

  /**
   * 업로드된 파일 삭제
   * @param fileUuids - 삭제할 파일 UUID 목록
   */
  static async deleteUploadedFiles(fileUuids: string[]): Promise<void> {
    await Promise.all(
      fileUuids.map((fileUuid) => FileService.deleteByUuid(fileUuid)),
    );
  }
}
```

---

## 기본 구조 (file=N)

파일 기능이 없는 경우 간소화된 버전:

```typescript
export class [모듈명PascalCase]TddService {
  /**
   * TDD 초기화: 테스트 데이터 생성
   * @param customParams - 커스텀 파라미터 (선택)
   * @returns 생성된 데이터 PK
   */
  static async init(customParams: Partial<[모듈명PascalCase]InsertDto> = {}): Promise<number> {
    const insertParams: [모듈명PascalCase]InsertDto = {
      value: 'TDD 기본값',
      subject: 'TDD 제목',
      contents: 'TDD 내용',
      insertSeq: SystemId.MEM_TDD,
      ...customParams,
    };

    return await [모듈명PascalCase]Service.insert(insertParams);
  }

  /**
   * TDD 정리: 데이터 삭제
   * @param [pk]Seq - 삭제할 데이터 PK
   * @returns 성공 여부
   */
  static async cleanup([pk]Seq: number): Promise<boolean> {
    await [모듈명PascalCase]Service.hardDelete([pk]Seq);
    return true;
  }
}
```

---

## 테스트 파일 준비

### 필요 파일

```
api/src/modules/[모듈명]/test/
├── [모듈명].test.ts      ← 테스트 파일
├── test-file.txt        ← 테스트용 일반 파일
└── test-image.png       ← 테스트용 이미지 파일
```

### 테스트 파일 내용

```bash
# test-file.txt
TDD 테스트용 파일입니다.

# test-image.png
1x1 투명 PNG 또는 간단한 테스트 이미지
```

---

## SystemId 상수

```typescript
// api/src/const/index.ts
export const SystemId = {
  MEM_TDD: 99999,     // TDD 테스트용 시스템 ID
  MEM_SYSTEM: 1,      // 시스템 기본 ID
  // ...
};
```

---

## 핵심 패턴

### 1. init() - 초기화

```typescript
// 기본 파라미터로 초기화
const result = await [모듈명PascalCase]TddService.init();

// 커스텀 파라미터로 초기화
const result = await [모듈명PascalCase]TddService.init({
  value: '커스텀 값',
  subject: '커스텀 제목',
});
```

### 2. cleanup() - 정리

```typescript
// 데이터 + 파일 모두 정리
await [모듈명PascalCase]TddService.cleanup([pk]Seq);
```

### 3. 부분 스프레드 패턴

```typescript
// customParams로 기본값 오버라이드
const insertParams = {
  value: 'TDD 기본값',      // 기본값
  subject: 'TDD 제목',      // 기본값
  ...customParams,         // 커스텀 값으로 덮어쓰기
};
```

---

## file 옵션별 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| init 반환 | `number` | `{ [pk]Seq, fileUuidList, imageUuidList }` |
| cleanup | `hardDelete` 호출 | `detailOne` → `hardDelete` → `deleteUploadedFiles` |
| 테스트 파일 | 불필요 | `test-file.txt`, `test-image.png` 필요 |
| 헬퍼 메서드 | 없음 | `uploadTestFiles`, `deleteUploadedFiles` |
