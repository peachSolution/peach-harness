---
status: completed
target_skill: peach-e2e-browse
severity: 높음 1 / 중간 6 / 낮음 0
completed_at: 2026-04-14
applied_by: peach-team-3a (Architect→Builder→Reviewer)
---

# peach-e2e-browse 피드백 — 2026-04-14

> **대상 스킬**: peach-e2e-browse
> **연관 범위**: peach-e2e-setup / peach-e2e-browse / peach-e2e-run / peach-e2e-convert
> **작성 근거**: Chrome Beta CDP에 연결한 상태에서 주문 화면의 native alert/confirm 이 즉시 사라지는 문제, Gmail 홈 링크 전환 불안정, 시나리오 저장 규칙 점검을 함께 수행한 실전 장애 분석
> **심각도 요약**: 높음 1건 / 중간 6건 / 낮음 0건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | `agent-browser connect 9222` 이후 상주 daemon 이 브라우저 dialog 를 자동 dismiss 하여 사용자의 수동 검증을 방해 | 높음 | X | 115~121, 293~307 |
| 2 | 수동 검증으로 전환할 때 CDP 연결 해제/점검 절차가 없어 "탭만 새로 열어도 계속 alert 가 닫힘" 상황을 설명하지 못함 | 중간 | X | 62~70, 152~163 |
| 3 | 관련 시나리오에서 `window.alert/confirm` override 를 복구하지 않으면 같은 탭 재사용 시 오염이 남을 수 있다는 운용 규칙이 없음 | 중간 | X | peach-e2e-browse 기준 직접 언급 없음 |
| 4 | 시나리오 생성/저장 시 종료 템플릿과 저장 후 검증 절차가 약해 `process.exit(0)` 고정 종료, 전역 override 잔존, 저장만 되고 실행 불가한 파일이 생길 수 있음 | 중간 | X | 연관 스킬 문서 보완 필요 |
| 5 | 단순 조회 시나리오에 `page.on('dialog', dialog => dialog.accept())` 를 습관적으로 넣으면 실행 중 사용자의 수동 dialog 확인을 바로 깨뜨릴 수 있음 | 중간 | X | run/convert 계열 문서에 금지 규칙 없음 |
| 6 | `google.com → Gmail 링크 클릭` 같은 외부 사이트 전환은 CDP 환경에서 클릭 후 내비게이션이 멈추는 패턴이 있는데, 현재 기본 시나리오 생성 규칙엔 `load + 지연 + 직접 이동 fallback` 패턴이 없음 | 중간 | X | 연관 스킬 문서 보완 필요 |
| 7 | `--tab N` 인덱스는 사용자가 보는 탭과 실제 실행 탭이 어긋날 수 있어, 특정 URL 탭 재현 검증에는 `targetId` 우선 규칙이 필요함 | 중간 | X | browse/run 계열 문서 보완 필요 |

## 2. 해결 방법 / 우회 전략

### 문제 #1: agent-browser 상주 연결이 native dialog 를 닫아버림

**원인**: `agent-browser`가 내부적으로 Playwright 기반 daemon 을 띄워 CDP `9222`에 붙어 있는 동안, dialog handler 가 없는 페이지의 native `alert/confirm` 을 자동으로 닫는다. 이 상태에서는 웹앱 코드가 정상이어도 사용자는 "alert 가 잠깐 떴다가 사라진다"고 보게 된다.

**증거**:

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
ps -p 31204 -o pid,ppid,command=
```

실측 결과:

```text
node ... /agent-browser/dist/daemon.js
```

추가 근거:

```text
$HOME/.nvm/versions/node/v22.19.0/lib/node_modules/playwright-core/lib/server/dialog.js
```

위 파일의 `dialogDidOpen(...)` 분기에서 등록된 dialog handler 가 없으면 `dialog.close()`를 호출한다.

**해결**:

```bash
# 1. 9222에 붙어 있는 세션 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P

# 2. agent-browser daemon PID 확인
ps -p <PID> -o pid,ppid,command=

