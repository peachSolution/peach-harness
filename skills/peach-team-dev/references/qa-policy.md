# QA 판정과 완료 정책

`peach-team-dev`의 QA 판정, Ralph Loop, 완료 보고 기준이다.

## 판정

QA 에이전트는 `APPROVED / CONDITIONAL / REJECTED` 3단계로 보고한다.

| 판정 | 처리 |
|------|------|
| `APPROVED` | `/peach-qa-gate` 실행 후 완료 처리 |
| `CONDITIONAL` | 오케스트레이터가 조건 수용/무시를 판단한다. 무시하면 근거를 최종 보고에 남긴다 |
| `REJECTED` | Ralph Loop로 dev 에이전트 수정 후 QA 재검증 |

`CONDITIONAL`은 Ralph Loop가 아니다. QA는 조건 항목과 `REJECTED`가 아닌 이유를 함께 보고해야 한다.

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
- 실행한 dev/qa 에이전트와 검증 결과
- 생성/수정 파일 목록
- `mode=backend|fullstack`에서 사용한 DB 스키마 기준
- proto 사용 시 ui-proto/Spec 반영 범위
- E2E가 필요한 경우 `/peach-team-e2e proto=<경로>` 안내

prompt 모드 보고에는 원본 prompt, 판정 규모, 영향 범위, 검증 한계를 함께 적는다.
