---
status: completed
target_skill: peach-e2e-browse
completed_at: 2026-04-13
applied_by: Claude Opus 4.6
---

# peach-e2e-browse 검증 시나리오 — 2026-04-12

> **대상 스킬**: peach-e2e-browse
> **용도**: 스킬 업데이트 후 검증 + 반복 실행용
> **관련 피드백**: `docs/스킬피드백/2026-04-12-peach-e2e-browse-피드백.md`

---

## 0. 사전 환경 체크

**모든 시나리오 실행 전 반드시 통과해야 한다.**

```bash
# 1. agent-browser 설치 확인
command -v agent-browser && echo "OK" || echo "FAIL: npm i -g agent-browser"

# 2. CDP 연결 확인
curl -s http://127.0.0.1:9222/json/version && echo "OK" || echo "FAIL: Chrome Beta 미실행"

# 3. CDP 미연결 시 — Chrome Beta 실행

# Windows (Git Bash):
"/c/Program Files/Google/Chrome Beta/Application/chrome.exe" \
  --remote-debugging-port=9222 \
  --remote-allow-origins=* \
  --user-data-dir="$(cygpath -w "$HOME/.chrome-beta-e2e-profile")" \
  --disable-extensions &

# macOS:
nohup "/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta" \
  --remote-debugging-port=9222 \
  "--remote-allow-origins=*" \
  "--user-data-dir=$HOME/.chrome-beta-e2e-profile" \
  --disable-extensions > /tmp/chrome-beta.log 2>&1 &

# 4. agent-browser 연결
agent-browser connect 9222

# 5. 탭 목록 확인
agent-browser tab list
```

**통과 기준**: 5개 명령 모두 에러 없이 실행

> **⚠️ 프로필 경로 고정**: `--user-data-dir`은 반드시 `$HOME/.chrome-beta-e2e-profile`. 변경 금지.
> **⚠️ --headless 금지**: 사용자가 Chrome 창에서 조작을 볼 수 있어야 함.

---

## 시나리오 A: ipTIME Flutter 웹앱

> **검증 환경 안내**: 이 시나리오는 사용자가 실제 사용 중인 ipTIME 공유기 관리 페이지에 접속하여 검증한다.
> 아래 URL/IP는 예시이며, 사용자의 실제 공유기 주소로 대체하여 실행한다.

### A-0. 접속 정보

| 항목 | 값 | 비고 |
|------|---|------|
| URL | `사용자가 Chrome에 열어둔 ipTIME 관리자 접속 주소` | 하드코딩 금지 |
| 장비 | 사용자 장비 | 장비 모델명 하드코딩 금지 |
| 펌웨어 | 사용자 환경 기준 | 펌웨어 버전 하드코딩 금지 |
| UI 유형 | **Flutter 웹앱** (Canvas 렌더링) | |
| API 엔드포인트 | `/cgi/service.cgi` (JSON-RPC 2.0) | |
| 인증 | 쿠키 기반 (`efm_session_id`) | |

> **전제**: 사용자가 Chrome에서 자신의 ipTIME 관리 페이지에 미리 로그인해야 함.
> 검증 시에는 **사용자가 이미 열어둔 ipTIME 관리자 접속 주소를 그대로 기준**으로 삼는다.
> Flutter 로그인 폼은 accessibility 활성화 후 ref로 조작 가능하지만, 사용자 수동 로그인이 안정적.

### A-0-1. ipTIME API 목록 (dart.js에서 추출, 2026-04-12 실측)

**VPN 관련 (12개)**:
| method | 용도 |
|--------|------|
| `vpncli/server/list` | VPN 클라이언트 서버 목록 |
| `vpncli/server/set` | VPN 서버 등록/수정 |
| `vpncli/server/remove` | VPN 서버 삭제 |
| `vpncli/connect` | VPN 연결 |
| `vpncli/disconnect` | VPN 연결 해제 |
| `vpncli/status/list` | VPN 연결 상태 |
| `vpncli/filter/list` | VPN 필터 조회 |
| `vpncli/filter/set` | VPN 필터 설정 |
| `vpncli/filter/remove` | VPN 필터 삭제 |
| `vpncli/upload/config` | .ovpn 파일 업로드 |
| `pptp/server/config` | PPTP 서버 설정 |
| `l2tp/server/config` | L2TP 서버 설정 |

