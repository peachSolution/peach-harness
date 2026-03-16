# 섹션 2. 백엔드 규칙 — Elysia

> AGENTS.md 섹션 2 소스 — Elysia 프로젝트용

기술 스택: Bun · Elysia · bunqldb · TypeBox(`t`) · Biome

→ 가이드 코드 `api/src/modules/test-data/` 참조

**추론 불가 규칙:**
- Plugin System: `response.plugin.ts`가 성공 응답 자동 래핑 → Controller에서 try-catch 금지, 수동 success 래핑 금지
- 에러: `throw new ErrorHandler(상태코드, '메시지')` 만 사용
- 모든 엔드포인트: `docs/[module].docs.ts`로 API 문서화 필수
- 환경변수: `process.env.*` 사용 (`Bun.env.*` 금지)
- Bun Native API 우선: 파일은 `Bun.write/Bun.file`, 암호화는 `Bun.password.*`
- DB PK: `int auto_increment`, 접미사 `seq`
- DB 감사 칼럼: `is_use`, `is_delete`, `insert_seq`, `insert_date`, `update_seq`, `update_date`
- 소프트 삭제: `is_delete` 컬럼
- 로그: 비즈니스 로직에서 info 로깅 금지, `ErrorHandler`만 사용
- 완전 독립 도메인: 다른 도메인의 DAO/Service/타입 import 금지

인터페이스 명명: `[테이블명]`, `[테이블명]PagingDto`, `[테이블명]InsertDto`, `[테이블명]UpdateDto`
필드 배치 순서: 비즈니스 필드 → 감사 필드 → 파일 필드

품질 검증: `bun test && bun run build && bun run lint:fixed`
DB 명령: `bun run db:up-dev` · `bun run db:down-dev` · `bun run db:extract-schema`
