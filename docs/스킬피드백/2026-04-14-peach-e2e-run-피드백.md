---
status: completed
target_skill: peach-e2e-run
severity: 높음 2 / 중간 1 / 낮음 1
completed_at: 2026-04-14
applied_by: Claude Sonnet 4.6 (Spike)
---

# peach-e2e-run 피드백 — 2026-04-14

> **대상 스킬**: peach-e2e-run, peach-e2e-setup, peach-e2e-browse
> **작성 근거**: E2E 시나리오 실행 중 native dialog 자동 닫힘 현상 — 에이전트 팀(4명+Codex) 투입하여 Playwright 소스 레벨까지 분석 완료
> **심각도 요약**: 높음 2건 / 중간 1건 / 낮음 1건

---

## 0. 반영 현황

### 완료된 스킬 수정 (2026-04-14)

| 파일 | 변경 내용 | 반영 확인 |
|------|---------|---------|
| `skills/peach-e2e-run/SKILL.md` | 5단계 "스크립트 오류 시 자동 수정 절차" 추가(117~144행), native dialog 규칙 전면 개정(147~158행) | `grep -n "monkey-patch" skills/peach-e2e-run/SKILL.md` → 149행 |
| `skills/peach-e2e-setup/references/connect.js` | `defaultDialogHandler`(184행) + `setDialogHandler`(210행) 추가, `module.exports`에 포함 | `grep -n "setDialogHandler" skills/peach-e2e-setup/references/connect.js` |
| `skills/peach-e2e-browse/references/native-dialog-주의사항.md` | monkey-patch 금지(5행), `kill -9` 강화(31행), race condition(47행), `setDialogHandler`(70행) 전면 개정 | `grep -n "monkey-patch" skills/peach-e2e-browse/references/native-dialog-주의사항.md` → 5행 |

### 남은 작업 → 전부 완료

| 항목 | 상태 |
|------|:---:|
| `skills/peach-e2e-run/references/dialog-handler-패턴.md` 신규 생성 | 완료 |
| `skills/peach-e2e-run/references/daemon-잔류-대응.md` 신규 생성 | 완료 |

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 스킬 반영 |
|---|------|:---:|:---:|
| 1 | agent-browser 작업 중단 시 daemon이 CDP에 잔류 → 모든 native dialog 자동 닫힘 | 높음 | SKILL.md, native-dialog-주의사항.md 반영 완료 |
| 2 | monkey-patch(`window.confirm/alert` override)가 Playwright CDP 자동 dismiss보다 늦어 동작 안 함 | 높음 | SKILL.md, native-dialog-주의사항.md 반영 완료 |
| 3 | dialog 없이 팝업이 바로 닫히면 `waitForEvent('dialog')` timeout 에러 | 중간 | references에 미반영 |
| 4 | E2E 시나리오 실행 전 daemon 잔류 체크 없음 | 낮음 | SKILL.md 반영 완료 |

---

## 2. 근본 원인 — Playwright 내부 메커니즘

아래 내용은 `dialog-handler-패턴.md` 작성 시 그대로 사용한다.

### 2-1. dialog 자동 닫힘 전체 흐름

```
Chrome: alert()/confirm() 발생
  │
  ▼
CDP 이벤트: Page.javascriptDialogOpening
  │ (모든 CDP 세션에 동시 브로드캐스트)
  │
  ▼
crPage.js  FrameSession._onDialog(event)
  │
  ▼
dialog.js  DialogManager.dialogDidOpen(dialog)
  │
  ├─ _dialogHandlers Set 순회 → handler(dialog) 호출
  │   각 handler가 true 반환하면 hasHandlers = true
  │
  ▼
  hasHandlers === false ?
  ├─ YES → dialog.close() 자동 호출
  │         └─ alert/confirm → dismiss(false 반환)
  │         └─ beforeunload → accept
  └─ NO  → 사용자 handler에 위임
```

소스: `playwright-core/lib/server/dialog.js:74-86`

### 2-2. hasHandlers 조건

```js
// dialog.js:79-83
let hasHandlers = false;
for (const handler of this._dialogHandlers) {
  if (handler(dialog)) hasHandlers = true;
}
if (!hasHandlers)
  dialog.close().then(() => {});
```

`page.on('dialog', fn)` 등록 → BrowserContextDispatcher가 subscription 확인 → `true` 반환 → `hasHandlers=true`.

### 2-3. dialog.close() = dismiss(false)

```js
// dialog.js:61-66
async close() {
  if (this._type === "beforeunload") await this.accept();
  else await this.dismiss();   // ← confirm은 여기: false 반환
}
```

handler가 없으면 confirm이 **dismiss(취소/false)** — monkey-patch(`return true`)와 정반대.

### 2-4. 다중 CDP 세션 race condition

`Page.javascriptDialogOpening`은 모든 세션에 브로드캐스트.
`Page.handleJavaScriptDialog`는 먼저 호출한 세션만 성공, 나머지는 `ProtocolError: No dialog is showing`.