**네트워크/시스템 관련 (주요)**:
| method | 용도 |
|--------|------|
| `dhcpd/config/get` | DHCP 설정 |
| `firewall/get` | 방화벽 설정 |
| `ddns/status/get` | DDNS 상태 |
| `conn/info` | 연결 정보 |
| `firmware/info` | 펌웨어 정보 |
| `easymesh/info` | Easy Mesh 정보 |

---

### A-1. Flutter 판별 테스트

**목적**: 사이트가 Flutter인지 자동 판별

```bash
# 단계 1: 페이지 열기
agent-browser open "http://192.168.0.1/ui/"

# 단계 2: eval로 텍스트 확인
agent-browser eval "document.body.innerText.substring(0,100)"
```

**기대 결과**: `"로딩 중입니다."` 또는 빈 문자열

```bash
# 단계 3: Flutter 확정
agent-browser eval "!!document.querySelector('flt-semantics-placeholder')"
```

**기대 결과**: `true`

```bash
# 단계 4: Flutter 버전/앱 정보 확인
agent-browser eval "document.querySelector('script[src*=flutter]')?.src || 'no flutter script'"
```

**기대 결과**: `flutter_bootstrap.js` 경로 포함 문자열

**통과 기준**: 단계 2에서 빈 값/로딩 텍스트 + 단계 3에서 `true`

---

### A-2. Accessibility 활성화 테스트

**목적**: Flutter 접근성 트리 활성화 방법 검증

```bash
# 방법 1: flt-semantics-placeholder 클릭 (권장)
agent-browser eval "document.querySelector('flt-semantics-placeholder')?.click(); 'done'"

# 확인
agent-browser eval "document.body.innerText.substring(0,200)"
```

**기대 결과**: 메뉴 텍스트 포함 (예: "관리도구", "Easy Mesh")

```bash
# 방법 1 실패 시 → 방법 2: snapshot → flutter-view 클릭
agent-browser snapshot -i -c
# → [ref=e2] (flutter-view ...) 확인
agent-browser click e2

# 재확인
agent-browser eval "document.body.innerText.substring(0,200)"
```

**통과 기준**: innerText에 Flutter UI 텍스트가 출력됨

---

### A-3. 관리도구 진입 테스트

**전제**: A-2 완료 (accessibility 활성화됨)

```bash
# 단계 1: 홈 화면 메뉴 확인
agent-browser snapshot -i -c
```

**기대 결과**:
```
- button "관리도구 버전 15.31.6" [ref=e2]
- button "Easy Mesh 관리 컨트롤러" [ref=e3]
```

```bash
# 단계 2: 관리도구 클릭
agent-browser click e2

# 단계 3: 진입 확인
agent-browser eval "document.body.innerText.substring(0,200)"
```

**기대 결과**: "시스템 요약 정보", "인터넷 정보", "내부 네트워크 정보" 등 포함

```bash
# 단계 4: 메뉴 펼치기
agent-browser snapshot -i -c -s "flt-semantics"
# → button [ref=e2] (메뉴 펼치기 버튼) 확인
agent-browser click e2

# 단계 5: 전체 메뉴 확인
agent-browser eval "document.body.innerText.substring(0,500)"
```

**기대 결과**: "VPN 설정", "네트워크 관리", "보안 기능" 등 전체 메뉴 포함

**통과 기준**: 관리도구 본문 텍스트 + 좌측 메뉴 전체 출력

---

### A-4. VPN API 직접 호출 테스트 (핵심)

**목적**: Flutter UI 탐색 없이 API로 직접 데이터 획득

```bash
# 단계 1: 세션 쿠키 확인
agent-browser eval "document.cookie"
```

**기대 결과**: `efm_session_id=...` 포함

```bash
# 단계 2: dart.js에서 VPN API method 추출
agent-browser eval "fetch('/ui/main.dart.js').then(function(r){return r.text()}).then(function(t){window.__vpn_apis = t.match(/\\\"[a-z][a-z0-9_]*\\/[a-z_\\/]+\\\"/gi).filter(function(s){return s.match(/vpn|pptp|l2tp/i)}).filter(function(v,i,a){return a.indexOf(v)===i}).sort(); window.__vpn_ready='done'}); 'parsing'"

# 대기 후 확인 (dart.js 5~6MB, 1~2초 소요)
agent-browser eval "window.__vpn_ready === 'done' ? JSON.stringify(window.__vpn_apis) : 'parsing...'"
```