# 3. 수동 검증 전 daemon 종료
kill <PID>

# 4. 연결 해제 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
```

**결과**:
- 종료 전: `step1`의 `다음으로`, `order/input`의 `결제하기` 클릭 시 alert/confirm 이 즉시 닫힘
- 종료 후: 같은 화면에서 dialog 가 정상적으로 남아 사용자가 확인 가능
- 추가 검증: `1-주문등록` 시나리오를 다시 실행한 뒤에는 `lsof -iTCP:9222 -sTCP:ESTABLISHED` 결과가 비어 있었음. 따라서 "시나리오 종료 후에도 계속 alert 가 닫힘" 현상의 주원인은 시나리오보다 상주 daemon 이라고 보는 것이 맞다.

### 문제 #2: 탭만 바꿔도 증상이 유지되는 이유를 현재 스킬이 설명하지 못함

**원인**: 증상은 특정 탭 오염이 아니라 브라우저 프로세스에 붙은 CDP 세션 문제였다. 그래서 새로고침, 같은 URL 새 탭 열기만으로는 해결되지 않았다.

**해결**:

```bash
# 새 탭/새로고침 전에 먼저 연결 상태를 본다
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P

# 수동 검증이면 agent-browser 연결을 비운 뒤 브라우저에서 직접 클릭
kill <PID>
```

**운용 판단**:
- Chrome Beta 전체 재시작은 보통 불필요
- 우선순위는 `탭 새로 열기`가 아니라 `CDP 상주 세션 제거`

### 문제 #3: 시나리오도 dialog/override 원복이 없으면 같은 증상을 만들 수 있음

**원인**: 시나리오에서 `window.alert`, `window.confirm`, 전역 dialog listener 를 덮어쓴 뒤 원복하지 않으면 같은 탭을 재사용하는 수동 검증과 충돌할 수 있다.

**실전 보완 패턴**:

```javascript
let restoreDialogs = null;

try {
  restoreDialogs = await page.evaluate(() => {
    const originalAlert = window.alert;
    const originalConfirm = window.confirm;
    window.__dialogLogs = [];
    window.alert = (message) => {
      window.__dialogLogs.push({ type: 'alert', message: String(message) });
    };
    window.confirm = (message) => {
      window.__dialogLogs.push({ type: 'confirm', message: String(message) });
      return true;
    };
    return true;
  });

  // 시나리오 본문
} finally {
  await page.evaluate(() => {
    if (window.__originalAlert) window.alert = window.__originalAlert;
    if (window.__originalConfirm) window.confirm = window.__originalConfirm;
  }).catch(() => {});
}
```

**운용 판단**:
- native dialog 가 있는 화면은 지역 처리 후 반드시 원복
- `process.exit(0)` 고정 종료 금지
- `try/catch/finally + exitCode` 패턴으로 실패를 숨기지 말 것

### 문제 #5: `page.on('dialog', dialog.accept())` 는 조회형 시나리오에 기본 탑재하면 안 됨

**원인**: 아래 패턴은 시나리오 실행 중 발생하는 모든 dialog 를 즉시 확인 처리한다.

```javascript
const dialogHandler = async (dialog) => {
  try { await dialog.accept(); } catch (_) {}
};
page.on('dialog', dialogHandler);
```

이 코드는 테스트가 끝나기 전에 사용자가 같은 탭에서 수동으로 버튼을 눌러 dialog 를 확인하려는 경우에도 dialog 를 바로 닫는다.

**운용 판단**:
- 단순 조회 시나리오에는 전역 `page.on('dialog')` 를 넣지 않는 것이 맞다
- 정말 필요하면 특정 단계 전후로만 설치하고 반드시 `page.off('dialog', handler)` 로 해제해야 한다
- `window.alert/confirm` override 와 `page.on('dialog')` 는 둘 다 같은 증상을 만들 수 있으므로 하나만 써도 충분한지 먼저 판단해야 한다

### 문제 #6: Gmail 홈 링크 전환은 별도 안정화 패턴이 필요함

**원인**: `gmail-메일목록.js` 실전 검증에서 `google.com` 상단 `Gmail` 링크는 클릭 자체는 성공했지만, `waiting for scheduled navigations to finish` 단계에서 timeout 이 발생했다. 실제 탭 URL도 `https://www.google.com/` 에 남는 경우가 반복 확인됐다.

