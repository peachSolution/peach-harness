# 테스트 및 품질

> peach-setup-harness Source of Truth — 대상 프로젝트 AGENTS.md의 테스트/품질 섹션 기준

## 기본 원칙
- 새로운 Service 로직: **bun test 기반 TDD** 테스트 포함
- 테스트는 실제 데이터베이스 사용, 모킹 금지
- **모든 테스트 100% 성공** 필수

---

## Backend 테스트 설정

→ `api/src/modules/test-data/test/test-data.test.ts` 참조

### Koa 프로젝트
```typescript
beforeAll(async () => {
  Server.setEnv();
  await Server.externalModule();  // await 필수
}, 30000);

afterAll(async () => {
  await DB.close();
}, 10000);
```

### Elysia 프로젝트
```typescript
beforeAll(() => {
  Server.setEnv();
  Server.externalModule();  // await 없음
});
```

테스트 항목: insert, findAll(findPaging), findById(findOne), update, softDelete/hardDelete

---

## Frontend 테스트 설정

→ `front/src/modules/test-data/` 테스트 파일 참조

```typescript
beforeAll(async () => {
  await VitestSetup.initializeTestEnvironment();
  await VitestSetup.sign('test', 'test!%#');
});
```

- API 숫자 타입 주의: `expect(result.isAdmin).toBe(1)` (boolean 혼동 금지)

---

## 품질 검증 명령어

### Backend
```bash
bun start && bun test && bun run lint:fixed
```

### Frontend
```bash
bun run dev && bun run test && bunx vue-tsc --noEmit && bun run lint:fix && bun run build
```