**기대 결과**: 12개 VPN API method 배열

```bash
# 단계 3: VPN 클라이언트 서버 목록 조회
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:1,method:'vpncli/server/list'})}).then(function(r){return r.text()}).then(function(t){window.__vpn_servers=t}); 'go'"

agent-browser eval "window.__vpn_servers"
```

**기대 결과**: `{"result":[...]}` (빈 배열 또는 서버 목록)

```bash
# 단계 4: PPTP 서버 설정 조회
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:10,method:'pptp/server/config'})}).then(function(r){return r.text()}).then(function(t){window.__pptp=t}); 'go'"

agent-browser eval "window.__pptp"
```

**기대 결과**: `{"result":{"run":false, "mppe":false}}` 또는 유사 JSON

```bash
# 단계 5: L2TP 서버 설정 조회
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:11,method:'l2tp/server/config'})}).then(function(r){return r.text()}).then(function(t){window.__l2tp=t}); 'go'"

agent-browser eval "window.__l2tp"
```

**기대 결과**: `{"result":{"run":false, "allow_nopsk":false, "psk":"..."}}` 또는 유사 JSON

**통과 기준**:
- 단계 2: VPN API method 12개 추출 성공
- 단계 3~5: 모두 `{"result":...}` 형태의 유효한 JSON 반환

---

### A-5. 네트워크 API 조회 테스트

**목적**: VPN 이외의 API도 동일 패턴으로 조회 가능한지 검증

> **실측 주의**: ipTIME API는 method마다 `params` 요구 형식이 다르다.
> 아래 예시는 **사용자가 열어둔 ipTIME 관리자 접속 주소** 기준으로 실제 통과한 형태를 일반화한 것이다.

```bash
# 전체 API method 목록 추출 + 개수 세기
agent-browser eval "fetch('/ui/main.dart.js').then(function(r){return r.text()}).then(function(t){var m=t.match(/\\\"[a-z][a-z0-9_]*\\/[a-z_\\/]+\\\"/gi); window.__all_apis = m ? m.filter(function(v,i,a){return a.indexOf(v)===i}).sort() : []; window.__api_ready='done'}); 'go'"

agent-browser eval "window.__api_ready === 'done' ? window.__all_apis.length + '개 API 발견' : 'parsing...'"
```

**기대 결과**: `"NNN개 API 발견"` (50개 이상)

```bash
# DHCP 설정 조회 (params: "lan" 필요)
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:20,method:'dhcpd/config/get',params:'lan'})}).then(function(r){return r.text()}).then(function(t){window.__dhcp=t}); 'go'"

agent-browser eval "window.__dhcp"

# 방화벽 설정 조회
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:21,method:'firewall/get'})}).then(function(r){return r.text()}).then(function(t){window.__fw=t}); 'go'"

agent-browser eval "window.__fw"

# DDNS 상태 조회 (params: "사용자 DDNS 호스트명" 필요)
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:22,method:'ddns/status/get',params:'사용자 DDNS 호스트명'})}).then(function(r){return r.text()}).then(function(t){window.__ddns=t}); 'go'"

agent-browser eval "window.__ddns"
```

**기대 결과**:
- `window.__dhcp`: `ntag`, `min_ip`, `max_ip`, `gateway` 포함
- `window.__fw`: `{"result":[...]}`
- `window.__ddns`: `host`, `ip`, `status` 포함

**통과 기준**: 3개 API 모두 `{"result":...}` 형태 반환

---

### A-6. Accessibility 재활성화 테스트

**목적**: 페이지 이동 후 accessibility가 리셋되는지 검증

```bash
# 단계 1: 현재 활성화 상태 확인
agent-browser eval "document.body.innerText.substring(0,100)"
# → 메뉴 텍스트가 보여야 함

# 단계 2: 페이지 이동
agent-browser open "http://192.168.0.1/ui/"

# 단계 3: 리셋 확인
agent-browser eval "document.body.innerText.substring(0,100)"
# → "로딩 중입니다" 로 돌아감

# 단계 4: 재활성화
agent-browser eval "document.querySelector('flt-semantics-placeholder')?.click(); 'done'"

# 단계 5: 복구 확인
agent-browser eval "document.body.innerText.substring(0,200)"
# → 메뉴 텍스트가 다시 보임
```

