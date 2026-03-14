# Frontend TDD 테스트 패턴

> ⚠️ **사용 조건**: 이 패턴은 Store에 복잡한 클라이언트 로직이 있을 때만 사용합니다.

## 언제 이 패턴을 사용하는가?

| 조건 | TDD 필요 | TDD 불필요 |
|------|---------|-----------|
| Store가 단순 API Wrapper | ❌ | ✅ |
| 복잡한 계산 로직 | ✅ | ❌ |
| 여러 API 응답 조합 | ✅ | ❌ |
| 상태 변환 로직 | ✅ | ❌ |

> 💡 대부분의 Store는 API Wrapper이므로 **Backend TDD만으로 충분**합니다.

---

> test-data.test.ts 기반 Frontend 통합 테스트 (실행기 스타일)

---

## 파일 구조

```
front/src/modules/[모듈명]/test/[모듈명].test.ts
```

---

## Import 패턴

```typescript
import { describe, expect, it, afterAll, beforeAll } from 'vitest';
import { use[모듈명PascalCase]Store } from '@/modules/[모듈명]/store/[모듈명].store.ts';
import type { [모듈명PascalCase]PagingDto, [모듈명PascalCase]SearchDto } from '../type/[모듈명].type';
import { VitestSetup } from '@/utils/vitest-setup.ts';
```

---

## 테스트 구조 (14단계 실행기 스타일)

