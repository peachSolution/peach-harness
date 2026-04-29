# Daemon 잔류 대응

## 증상

- native `alert`/`confirm` 클릭 시 dialog가 보이지도 않고 바로 닫힘
- 버튼 클릭이 무반응처럼 보임
- E2E 시나리오에서 `"결제 확인 다이얼로그를 기록하지 못했습니다"` 에러
- `ProtocolError: No dialog is showing` 에러

**위 증상이 하나라도 발생하면 daemon 잔류를 먼저 의심한다.**

---

## 원인: agent-browser daemon CDP 잔류

`agent-browser connect 9222` 실행 시 `node ... daemon.js` 프로세스가 CDP 9222에 연결된다.
이 daemon도 Playwright 기반이므로 `DialogManager`가 handler 없는 dialog를 자동으로 dismiss(false)한다.

### 잔류 발생 케이스

| 케이스 | 설명 |
|--------|------|
| 스킬 중단 (Ctrl+C) | peach-e2e-browse, peach-skill-feedback 등 agent-browser를 사용하는 스킬이 중단되면 daemon이 종료되지 않음 |
| 대화 세션 종료 | Claude Code 세션이 끝나도 daemon은 별도 프로세스로 생존 |
| 시나리오 실행 후 | 시나리오 자체는 `browser.close()`로 끊지만, 별도 daemon이 있으면 그것은 남음 |

---

## Race Condition 메커니즘

CDP `Page.javascriptDialogOpening` 이벤트는 **모든 연결된 CDP 세션에 동시 브로드캐스트**된다.
그러나 `Page.handleJavaScriptDialog`는 **먼저 호출한 세션만 성공**하고, 나머지는 에러가 발생한다.

```
Chrome alert() 발생
  │
  ├──▶ CDP 세션 A (agent-browser daemon)
  │     └─ DialogManager: handler 없음 → dialog.close() → 성공
  │
  ├──▶ CDP 세션 B (E2E 스크립트)
  │     └─ DialogManager: handler 있음 → dialog.accept() 시도
  │     └─ ProtocolError: No dialog is showing (이미 세션 A가 닫음)
```

E2E 스크립트에 `page.on('dialog', handler)`를 아무리 잘 등록해도,
daemon이 먼저 dismiss하면 스크립트의 handler는 실행 기회가 없다.

**해결: daemon을 먼저 종료하고 시나리오를 실행한다.**

---

## 확인 및 종료 명령

### 1. 잔류 daemon 확인

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P
```

출력 예시 (daemon 있음):
```
COMMAND   PID   USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
node    51192 nettem   18u  IPv4  ...    0t0  TCP 127.0.0.1:59951->127.0.0.1:9222 (ESTABLISHED)
Google  74747 nettem  233u  IPv4  ...    0t0  TCP 127.0.0.1:9222->127.0.0.1:59951 (ESTABLISHED)
```

출력 없음 → 정상 (daemon 없음)

### 2. 강제 종료

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P | awk '/node/{print $2}' | xargs kill -9
```

> **`kill -9` 필수.** 일반 `kill`은 자식 프로세스(`daemon.js`)가 살아남는 경우가 있다.

### 3. 종료 확인

```bash
lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P  # 출력 없으면 정상
```

---

## E2E 시나리오 실행 전 체크 루틴

dialog 관련 에러가 발생했을 때 실행 전 항상:

```bash
# daemon 잔류 확인 후 있으면 강제 종료
DAEMON_PIDS=$(lsof -iTCP:9222 -sTCP:ESTABLISHED -n -P 2>/dev/null | awk '/node/{print $2}')
if [ -n "$DAEMON_PIDS" ]; then
  echo "⚠️  CDP 잔류 daemon 감지: PID $DAEMON_PIDS — 종료합니다"
  kill -9 $DAEMON_PIDS
fi
```

---

## 브라우저 재시작은 필요한가

**거의 없다.** daemon만 종료하면 브라우저는 정상 동작한다.

브라우저 재시작이 필요한 경우:
- CDP 포트 자체가 응답하지 않을 때: `curl -s http://127.0.0.1:9222/json/version` 실패
- daemon 종료 후에도 dialog가 자동으로 닫히면 → `lsof` 재확인 (다른 CDP 클라이언트가 남아있을 수 있음)