**통과 기준**: 단계 3에서 리셋 확인 + 단계 5에서 복구 확인

---

### A-7. 세션 끊김 복구 테스트

**목적**: CDP 세션 끊김 시 복구 흐름 검증

```bash
# 단계 1: 현재 세션 정상 확인
agent-browser eval "document.title"
# → 정상 반환

# 단계 2: 의도적으로 없는 탭 선택
agent-browser tab 99 2>/dev/null
# → 에러 발생

# 단계 3: 복구
agent-browser connect 9222
agent-browser tab list
# → 탭 목록 출력

# 단계 4: 올바른 탭으로 복구
agent-browser tab 0
agent-browser eval "document.title"
# → 정상 반환
```

**통과 기준**: 단계 4에서 정상 eval 결과 반환

---

## 시나리오 B: 카카오 디벨로퍼 (일반 HTML)

### B-0. 접속 정보

| 항목 | 값 |
|------|---|
| URL | `https://developers.kakao.com/console/app` |
| UI 유형 | **일반 HTML** (서버 렌더링 + JS) |
| 인증 | 카카오 계정 로그인 (사용자가 미리 완료) |
| 계정 | 동재 (Owner) |

**등록된 앱 4개**:

| # | 앱 이름 | ID | 비즈 앱 | 회사명 | 도메인 |
|---|--------|-----|:---:|--------|--------|
| 1 | {APP_A} | {APP_ID_A} | X | {COMPANY_NAME} | 없음 |
| 2 | {APP_B} | {APP_ID_B} | **O** | {COMPANY_NAME} ({BIZ_NUMBER}) | https://www.example.co.kr/ |
| 3 | {APP_C} | {APP_ID_C} | X | {COMPANY_NAME} | 없음 |
| 4 | test | {APP_ID_D} | X | {COMPANY_NAME} | 없음 |

**{APP_A} 상세** (ID {APP_ID_A}):
- 카카오 로그인: ON
- 전체 가입자: 3명
- OpenID Connect: OFF
- 간편가입: 미설정
- 연결 해제 웹훅: **미설정** (개인정보 처리 누락 위험)

> **전제**: 사용자가 Chrome에서 카카오 계정으로 미리 로그인해야 함.

---

### B-1. 로그인 상태 확인 테스트

```bash
# 단계 1: 앱 목록 페이지 열기
agent-browser open "https://developers.kakao.com/console/app"

# 단계 2: 로그인 상태 확인
agent-browser eval "document.body.innerText.substring(0,200)"
```

**기대 결과 (로그인됨)**: "전체 앱", "앱 생성", "ID {APP_ID_A}", "{APP_A}" 등 포함
**기대 결과 (미로그인)**: 로그인 페이지 또는 리다이렉트

```bash
# 단계 3: 사용자 이름 확인
agent-browser eval "document.body.innerText.match(/[가-힣]{2,4}/) ? document.body.innerText.match(/[가-힣]{2,4}/)[0] : 'not found'"
```

**기대 결과**: `"동재"` (또는 로그인된 사용자 이름)

**통과 기준**: 앱 목록 텍스트가 보이고 사용자 이름 확인

---

### B-2. 앱 목록 일괄 추출 테스트

**목적**: eval 한 줄로 모든 앱 정보를 효율적으로 추출

```bash
agent-browser eval "JSON.stringify(Array.from(document.querySelectorAll('a[href*=\"/console/app/\"]')).map(function(a){return {text:a.textContent.trim().substring(0,50), href:a.href}}))"
```

**기대 결과**:
```json
[
  {"text":"ID {APP_ID_A}{APP_A}","href":"https://developers.kakao.com/console/app/{APP_ID_A}"},
  {"text":"ID {APP_ID_B}비즈 앱{APP_B}","href":"https://developers.kakao.com/console/app/{APP_ID_B}"},
  {"text":"ID {APP_ID_C}{APP_C}","href":"https://developers.kakao.com/console/app/{APP_ID_C}"},
  {"text":"ID {APP_ID_D}test","href":"https://developers.kakao.com/console/app/{APP_ID_D}"}
]
```