```typescript
/**
 * ============================================
 * 🚀 통합 [모듈명] 실행기 (Frontend Unified Runner)
 * ============================================
 *
 * 📋 용도: 프론트엔드 [모듈명] 모든 기능을 통합하여 실행하고 검증
 * 🔄 흐름: Backend TDD 패턴과 완전 동기화된 통합 워크플로우
 *
 * 실행 명령어:
 * npx vitest run src/modules/[모듈명]/test/[모듈명].test.ts
 */

/**
 * 📋 테스트 데이터 정의 (Backend 패턴 동기화)
 */
const TEST_DATA = {
  init: {
    value: 'Runner테스트',
    subject: 'Runner실행기',
    contents: 'CRUD 전체 생명주기 테스트',
    bigint: '999',
    decimal: '123.45',
  },
  update: {
    subject: 'Runner실행기_수정완료',
    contents: '수정된 내용입니다',
  },
} as const;

/**
 * [모듈명] 통합 실행기 (Frontend) - Backend TDD 패턴 완전 동기화
 */
describe('[모듈명] 통합 테스트 (CRUD + 파일 처리)', () => {
  let [모듈명]Store: ReturnType<typeof use[모듈명PascalCase]Store>;

  // 테스트 시작 전 환경 설정
  beforeAll(async () => {
    await VitestSetup.initializeTestEnvironment();
    await VitestSetup.sign();
    [모듈명]Store = use[모듈명PascalCase]Store();
  }, 30000);

  // 테스트 종료 후 정리
  afterAll(async () => {
    // Vitest는 자동으로 환경 정리
  });

  /**
   * 🚀 통합 워크플로우: 파일 생성 → CRUD 전체 라이프사이클 → 파일 수정 → 삭제
   */
  it('통합 워크플로우: 파일 생성 → CRUD → 파일 수정 → 삭제', async () => {
    let [pk]Seq = 0;
    let fileUuidList: string[] = [];
    let imageUuidList: string[] = [];

    console.log('\n🚀 ======= 통합 테스트 시작 (Backend 패턴 동기화) =======');

    try {
      // ==================== 1. TDD 데이터 생성 (파일 포함) ====================
      console.log('\n📁 Step 1: TDD 데이터 생성 (Backend에서 자동 생성)');
      const createResult = await [모듈명]Store.initTdd(TEST_DATA.init);

      [pk]Seq = createResult.[pk]Seq;
      fileUuidList = createResult.fileUuidList;
      imageUuidList = createResult.imageUuidList;

      expect([pk]Seq).toBeGreaterThan(0);
      console.log(`✅ 1. 데이터 생성 완료 - [pk]Seq: ${[pk]Seq}`);

      // ==================== 2. 상세 조회 (파일 연결 확인) ====================
      console.log('\n🔍 Step 2: 상세 조회 (파일 포함)');
      await [모듈명]Store.detail([pk]Seq);
      const detailResult = [모듈명]Store.detailData;
      expect(detailResult).toBeDefined();
      expect(detailResult.isUse).toBe('Y');
      console.log(`✅ 2. 상세 조회 완료`);

      // ==================== 3. 데이터 수정 ====================
      console.log('\n✏️ Step 3: 데이터 수정');
      const updateResult = await [모듈명]Store.update([pk]Seq, {
        value: TEST_DATA.init.value,
        subject: TEST_DATA.update.subject,
        contents: TEST_DATA.update.contents,
        bigint: 777,
        fileUuidList,
        imageUuidList
      });
      expect(updateResult.isSuccess).toBe(true);
      console.log(`✅ 3. 데이터 수정 완료`);

      // ==================== 4. 사용여부 변경 ====================
      console.log('\n🔄 Step 4: 사용여부 변경');
      const updateUseResult = await [모듈명]Store.updateUse([pk]Seq, 'N');
      expect(updateUseResult.isSuccess).toBe(true);

      await [모듈명]Store.detail([pk]Seq);
      expect([모듈명]Store.detailData.isUse).toBe('N');
      console.log('✅ 4. 사용여부 변경 완료 - isUse: N');

      // ==================== 5. 리스트 조회 ====================
      console.log('\n📊 Step 5: 리스트 조회');
      const searchParams: [모듈명PascalCase]SearchDto = {
        startDate: '2022-01-01',
        endDate: '2025-12-31',
        keyword: TEST_DATA.update.subject,
        opt: '',
        isUse: '',
        selected: ''
      };
      const listResult = await [모듈명]Store.list(searchParams);
      expect(Array.isArray(listResult)).toBe(true);
      console.log(`✅ 5. 리스트 조회 완료 - ${listResult.length}건`);

      // ==================== 6. 페이징 조회 ====================
      console.log('\n📄 Step 6: 페이징 조회');
      const pagingParams: [모듈명PascalCase]PagingDto = {
        ...searchParams,
        sortBy: '[pk]Seq',
        sortType: 'desc',
        sortData: '[pk]Seq,desc',
        row: 10,
        page: 1,
        time: new Date().getTime().toString()
      };
      await [모듈명]Store.paging(pagingParams);
      expect(Array.isArray([모듈명]Store.listData)).toBe(true);
      console.log(`✅ 6. 페이징 조회 완료 - ${[모듈명]Store.listData.length}건`);

      // ==================== 7-A. 커서 조회 ====================
      console.log('\n🔄 Step 7-A: 커서 조회');
      const cursorResult = await [모듈명]Store.cursorList({
        keyword: TEST_DATA.update.subject,
        limit: 2
      });
      expect(cursorResult).toHaveProperty('data');
      expect(cursorResult).toHaveProperty('nextCursor');
      console.log(`✅ 7-A. 커서 조회 완료 - ${cursorResult.data.length}건`);

      // ==================== 7-B. nextCursor 페이징 ====================
      if (cursorResult.nextCursor) {
        console.log('\n🔄 Step 7-B: nextCursor 페이징');
        const nextPage = await [모듈명]Store.cursorList({
          keyword: TEST_DATA.update.subject,
          limit: 2,
          cursor: cursorResult.nextCursor
        });
        console.log(`✅ 7-B. nextCursor 페이징 완료 - ${nextPage.data.length}건`);
      }

      // ==================== 8-11. 파일 업로드/수정 테스트 (file=Y) ====================
      // (file=Y인 경우에만 포함)

      // ==================== 12. 논리적 삭제 ====================
      console.log('\n🗑️ Step 12: 논리적 삭제');
      const softDeleteResult = await [모듈명]Store.softDelete([pk]Seq);
      expect(softDeleteResult.isSuccess).toBe(true);

      await [모듈명]Store.detail([pk]Seq);
      expect([모듈명]Store.detailData.isDelete).toBe('Y');
      console.log('✅ 12. 논리 삭제 완료 - isDelete: Y');

      // ==================== 13. TDD 물리 삭제 ====================
      console.log('\n💥 Step 13: TDD 물리 삭제 (데이터 + 파일)');
      const deleteResult = await [모듈명]Store.cleanupTdd([pk]Seq);
      expect(deleteResult.isSuccess).toBe(true);
      console.log('✅ 13. 데이터 + 파일 물리 삭제 완료');

      // ==================== 14. 삭제 확인 ====================
      console.log('\n✅ Step 14: 삭제 확인');
      try {
        await [모듈명]Store.detail([pk]Seq);
        console.log('⚠️ 삭제된 데이터가 조회됨 (예상과 다름)');
      } catch {
        console.log('✅ 14. 삭제 확인 완료 (데이터 조회 불가) ✓');
      }

      console.log('\n🎉 ======= 통합 테스트 완료 =======');
    } catch (error) {
      console.error(`\n❌ 통합 테스트 실패: ${error}`);
      throw error;
    } finally {
      // 예외 발생 시 정리
      if ([pk]Seq > 0) {
        console.log('\n🧹 예외 발생 시 데이터 정리');
        try {
          await [모듈명]Store.cleanupTdd([pk]Seq);
          console.log(`✅ 테스트 데이터 정리 완료 - [pk]Seq: ${[pk]Seq}`);
        } catch {
          console.log('정리 불필요 (이미 삭제됨)');
        }
      }
    }
  }, 60000);
});
```

