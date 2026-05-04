# Runtime Adapter

`peach-team-dev`는 Claude Code 팀 기능이 있으면 team mode로 실행하고, 없으면 generic mode로 실행한다. 두 모드 모두 같은 입력, 같은 완료 기준, 같은 QA 정책을 사용한다.

## 모드 선택

| 런타임 | 실행 모드 | 처리 |
|------|-----------|------|
| Claude Code + TeamCreate/TaskCreate/SendMessage 사용 가능 | Claude team mode | 팀 생성, 역할별 task 등록, SendMessage 기반 조율 |
| Codex 또는 일반 skills.sh 소비자 | generic mode | 오케스트레이터가 역할 큐를 순차/제한 병렬로 직접 수행 |
| Claude Code지만 팀 기능 비활성 | 사용자에게 team mode 활성화 안내 후 generic mode 가능 여부 확인 |

## Claude team mode

기존 절차를 그대로 사용한다.

```text
TeamCreate
TaskCreate
SendMessage
TaskUpdate
QA worktree isolation
```

QA 에이전트는 읽기전용과 worktree 격리를 유지한다.

## Generic mode

Claude 전용 팀 도구를 사용하지 않는다.

```text
1. 오케스트레이터가 역할 큐를 만든다.
2. backend-dev/store-dev/ui-dev 역할 지침을 필요한 순서대로 직접 적용한다.
3. QA 역할은 같은 세션에서 독립 체크리스트로 수행한다.
4. 가능한 경우 별도 worktree 또는 별도 검증 명령으로 확증 편향을 줄인다.
5. REJECTED면 같은 Ralph Loop 정책으로 수정하고 재검증한다.
```

Generic mode에서는 `SendMessage` 대신 현재 세션의 작업 기록에 역할별 결과를 남긴다.

## 역할 큐

| mode | 실행 순서 |
|------|-----------|
| backend | backend-dev → backend-qa → store-dev → frontend-qa |
| ui | ui-dev → frontend-qa |
| fullstack | backend-dev → backend-qa + store-dev → ui-dev → frontend-qa |
| prompt 소규모 | 영향 범위에 맞는 dev 역할 1개 → 대응 QA |

병렬 실행이 가능한 런타임이면 backend-dev 완료 후 backend-qa와 store-dev를 병렬로 실행할 수 있다. 병렬 실행이 불가하면 순차 실행한다.

## 공통 완료 기준

- TDD/lint/build를 실제 명령으로 확인한다.
- `mode=backend|fullstack`은 Contract Gate 결과를 남긴다.
- Spec TEST_ID 구현 상태(`I01/I02/I03/I90`) 매핑을 남긴다.
- blocked 항목은 `PRD_TO_SPEC_REQUIRED`, `DB_CHANGE_REQUIRED`, `DECISION_REQUIRED` 등으로 분리한다.
- E2E가 필요한 잔여 리스크를 `peach-team-e2e`로 넘긴다.