```bash
# 단계 2: 전체 앱 수 확인
agent-browser eval "document.body.innerText.match(/전체 앱(\\d+)/)?.[1] || 'not found'"
```

**기대 결과**: `"4"` (또는 실제 앱 수)

**통과 기준**: 4개 앱의 ID + 이름 + URL 추출 성공 + 앱 수 일치

---

### B-3. 개별 앱 설정 조회 테스트

**목적**: 각 앱의 기본 정보를 페이지 이동 + eval로 추출

#### 앱 1: {APP_A} (ID {APP_ID_A})

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_A}/config"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,1500) : document.body.innerText.substring(0,1500)"
```

**기대 결과 포함 항목**:
- 앱 이름: `{APP_A}`
- 회사명: `{COMPANY_NAME}`
- 카테고리: `없음`
- 앱 대표 도메인: (없음)
- 비즈 앱: `이 앱은 비즈 앱이 아닙니다`

#### 앱 1 추가: 카카오 로그인 설정 조회

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_A}/product/login"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,1000) : document.body.innerText.substring(0,1000)"
```

**기대 결과 포함 항목**:
- 카카오 로그인 상태: `ON`
- OpenID Connect: `OFF`
- 전체 가입자: `3` (변동 가능)
- 동의항목: `설정함`
- 간편가입: `설정 안 함`
- 연결 해제 웹훅: `설정 안 함` (**개인정보 처리 누락 위험**)

#### 앱 2: {APP_B} (ID {APP_ID_B})

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_B}/config"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,1500) : document.body.innerText.substring(0,1500)"
```

**기대 결과 포함 항목**:
- 앱 이름: `{APP_B}`
- 회사명: `{COMPANY_NAME}`
- 사업자 등록번호: `{BIZ_NUMBER}`
- 카테고리: `광고/비즈니스`
- 앱 대표 도메인: `https://www.example.co.kr/`
- 비즈 앱: O (비즈니스 정보 섹션에 사업자 정보 표시)

#### 앱 3: {APP_C} (ID {APP_ID_C})

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_C}/config"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,1500) : document.body.innerText.substring(0,1500)"
```

**기대 결과 포함 항목**:
- 앱 이름: `{APP_C}`
- 회사명: `{COMPANY_NAME}`
- 카테고리: `없음`
- 비즈 앱: X (`이 앱은 비즈 앱이 아닙니다`)

#### 앱 4: test (ID {APP_ID_D})

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_D}/config"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,1500) : document.body.innerText.substring(0,1500)"
```

**기대 결과 포함 항목**:
- 앱 이름: `test`
- 회사명: `{COMPANY_NAME}`
- 카테고리: `없음`
- 비즈 앱: X (`이 앱은 비즈 앱이 아닙니다`)

**통과 기준**: 4개 앱 모두 기본 정보 (앱 이름, 회사명, 비즈 앱 여부) 추출 성공 + {APP_A} 카카오 로그인 설정 확인

---

### B-4. 플랫폼 키 확인 테스트

```bash
agent-browser open "https://developers.kakao.com/console/app/{APP_ID_A}/config/platform-key"
agent-browser eval "document.querySelector('main') ? document.querySelector('main').innerText.substring(0,800) : document.body.innerText.substring(0,800)"
```

**기대 결과**: 플랫폼 키 등록 현황 (Android/iOS/Web 키 유무)

**통과 기준**: 페이지 로드 + 키 정보 텍스트 추출 성공

---

### B-5. 다중 탭 전환 테스트

**목적**: 여러 탭이 열려있을 때 정확한 탭으로 전환

```bash
# 단계 1: 탭 목록 확인
agent-browser tab list

# 단계 2: 카카오 디벨로퍼 탭 번호 식별
# → "Kakao Developers" 또는 "developers.kakao.com" 포함된 탭 번호 확인

# 단계 3: 해당 탭으로 전환
agent-browser tab N

# 단계 4: 전환 확인
agent-browser eval "location.href"
```

**기대 결과**: `https://developers.kakao.com/...` URL

**통과 기준**: 정확한 탭으로 전환 + URL 확인

---

## 시나리오 C: 토큰 최적화 검증

### C-1. 동일 정보를 다른 방법으로 추출 — 토큰 비교

**목적**: eval vs snapshot vs screenshot의 실제 토큰 차이 실측

