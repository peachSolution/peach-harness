# 섹션 4. AI 자율성 허용 범위 (Bounded Autonomy)

> AGENTS.md 섹션 4 소스 — 가이드 코드가 말 못하는 것만

### Must Follow (절대 준수)
- 모듈 경계 (`_common`만 import, 다른 도메인의 Store/타입 금지. 단, _common 컴포넌트 및 타 모듈 모달 호출은 허용)
- 네이밍 규칙 (snake_case / kebab-case / PascalCase / camelCase)
- 타입 원칙 (옵셔널/null/undefined 금지)
- 보안 규칙 (XSS, OWASP top 10 방지)
- Mock 모드 원칙 (Store 경유 API 호출, Mock interceptor 사용)
- 테스트/lint/build 통과

### May Adapt (분석 후 보완 가능)
- Store 메서드 분리 방식
- UI 상호작용 흐름
- 컴포넌트 분리/배치 구조
- Mock 데이터 설계
