# Controller 레이어 패턴

> test-data 가이드코드 기반 Controller + Validator 패턴

---

## Validator 사용 원칙

```
┌─────────────────────────────────────────────────────────────────┐
│  Validator 적용 규칙                                            │
│                                                                 │
│  ✅ Validator 적용: INSERT, UPDATE만                           │
│     - 복잡한 비즈니스 필드 검증                                 │
│     - 파일 업로드 (fileUuidList, imageUuidList)                │
│     - 최소한의 검증만 수행 (대부분 프론트 검증)                │
│                                                                 │
│  ❌ Validator 불필요: 조회, 페이징, 상태 변경                  │
│     - inline 타입으로 충분                                      │
│     - 간단한 파라미터만 전달                                    │
│                                                                 │
│  원칙: 프론트에서 대부분 검증, 백엔드는 최소화                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 라우트 경로 패턴 규칙

```
┌─────────────────────────────────────────────────────────────────┐
│  GET 메서드 숫자 PK 정규식 패턴 적용 (필수)                     │
│                                                                 │
│  ✅ GET 메서드의 숫자 PK 경로에는 (\\d+) 패턴 적용             │
│     - @Get('/:seq(\\d+)')                                       │
│                                                                 │
│  ❌ 정규식 없는 GET 경로는 라우트 순서에 의존적                │
│     - @Get('/:seq') ← 'list' 같은 영문도 매칭될 수 있음        │
│                                                                 │
│  ✅ PUT, DELETE, PATCH는 패턴 불필요 (영문 경로 충돌 없음)     │
│     - @Put('/:seq')      ← 그대로 사용                          │
│     - @Delete('/:seq')   ← 그대로 사용                          │
│     - @Patch('/:seq/use') ← 그대로 사용                         │
│                                                                 │
│  이유: GET에서만 /paging, /list 등 영문 경로와 /:seq 공존      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 파일 구조

```
api/src/modules/[모듈명]/controller/
├── [모듈명].controller.ts    ← API 엔드포인트
└── [모듈명].validator.ts     ← 입력 검증
```

---

## Controller Import 패턴

```typescript
import {
  Authorized,
  Body,
  Controller,
  CurrentUser,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  QueryParams,
} from 'routing-controllers';
import type { Member } from '../../member/type/member.type';
import { [모듈명PascalCase]Service } from '../service/[모듈명].service';
import { [모듈명PascalCase]TddService } from '../service/[모듈명]-tdd.service';
import {
  [모듈명PascalCase]InsertValidator,
  [모듈명PascalCase]UpdateValidator,
} from './[모듈명].validator';
```

---

## Controller 기본 구조