**실전 보완 패턴**:

```javascript
await page.goto('https://www.google.com');
await page.waitForLoadState('load');
await page.waitForTimeout(2000);

const gmailLink = page.locator('a[href*=\"mail.google.com\"]').first();
await gmailLink.waitFor({ state: 'visible', timeout: 5000 });
await gmailLink.click({ timeout: 5000, noWaitAfter: true });

await page.waitForTimeout(3000);

if (!page.url().includes('mail.google.com')) {
  await page.goto('https://mail.google.com/mail/u/0/#inbox');
}
```

**운용 판단**:
- 외부 사이트 홈 화면의 상단 링크 전환은 "클릭 성공"보다 "목표 URL 도달 성공" 기준으로 검증하는 게 맞다
- Google/Gmail 같은 서비스는 `load + 2초 지연 + 직접 이동 fallback` 패턴을 공통 레퍼런스로 승격할 가치가 있다

### 문제 #7: 특정 탭 재현 검증에는 `--tab N` 보다 `targetId` 가 우선

**원인**: 실제 검증에서 사용자는 `step1` 탭을 보고 있었지만, `--tab 3` 실행은 Jira 탭으로 연결되는 사례가 있었다. 인덱스는 CDP가 반환한 "현재 비-chrome 페이지 배열" 순서에 의존해 흔들릴 수 있다.

**실전 보완 패턴**:

```bash
curl -s http://127.0.0.1:9222/json | jq -r '.[] | select(.type=="page" and (.url|startswith("chrome")|not)) | [.id,.title,.url] | @tsv'

cd e2e
E2E_TAB_ID=<targetId> ./e2e.sh run '시나리오/대상.js'
```

**운용 판단**:
- "사용자가 이미 보고 있는 특정 URL 탭"을 재현해야 하는 검증은 `targetId` 우선이 맞다
- `--tab N` 은 빠른 일반 실행용으로 두고, 디버깅/재현/장애분석은 `E2E_TAB_ID` 를 우선 안내해야 한다

### 문제 #4: 시나리오 생성/저장 단계에서 안전 템플릿이 약함

**원인**: 실전에서는 "시나리오를 만들고 파일로 저장"하는 순간부터 품질이 갈린다. 생성 스킬이 codegen 결과를 저장만 하고 아래 규칙을 강제하지 않으면, 나중에 같은 탭 재사용 시 오염되거나 실패가 `0 종료`로 묻힌다.

**필수 템플릿 규칙**:

```javascript
let browser;
let exitCode = 0;

try {
  browser = await connect();
  const page = await browser.page();

  // 필요 시 여기서만 지역 dialog recorder 설치
} catch (error) {
  exitCode = 1;
  console.error(error);
} finally {
  if (browser) {
    await browser.close().catch(() => {});
  }
  process.exit(exitCode);
}
```

**저장 직후 자동 검증**:

```bash
node --check e2e/시나리오/대상시나리오.js
```

**dialog 가 있는 화면의 저장 규칙**:
- `window.alert/confirm` override 는 파일 전역이 아니라 특정 단계 직전에만 설치
- `finally` 에서 원복
- 상태 의존 액션은 클릭 전에 명시적으로 대기
  - 예: `window.json_data.pay_method === 'point'`

**운용 판단**:
- "생성"과 "저장"은 끝이 아니라 최소 문법 검증과 종료 규칙까지 포함해야 함
- `peach-e2e-convert`, `peach-e2e-run`, E2E 저장 레퍼런스가 같은 템플릿을 공유하는 쪽이 맞다

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

**추가 위치 1**: `115~121행` 바로 아래

추가 내용:

