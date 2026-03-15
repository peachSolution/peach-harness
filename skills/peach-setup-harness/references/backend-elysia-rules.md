# Elysia 전용 백엔드 규칙

> peach-setup-harness Source of Truth — Elysia 프레임워크 프로젝트 전용 규칙
> 감지 조건: `head -3 api/src/modules/test-data/controller/test-data.controller.ts` 에서 `elysia` 또는 `createElysia` 확인 시 적용

## 기술 스택 (Elysia)
- **런타임**: Bun · **프레임워크**: Elysia · **ORM**: bunqldb · **린트**: Biome

## 모듈 구조 (Elysia 추가)
→ `api/src/modules/test-data/` 참조
- controller/ · service/ · dao/ · **docs/** · type/ · test/

## Plugin System (핵심 — 추론 불가)
- **response.plugin.ts**: 성공 응답 자동 래핑 `{ success: true, content: 원본응답 }`
- **error.plugin.ts**: ErrorHandler를 HTTP 상태코드로 자동 변환
- **auth.plugin.ts**: JWT 토큰 기반 인증/인가

**금지 사항:**
- 컨트롤러에서 try-catch 사용 금지
- 수동 success 래핑 금지

→ `api/src/modules/test-data/controller/test-data.controller.ts` 패턴 참조

## Error Handling
→ `ErrorHandler(상태코드, '메시지')` 형식으로 throw
- 400 잘못된 요청 · 401 인증 실패 · 403 권한 없음 · 404 리소스 없음 · 409 충돌

## Authentication Pattern
→ `api/src/plugins/auth.plugin.ts` 및 test-data controller 참조
- `{ user }: AuthContext` 파라미터, `auth: true` 옵션 필수

## 환경변수 규칙
- `process.env.*` 사용 (`Bun.env.*` 금지)

## Bun Native API 우선
- 파일: `Bun.write()` / `Bun.file()`
- 암호화: `Bun.password.hash()` / `Bun.password.verify()`

## API 문서화 (docs/ 필수)
→ `api/src/modules/test-data/docs/test-data.docs.ts` 참조
- 모든 엔드포인트에 `detail: docs.엔드포인트명` 필수

## 로깅 규칙
- 비즈니스 로직에서 info 로깅 금지, ErrorHandler만 사용

## DB 규칙 (Elysia)
- PK: `int auto_increment`, 접미사 `seq`
- 소프트 삭제: `is_delete` 컬럼
- 날짜: `default CURRENT_TIMESTAMP`

## 품질 검증
```bash
bun test && bun run build && bun run lint:fixed
```
