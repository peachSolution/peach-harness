# TDD 테스트 리팩토링

> test-data.test.ts 기반 실행기(Runner) 스타일 TDD 패턴

---

## 파일 구조

```
api/src/modules/[모듈명]/test/[모듈명].test.ts
```

## 참조 템플릿

`api/src/modules/test-data/test/test-data.test.ts`

---

## Import 패턴

```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import { Server } from '../../../../server';
import { [모듈명PascalCase]TddService } from '../service/[모듈명]-tdd.service';
import { [모듈명PascalCase]Service } from '../service/[모듈명].service';
```

---

## 테스트 구조 (실행기 스타일)

```typescript
describe('[모듈명] 통합 테스트', () => {
  // ==================== 서버 초기화 ====================
  beforeAll(async () => {
    Server.setEnv();
    await Server.externalModule();
  });

  // ==================== 통합 워크플로우 ====================
  it('통합 워크플로우', async () => {
    // 1. 초기화 (데이터 + 파일 생성)
    const createResult = await [모듈명PascalCase]TddService.init({
      value: 'TDD 테스트',
      subject: '테스트 제목',
      contents: '테스트 내용',
    });
    const [pk]Seq = createResult.[pk]Seq;
    expect([pk]Seq).toBeGreaterThan(0);
    console.log(`✅ 1. 초기화 완료: [pk]Seq=${[pk]Seq}`);

    // 2. 상세 조회 (file=Y: detailOne / file=N: findOne)
    const detail = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    expect(detail).toBeDefined();
    expect(detail.value).toBe('TDD 테스트');
    console.log(`✅ 2. 상세 조회 완료`);

    // 3. 목록 조회
    const list = await [모듈명PascalCase]Service.findList('TDD');
    expect(list.length).toBeGreaterThan(0);
    console.log(`✅ 3. 목록 조회 완료: ${list.length}건`);

    // 4. 페이징 조회
    const paging = await [모듈명PascalCase]Service.findPaging({
      keyword: 'TDD',
      isUse: '',
      startDate: '',
      endDate: '',
      sortBy: '[pk]Seq',
      sortType: 'desc',
      row: 10,
      page: 1,
    });
    expect(paging.data.length).toBeGreaterThan(0);
    expect(paging.totalRow).toBeGreaterThan(0);
    console.log(`✅ 4. 페이징 조회 완료: ${paging.totalRow}건`);

    // 5. 페이징 파라미터 테스트
    console.log('\n🔍 Step 5: 페이징 파라미터 테스트');

    // 5-A. 키워드 검색
    const keywordCases = ['', 'TDD', '테스트'];
    for (const keyword of keywordCases) {
      const result = await [모듈명PascalCase]Service.findPaging({
        keyword, isUse: '', startDate: '', endDate: '',
        sortBy: '[pk]Seq', sortType: 'desc', row: 10, page: 1,
      });
      expect(result.data).toBeDefined();
    }
    console.log('  ✅ 5-A. 키워드 검색 완료 (빈값/영문/한글)');

    // 5-B. 날짜 범위
    const dateResult = await [모듈명PascalCase]Service.findPaging({
      keyword: '', isUse: '', startDate: '2024-01-01', endDate: '2024-12-31',
      sortBy: '[pk]Seq', sortType: 'desc', row: 10, page: 1,
    });
    expect(dateResult.data).toBeDefined();
    console.log('  ✅ 5-B. 날짜 범위 완료');

    // 5-C. 정렬 옵션
    const sortCases = [
      { sortBy: '[pk]Seq', sortType: 'desc' as const },
      { sortBy: '[pk]Seq', sortType: 'asc' as const },
      { sortBy: 'insertDate', sortType: 'desc' as const },
    ];
    for (const { sortBy, sortType } of sortCases) {
      const result = await [모듈명PascalCase]Service.findPaging({
        keyword: '', isUse: '', startDate: '', endDate: '',
        sortBy, sortType, row: 10, page: 1,
      });
      expect(result.data).toBeDefined();
    }
    console.log('  ✅ 5-C. 정렬 옵션 완료 (PK desc/asc, 날짜 desc)');
    console.log(`✅ 5. 페이징 파라미터 테스트 완료`);

    // 6. 수정
    const updateResult = await [모듈명PascalCase]Service.update([pk]Seq, {
      value: 'TDD 수정',
      subject: '수정된 제목',
      contents: '수정된 내용',
      updateSeq: 1,
      fileUuidList: createResult.fileUuidList,
      imageUuidList: createResult.imageUuidList,
    });
    expect(updateResult).toBe(true);
    console.log(`✅ 6. 수정 완료`);

    // 7. 수정 확인
    const updated = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    expect(updated.value).toBe('TDD 수정');
    console.log(`✅ 7. 수정 확인 완료`);

    // 8. 비활성화
    await [모듈명PascalCase]Service.updateUse([pk]Seq, 'N', 1);
    const disabled = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    expect(disabled.isUse).toBe('N');
    console.log(`✅ 8. 비활성화 완료`);

    // 9. 활성화
    await [모듈명PascalCase]Service.updateUse([pk]Seq, 'Y', 1);
    const enabled = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    expect(enabled.isUse).toBe('Y');
    console.log(`✅ 9. 활성화 완료`);

    // 10. 소프트 삭제
    await [모듈명PascalCase]Service.softDelete([pk]Seq, 'Y', 1);
    const softDeleted = await [모듈명PascalCase]Service.detailOne([pk]Seq);
    expect(softDeleted.isDelete).toBe('Y');
    console.log(`✅ 10. 소프트 삭제 완료`);

    // 11. 정리 (하드 삭제 + 파일 삭제)
    await [모듈명PascalCase]TddService.cleanup([pk]Seq);
    console.log(`✅ 11. 정리 완료`);
  });
});
```

