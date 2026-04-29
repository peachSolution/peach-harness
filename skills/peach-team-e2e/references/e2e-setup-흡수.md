# E2E 환경 세팅 흡수

`peach-team-e2e`가 시작 시 E2E 환경이 미세팅이면 자동으로 처리하는 절차.

## 목적

- 사용자가 `peach-e2e-setup`을 별도 호출하지 않아도 자동 처리
- 이미 세팅되어 있으면 건너뛰고 바로 검증 진행

## 환경 요구사항

| 요소 | 요구 |
|------|------|
| Node.js | 설치 필수 |
| `agent-browser` | 글로벌 설치 |
| `playwright-cli` | 글로벌 설치 (iframe fallback용) |
| Chrome Beta | macOS: `/Applications/Google Chrome Beta.app` 설치 |
| Chrome Beta CDP | 9222 포트 연결 |
| `e2e/` 폴더 | 본 프로젝트 루트에 인프라 코드 배포 |

## 절차

### 1. 인라인 환경 체크

```bash
# 도구 설치 여부
command -v node && echo "✅ node" || echo "❌ node 미설치"
command -v agent-browser && echo "✅ agent-browser" || echo "❌ agent-browser 미설치"
command -v playwright-cli && echo "✅ playwright-cli" || echo "❌ playwright-cli 미설치"

# Chrome Beta
ls "/Applications/Google Chrome Beta.app" 2>/dev/null && echo "✅ Chrome Beta" || echo "❌ Chrome Beta 미설치"

# CDP 연결
curl -s http://127.0.0.1:9222/json/version > /dev/null && echo "✅ CDP 연결" || echo "❌ CDP 미연결"

# e2e/ 폴더
[ -d "e2e" ] && echo "✅ e2e/ 존재" || echo "❌ e2e/ 없음"
```

### 2. 미충족 항목별 처리

#### 도구 미설치

자동 설치하지 않는다. 사용자에게 안내 후 중단:

```
⚠️ 다음 도구가 설치되어 있지 않습니다:
- agent-browser: npm i -g agent-browser
- playwright-cli: npm i -g @playwright/cli

설치 후 다시 시도해주세요.
```

이유: 글로벌 npm 설치는 사용자 환경에 영향을 주므로 사용자 확인 필요.

#### Chrome Beta 미설치

자동 처리 불가. 사용자에게 안내 후 중단:

```
⚠️ Chrome Beta가 설치되어 있지 않습니다.

다운로드: https://www.google.com/chrome/beta/

설치 후 다시 시도해주세요.
```

#### CDP 미연결

자동 복구 시도:

```bash
# Chrome Beta 실행
nohup "/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta" \
  --remote-debugging-port=9222 \
  "--remote-allow-origins=*" \
  "--user-data-dir=$HOME/.chrome-beta-e2e-profile" \
  --disable-extensions > /tmp/chrome-beta.log 2>&1 &
sleep 5

# 재확인
curl -s http://127.0.0.1:9222/json/version
```

또는 e2e/ 폴더가 있으면:

```bash
cd e2e && ./e2e.sh chrome &
sleep 4
cd e2e && ./e2e.sh status
```

여전히 미연결이면 사용자 안내:
```
⚠️ Chrome Beta CDP 연결 실패

수동으로 실행해주세요:
cd e2e && ./e2e.sh chrome

연결 후 다시 시도해주세요.
```

> **프로필 경로 고정 규칙**: `--user-data-dir`은 반드시 `$HOME/.chrome-beta-e2e-profile`.
> 어떤 상황에서도 다른 경로로 변경하지 않는다. 오류가 나도 경로 변경 금지.

#### e2e/ 폴더 없음

`peach-e2e-setup`의 인프라 코드를 자동 배포한다.

```bash
# peach-e2e-setup 스킬 위치 추적
SETUP_PATH=$(find ~/.claude ~/.agents -type d -name "peach-e2e-setup" 2>/dev/null | head -1)

if [ -n "$SETUP_PATH" ]; then
  # 인프라 코드 복사
  mkdir -p e2e/lib e2e/시나리오
  cp "$SETUP_PATH/references/e2e.sh" e2e/
  cp "$SETUP_PATH/references/pwc.sh" e2e/
  cp "$SETUP_PATH/references/connect.js" e2e/lib/
  cp "$SETUP_PATH/references/selector.js" e2e/lib/
  chmod +x e2e/e2e.sh e2e/pwc.sh

  echo "✅ e2e/ 인프라 배포 완료"
else
  echo "❌ peach-e2e-setup 스킬을 찾을 수 없습니다. /peach-e2e-setup을 먼저 호출해주세요."
fi
```

> 본 스킬은 e2e/ 인프라의 SoT가 아니다. SoT는 `peach-e2e-setup/references/`이며,
> 본 스킬은 그것을 복사만 한다. 인프라 코드 변경 시 `peach-e2e-setup`을 수정해야 한다.

### 3. CDP 연결 후

```bash
agent-browser connect 9222
agent-browser tab list
```

탭 목록을 사용자에게 보여주고 **검증 실행 탭을 확인**한다.

```
탭 목록:
[0] local.example.com/admin/...
[1] PEACH - https://app.local.example.com/

검증을 어느 탭에서 실행할까요? (번호 입력)
```

### 4. 환경 세팅 완료 보고

```
✅ E2E 환경 세팅 확인 완료

- Node.js: 설치됨
- agent-browser: 설치됨
- playwright-cli: 설치됨
- Chrome Beta: 설치됨, CDP 9222 연결됨
- e2e/ 인프라: 배포됨
- 작업 탭: [선택된 번호]

검증 시작 준비 완료.
```

## 비고

- 이 절차는 **본 스킬 실행마다 매번 수행**된다 (이미 세팅된 항목은 건너뜀)
- 사용자가 `peach-e2e-setup`을 직접 호출했어도 무방. 본 스킬이 다시 체크해도 idempotent.
- 환경 세팅에 실패하면 본 스킬은 즉시 중단. 검증 기준 로드 단계로 진입하지 않음.
- 자동 설치 정책: **도구는 자동 설치하지 않음** (사용자 확인 필요), **인프라 코드는 자동 배포** (본 프로젝트 내부 변경이므로)
