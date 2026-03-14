# DAO 레이어 패턴

> test-data 가이드코드 기반 DAO 패턴 (PostgreSQL/MySQL 분기)

---

## ⚠️ 라이브러리 감지 (필수 첫 단계)

**코드 생성 전 test-data DAO의 import 문을 확인하여 라이브러리를 감지합니다.**

```bash
head -5 api/src/modules/test-data/dao/test-data.dao.ts
```

### 판별 기준

| Import 패턴 | 라이브러리 | 사용 섹션 |
|-------------|-----------|----------|
| `from 'bunqldb'` | bunqldb (기본값) | [bunqldb 패턴](#bunqldb-패턴-기본값-권장) |
| `from 'sql-template-strings'` | sql-template-strings | [sql-template-strings 패턴](#sql-template-strings-패턴-레거시) |

### 핵심 차이

| 항목 | bunqldb | sql-template-strings |
|------|---------|---------------------|
| Import | `import { DB, sql } from 'bunqldb'` | `import { DB } from 'libs/database/database.lib'`<br>`import sql from 'sql-template-strings'` |
| 쿼리 조합 | `query = sql\`${query} AND ...\`` (재할당) | `query.append(sql\`AND ...\`)` |
| 타입 캐스팅 | 자동 | `as [타입][]` 필요 |

---

## 파일 구조

```
api/src/modules/[모듈명]/dao/[모듈명].dao.ts
```

---

# bunqldb 패턴 (기본값, 권장)

## Import 패턴 (bunqldb)

```typescript
import { DB, sql } from 'bunqldb';
import type {
  [모듈명PascalCase],
  [모듈명PascalCase]File,
  [모듈명PascalCase]InsertDto,
  [모듈명PascalCase]PagingDto,
  [모듈명PascalCase]UpdateDto,
} from '../type/[모듈명].type';
```

---

## DB 종류별 문법 차이

| 항목 | PostgreSQL | MySQL |
|------|-----------|-------|
| 식별자 따옴표 | `"column"` | `` `column` `` |
| 캐스팅 | `::text`, `::timestamp` | `CAST(col AS CHAR)` |
| 문자열 연결 | `\|\|` | `CONCAT()` |
| LIKE 캐스팅 | `col::text LIKE` | `CAST(col AS CHAR) LIKE` |

---

## ⚠️ 숫자 파라미터 필터링 패턴 (필수)

> **HTTP GET 쿼리 파라미터는 항상 문자열로 전달됩니다.**
> 숫자 비교 시 반드시 `Number()` 변환을 적용하세요.

### 패턴 1: 단순 숫자 필터 (0 = 전체)

```typescript
// ❌ 잘못된 패턴
if (params.bizType !== 0) { ... }  // "0" !== 0 → true (버그!)

// ✅ 올바른 패턴
if (params.bizType !== undefined && Number(params.bizType) !== 0) {
  query = sql`${query} AND table.biz_type = ${params.bizType} `;
}
```

### 패턴 2: 특수값 분기 필터 (-1=미배정, -2=삭제 등)

```typescript
// ✅ 변수로 먼저 변환 후 다중 조건 분기
if (params.empSeq) {
  const empSeq = Number(params.empSeq);
  if (empSeq === -1) {
    query = sql`${query} AND worker.emp_seq IS NULL `;
  } else if (empSeq === -2) {
    query = sql`${query} AND worker.retire_yn = 'Y' `;
  } else if (empSeq !== 0) {
    query = sql`${query} AND table.emp_seq = ${empSeq} `;
  }
}
```

### 잘못된 패턴 vs 올바른 패턴

| ❌ 잘못된 패턴 | ✅ 올바른 패턴 |
|--------------|--------------|
| `params.seq !== 0` | `Number(params.seq) !== 0` |
| `params.seq === -1` | `Number(params.seq) === -1` |
| `params.seq > 0` | `Number(params.seq) > 0` |

---

## findPaging 패턴 (PostgreSQL)

```typescript
static async findPaging(
  params: [모듈명PascalCase]PagingDto,
): Promise<{ data: [모듈명PascalCase][]; totalRow: number }> {
  let query = sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        , [테이블].contents
        , [테이블]."bigint"
        , [테이블]."decimal"
        , [테이블].is_use
        , [테이블].is_delete
        , [테이블].insert_seq
        , [테이블].insert_date
        , [테이블].update_seq
        , [테이블].update_date

     FROM [테이블]
    WHERE [테이블].is_delete = 'N'
  `;

  // 키워드 검색
  if (params.keyword !== undefined && params.keyword !== '') {
    const keyword = `%${params.keyword}%`;
    query = sql`${query}
      AND ( [테이블].[pk]_seq::text LIKE ${keyword}
         OR [테이블].value LIKE ${keyword}
         OR [테이블].subject LIKE ${keyword} )
    `;
  }

  // 사용여부 필터
  if (params.isUse !== undefined && params.isUse !== '') {
    query = sql`${query} AND [테이블].is_use = ${params.isUse}`;
  }

  // 기간 필터 (PostgreSQL)
  if (params.startDate) {
    query = sql`${query} AND [테이블].insert_date >= (${params.startDate} || ' 00:00:00')::timestamp`;
  }
  if (params.endDate) {
    query = sql`${query} AND [테이블].insert_date <= (${params.endDate} || ' 23:59:59')::timestamp`;
  }

  // 정렬 패턴 1: 단순 정렬
  // 각 sortBy/sortType 조합을 명시적으로 분기하여 ASC/DESC 하드코딩
  if (params.sortBy === '[pk]Seq' && params.sortType === 'asc')
    query = sql`${query} ORDER BY [테이블].[pk]_seq ASC`;
  else if (params.sortBy === '[pk]Seq' && params.sortType !== 'asc')
    query = sql`${query} ORDER BY [테이블].[pk]_seq DESC`;
  else if (params.sortBy === 'insertDate' && params.sortType === 'asc')
    query = sql`${query} ORDER BY [테이블].insert_date ASC`;
  else if (params.sortBy === 'insertDate' && params.sortType !== 'asc')
    query = sql`${query} ORDER BY [테이블].insert_date DESC`;
  else query = sql`${query} ORDER BY [테이블].[pk]_seq DESC`;

  // 정렬 패턴 2: CASE WHEN 우선순위 정렬 + 다중 컬럼
  // 복잡한 정렬이 필요한 경우 (예: 특정 조건 우선순위 + 다중 컬럼 정렬)
  /*
  if (params.sortBy === 'clientName' && params.sortType === 'asc') {
    query = sql`${query}
      ORDER BY CASE WHEN [테이블].accept_state = 2 THEN 2 ELSE 1 END ASC
             , [테이블].client_name ASC
             , [테이블].insert_date ASC
    `;
  } else if (params.sortBy === 'clientName' && params.sortType !== 'asc') {
    query = sql`${query}
      ORDER BY CASE WHEN [테이블].accept_state = 2 THEN 2 ELSE 1 END ASC
             , [테이블].client_name DESC
             , [테이블].insert_date ASC
    `;
  }
  */

  // ⚠️ 잘못된 패턴: SQL 템플릿 내 변수 사용 금지
  // const dir = params.sortType === 'asc' ? sql`ASC` : sql`DESC`;
  // query = sql`${query} ORDER BY [테이블].[pk]_seq ${dir}`;
  // 문제: sql-template-strings가 ASC/DESC를 파라미터로 인식하여 오류 발생
  // 해결: 각 조건을 명시적으로 분기하여 ASC/DESC 하드코딩

  const result = await DB.manyPagingParams<[모듈명PascalCase]>(params, query);
  return {
    data: result.data,
    totalRow: result.totalRow,
  };
}
```

---

## findPaging 패턴 (MySQL)

```typescript
static async findPaging(
  params: [모듈명PascalCase]PagingDto,
): Promise<{ data: [모듈명PascalCase][]; totalRow: number }> {
  let query = sql`
   SELECT [테이블].\`[pk]_seq\`
        , [테이블].\`value\`
        , [테이블].\`subject\`
        , [테이블].\`contents\`
        , [테이블].\`bigint\`
        , [테이블].\`decimal\`
        , [테이블].\`is_use\`
        , [테이블].\`is_delete\`
        , [테이블].\`insert_seq\`
        , [테이블].\`insert_date\`
        , [테이블].\`update_seq\`
        , [테이블].\`update_date\`

     FROM [테이블]
    WHERE [테이블].\`is_delete\` = 'N'
  `;

  // 키워드 검색 (MySQL)
  if (params.keyword !== undefined && params.keyword !== '') {
    const keyword = `%${params.keyword}%`;
    query = sql`${query}
      AND ( CAST([테이블].\`[pk]_seq\` AS CHAR) LIKE ${keyword}
         OR [테이블].\`value\` LIKE ${keyword}
         OR [테이블].\`subject\` LIKE ${keyword} )
    `;
  }

  // 기간 필터 (MySQL)
  if (params.startDate) {
    query = sql`${query} AND [테이블].\`insert_date\` >= CONCAT(${params.startDate}, ' 00:00:00')`;
  }
  if (params.endDate) {
    query = sql`${query} AND [테이블].\`insert_date\` <= CONCAT(${params.endDate}, ' 23:59:59')`;
  }

  // 정렬 패턴 1: 단순 정렬
  // 각 sortBy/sortType 조합을 명시적으로 분기하여 ASC/DESC 하드코딩
  if (params.sortBy === '[pk]Seq' && params.sortType === 'asc')
    query = sql`${query} ORDER BY [테이블].\`[pk]_seq\` ASC`;
  else if (params.sortBy === '[pk]Seq' && params.sortType !== 'asc')
    query = sql`${query} ORDER BY [테이블].\`[pk]_seq\` DESC`;
  else if (params.sortBy === 'insertDate' && params.sortType === 'asc')
    query = sql`${query} ORDER BY [테이블].\`insert_date\` ASC`;
  else if (params.sortBy === 'insertDate' && params.sortType !== 'asc')
    query = sql`${query} ORDER BY [테이블].\`insert_date\` DESC`;
  else query = sql`${query} ORDER BY [테이블].\`[pk]_seq\` DESC`;

  // 정렬 패턴 2: CASE WHEN 우선순위 정렬 + 다중 컬럼
  // 복잡한 정렬이 필요한 경우 (예: 특정 조건 우선순위 + 다중 컬럼 정렬)
  /*
  if (params.sortBy === 'clientName' && params.sortType === 'asc') {
    query = sql`${query}
      ORDER BY CASE WHEN [테이블].\`accept_state\` = 2 THEN 2 ELSE 1 END ASC
             , [테이블].\`client_name\` ASC
             , [테이블].\`insert_date\` ASC
    `;
  } else if (params.sortBy === 'clientName' && params.sortType !== 'asc') {
    query = sql`${query}
      ORDER BY CASE WHEN [테이블].\`accept_state\` = 2 THEN 2 ELSE 1 END ASC
             , [테이블].\`client_name\` DESC
             , [테이블].\`insert_date\` ASC
    `;
  }
  */

  // ⚠️ 잘못된 패턴: SQL 템플릿 내 변수 사용 금지
  // const dir = params.sortType === 'asc' ? sql`ASC` : sql`DESC`;
  // query = sql`${query} ORDER BY [테이블].\`[pk]_seq\` ${dir}`;
  // 문제: sql-template-strings가 ASC/DESC를 파라미터로 인식하여 오류 발생
  // 해결: 각 조건을 명시적으로 분기하여 ASC/DESC 하드코딩

  const result = await DB.manyPagingParams<[모듈명PascalCase]>(params, query);
  return {
    data: result.data,
    totalRow: result.totalRow,
  };
}
```

---

## findList 패턴

```typescript
static async findList(keyword: string): Promise<[모듈명PascalCase][]> {
  let query = sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        -- ... 컬럼 목록
     FROM [테이블]
    WHERE [테이블].is_delete = 'N'
  `;

  if (keyword !== undefined && keyword !== '') {
    const keywordParam = `%${keyword}%`;
    query = sql`${query}
      AND ( [테이블].[pk]_seq::text LIKE ${keywordParam}
         OR [테이블].value LIKE ${keywordParam} )
    `;
  }

  query = sql`${query} ORDER BY [테이블].[pk]_seq DESC`;

  return await DB.many<[모듈명PascalCase]>(query);
}
```

---

## findOne 패턴

```typescript
static findOne([pk]Seq: number): Promise<[모듈명PascalCase] | undefined> {
  return DB.maybeOne<[모듈명PascalCase]>(sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        -- ... 컬럼 목록
     FROM [테이블]
    WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## insert 패턴

```typescript
static insert(params: [모듈명PascalCase]InsertDto): Promise<number> {
  return DB.insert(sql`
    INSERT INTO [테이블] (
          value
        , subject
        , contents
        , is_use
        , is_delete
        , insert_seq
        , insert_date
        , update_seq
        , update_date
     ) VALUES (
        ${params.value}
      , ${params.subject}
      , ${params.contents}
      , 'Y'
      , 'N'
      , ${params.insertSeq}
      , NOW()
      , ${params.insertSeq}
      , NOW()
     )
     RETURNING [pk]_seq
  `);
}
```

---

## update 패턴

```typescript
static update([pk]Seq: number, params: [모듈명PascalCase]UpdateDto): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET value = ${params.value}
         , subject = ${params.subject}
         , contents = ${params.contents}
         , update_seq = ${params.updateSeq}
         , update_date = NOW()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## updateUse 패턴

```typescript
static updateUse([pk]Seq: number, isUse: string, updateSeq: number): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET is_use = ${isUse}
         , update_seq = ${updateSeq}
         , update_date = NOW()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## softDelete 패턴

```typescript
static softDelete([pk]Seq: number, isDelete: string, updateSeq: number): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET is_delete = ${isDelete}
         , update_seq = ${updateSeq}
         , update_date = NOW()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## hardDelete 패턴 (테스트용)

```typescript
static hardDelete([pk]Seq: number): Promise<number> {
  return DB.delete(sql`
    DELETE FROM [테이블] WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## 파일 관련 메서드 (file=Y)

```typescript
// UUID로 파일 조회
static findFileUuidOne(fileUuid: string): Promise<[모듈명PascalCase]File | undefined> {
  return DB.maybeOne<[모듈명PascalCase]File>(sql`
    SELECT common_file.file_seq
         , common_file.parent_code
         , common_file.storage_type
         -- ... 컬럼 목록
      FROM common_file
     WHERE file_uuid = ${fileUuid}
  `);
}

// 부모코드로 파일 목록 조회
static findFileParentList(parentCode: string): Promise<[모듈명PascalCase]File[]> {
  return DB.many<[모듈명PascalCase]File>(sql`
    SELECT common_file.file_seq
         , common_file.parent_code
         -- ... 컬럼 목록
      FROM common_file
     WHERE parent_code LIKE ${parentCode}
     ORDER BY common_file.order_value ASC, common_file.file_seq ASC
  `);
}

// 파일 부모코드 업데이트
static updateFileParent(
  fileSeq: number,
  parentCode: string,
  orderValue: number,
  updateSeq: number,
): Promise<number> {
  return DB.update(sql`
    UPDATE common_file
       SET parent_code = ${parentCode}
         , order_value = ${orderValue}
         , update_seq = ${updateSeq}
         , update_date = NOW()
     WHERE file_seq = ${fileSeq}
  `);
}

// 파일 부모코드 초기화
static reSetFileParent(parentCode: string, updateSeq: number): Promise<number> {
  return DB.update(sql`
    UPDATE common_file
       SET parent_code = NULL
         , update_seq = ${updateSeq}
         , update_date = NOW()
     WHERE parent_code = ${parentCode}
  `);
}
```

---

## DB 함수 정리 (bunqldb)

| 함수 | 용도 | 반환 |
|------|------|------|
| `DB.manyPagingParams` | 페이징 조회 | `{ data, totalRow }` |
| `DB.cursorPaginate` | 커서 페이징 | `{ data, nextCursor }` |
| `DB.many` | 다건 조회 | `T[]` |
| `DB.maybeOne` | 단건 조회 (nullable) | `T \| undefined` |
| `DB.one` | 단건 조회 (필수) | `T` |
| `DB.insert` | 등록 | PK 값 |
| `DB.update` | 수정 | 영향받은 행 수 |
| `DB.delete` | 삭제 | 영향받은 행 수 |

---

# sql-template-strings 패턴 (레거시)

> 레거시 프로젝트 호환용 패턴. `query.append()` 방식으로 동적 쿼리 빌딩.

## Import 패턴 (sql-template-strings)

```typescript
import { DB } from '../../../libs/database/database.lib';
import sql from 'sql-template-strings';
import type {
  [모듈명PascalCase],
  [모듈명PascalCase]PagingDto,
  [모듈명PascalCase]InsertDto,
  [모듈명PascalCase]UpdateDto,
} from '../type/[모듈명].type';
```

---

## findPaging 패턴 (sql-template-strings)

```typescript
static async findPaging(
  params: [모듈명PascalCase]PagingDto,
): Promise<{ totalRow: number; data: [모듈명PascalCase][] }> {
  const query = sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        , [테이블].contents
        , [테이블].\`bigint\`
        , [테이블].is_use
        , [테이블].is_delete
        , [테이블].insert_seq
        , [테이블].insert_date
        , [테이블].update_seq
        , [테이블].update_date

     FROM [테이블]
    WHERE [테이블].is_delete = 'N'
  `;

  // 키워드 검색 (append 방식)
  if (params.keyword != undefined && params.keyword != '') {
    params.keyword = '%' + params.keyword + '%';
    query.append(sql`
      AND ( [테이블].[pk]_seq LIKE ${params.keyword}
         OR [테이블].value LIKE ${params.keyword}
         OR [테이블].subject LIKE ${params.keyword} )
    `);
  }

  // 사용여부 필터
  if (params.isUse != undefined && params.isUse != '') {
    query.append(sql` AND [테이블].is_use = ${params.isUse}`);
  }

  // 정렬 (명시적 분기 + append)
  if (params.sortBy == '[pk]Seq' && params.sortType == 'asc')
    query.append(sql` ORDER BY [테이블].[pk]_seq ASC `);
  else if (params.sortBy == '[pk]Seq' && params.sortType != 'asc')
    query.append(sql` ORDER BY [테이블].[pk]_seq DESC `);
  else if (params.sortBy == 'value' && params.sortType == 'asc')
    query.append(sql` ORDER BY [테이블].value ASC `);
  else if (params.sortBy == 'value' && params.sortType != 'asc')
    query.append(sql` ORDER BY [테이블].value DESC `);
  else if (params.sortBy == 'insertDate' && params.sortType == 'asc')
    query.append(sql` ORDER BY [테이블].insert_date ASC `);
  else if (params.sortBy == 'insertDate' && params.sortType != 'asc')
    query.append(sql` ORDER BY [테이블].insert_date DESC `);
  else query.append(sql` ORDER BY [테이블].[pk]_seq DESC `);

  const result = await DB.manyPagingParams(params, query);
  return {
    data: result.data as [모듈명PascalCase][],
    totalRow: result.totalRow,
  };
}
```

---

## findList 패턴 (sql-template-strings)

```typescript
static async findList(keyword: string): Promise<[모듈명PascalCase][]> {
  const query = sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        , [테이블].contents
        , [테이블].\`bigint\`
        , [테이블].is_use
        , [테이블].is_delete
        , [테이블].insert_seq
        , [테이블].insert_date
        , [테이블].update_seq
        , [테이블].update_date

     FROM [테이블]
    WHERE [테이블].is_delete = 'N'
  `;

  if (keyword != undefined && keyword != '') {
    keyword = '%' + keyword + '%';
    query.append(sql`
      AND ( [테이블].[pk]_seq LIKE ${keyword}
         OR [테이블].value LIKE ${keyword}
         OR [테이블].subject LIKE ${keyword} )
    `);
  }

  query.append(sql` ORDER BY [테이블].[pk]_seq DESC `);

  return await DB.many(query);
}
```

---

## findOne 패턴 (sql-template-strings)

```typescript
static findOne([pk]Seq: number): Promise<[모듈명PascalCase] | undefined> {
  return DB.maybeOne(sql`
   SELECT [테이블].[pk]_seq
        , [테이블].value
        , [테이블].subject
        , [테이블].contents
        , [테이블].\`bigint\`
        , [테이블].is_use
        , [테이블].is_delete
        , [테이블].insert_seq
        , [테이블].insert_date
        , [테이블].update_seq
        , [테이블].update_date
     FROM [테이블]
    WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## insert 패턴 (sql-template-strings)

```typescript
static insert(params: [모듈명PascalCase]InsertDto): Promise<number> {
  return DB.insert(sql`
    INSERT INTO [테이블] (
          value
        , subject
        , contents
        , \`bigint\`
        , is_use
        , is_delete
        , insert_seq
        , insert_date
        , update_seq
        , update_date
     ) VALUES (
        ${params.value}
      , ${params.subject}
      , ${params.contents}
      , ${params.bigint}
      , 'Y'
      , 'N'
      , ${params.insertSeq}
      , now()
      , ${params.insertSeq}
      , now()
     )
  `);
}
```

---

## update 패턴 (sql-template-strings)

```typescript
static update([pk]Seq: number, params: [모듈명PascalCase]UpdateDto): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET value = ${params.value}
         , subject = ${params.subject}
         , contents = ${params.contents}
         , update_seq = ${params.updateSeq}
         , update_date = now()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## updateUse 패턴 (sql-template-strings)

```typescript
static updateUse([pk]Seq: number, isUse: string, updateSeq: number): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET is_use = ${isUse}
         , update_seq = ${updateSeq}
         , update_date = now()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## softDelete 패턴 (sql-template-strings)

```typescript
static softDelete([pk]Seq: number, isDelete: string, updateSeq: number): Promise<number> {
  return DB.update(sql`
    UPDATE [테이블]
       SET is_delete = ${isDelete}
         , update_seq = ${updateSeq}
         , update_date = now()
     WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## hardDelete 패턴 (sql-template-strings)

```typescript
static hardDelete([pk]Seq: number): Promise<number> {
  return DB.delete(sql`
    DELETE FROM [테이블] WHERE [pk]_seq = ${[pk]Seq}
  `);
}
```

---

## DB 함수 정리 (sql-template-strings)

| 함수 | 용도 | 반환 | 비고 |
|------|------|------|------|
| `DB.manyPagingParams` | 페이징 조회 | `{ data, totalRow }` | `as [타입][]` 필요 |
| `DB.many` | 다건 조회 | `any[]` | 타입 캐스팅 필요 |
| `DB.maybeOne` | 단건 조회 | `any \| undefined` | - |
| `DB.insert` | 등록 | PK 값 | - |
| `DB.update` | 수정 | 영향받은 행 수 | - |
| `DB.delete` | 삭제 | 영향받은 행 수 | - |

---

## 패턴 비교 요약

| 항목 | bunqldb | sql-template-strings |
|------|---------|---------------------|
| **Import** | `import { DB, sql } from 'bunqldb'` | `import { DB } from 'libs/database/database.lib'`<br>`import sql from 'sql-template-strings'` |
| **쿼리 조합** | `query = sql\`${query} AND ...\`` | `query.append(sql\`AND ...\`)` |
| **변수 선언** | `let query = sql\`...\`` | `const query = sql\`...\`` |
| **타입 안전성** | 자동 타입 추론 | `as [타입][]` 캐스팅 필요 |
| **권장 여부** | ✅ 권장 (현대적) | 레거시 호환용 |
