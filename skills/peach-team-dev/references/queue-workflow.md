# 기능 큐 워크플로우

대규모 작업에서 여러 기능을 한 번에 밀어 넣지 않고, 기능별 입력과 상태를 분리해 장시간 자율 개발 중 누락을 줄이는 운영 기준이다.

## 적용 기준

기능 큐는 모든 작업의 필수 산출물이 아니다. 아래 조건 중 하나 이상이면 사용한다.

- Spec 또는 PRD 안에 독립 기능이 3개 이상이다.
- Backend, Store, UI, E2E 잔여 리스크가 기능별로 갈라진다.
- 한 기능 실패가 다른 기능 완료를 막지 않도록 분리해야 한다.
- Ralph Loop 재시도 대상과 blocked 대상을 명확히 남겨야 한다.

단일 파일 수정, 작은 버그 수정, 단순 CRUD는 완료 보고에 요약만 남기고 큐 파일은 만들지 않는다.

## 큐 파일 위치

```text
docs/qa/{년}/{월}/{작업명}-team-dev-status.md
```

## 필수 섹션

```markdown
# {작업명} team-dev 상태

## 실행 기준

| 항목 | 값 |
|------|----|
| Spec | docs/spec/... |
| schema | api/db/schema/... |
| proto | src/modules-task/... 또는 - |
| mode | backend / ui / fullstack |
| 시작일 | YYYY-MM-DD |

## 사용자 요약 상태

| 상태 | 개수 | 기준 |
|------|------|------|
| 미구현 | 0 | 아직 구현 시작 전 |
| 구현중 | 0 | 일부 레이어 구현 또는 QA 실패 |
| 구현완료 | 0 | team-dev 책임 검증 통과 |
| 차단 | 0 | Spec/schema/권한/DB 결정 필요 |

## 기능 큐

| feature_id | 관련 TEST_ID | 입력 | mode | status | retry_count | evidence | blocked_reason | next_skill |
|------------|--------------|------|------|--------|-------------|----------|----------------|------------|
| F-001 | T-001,T-002 | Spec 섹션 / schema / proto 화면 | backend | pending | 0 | - | - | - |

## Contract Gate

| feature_id | API | Store | UI | 결과 | 근거 |
|------------|-----|-------|----|------|------|
| F-001 | - | - | - | 미실행 | - |

## E2E 인계

| feature_id | 관련 TEST_ID | E2E 잔여 리스크 | 권장 검증 | 비고 |
|------------|--------------|----------------|-----------|------|
| F-001 | T-001 | - | peach-team-e2e | - |
```

## 상태 매핑

| 큐 status | 사용자 요약 | Spec 구현 상태 | 기준 |
|-----------|-------------|----------------|------|
| pending | 미구현 | I01 구현전(TODO) | 구현 시작 전 |
| running | 구현중 | I02 일부구현(PARTIAL) | 구현 진행 중 |
| qa_failed | 구현중 | I02 일부구현(PARTIAL) | TDD/lint/build/Contract Gate 실패 |
| blocked | 차단 | I90 차단(BLOCKED) | 결정 또는 기준 부족으로 진행 불가 |
| done | 구현완료 | I03 구현완료(DONE) | team-dev 책임 검증 통과 |

사용자 보고에는 `미구현/구현중/구현완료/차단`을 우선 쓰고, `Ixx` 코드는 Spec 상세 표와 근거 보고에만 병기한다.

## 갱신 규칙

- 기능 하나를 시작할 때 `status=running`으로 바꾼다.
- 실패한 기능만 `qa_failed`로 두고 `retry_count`와 실패 근거를 남긴다.
- 기준이 모호하면 추측 구현하지 않고 `blocked`와 `blocked_reason`을 남긴다.
- 기능이 끝나면 `evidence`에 테스트, lint, build, Contract Gate 근거를 적는다.
- Spec의 `TEST_ID별 상태` 표가 있으면 구현 상태 축만 갱신한다.
- `TEST_ID별 상태` 표를 갱신하면 Spec의 `상태 요약`도 같은 집계 규칙으로 재계산한다.
- E2E 최종 통과 여부는 기록하지 않는다. `peach-team-e2e`가 검증 상태 축으로 갱신한다.

## E2E 위임 수신 기록

`peach-team-e2e`가 코드 문제를 `team-dev`로 위임하면 같은 상태 파일에 아래 섹션을 추가한다.

```markdown
## E2E 위임 수신 이력

| delegated_at | feature_id | 관련 TEST_ID | 문제 분류 | 수정 상태 | 수정 근거 | 재검증 요청 |
|--------------|------------|--------------|-----------|-----------|-----------|-------------|
| YYYY-MM-DD | F-001 | T-001 | Spec 위반 / proto 불일치 | pending | - | peach-team-e2e |
```

위임 수신 후 수정이 끝나면 해당 기능의 `evidence`와 `E2E 위임 수신 이력`을 함께 갱신하고, 재검증은 `peach-team-e2e`로 넘긴다.
