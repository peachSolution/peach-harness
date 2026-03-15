# UI Proto 공통 원칙

> peach-setup-ui-proto Source of Truth — Frontend-Only UI Proto 프로젝트 공통 원칙

## 기본 규칙
- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- Mock 모드: Backend API 없음, 모든 API는 Mock 데이터 반환

## 네이밍 컨벤션
| 대상 | 규칙 |
|------|------|
| 테이블/컬럼 | snake_case |
| 파일/폴더 | kebab-case |
| 클래스/타입 | PascalCase |
| 변수/함수 | camelCase |

## 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지

## 가이드 코드 위치
- Frontend: `src/modules/test-data/`
