# 섹션 1. 공통 원칙

> AGENTS.md 섹션 1 소스 — 가이드 코드가 말 못하는 것만

- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- Mock 모드: Backend API 없음, 모든 API는 Mock 데이터 반환
- 가이드 코드: `src/modules/test-data/`

### 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블/칼럼 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.store.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |

### 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지
