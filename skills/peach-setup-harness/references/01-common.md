# 섹션 1. 공통 원칙

> AGENTS.md 섹션 1 소스 — 가이드 코드가 말 못하는 것만

- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지
- 타입 규칙: 옵셔널(`?`)/`null`/`undefined` 금지
- 가이드 코드: `api/src/modules/test-data/` · `front/src/modules/test-data/`

### 주석 원칙
- CRUD 보일러플레이트: 주석 불필요
- 비즈니스 로직 분기/조건: 왜 이 조건인지 주석 필수
- 매직넘버/하드코딩 상수: 근거 주석 필수
- 상태 전이/승인 흐름: 도메인 규칙 주석 필수
- 환경 제한 조건(prod 체크 등): 보안 의도 주석 필수
- 모듈 전체 설계 맥락은 주석 대신 `peach-gen-feature-docs`로 문서화

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블/칼럼 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.service.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |
