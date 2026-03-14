# excel 옵션 처리 가이드

> test-data 기반 엑셀 업로드 API 패턴

---

## excel=N (기본)

엑셀 관련 코드 없음.

---

## excel=Y

### Type

```typescript
// [모듈명].type.ts에 추가

// ==================== Excel 관련 타입 ====================
/**
 * 엑셀 업로드 Dto
 */
export interface [모듈명PascalCase]ExcelUploadDto {
  subject: string;      // 제목 (중복 체크 기준)
  contents: string;     // 내용
  value: string;        // 값
  // ... 비즈니스 필드
  userSeq: number;      // 사용자번호 (CurrentUser에서)
}
```

---

### DAO

```typescript
// [모듈명].dao.ts에 추가

/**
 * 중복 체크용 - subject로 조회
 */
static async findOneBySubject(subject: string): Promise<[모듈명] | undefined> {
  // PostgreSQL
  const result = await DB.maybeOne`
    SELECT *
    FROM [테이블명]
    WHERE "subject" = ${subject}
      AND is_delete = false
  `;

  // MySQL
  const result = await DB.maybeOne`
    SELECT *
    FROM [테이블명]
    WHERE \`subject\` = ${subject}
      AND is_delete = false
  `;

  return result ? this.toCamelCase(result) : undefined;
}
```

---

### Service

```typescript
// [모듈명].service.ts에 추가

// ==================== Excel 업로드 ====================
/**
 * Excel 데이터 업로드 처리
 * @param params Excel 업로드 파라미터
 * @returns 업로드 결과 (성공 여부 및 insert/update 구분)
 */
static async excelUpload(
  params: [모듈명PascalCase]ExcelUploadDto,
): Promise<{ isSuccess: boolean; method: 'insert' | 'update' }> {
  // 1. 중복 체크 (subject 기준)
  const existingData = await [모듈명PascalCase]Dao.findOneBySubject(params.subject);

  if (existingData) {
    // 2-a. 기존 데이터 있으면 update
    await [모듈명PascalCase]Dao.update(existingData.[pk]Seq, {
      ...params,
      updateSeq: params.userSeq,
      fileUuidList: [],      // Excel 업로드는 파일을 처리하지 않음
      imageUuidList: [],     // Excel 업로드는 파일을 처리하지 않음
    });
    return { isSuccess: true, method: 'update' };
  } else {
    // 2-b. 기존 데이터 없으면 insert
    await [모듈명PascalCase]Dao.insert({
      ...params,
      insertSeq: params.userSeq,
      fileUuidList: [],
      imageUuidList: [],
    });
    return { isSuccess: true, method: 'insert' };
  }
}
```

---

### Controller

```typescript
// [모듈명].controller.ts에 추가

// ==================== Excel 업로드 ====================

@Authorized()
@Post('/excel/upload')
async excelUpload(
  @Body()
  params: {
    subject: string;
    contents: string;
    value: string;
    // ... 비즈니스 필드
  },
  @CurrentUser() user: User,
): Promise<{ isSuccess: boolean; method: 'insert' | 'update' }> {
  return [모듈명PascalCase]Service.excelUpload({
    ...params,
    userSeq: user.memberSeq,
  });
}
```

---

## 중복 체크 기준 필드

엑셀 업로드에서 중복 체크는 **고유한 비즈니스 키**를 기준으로 합니다.

| 예시 | 중복 체크 기준 | DAO 메서드 |
|------|---------------|-----------|
| test-data | subject | findOneBySubject |
| member | email | findOneByEmail |
| product | productCode | findOneByProductCode |
| category | categoryCode | findOneByCode |

**구현 시 고려사항:**
- 테이블에 unique constraint가 있는 필드 사용
- 없으면 비즈니스적으로 고유해야 하는 필드 선택
- 복합키인 경우 여러 필드 조합

---

## 엑셀 업로드 흐름

```
Frontend (excel-upload.modal.vue)
    ↓
엑셀 파일 → XLSX 파싱 → 행별 DTO 생성
    ↓
POST /[모듈명]/excel/upload (행별 순차 호출)
    ↓
Controller: params + userSeq 조합
    ↓
Service.excelUpload(params)
    ├─ findOneBySubject(subject)
    ├─ 있으면 → update → { isSuccess: true, method: 'update' }
    └─ 없으면 → insert → { isSuccess: true, method: 'insert' }
    ↓
Frontend: 행별 상태 업데이트 (success/failure, insert/update)
```

---

## 응답 형식

```typescript
interface ExcelUploadResponse {
  isSuccess: boolean;         // 처리 성공 여부
  method: 'insert' | 'update'; // 등록/수정 구분
}
```

---

## 파일 처리 주의사항

Excel 업로드는 **파일을 처리하지 않습니다**:

```typescript
// Service에서 명시적으로 빈 배열 전달
await [모듈명]Dao.update(existingData.[pk]Seq, {
  ...params,
  updateSeq: params.userSeq,
  fileUuidList: [],      // 명시적으로 빈 배열
  imageUuidList: [],     // 명시적으로 빈 배열
});
```

파일이 필요한 경우 별도의 API (등록/수정 API)를 통해 처리합니다.

---

## 체크리스트

### excel=Y 추가 사항

**Type**
- [ ] ExcelUploadDto Interface (비즈니스 필드 + userSeq)

**DAO**
- [ ] findOneBySubject (또는 적절한 중복 체크 메서드)

**Service**
- [ ] excelUpload 메서드 (중복 체크 → insert/update 분기)

**Controller**
- [ ] @Post('/excel/upload') 엔드포인트
- [ ] @Authorized() 데코레이터
- [ ] @CurrentUser()로 userSeq 주입