```typescript
@Controller('/[모듈명]')
export class [모듈명PascalCase]Controller {
  // ==================== 조회 ====================

  /**
   * 페이징 목록
   */
  @Authorized()
  @Get('/paging')
  paging(
    @QueryParams()
    params: {
      startDate?: string;
      endDate?: string;
      keyword?: string;
      isUse?: string;
      sortBy?: string;
      sortType?: string;
      row?: number;
      page?: number;
    },
  ) {
    return [모듈명PascalCase]Service.findPaging(params);
  }

  /**
   * 전체 목록
   */
  @Authorized()
  @Get('/list')
  list(@QueryParams() params: { keyword: string }) {
    return [모듈명PascalCase]Service.findList(params.keyword || '');
  }

  /**
   * 상세 조회
   * - file=N: findOne
   * - file=Y: detailOne
   */
  @Authorized()
  @Get('/:seq(\\d+)')  // 정규식 패턴 적용 (영문 경로와 충돌 방지)
  one(@Param('seq') seq: number) {
    return [모듈명PascalCase]Service.detailOne(seq);  // file=Y
    // return [모듈명PascalCase]Service.findOne(seq); // file=N
  }

  // ==================== 등록/수정 ====================

  /**
   * 등록
   */
  @Authorized()
  @Post()
  insert(
    @CurrentUser() user: Member,
    @Body() body: [모듈명PascalCase]InsertValidator,
  ) {
    return [모듈명PascalCase]Service.insert({
      ...body,
      insertSeq: user.memberSeq,
    });
  }

  /**
   * 수정
   */
  @Authorized()
  @Put('/:seq')
  update(
    @CurrentUser() user: Member,
    @Param('seq') seq: number,
    @Body() body: [모듈명PascalCase]UpdateValidator,
  ) {
    return [모듈명PascalCase]Service.update(seq, {
      ...body,
      updateSeq: user.memberSeq,
    });
  }

  // ==================== 상태 변경 ====================

  /**
   * 활성화/비활성화
   */
  @Authorized()
  @Patch('/:seq/use')
  updateUse(
    @CurrentUser() user: Member,
    @Param('seq') seq: number,
    @Body() body: { isUse: string },
  ) {
    return [모듈명PascalCase]Service.updateUse(seq, body.isUse, user.memberSeq);
  }

  /**
   * 삭제 (소프트)
   */
  @Authorized()
  @Delete('/:seq')
  softDelete(@CurrentUser() user: Member, @Param('seq') seq: number) {
    return [모듈명PascalCase]Service.softDelete(seq, 'Y', user.memberSeq);
  }

  // ==================== TDD 전용 (controllerTdd=Y인 경우만) ====================
  // ⚠️ 기본적으로 생성하지 않음
  // - 백엔드 TDD 테스트: TddService 직접 호출로 충분
  // - 프론트 Store 테스트: controllerTdd=Y 옵션으로 API 노출 필요
  //
  // 사용 시점:
  // - 프론트엔드 Store 테스트에서 API로 테스트 데이터 생성 필요 시
  // - E2E 테스트에서 테스트 데이터 셋업 필요 시
  //
  // gen-store에서 storeTdd=Y 사용 시 이 API가 필요합니다.

  /**
   * TDD 초기화 (controllerTdd=Y)
   * @description 테스트 데이터 + 파일 생성
   */
  @Authorized()
  @Post('/tdd/init')
  tddInit(
    @Body()
    body: {
      value?: string;
      subject?: string;
      contents?: string;
    },
  ) {
    return [모듈명PascalCase]TddService.init(body);
  }

  /**
   * TDD 정리 (controllerTdd=Y)
   * @description 데이터 삭제 + 파일 삭제
   */
  @Authorized()
  @Delete('/tdd/cleanup/:seq')
  tddCleanup(@Param('seq') seq: number) {
    return [모듈명PascalCase]TddService.cleanup(seq);
  }
}
```

---

## Validator Import 패턴

```typescript
import { IsArray, IsNumber, IsOptional, IsString } from 'class-validator';
```

---

## Validator 기본 구조

> INSERT/UPDATE만 Validator 사용, 최소 필드만 검증

```typescript
// ==================== 등록 ====================
export class [모듈명PascalCase]InsertValidator {
  @IsOptional()
  @IsString()
  value: string;

  @IsOptional()
  @IsString()
  subject: string;

  @IsOptional()
  @IsString()
  contents: string;

  // file=Y인 경우
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  fileUuidList: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUuidList: string[];
}

// ==================== 수정 ====================
export class [모듈명PascalCase]UpdateValidator {
  @IsOptional()
  @IsString()
  value: string;

  @IsOptional()
  @IsString()
  subject: string;

  @IsOptional()
  @IsString()
  contents: string;

  // file=Y인 경우
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  fileUuidList: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUuidList: string[];
}
```

---

## 데코레이터 정리

### Controller 데코레이터

| 데코레이터 | 용도 | 예시 |
|-----------|------|------|
| `@Controller('/path')` | 라우트 그룹 | `@Controller('/notice')` |
| `@Authorized()` | 인증 필수 | 모든 엔드포인트에 사용 |
| `@Get('/path')` | GET 요청 | `@Get('/paging')` |
| `@Post('/path')` | POST 요청 | `@Post()` |
| `@Put('/path')` | PUT 요청 | `@Put('/:seq')` |
| `@Patch('/path')` | PATCH 요청 | `@Patch('/:seq/use')` |
| `@Delete('/path')` | DELETE 요청 | `@Delete('/:seq')` |

### 파라미터 데코레이터