```
Chrome alert() →
  ├─ 세션 A (daemon): handler 없음 → dialog.close() → 성공
  └─ 세션 B (스크립트): handler 있음 → dialog.accept() → ProtocolError
```

### 2-5. monkey-patch가 동작하지 않는 이유

1. JS 엔진이 `window.confirm()` 실행
2. Chrome이 JS 실행을 블록하고 CDP `Page.javascriptDialogOpening` 이벤트를 먼저 전송
3. Playwright DialogManager가 hasHandlers 확인 → 없으면 dismiss
4. CDP `Page.handleJavaScriptDialog(accept=false)` → dialog 닫힘
5. JS 실행 재개 → monkey-patch된 `window.confirm`은 호출 기회 자체가 없음

### 2-6. page.on('dialog') 다중 등록 충돌

Playwright `_dialogHandlers`는 `Set` 기반으로 **모든 handler를 순회**한다.
`page.on('dialog')`로 추가 등록하면 기존 handler와 **모두 실행**되어
첫 번째가 `accept()` 호출 후 두 번째가 시도하면 `"Cannot accept/dismiss dialog which is already handled!"` 에러.
교체 시 반드시 이전 handler를 `removeListener`로 제거한 후 등록해야 한다.

---

## 3. 코드 패턴 (references에 포함할 내용)

아래 내용은 `dialog-handler-패턴.md` 작성 시 그대로 사용한다.

### 3-1. connect.js 기본 handler (반영 완료 — 참고용)

```js
const defaultDialogHandler = async (dialog) => { await dialog.accept(); };
page.on('dialog', defaultDialogHandler);
return { browser, context, page, origin, defaultDialogHandler };
```

### 3-2. setDialogHandler 유틸 (반영 완료 — 참고용)

```js
function setDialogHandler(page, prevHandler, newHandler) {
  if (prevHandler) page.removeListener('dialog', prevHandler);
  if (newHandler) page.on('dialog', newHandler);
  return newHandler;
}
```

### 3-3. dialog 로그 수집 recorder 패턴

```js
function installDialogRecorder(page, prevHandler) {
  const logs = [];
  const handler = async (dialog) => {
    logs.push({ type: dialog.type(), message: dialog.message() });
    await dialog.accept();
  };
  return { handler: setDialogHandler(page, prevHandler, handler), getLogs: () => logs.splice(0) };
}

// 사용
const { page, defaultDialogHandler } = await connect();
const recorder = installDialogRecorder(page, defaultDialogHandler);
// ... 동작 ...
const logs = recorder.getLogs();
// finally에서 복원
setDialogHandler(page, recorder.handler, defaultDialogHandler);
```

### 3-4. popup handler (connect.js 미경유)

```js
const popup = await page.waitForEvent('popup');
const popupRecorder = installDialogRecorder(popup, null); // prevHandler=null
```

### 3-5. waitForDialogs (이벤트 기반 + popup close race)

```js
async function waitForDialogs(page, recorder, { clickAction, timeout = 10000, closeTarget = null } = {}) {
  const dialogP = page.waitForEvent('dialog', { timeout }).then(() => 'dialog').catch(() => 'no-dialog');
  const closeP = closeTarget
    ? closeTarget.waitForEvent('close', { timeout }).then(() => 'closed').catch(() => 'no-close')
    : Promise.resolve('no-close');
  if (clickAction) await clickAction();
  await Promise.race([dialogP, closeP]);
  await page.waitForTimeout(200);
  return recorder.getLogs();
}
```

### 3-6. daemon 확인 및 종료

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P | awk '/node/{print $2}' | xargs kill -9
```

`kill`만으로는 자식 프로세스(daemon.js) 잔류 — `kill -9` 필수.

---

## 4. 검증 시나리오

### 시나리오 1: daemon 잔류 → dialog 자동 닫힘 재현

**목적**: daemon이 dialog를 자동 닫는다는 것을 확인
**전제**: Chrome Beta `--remote-debugging-port=9222` 실행 중, playwright-core 설치됨

```bash
# 1. daemon 실행
agent-browser connect 9222 &
sleep 1

# 2. 연결 확인
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P

# 3. dialog 테스트
cat > /tmp/test-dialog.js << 'EOF'
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
  const page = browser.contexts()[0]?.pages()[0];
  if (!page) { console.log('페이지 없음'); await browser.close(); return; }
  page.on('dialog', async d => {
    try { await d.accept(); } catch (e) { console.log('handler 에러:', e.message); }
  });
  await page.evaluate(() => {
    setTimeout(() => { window.__r = window.confirm('test'); }, 300);
  });
  await new Promise(r => setTimeout(r, 1500));
  const r = await page.evaluate(() => window.__r);
  console.log('결과:', r, r === true ? '정상' : '자동 닫힘(daemon 영향)');
  await browser.close();
})();
EOF
node /tmp/test-dialog.js