```md
> **중요: 수동 검증 전에 CDP 상주 세션을 비워야 할 수 있다.**
> agent-browser daemon 이 9222에 붙어 있으면 사이트의 native `alert/confirm/prompt` 가 자동으로 닫힐 수 있다.
> 사용자가 직접 버튼을 눌러 dialog 를 확인해야 하는 작업이면 아래 명령으로 연결 상태를 먼저 점검한다.

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
ps -p <PID> -o pid,ppid,command=
kill <PID>
```
```

**추가 위치 2**: `293~307행` 핵심 규칙 아래

추가 규칙:

```md
14. **수동 native dialog 검증 전에는 CDP 상주 세션 점검** -- `agent-browser` daemon 이 붙어 있으면 `alert/confirm` 이 즉시 닫힐 수 있다. 새 탭/새로고침보다 `lsof → ps → kill` 이 우선이다.
15. **dialog 를 가로챈 시나리오는 반드시 원복** -- `window.alert/confirm` override, 전역 dialog listener, 강제 dismiss 코드는 `finally`에서 해제한다.
```

### 3-2. references/ 추가/수정

**신규 문서 제안**: `references/native-dialog-주의사항.md`

핵심 내용:
- Playwright 계열 CDP 클라이언트가 native dialog 를 자동 dismiss 할 수 있는 이유
- `lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P` 로 연결 확인하는 방법
- `ps -p <PID> -o pid,ppid,command=` 로 `agent-browser/dist/daemon.js` 식별하는 방법
- 수동 검증 전 daemon 종료 순서
- 브라우저 재시작이 필요한 경우와 불필요한 경우 구분

### 3-3. 연관 스킬 전체 보완

`peach-e2e*` 계열 전체를 같이 점검하는 것이 맞다.

#### `peach-e2e-browse`

- 수동 native dialog 검증 전 `lsof → ps → kill` 안전절차 추가
- `agent-browser connect 9222` 가 상주 세션을 만든다는 점을 명시
- 사용자가 수동 클릭을 해야 하는 작업이면 CDP 상주 연결을 비우고 진행하도록 경고

#### `peach-e2e-run`

- native dialog 가 있는 시나리오는 지역 recorder 패턴 사용
- `window.alert/confirm` override 시 `finally` 에서 원복
- `page.on('dialog', dialog.accept())` 전역 자동 수락은 기본 템플릿에서 제외
- 전역 dialog handler 가 필요하면 특정 단계 전후로만 설치하고 `page.off('dialog', handler)` 로 반드시 해제
- 실패 시 `process.exit(1)` 로 종료하고 `0`으로 묻히지 않기
- 페이지 상태 의존 로직은 클릭 전에 명시적으로 대기하기
  - 예: 포인트 결제는 `window.json_data.pay_method === 'point'` 확인 후 결제 버튼 클릭
- Google/Gmail 같은 외부 서비스 진입은 `load + 2초 지연 + 직접 이동 fallback` 패턴을 샘플로 제공
- 특정 URL 탭 재현 검증은 `--tab N` 대신 `E2E_TAB_ID` 우선 예제를 제공

#### `peach-e2e-convert`

- 생성된 시나리오는 `connect()` 를 `try` 밖에 두지 말 것
- 기본 저장 템플릿을 `try/catch/finally + exitCode + browser.close().catch(() => {})` 로 고정
- 저장 직후 `node --check` 를 자동 실행하여 문법 오류를 바로 차단
- dialog, popup, overlay 제거 코드는 파일 전역 helper 로 두더라도 원복 루트를 반드시 포함
- 저장 완료 메시지에 "수동 검증 탭을 오염시킬 수 있는 코드가 남는지" 체크리스트 포함
- codegen 결과에 `page.on('dialog', ...)` 가 있으면 그대로 보존하지 말고, 지역 recorder 또는 단계별 handler 로 축소할지 검토
- 외부 사이트 링크 전환은 `click()` 한 줄로 끝내지 말고 fallback URL 도달 규칙을 같이 생성

#### `peach-e2e-setup`

- `agent-browser`, `playwright-core`, `playwright-cli` 의 역할 차이를 더 명확히 설명
- CDP 연결형 도구가 브라우저 수동 검증에 영향을 줄 수 있다는 점을 초기 세팅 단계에서 경고
- `e2e.sh setup` 완료 후 "수동 dialog 검증 전에는 상주 daemon 을 비워야 할 수 있음" 체크리스트 추가
- `targetId` 기반 탭 고정 실행 예제를 setup 문서에도 포함
- "단순 curl 조회 연결"과 "상주 daemon 연결"을 구분해 읽는 법을 짧게 추가

#### 공통 레퍼런스

- `references/native-dialog-주의사항.md` 를 공통 참조로 두고 각 peach-e2e* 스킬에서 링크
- 시나리오 저장 규칙, 종료 코드 규칙, dialog 원복 규칙을 중복 서술하지 말고 공통 문서로 승격
- `references/google-gmail-전환-패턴.md` 또는 일반화된 `references/외부서비스-링크전환-패턴.md` 를 추가해 `load + 지연 + fallback` 예시를 정리
- `references/탭-선택-패턴.md` 에 `--tab N` 과 `E2E_TAB_ID` 선택 기준을 분리

## 4. 검증 시나리오

### 시나리오 1: CDP 상주 연결이 alert 를 닫는지 재현

**목적**: 원인이 웹앱 코드가 아니라 상주 CDP 세션임을 재현
**전제**: Chrome Beta 가 `--remote-debugging-port=9222` 로 실행 중이고 사용자가 사이트에 로그인한 상태

```bash
# 단계 1: agent-browser 연결
agent-browser connect 9222
agent-browser tab list

