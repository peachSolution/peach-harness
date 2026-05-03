# API-Store Contract Gate

`peach-team-dev`가 E2E 이전에 Backend, Store, UI 연결 오류를 줄이기 위해 수행하는 게이트다.

## 적용 범위

| mode | 적용 |
|------|------|
| backend | Backend API와 Store 연결까지 확인 |
| fullstack | Backend, Store, UI 사용 필드까지 확인 |
| ui | 기존 Store와 UI 사용 필드만 확인 |

스킵은 backend-only처럼 UI가 없는 사유가 명확할 때만 허용한다.

## 확인 항목

| 항목 | 확인 내용 | 실패 시 |
|------|-----------|---------|
| Backend 타입 | `api/src/modules/[모듈]/type/` 응답 타입과 controller 반환 구조 일치 | backend-dev 재수정 |
| Store 타입 | `front/src/modules/[모듈]/type/`, store state/action 타입 일치 | store-dev 재수정 |
| 응답 키 | API 응답 키와 Store 변환/컴포넌트 사용 필드 일치 | store-dev 또는 ui-dev 재수정 |
| 페이지네이션 | `list/totalRow/page/limit` 등 프로젝트 규약 일치 | backend-dev/store-dev 재수정 |
| 에러 응답 | validator/service 에러와 UI 처리 방식 일치 | backend-dev/ui-dev 재수정 |
| 옵션 기능 | file/excel/external API가 Backend→Store→UI까지 연결됨 | 해당 레이어 재수정 |
| DB 변경 필요 | 구현에 필요한 컬럼/인덱스/상태값이 schema에 존재함 | `DB_CHANGE_REQUIRED` 작성 후 blocked |

## 보고 형식

```markdown
## API-Store Contract Gate

| 항목 | 결과 | 근거 |
|------|------|------|
| Backend 타입 | 통과/실패/스킵 | ... |
| Store 타입 | 통과/실패/스킵 | ... |
| 응답 키 | 통과/실패/스킵 | ... |
| 페이지네이션 | 통과/실패/스킵 | ... |
| 에러 응답 | 통과/실패/스킵 | ... |
| 옵션 기능 | 통과/실패/스킵 | ... |
| DB 변경 필요 | 없음/필요 | ... |
```

실패가 구조 변경 없이 해결 가능하면 해당 dev 역할로 재수정한다. DB, 권한, 공통 모듈 변경이 필요하면 자동 수정하지 않고 blocked로 분리한다.