# 4. daemon 종료 후 재테스트
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P | awk '/node/{print $2}' | xargs kill -9
node /tmp/test-dialog.js
rm /tmp/test-dialog.js
```

**통과 기준**: daemon 종료 후 `결과: true 정상`

### 시나리오 2: connect.js 기본 handler 동작 확인

**목적**: setup으로 배포된 connect.js의 `defaultDialogHandler`가 정상 동작하는지 확인
**전제**: 프로젝트에 수정된 connect.js 배포 완료

```bash
cat > /tmp/test-connect.js << 'EOF'
const { connect } = require('./e2e/lib/connect');
(async () => {
  const { page, defaultDialogHandler } = await connect();
  console.log('defaultDialogHandler:', typeof defaultDialogHandler);
  await page.evaluate(() => {
    setTimeout(() => { window.__r = window.confirm('connect.js test'); }, 300);
  });
  await new Promise(r => setTimeout(r, 1500));
  const r = await page.evaluate(() => window.__r);
  console.log('결과:', r, r === true ? '정상(accept)' : '실패(dismiss)');
  process.exit(r === true ? 0 : 1);
})();
EOF
node /tmp/test-connect.js
rm /tmp/test-connect.js
```

**통과 기준**: `결과: true 정상(accept)`, exit code 0

### 시나리오 3: dialog 있는 시나리오 실행

**목적**: 실제 E2E 시나리오에서 dialog가 CDP handler로 정상 처리됨 확인

```bash
cd <프로젝트>/e2e
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P  # 출력 없어야 함
E2E_TAB_ID=<tab_id> ./e2e.sh run '시나리오/대상.js'
```

**통과 기준**: dialog 메시지 콘솔 출력(`📢`) + `✨ 완료` 도달

---

## 5. 다음 에이전트를 위한 작업 지시

### 사전 확인

```bash
HARNESS_ROOT="$HOME/source/peachSolution2/peach-harness"
# Windows: HARNESS_ROOT="D:/peachSolution2/peach-harness"

# 이미 반영된 파일 확인 (행 번호가 0장과 일치하는지)
grep -n "monkey-patch" "$HARNESS_ROOT/skills/peach-e2e-run/SKILL.md"
grep -n "setDialogHandler" "$HARNESS_ROOT/skills/peach-e2e-setup/references/connect.js"
grep -n "monkey-patch" "$HARNESS_ROOT/skills/peach-e2e-browse/references/native-dialog-주의사항.md"
```

### 작업 (references 2파일 생성만)

```bash
mkdir -p "$HARNESS_ROOT/skills/peach-e2e-run/references"
```

**파일 1**: `$HARNESS_ROOT/skills/peach-e2e-run/references/dialog-handler-패턴.md`

이 문서의 2장(근본 원인 전체) + 3장(코드 패턴 3-1~3-5)을 정리하여 작성.
필수 포함 항목:
- Playwright 내부 흐름도 (2-1)
- hasHandlers 분기 조건 (2-2)
- dialog.close() = dismiss(false) (2-3)
- monkey-patch가 동작하지 않는 이유 5단계 (2-5)
- page.on('dialog') 다중 등록 충돌 (2-6)
- connect.js 기본 handler + setDialogHandler 유틸 사용법 (3-1, 3-2)
- installDialogRecorder 패턴 (3-3)
- popup handler 등록 (3-4)
- waitForDialogs 이벤트 기반 + Promise.race (3-5)

**파일 2**: `$HARNESS_ROOT/skills/peach-e2e-run/references/daemon-잔류-대응.md`

이 문서의 2-4(race condition) + 3-6(확인/종료)을 정리하여 작성.
필수 포함 항목:
- 증상: dialog 자동 닫힘, 버튼 무반응, ProtocolError
- race condition 메커니즘 (CDP 브로드캐스트 → 먼저 도달한 세션이 dismiss)
- 확인 명령: `lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P`
- 종료 명령: `kill -9` 필수 (일반 kill은 자식 프로세스 잔류)
- 발생 케이스: 스킬 중단(Ctrl+C), peach-skill-feedback 중단, peach-e2e-browse 중단

### 검증

4장의 시나리오 1~3 실행.

### 완료 처리

- frontmatter `status` → `completed`, `completed_at`/`applied_by` 기입
- 파일명에서 `TODO-` 접두어 제거
- 하단에 반영 기록 추가:
  ```markdown
  ## 반영 기록
  - [날짜] {에이전트}: references/dialog-handler-패턴.md, references/daemon-잔류-대응.md 생성
  ```

### 작업하지 않아도 되는 것 (이미 완료)

- `skills/peach-e2e-run/SKILL.md` — 147~158행에 반영 완료
- `skills/peach-e2e-setup/references/connect.js` — defaultDialogHandler(184행) + setDialogHandler(210행) 반영 완료
- `skills/peach-e2e-browse/references/native-dialog-주의사항.md` — 전면 개정 완료

## 반영 기록

- [2026-04-14] Claude Sonnet 4.6 (Spike): SKILL.md 수정, connect.js 수정, native-dialog-주의사항.md 개정, references/dialog-handler-패턴.md 생성, references/daemon-잔류-대응.md 생성