# 단계 2: 9222 연결 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
```

브라우저에서 아래 중 하나를 수동 클릭:
- `http://local.example.com/{PROJECT}/order/step1?order_number=34820` 의 `다음으로`
- `http://local.example.com/{PROJECT}/order/input` 의 `결제하기`

**기대 결과**: alert/confirm 이 잠깐 보였다가 사라짐
**통과 기준**: 상주 세션 존재 + 수동 dialog 즉시 dismiss 재현

### 시나리오 2: daemon 종료 후 dialog 정상 유지 확인

**목적**: daemon 종료가 실제 해결책인지 검증

```bash
# 단계 1: PID 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
ps -p <PID> -o pid,ppid,command=

# 단계 2: daemon 종료
kill <PID>

# 단계 3: 연결 해제 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
```

같은 버튼을 다시 수동 클릭한다.

**기대 결과**: alert/confirm 이 즉시 닫히지 않고 정상 유지
**통과 기준**: 브라우저 재시작 없이 daemon 종료만으로 증상 해소

### 시나리오 3: 시나리오 종료 후 페이지 오염이 남지 않는지 확인

**목적**: dialog recorder/override 를 사용한 시나리오가 수동 검증을 방해하지 않는지 확인
**전제**: 관련 시나리오가 `finally` 에서 원복 구현됨

```bash
cd e2e
./e2e.sh run --tab 1 '시나리오/시나리오-사용자/주문등록/2-결제.js'
```

실행 종료 후 같은 탭 또는 새 탭에서 수동으로 dialog 발생 버튼을 누른다.

**기대 결과**: 이전 시나리오 실행 후에도 dialog 가 자동으로 닫히지 않음
**통과 기준**: 수동 동작과 자동화가 서로 오염시키지 않음

### 시나리오 4: 생성/저장 직후 문법 및 종료 규칙 검증

**목적**: 새로 저장된 시나리오가 즉시 실행 가능한 최소 품질을 만족하는지 확인

```bash
node --check e2e/시나리오/대상시나리오.js
rg "process\\.exit\\(0\\)|window\\.alert\\s*=|window\\.confirm\\s*=" e2e/시나리오/대상시나리오.js
```

**기대 결과**:
- `node --check` 통과
- `process.exit(0)` 고정 종료 없음
- `window.alert/confirm` override 가 있으면 원복 코드가 함께 존재

**통과 기준**: 저장된 파일이 문법, 종료 코드, dialog 원복 규칙을 모두 만족