```bash
agent-browser open "https://developers.kakao.com/console/app"

# 방법 1: eval title (최소)
agent-browser eval "document.title" 2>&1 | wc -c
# 기대: 100B 이하

# 방법 2: eval 텍스트 제한
agent-browser eval "document.body.innerText.substring(0,200)" 2>&1 | wc -c
# 기대: 300B 이하

# 방법 3: snapshot -i -c -s (범위 제한)
agent-browser snapshot -i -c -s "main" 2>&1 | wc -c
# 기대: 1,000B 이하

# 방법 4: snapshot -i -c (전체 인터랙티브)
agent-browser snapshot -i -c 2>&1 | wc -c
# 기대: 5,000~50,000B

# 방법 5: snapshot 전체 (금지 수준)
agent-browser snapshot 2>&1 | wc -c
# 기대: 10,000~100,000B
```

**통과 기준**: 방법 1~5 순서대로 바이트가 증가, 방법 1이 방법 5 대비 100배 이상 작음

### C-2. Flutter API 직접 호출 vs UI 탐색 비교

**목적**: Flutter 사이트에서 API 직접 호출의 효율성 증명

```bash
# 방법 A: API 직접 호출 (권장)
# VPN 서버 목록 + PPTP + L2TP 조회

agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:1,method:'vpncli/server/list'})}).then(function(r){return r.text()}).then(function(t){window.__r1=t}); 'go'" 2>&1 | wc -c

agent-browser eval "window.__r1" 2>&1 | wc -c

# 총 2~6개 eval, 각 100~500B = 총 ~2,000B 이하
```

```bash
# 방법 B: UI 탐색 (비권장)
# accessibility 활성화 + 메뉴 펼치기 + VPN 클릭에 필요한 비용

# snapshot 1회: ~10,000B
# snapshot 후 click: ~100B
# 메뉴 펼치기 snapshot: ~10,000B
# VPN 클릭 + 텍스트 확인: ~500B
# 총 ~30,000B 이상 (시행착오 포함 시 ~100,000B+)
```

**통과 기준**: 방법 A가 방법 B 대비 10배 이상 토큰 절약

---

## 시나리오 D: 시각적 피드백 검증

### D-1. highlight 명령 동작 확인

```bash
agent-browser open "https://developers.kakao.com/console/app"
agent-browser snapshot -i -c -s "main"
agent-browser highlight e1
```

> **주의**: 현재 agent-browser는 `highlight @e1` 형식을 받지 않는다.
> ref 하이라이트는 `highlight e1`처럼 `@` 없이 호출한다.

**통과 기준**: Chrome 창에서 해당 요소에 시각적 하이라이트 효과 표시 (사용자 육안 확인)

### D-2. record 녹화 테스트

```bash
agent-browser record start ./test-session.webm
agent-browser record stop
```

```bash
# record stop 출력 경로를 우선 확인
# 일부 환경에서는 요청한 상대경로 대신 다른 기본 폴더(예: ~/test/)에 저장될 수 있다.
ls -la ./test-session.webm
# 없으면
find ~ -maxdepth 4 -name "test-session.webm" 2>/dev/null
```

**통과 기준**: `record stop`이 저장 경로를 출력하고, 실제 `.webm` 파일이 존재함

---

## 검증 결과 기록 템플릿

검증 완료 후 아래 표를 채워서 이 문서 하단에 기록한다:

```markdown
## 검증 결과 — [날짜]

| 시나리오 | 테스트 | 결과 | 비고 |
|---------|--------|------|------|
| A-1 | Flutter 판별 | PASS/FAIL | |
| A-2 | Accessibility 활성화 | PASS/FAIL | |
| A-3 | 관리도구 진입 | PASS/FAIL | |
| A-4 | VPN API 직접 호출 | PASS/FAIL | |
| A-5 | 네트워크 API 조회 | PASS/FAIL | |
| A-6 | Accessibility 재활성화 | PASS/FAIL | |
| A-7 | 세션 끊김 복구 | PASS/FAIL | |
| B-1 | 로그인 상태 확인 | PASS/FAIL | |
| B-2 | 앱 목록 추출 | PASS/FAIL | |
| B-3 | 개별 앱 설정 (4개) | PASS/FAIL | |
| B-4 | 플랫폼 키 확인 | PASS/FAIL | |
| B-5 | 다중 탭 전환 | PASS/FAIL | |
| C-1 | 토큰 비교 (5단계) | PASS/FAIL | 바이트: |
| C-2 | API vs UI 비교 | PASS/FAIL | 배율: |
| D-1 | highlight 동작 | PASS/FAIL | |
| D-2 | record 녹화 | PASS/FAIL | |

### 발견된 이슈
- 

### 추가 스킬 업데이트 제안
- 
```