| 데코레이터 | 용도 | 예시 |
|-----------|------|------|
| `@QueryParams()` | 쿼리 파라미터 | `@QueryParams() params: PagingValidator` |
| `@Param('name')` | 경로 파라미터 | `@Param('seq') seq: number` |
| `@Body()` | 요청 바디 | `@Body() body: InsertValidator` |
| `@CurrentUser()` | 로그인 사용자 | `@CurrentUser() user: Member` |

### Validator 데코레이터

| 데코레이터 | 용도 | 예시 |
|-----------|------|------|
| `@IsOptional()` | 선택 필드 | 대부분의 필드에 사용 |
| `@IsString()` | 문자열 검증 | `@IsString() value: string` |
| `@IsNumber()` | 숫자 검증 | `@IsNumber() row: number` |
| `@IsArray()` | 배열 검증 | `@IsArray() fileUuidList: string[]` |
| `@IsString({ each: true })` | 배열 요소 검증 | 문자열 배열용 |

---

## API 엔드포인트 정리

| HTTP | 경로 | 설명 | Validator |
|------|------|------|-----------|
| GET | `/[모듈명]/paging` | 페이징 목록 | - (inline 타입) |
| GET | `/[모듈명]/list` | 전체 목록 | - |
| GET | `/[모듈명]/:seq` | 상세 조회 | - |
| POST | `/[모듈명]` | 등록 | ✅ InsertValidator |
| PUT | `/[모듈명]/:seq` | 수정 | ✅ UpdateValidator |
| PATCH | `/[모듈명]/:seq/use` | 활성화/비활성화 | - (inline 타입) |
| DELETE | `/[모듈명]/:seq` | 삭제 | - |
| POST | `/[모듈명]/tdd/init` | TDD 초기화 | - (controllerTdd=Y만) |
| DELETE | `/[모듈명]/tdd/cleanup/:seq` | TDD 정리 | - (controllerTdd=Y만) |

---

## file 옵션별 차이

| 항목 | file=N | file=Y |
|------|--------|--------|
| 상세 조회 | `findOne(seq)` | `detailOne(seq)` |
| InsertValidator | 파일 필드 제외 | `fileUuidList`, `imageUuidList` 포함 |
| UpdateValidator | 파일 필드 제외 | `fileUuidList`, `imageUuidList` 포함 |

---

# Elysia 패턴 (createElysia 프레임워크)

> 프레임워크 감지: `head -3 api/src/modules/test-data/controller/test-data.controller.ts`에서 `elysia` 또는 `createElysia` 감지 시 이 섹션 적용

---

## Elysia Controller Import 패턴

```typescript
import { createElysia } from 'src/utils/elysia/elysia.util';
import { t } from 'elysia';
import { [모듈명PascalCase]Service } from '../service/[모듈명].service';
import { [모듈명PascalCase]TddService } from '../service/[모듈명]-tdd.service';
import { [모듈명PascalCase]InsertValidator, [모듈명PascalCase]UpdateValidator } from './[모듈명].validator';
import { [모듈명PascalCase]Docs } from '../docs/[모듈명].docs';
```

---

## Elysia Controller 기본 구조

