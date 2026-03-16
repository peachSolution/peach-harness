# 섹션 2. 백엔드 규칙 — Koa (routing-controllers)

> AGENTS.md 섹션 2 소스 — Koa 프로젝트용

기술 스택: Bun · Koa + routing-controllers · bunqldb · class-validator · Biome

→ 가이드 코드 `api/src/modules/test-data/` 참조

**추론 불가 규칙:**
- Service: static 메서드
- DB PK: `int` 자동증가, 접미사 `seq` (예: `member_seq`)
- DB 감사 칼럼: `is_use`, `is_delete`, `insert_seq`, `insert_date`, `update_seq`, `update_date`
- DB Boolean: `CHAR(1)` Y/N · 금액: `DECIMAL(14,0)`
- 에러: 기능오류 → HTTP 200 + `{success:false}` | 시스템예외 → `ErrorHandler`
- 파일 업로드: `_common/file` 사용
- 완전 독립 도메인: 다른 도메인의 DAO/Service/타입 import 금지

인터페이스 명명: `[테이블명]`, `[테이블명]PagingDto`, `[테이블명]InsertDto`, `[테이블명]UpdateDto`
필드 배치 순서: 비즈니스 필드 → 감사 필드 → 파일 필드

품질 검증: `bun start && bun test && bun run lint:fixed`
DB 명령: `bun run db:up-dev` · `bun run db:down-dev` · `bun run db:extract-schema`