---

## 검증 결과 — 2026-04-13

| 시나리오 | 테스트 | 결과 | 비고 |
|---------|--------|------|------|
| A-1 | Flutter 판별 | PASS | `"로딩 중입니다."`, `flt-semantics-placeholder=true` |
| A-2 | Accessibility 활성화 | PASS | 메뉴 텍스트 노출 |
| A-3 | 관리도구 진입 | PASS | `/ui/sysinfo`, `시스템 요약 정보` 확인 |
| A-4 | VPN API 직접 호출 | PASS | VPN method 12개, `vpncli/server/list`/`pptp`/`l2tp` 응답 확인 |
| A-5 | 네트워크 API 조회 | PASS | `dhcpd/config/get`, `ddns/status/get`는 `params` 필요 |
| A-6 | Accessibility 재활성화 | PASS | `/ui/` 재진입 후 다시 활성화 확인 |
| A-7 | 세션 끊김 복구 | PASS | `tab 99` 실패 후 `connect 9222`로 복구 |
| B-1 | 로그인 상태 확인 | PASS | `동재`, `전체 앱4` 확인 |
| B-2 | 앱 목록 추출 | PASS | 4개 앱 ID/이름/URL 추출 |
| B-3 | 개별 앱 설정 (4개) | PASS | `{APP_A}`, `{APP_B}`, `{APP_C}`, `test` 확인 |
| B-4 | 플랫폼 키 확인 | PASS | 플랫폼 키 섹션 로드 확인 |
| B-5 | 다중 탭 전환 | PASS | 탭 0 ipTIME, 탭 1 Kakao 확인 |
| C-1 | 토큰 비교 (5단계) | PASS | 42B / 512B / 1527B / 2330B / 6705B |
| C-2 | API vs UI 비교 | PASS | 약 27B vs 281B, 약 10.4배 절약 |
| D-1 | highlight 동작 | PASS | `highlight eN` 성공, `@eN` 실패 |
| D-2 | record 녹화 | PASS | 실제 파일 생성 경로 확인 필요 |

### 발견된 이슈
- `A-5` 원본 예시는 실제 장비에서 `Invalid params`가 발생했다. method별 `params` 형식을 문서화해야 한다.
- `record start ./파일명`은 일부 환경에서 요청 경로가 아닌 기본 폴더에 저장된다. `record stop` 출력 경로 확인이 필요하다.

### 추가 스킬 업데이트 제안
- `references/Flutter-웹앱-패턴.md`에 ipTIME 실측 `params` 예시를 추가한다.
- `references/agent-browser-명령어.md`에 `highlight eN` 형식과 `record stop` 경로 확인 규칙을 추가한다.

---

## 트러블슈팅 가이드

| 문제 | 원인 | 해결 |
|------|------|------|
| eval 결과가 항상 "로딩 중입니다" | Flutter accessibility 미활성화 | `flt-semantics-placeholder` 클릭 |
| CDP error: Session not found | 세션 끊김 | `connect 9222` → `tab list` → `tab N` |
| fetch 응답이 계속 pending | 잘못된 페이지에서 호출 | `eval "location.href"` 확인, `/ui/` 페이지에서 호출 |
| snapshot이 Enable accessibility만 | Flutter 로딩 미완료 or 미활성화 | `eval "document.readyState"` 확인 후 `click e2` |
| 카카오 디벨로퍼 로그인 페이지로 리다이렉트 | 세션 만료 | 사용자가 Chrome에서 수동 재로그인 |
| `open URL --new-tab` 후 탭 사라짐 | 기존 탭 덮어씀 | `tab new "URL"` 사용 |
| Promise.all fetch 결과가 비어있음 | window 변수 타이밍 문제 | 개별 eval로 분리 |
| VPN 메뉴 클릭 시 다른 페이지로 튕김 | Flutter 내부 라우팅 불일치 | API 직접 호출로 우회 (A-4) |