---

## 핵심 패턴

### 1. VitestSetup 초기화

```typescript
beforeAll(async () => {
  await VitestSetup.initializeTestEnvironment();  // 환경 초기화
  await VitestSetup.sign();                        // 로그인 (인증 토큰)
  store = useStore();                              // 스토어 인스턴스
}, 30000);
```

### 2. TDD 데이터 생명주기

```typescript
// 생성: Backend TDD API 호출
const createResult = await store.initTdd(TEST_DATA.init);

// 정리: 물리 삭제 + 파일 삭제
await store.cleanupTdd([pk]Seq);
```

### 3. 단일 통합 테스트 (실행기 스타일)

```typescript
// ❌ 분리된 테스트 (사용 금지)
it('등록', async () => { ... });
it('조회', async () => { ... });

// ✅ 통합 워크플로우 (권장)
it('통합 워크플로우', async () => {
  // 1. 생성 → 2. 조회 → ... → N. 정리
});
```

### 4. 진행 상황 로깅

```typescript
console.log('\n📁 Step 1: TDD 데이터 생성');
// ... 작업 수행
console.log(`✅ 1. 데이터 생성 완료 - [pk]Seq: ${[pk]Seq}`);
```

### 5. finally 블록 정리

```typescript
finally {
  if ([pk]Seq > 0) {
    try {
      await store.cleanupTdd([pk]Seq);
    } catch {
      // 이미 삭제된 경우 무시
    }
  }
}
```

---

## 테스트 실행

```bash
# 단일 모듈 테스트
cd front && npx vitest run src/modules/[모듈명]/test/

# 전체 테스트
cd front && npx vitest run

# 감시 모드
cd front && npx vitest
```

---

## file=Y 추가 단계

file=Y인 경우 8-11단계 추가:

```typescript
// ==================== 8. 프론트에서 새 파일 업로드 ====================
const newFile = new File([new Blob(['test'])], 'test.txt', { type: 'text/plain' });
const uploadResult = await store.uploadFileLocal(false, newFile, () => {});
expect(uploadResult.fileUuid).toBeTruthy();

// ==================== 9. 프론트에서 새 이미지 업로드 ====================
// PNG 바이너리 생성 후 업로드

// ==================== 10. 데이터 수정 (파일 병합) ====================
const mergedFileUuidList = [...fileUuidList, uploadResult.fileUuid];
await store.update([pk]Seq, { ...updateDto, fileUuidList: mergedFileUuidList });

// ==================== 11. 상세 조회 (파일 수정 확인) ====================
await store.detail([pk]Seq);
expect(store.detailData.fileList.length).toBe(expectedCount);
```
