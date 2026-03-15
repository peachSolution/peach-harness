# 공통 원칙

> peach-setup-harness Source of Truth — 모든 PeachSolution 프로젝트 공통 원칙

## 기본 규칙
- 응답 언어: **한국어**
- 독립 모듈: `_common`만 import 허용, 타 모듈 import 금지
- FK 없음: Foreign Key 제약조건 생성 금지

## 네이밍 컨벤션
| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블/컬럼 | snake_case | `user_info`, `test_data` |
| 파일/폴더 | kebab-case | `test-data/`, `user-info.service.ts` |
| 클래스/타입 | PascalCase | `TestData`, `UserInfoPagingDto` |
| 변수/함수 | camelCase | `findOne`, `listParams` |
| 상수/환경변수 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| URL 경로 | kebab-case | `/user-info`, `/test-data` |

## 타입 규칙
- 옵셔널(`?`) 금지
- `null` 타입 금지
- `undefined` 타입 금지

## 가이드 코드 위치
코드 생성 = **가이드 코드 참조** → 도메인 분석 → Bounded Autonomy 범위 내 적응
- Backend: `api/src/modules/test-data/`
- Frontend: `front/src/modules/test-data/`

---

## AI 자율성 허용 범위 (Bounded Autonomy)

### Must Follow (절대 준수)
- 모듈 경계 (`_common`만 import)
- 네이밍/타입 규칙
- 보안 규칙 (SQL injection, XSS, OWASP top 10 방지)
- 공통 에러 처리 원칙
- 테스트/lint/build 통과

### May Adapt (분석 후 보완 가능)
- service 메서드 분리 방식
- DAO 내부 쿼리 구성 세부 형태
- validator 구조의 세부 배치
- UI 상호작용 흐름

---

## 완전 독립 도메인

**"관리되는 독립성"** — 결합은 부채, 중복은 비용.

- 다른 도메인의 DAO/Service/타입 import 금지
- 필요한 모든 쿼리는 자체 DAO에 구현