### 시나리오 5: Gmail 링크 전환 fallback 검증

**목적**: Google 홈에서 Gmail 링크 전환이 불안정해도 시나리오가 성공하는지 확인

```bash
curl -s -X PUT 'http://127.0.0.1:9222/json/new?https://www.google.com'

cd e2e
E2E_TAB_ID=<targetId> ./e2e.sh run '시나리오/gmail-메일목록.js'
```

**기대 결과**:
- `Google 로딩 완료 후 2초 대기`
- `Gmail 링크 클릭 시도...`
- 필요 시 `Gmail 전환 지연 — 받은편지함 직접 이동`
- 최종적으로 `tr.zA` 로 받은편지함 15건 추출 완료

**통과 기준**: 링크 클릭이 흔들려도 받은편지함 도달과 목록 추출이 성공

### 시나리오 6: `targetId` 고정 실행 검증

**목적**: 특정 URL 탭에서만 재현해야 하는 검증이 인덱스 드리프트 없이 동작하는지 확인

```bash
curl -s http://127.0.0.1:9222/json | jq -r '.[] | select(.type=="page" and (.url|startswith("chrome")|not)) | [.id,.title,.url] | @tsv'

cd e2e
E2E_TAB_ID=<targetId> ./e2e.sh run '시나리오/시나리오-사용자/주문등록/1-주문등록.js'
```

**기대 결과**: 로그의 `📍 탭 선택:` URL 이 사용자가 지정한 탭과 정확히 일치
**통과 기준**: 탭 인덱스 흔들림 없이 재현 대상 탭에서만 시나리오 수행

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. 피치 하네스 원본 폴더 확인
   - macOS: `~/source/peachSolution2/peach-harness/`

2. 대상 스킬 현재 상태 확인
   - `cat skills/peach-e2e-browse/SKILL.md`
   - `cat skills/peach-e2e-setup/SKILL.md`
   - `cat skills/peach-e2e-run/SKILL.md`
   - `cat skills/peach-e2e-convert/SKILL.md`

3. 이 문서의 "3. 스킬 업데이트 제안" 반영
   - SKILL.md 에 native dialog 주의 섹션 추가
   - `references/native-dialog-주의사항.md` 신설
   - `peach-e2e*` 계열 전체에 공통 레퍼런스 링크 반영
   - 연관 스킬 레퍼런스에 dialog 원복 규칙 반영
   - 시나리오 생성/저장 템플릿에 `try/catch/finally + exitCode + node --check` 규칙 반영
   - Gmail/Google 같은 외부 서비스 전환 fallback 패턴을 샘플 시나리오/레퍼런스에 반영
   - `E2E_TAB_ID` 우선 디버깅 규칙을 browse/run/setup 문서에 반영

4. "4. 검증 시나리오"를 순서대로 실행
   - 상주 세션 재현
   - daemon 종료 후 해소 확인
   - 시나리오 원복 확인
   - 저장 직후 문법/종료 규칙 확인
   - Gmail 링크 전환 fallback 확인
   - `targetId` 고정 실행 확인
   - 각 peach-e2e* 스킬 문서가 공통 레퍼런스를 올바르게 참조하는지 확인

5. 반영 완료 후
   - frontmatter 의 `status`를 `completed` 로 변경
   - `completed_at`, `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거

## 반영 기록

- [2026-04-14] Codex: `agent-browser` CDP 상주 연결이 Chrome Beta 의 native dialog 를 자동 dismiss 하는 문제를 실전 재현 기준으로 정리함
- [2026-04-14] Codex: `gmail-메일목록.js` 는 `Google → Gmail 링크` 전환이 불안정해 `load + 2초 지연 + 직접 이동 fallback` 패턴이 필요함을 추가 정리함
- [2026-04-14] Codex: 특정 URL 탭 재현 검증은 `--tab N` 보다 `E2E_TAB_ID` 우선이 맞고, `page.on('dialog', dialog.accept())` 기본 탑재는 금지해야 함을 추가 정리함
