# Dialog Handler 패턴

## 핵심 원칙

- `window.confirm/alert` JS monkey-patch는 **동작하지 않는다** — 사용 금지
- 반드시 `page.on('dialog', handler)` CDP 레이어 handler 사용
- handler 교체 시 `setDialogHandler` 유틸 사용 필수 — 다중 등록 충돌 방지

---

## 1. Playwright 내부 메커니즘

### 1-1. dialog 자동 닫힘 흐름

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

### 1-2. hasHandlers 조건

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

### 1-3. dialog.close() = dismiss(false)

```js
// dialog.js:61-66
async close() {
  if (this._type === "beforeunload") await this.accept();
  else await this.dismiss();   // ← confirm은 여기: false 반환
}
```

handler가 없으면 confirm이 **dismiss(취소/false)** — monkey-patch(`return true`)와 정반대.

### 1-4. monkey-patch가 동작하지 않는 이유

1. JS 엔진이 `window.confirm()` 실행
2. Chrome이 JS 실행을 블록하고 CDP `Page.javascriptDialogOpening` 이벤트를 먼저 전송
3. Playwright DialogManager가 hasHandlers 확인 → 없으면 dismiss
4. CDP `Page.handleJavaScriptDialog(accept=false)` → dialog 닫힘
5. JS 실행 재개 → monkey-patch된 `window.confirm`은 호출 기회 자체가 없음

### 1-5. page.on('dialog') 다중 등록 충돌

Playwright `_dialogHandlers`는 `Set` 기반으로 **모든 handler를 순회**한다.
`page.on('dialog')`로 추가 등록하면 기존 handler와 **모두 실행**되어
첫 번째가 `accept()` 호출 후 두 번째가 시도하면 `"Cannot accept/dismiss dialog which is already handled!"` 에러.
교체 시 반드시 이전 handler를 `removeListener`로 제거한 후 등록해야 한다.

---

## 2. 코드 패턴

### 2-1. connect.js 기본 handler

`connect()`는 기본 `accept` handler를 자동 등록하고 `defaultDialogHandler`를 반환한다.

```js
const { page, defaultDialogHandler } = await connect();
// 이미 기본 accept handler가 등록된 상태
```

### 2-2. setDialogHandler 유틸 (교체 패턴)

```js
const { connect, setDialogHandler } = require('../../lib/connect');

// handler 교체: 이전 handler를 제거하고 새 handler를 등록
const newHandler = setDialogHandler(page, defaultDialogHandler, async (dialog) => {
  await dialog.dismiss(); // 예: confirm 취소
});

// 복원
setDialogHandler(page, newHandler, defaultDialogHandler);
```

### 2-3. dialog 로그 수집 recorder 패턴

dialog 메시지를 검증해야 하는 시나리오에서 사용:

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
const recorder = installDialogRecorder(page, defaultDialogHandler);

// 클릭 등 동작 후
const logs = recorder.getLogs();
console.log(logs[0]?.message); // dialog 메시지

// finally에서 반드시 복원
setDialogHandler(page, recorder.handler, defaultDialogHandler);
```

### 2-4. popup handler

popup은 `connect.js`를 거치지 않으므로 기본 handler가 없다. 별도 등록 필요:

```js
const popup = await page.waitForEvent('popup');
const popupRecorder = installDialogRecorder(popup, null); // prevHandler=null

// popup에서 dialog 처리 후
restoreDialogRecorder(popup, popupRecorder.handler, null);
```

### 2-5. waitForDialogs (이벤트 기반 대기)

고정 `waitForTimeout(500)` 대신 이벤트 기반 대기.
팝업이 dialog 없이 바로 닫힐 수 있으므로 `Promise.race` 사용:

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

// 사용 — 일반 페이지
const logs = await waitForDialogs(page, recorder, {
  clickAction: () => btn.click(),
});

// 사용 — popup (dialog 없이 닫힐 수 있는 경우)
const logs = await waitForDialogs(popup, popupRecorder, {
  clickAction: () => deleteBtn.click(),
  closeTarget: popup,
});
await popup.waitForEvent('close', { timeout: 10000 }).catch(() => {});
```

---

## 3. 금지 규칙

- `window.confirm/alert` JS monkey-patch **금지** — CDP 레이어보다 늦어 실행 기회 없음
- `page.on('dialog')` 직접 추가 등록 **금지** — `setDialogHandler`로 교체
- dialog handler `finally` 복원 생략 **금지**
- 고정 `waitForTimeout` 후 dialog 로그 읽기 **금지** — `waitForEvent` 이벤트 기반 사용
