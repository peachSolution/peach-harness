# Runtime Adapter

`peach-team-e2e`는 Claude Code 팀 기능이 있으면 team mode로 실행하고, 없으면 generic mode로 실행한다. 두 모드 모두 검증 기준 로드, 시나리오 분할, suite 실행, 미스매치 분류, 보완 루프를 수행한다.

## 모드 선택

| 런타임 | 실행 모드 | 처리 |
|------|-----------|------|
| Claude Code + TeamCreate/TaskCreate/SendMessage 사용 가능 | Claude team mode | E2E 역할별 팀 생성과 SendMessage 조율 |
| Codex 또는 일반 skills.sh 소비자 | generic mode | 오케스트레이터가 시나리오 작성/검증/suite 실행을 순차 수행 |
| Claude Code지만 팀 기능 비활성 | 사용자에게 team mode 활성화 안내 후 generic mode 가능 여부 확인 |

## Claude team mode

```text
TeamCreate
TaskCreate
SendMessage
TaskUpdate
QA worktree isolation
```

기존 `e2e-scenario-dev`, `e2e-scenario-qa`, `e2e-suite-dev`, `e2e-suite-qa` 역할을 분리해 실행한다.

## Generic mode

Claude 전용 팀 도구를 사용하지 않는다.

```text
1. 검증 기준을 로드한다.
2. 오케스트레이터가 단위 시나리오를 작성한다.
3. 같은 기준으로 시나리오 QA 체크리스트를 수행한다.
4. 통합 suite를 작성하고 실행한다.
5. 실패를 미스매치 분류 기준으로 나눈다.
6. 시나리오 오류는 직접 수정하고, 코드 문제는 `peach-team-dev`로 넘긴다.
```

Generic mode에서는 `SendMessage` 대신 현재 세션의 실행 이력과 보고서에 역할별 결과를 남긴다.

## 공통 게이트

- `./e2e.sh status`로 탭 목록을 확인한다.
- 사용자가 실행 탭을 지정하기 전에는 실제 브라우저 실행을 시작하지 않는다.
- 로그인/OAuth/결제/관리자 콘솔처럼 세션 유지가 중요한 작업은 실제 실행 전 사용자 확인을 받는다.
- OS 레벨 브라우저 우회는 하지 않는다.
