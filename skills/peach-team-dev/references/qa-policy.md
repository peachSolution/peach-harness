# QA 판정과 완료 정책

`peach-team-dev`의 QA 판정, Ralph Loop, 완료 보고 기준이다.

## 판정

QA 에이전트는 `APPROVED / CONDITIONAL / REJECTED` 3단계로 보고한다.

| 판정 | 처리 |
|------|------|
| `APPROVED` | `/peach-qa-gate` 실행 후 완료 처리 |
| `CONDITIONAL` | 자동 수용 조건이면 오케스트레이터가 근거를 기록하고 진행한다. 기준 충돌/정책 판단이면 사용자 확인으로 올린다 |
| `REJECTED` | Ralph Loop로 dev 에이전트 수정 후 QA 재검증 |

`CONDITIONAL`은 Ralph Loop가 아니다. QA는 조건 항목과 `REJECTED`가 아닌 이유를 함께 보고해야 한다.

## CONDITIONAL 자동 처리 기준

자동 수용 가능:

- test/lint/build가 통과했다.
- Must Follow 위반이 없다.
- Spec `TEST_ID` 기준 완료 여부에 영향이 없다.
- 공통 모듈, DB 구조, 권한 정책을 바꾸지 않는다.
- 잔여 리스크가 E2E 또는 후속 작업으로 명확히 이관 가능하다.

사용자 확인 필요:

- Spec과 ui-proto가 충돌한다.
- PRD에는 있으나 Spec에 없는 요구가 발견됐다.
- 권한, 데이터 소유 범위, 상태 전이 해석이 필요하다.
- DB schema, 공통 상수, 공통 컴포넌트 변경이 필요하다.
- `DB_CHANGE_REQUIRED`가 발생해 컬럼/인덱스/상태값 변경이 필요하다.
- Contract Gate 실패를 구조 변경 없이 해결할 수 없다.
- 반복 실패로 자동 보완 신뢰도가 낮아졌다.

## Ralph Loop

| 반복 횟수 | 단계 | 행동 |
|----------|------|------|
| 1~3회 | 자율 수정 | QA 피드백만으로 코드 수정 |
| 4회 | 가이드 재참조 | test-data 기준골격 재확인 |
| 5~7회 | 독립 진단 | `codex:codex-rescue` 사용 가능 시 실패 원인 진단 |
| 8~10회 | 최소 수정 | Must Follow 항목만 집중 |
| 11+ | 중단 | 사용자 에스컬레이션 |

prompt 모드는 검증 기준이 약하므로 5회를 상한으로 둔다. 초과 시 Spec 작성을 권고하고 중단한다.

## 완료

모든 QA가 `APPROVED`가 된 뒤 `/peach-qa-gate`를 실행한다. 게이트가 실패하면 해당 항목을 수정하고 재실행한다.

완료 보고에는 다음을 포함한다.

- 모듈명, mode, proto 경로와 Spec 사본 경로
- queue 모드인 경우 기능별 상태(`pending/running/qa_failed/blocked/done`)와 재시도 횟수
- 실행한 dev/qa 에이전트와 검증 결과
- 생성/수정 파일 목록
- `mode=backend|fullstack`에서 사용한 DB 스키마 기준
- proto 사용 시 ui-proto/Spec 반영 범위
- Spec `TEST_ID`와 구현 상태(`I01/I02/I03/I90`) 매핑, 상태 요약 재계산 결과
- API-Store Contract Gate 결과 (`통과/실패/스킵` + 사유)
- `DB_CHANGE_REQUIRED` 발생 여부와 blocked 기능 목록
- `PRD_TO_SPEC_REQUIRED` 발생 여부와 blocked 기능 목록
- Spec-only 모드라면 UI Proto 부재로 인한 화면/E2E 검증 한계
- E2E로 넘길 잔여 리스크와 검증 불가 항목
- E2E가 필요한 경우 `/peach-team-e2e proto=<경로>` 안내

prompt 모드 보고에는 원본 prompt, 판정 규모, 영향 범위, 검증 한계를 함께 적는다.