---

## file=N 버전 (파일 없음)

```typescript
describe('[모듈명] 통합 테스트', () => {
  beforeAll(async () => {
    Server.setEnv();
    await Server.externalModule();
  });

  it('통합 워크플로우', async () => {
    // 1. 등록
    const [pk]Seq = await [모듈명PascalCase]Service.insert({
      value: 'TDD 테스트',
      subject: '테스트 제목',
      contents: '테스트 내용',
      insertSeq: 1,
    });
    expect([pk]Seq).toBeGreaterThan(0);
    console.log(`✅ 1. 등록 완료: [pk]Seq=${[pk]Seq}`);

    // 2. 조회
    const data = await [모듈명PascalCase]Service.findOne([pk]Seq);
    expect(data).toBeDefined();
    expect(data!.value).toBe('TDD 테스트');
    console.log(`✅ 2. 조회 완료`);

    // 3-9. 동일한 CRUD 테스트...

    // 10. 정리
    await [모듈명PascalCase]Service.hardDelete([pk]Seq);
    console.log(`✅ 10. 정리 완료`);
  });
});
```

---

## 핵심 패턴

### 1. 서버 초기화 (beforeAll)

```typescript
beforeAll(async () => {
  Server.setEnv();        // 환경변수 설정
  await Server.externalModule();  // DB 연결 등 외부 모듈 초기화
});
```

### 2. 단일 통합 테스트 (Runner 스타일)

```typescript
// ❌ 잘못된 패턴: 분리된 테스트
it('등록', async () => { ... });
it('조회', async () => { ... });
it('수정', async () => { ... });

// ✅ 올바른 패턴: 통합 워크플로우
it('통합 워크플로우', async () => {
  // 1. 등록 → 2. 조회 → 3. 수정 → ... → N. 정리
});
```

### 3. 진행 상황 로깅

```typescript
console.log(`✅ 1. 등록 완료: [pk]Seq=${[pk]Seq}`);
```

### 4. TddService 활용 (file=Y)

```typescript
// 초기화: 테스트 데이터 + 파일 생성
const result = await [모듈명PascalCase]TddService.init(customParams);

// 정리: 하드 삭제 + 업로드 파일 삭제
await [모듈명PascalCase]TddService.cleanup([pk]Seq);
```

---

## 체크리스트

- [ ] describe('[모듈명] 통합 테스트') 구조
- [ ] beforeAll - Server.setEnv() + Server.externalModule()
- [ ] it('통합 워크플로우') - 실행기 스타일 단일 테스트
  - [ ] 1. 초기화 (TddService.init)
  - [ ] 2. 상세 조회 (detailOne/findOne)
  - [ ] 3. 목록 조회 (findList)
  - [ ] 4. 페이징 조회 (findPaging)
  - [ ] 5. 페이징 파라미터 테스트 (키워드/날짜/정렬)
  - [ ] 6. 수정 (update)
  - [ ] 7. 수정 확인
  - [ ] 8. 비활성화 (updateUse N)
  - [ ] 9. 활성화 (updateUse Y)
  - [ ] 10. 소프트 삭제 (softDelete)
  - [ ] 11. 정리 (TddService.cleanup)
- [ ] 진행 로그: console.log(`✅ N. 단계명`)

---

## 패턴 규칙

- 실제 DB 사용 (모킹 금지)
- 단일 통합 테스트로 전체 워크플로우 검증
- 테스트 데이터는 TDD 전용 (실제 데이터 영향 없음)
- TddService로 초기화/정리 처리 (file=Y)
- Service 직접 호출 (API 호출 아님)

---

## 테스트 실행

```bash
# 단일 모듈 테스트
cd api && bun test src/modules/[모듈명]/test/

# 전체 테스트
cd api && bun test
```
