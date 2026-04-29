# 섹션 5. AI 자율성 허용 범위 (Bounded Autonomy)

> AGENTS.md 섹션 5 소스 — 가이드 코드가 말 못하는 것만

### Must Follow (절대 준수)
- 모듈 경계 (`_common`만 import, 타 모듈 금지)
- 네이밍 규칙 (snake_case / kebab-case / PascalCase / camelCase)
- 타입 원칙 (옵셔널/null/undefined 금지)
- 보안 규칙 (SQL injection, XSS, OWASP top 10 방지)
- 공통 에러 처리 원칙 (기능오류 → 200+success:false, 시스템예외 → ErrorHandler)
- 테스트/lint/build 통과

### May Adapt (분석 후 보완 가능)
- service 메서드 분리 방식
- DAO 내부 쿼리 구성 세부 형태
- validator 구조의 세부 배치
- UI 상호작용 흐름

### May Suggest (제안 후 사용자 확인)
- 모듈 내부 파일/디렉토리 구조 (service 분리, step별 분리)
- modules 분리 전략
- 트랜잭션 서비스 필요 여부
- _common 선택 구성

Suggest 조건:
1. 가이드코드 대비 이유를 설명
2. Must Follow 침범 금지
3. 사용자 확인 필수