```typescript
export default createElysia({ prefix: '/[모듈명]' })
  // ==================== 조회 ====================

  .get('/paging', ({ query, user }) => {
    return [모듈명PascalCase]Service.findPaging(query);
  }, {
    query: t.Object({
      startDate: t.Optional(t.String()),
      endDate: t.Optional(t.String()),
      keyword: t.Optional(t.String()),
      isUse: t.Optional(t.String()),
      sortBy: t.Optional(t.String()),
      sortType: t.Optional(t.String()),
      row: t.Optional(t.Number()),
      page: t.Optional(t.Number()),
    }),
    auth: true,
    detail: [모듈명PascalCase]Docs.paging,
  })

  .get('/list', ({ query, user }) => {
    return [모듈명PascalCase]Service.findList(query.keyword || '');
  }, {
    query: t.Object({ keyword: t.Optional(t.String()) }),
    auth: true,
    detail: [모듈명PascalCase]Docs.list,
  })

  .get('/:seq', ({ params, user }) => {
    return [모듈명PascalCase]Service.findOne(Number(params.seq));
  }, {
    params: t.Object({ seq: t.String() }),
    auth: true,
    detail: [모듈명PascalCase]Docs.one,
  })

  // ==================== 등록/수정 ====================

  .post('/', ({ body, user }) => {
    return [모듈명PascalCase]Service.insert({ ...body, insertSeq: user.memberSeq });
  }, {
    body: [모듈명PascalCase]InsertValidator,
    auth: true,
    detail: [모듈명PascalCase]Docs.insert,
  })

  .put('/:seq', ({ params, body, user }) => {
    return [모듈명PascalCase]Service.update(Number(params.seq), { ...body, updateSeq: user.memberSeq });
  }, {
    params: t.Object({ seq: t.String() }),
    body: [모듈명PascalCase]UpdateValidator,
    auth: true,
    detail: [모듈명PascalCase]Docs.update,
  })

  // ==================== 상태 변경 ====================

  .patch('/:seq/use', ({ params, body, user }) => {
    return [모듈명PascalCase]Service.updateUse(Number(params.seq), body.isUse, user.memberSeq);
  }, {
    params: t.Object({ seq: t.String() }),
    body: t.Object({ isUse: t.String() }),
    auth: true,
    detail: [모듈명PascalCase]Docs.updateUse,
  })

  .delete('/:seq', ({ params, user }) => {
    return [모듈명PascalCase]Service.softDelete(Number(params.seq), 'Y', user.memberSeq);
  }, {
    params: t.Object({ seq: t.String() }),
    auth: true,
    detail: [모듈명PascalCase]Docs.softDelete,
  });
```

---

## Elysia Validator 구조 (TypeBox)

```typescript
import { t } from 'elysia';

// ==================== 등록 ====================
export const [모듈명PascalCase]InsertValidator = t.Object({
  value: t.Optional(t.String()),
  subject: t.Optional(t.String()),
  contents: t.Optional(t.String()),

  // file=Y인 경우
  fileUuidList: t.Optional(t.Array(t.String())),
  imageUuidList: t.Optional(t.Array(t.String())),
});

// ==================== 수정 ====================
export const [모듈명PascalCase]UpdateValidator = t.Object({
  value: t.Optional(t.String()),
  subject: t.Optional(t.String()),
  contents: t.Optional(t.String()),

  // file=Y인 경우
  fileUuidList: t.Optional(t.Array(t.String())),
  imageUuidList: t.Optional(t.Array(t.String())),
});
```

---

## Elysia Docs 구조

```typescript
// docs/[모듈명].docs.ts
export const [모듈명PascalCase]Docs = {
  paging: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 페이징 목록',
  },
  list: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 전체 목록',
  },
  one: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 상세 조회',
  },
  insert: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 등록',
  },
  update: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 수정',
  },
  updateUse: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 활성화/비활성화',
  },
  softDelete: {
    tags: ['[모듈명]'],
    summary: '[모듈명] 삭제',
  },
};
```

---

## Koa ↔ Elysia 데코레이터 매핑

| Koa (routing-controllers) | Elysia |
|--------------------------|--------|
| `@Controller('/path')` | `createElysia({ prefix: '/path' })` |
| `@Authorized()` | `auth: true` 옵션 |
| `@Get('/paging')` | `.get('/paging', handler, options)` |
| `@Post()` | `.post('/', handler, options)` |
| `@Put('/:seq')` | `.put('/:seq', handler, options)` |
| `@Patch('/:seq/use')` | `.patch('/:seq/use', handler, options)` |
| `@Delete('/:seq')` | `.delete('/:seq', handler, options)` |
| `@QueryParams()` | `{ query }` destructuring |
| `@Body()` | `{ body }` destructuring |
| `@Param('seq')` | `{ params }` destructuring |
| `@CurrentUser()` | `{ user }` destructuring |
| `class-validator` | TypeBox `t` |
| export class Controller | `export default createElysia(...)` |

---

## Elysia 파일 업로드 패턴 (file=Y)

```typescript
.post('/upload', ({ body, user }) => {
  return [모듈명PascalCase]Service.uploadFile(body.file, user.memberSeq);
}, {
  body: t.Object({
    file: t.File(),
  }),
  auth: true,
  detail: [모듈명PascalCase]Docs.upload,
})
```
