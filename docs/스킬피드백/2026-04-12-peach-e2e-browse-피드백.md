---
status: completed
target_skill: peach-e2e-browse
severity: 높음 3 / 중간 4 / 낮음 3
completed_at: 2026-04-13
applied_by: Claude Opus 4.6
---

# peach-e2e-browse 피드백 — 2026-04-12

> **대상 스킬**: peach-e2e-browse
> **작성 근거**: ipTIME Flutter 웹앱 VPN 설정 조회 + 카카오 디벨로퍼 앱 설정 조회 실전 작업
> **심각도 요약**: 높음 3건 / 중간 4건 / 낮음 3건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | Flutter 웹앱 대응 방법 없음 (accessibility 활성화, API 직접 호출) | 높음 | X | 28~41 의사결정 트리 |
| 2 | screenshot + Read 조합이 수천 토큰 낭비인데 금지 규칙 없음 | 높음 | X | 277~286 핵심 규칙 |
| 3 | 세션 끊김 감지/복구 흐름 없음 | 높음 | X | — |
| 4 | eval click()의 isTrusted:false 한계 미기재 | 중간 | X | 277~286 핵심 규칙 |
| 5 | SPA 로딩 대기 방법 미기재 (wait --load networkidle) | 중간 | X | 28~41 의사결정 트리 |
| 6 | snapshot 없이 요소 탐색하는 find 명령 미문서화 | 중간 | X | references/agent-browser-명령어.md |
| 7 | 토큰 실측 데이터가 사이트별로 편차가 큼 (50B~107,000B) | 중간 | 부분적 (189~190행) | — |
| 8 | highlight 명령 미문서화 (시각적 피드백) | 낮음 | X | references/agent-browser-명령어.md |
| 9 | record/trace/diff 명령 미문서화 | 낮음 | X | references/agent-browser-명령어.md |
| 10 | IIFE 금지 사유가 불명확 (반환값 크기 제한이 본질) | 낮음 | 부분적 (282행) | — |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: Flutter 웹앱 대응 방법 없음

**원인**: SKILL.md 의사결정 트리(28~41행)에 Flutter 분기가 없음. eval 결과가 빈 값/"로딩 중"일 때의 대응이 없어서 30분 시행착오 발생.

**해결 — Accessibility 활성화**:
```bash
# 가장 확실한 방법
agent-browser eval "document.querySelector('flt-semantics-placeholder')?.click(); 'done'"

# 안 되면 flutter-view 클릭
agent-browser snapshot -i -c
# → [ref=e2] (flutter-view) 확인
agent-browser click e2
```

**해결 — API 직접 호출 (핵심 우회)**:
```bash
# 1단계: performance API로 엔드포인트 발견
agent-browser eval "performance.getEntriesByType('resource').map(function(r){return r.name}).filter(function(u){return u.includes('cgi') || u.includes('api')}).join('\n')"

# 2단계: dart.js에서 API method 추출
agent-browser eval "fetch('/ui/main.dart.js').then(function(r){return r.text()}).then(function(t){window.__apis = t.match(/\\\"[a-z][a-z0-9_]*\\/[a-z_\\/]+\\\"/gi).filter(function(s){return s.match(/vpn|pptp|l2tp/i)}).filter(function(v,i,a){return a.indexOf(v)===i}).sort(); window.__ready='done'}); 'parsing'"

agent-browser eval "window.__ready === 'done' ? JSON.stringify(window.__apis) : 'parsing...'"

# 3단계: fetch로 직접 호출 (세션 쿠키 자동 포함)
agent-browser eval "fetch('/cgi/service.cgi',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:1,method:'vpncli/server/list'})}).then(function(r){return r.text()}).then(function(t){window.__result=t}); 'go'"

agent-browser eval "window.__result"
```

**핵심 주의사항**:
- 페이지 이동마다 accessibility 재활성화 필요
- Flutter는 Dart HttpClient 사용 → JS fetch monkey-patch 불가
- URL 해시 라우팅 안 먹힘 → 메뉴 클릭 or API 직접 호출만 가능
- Promise.all fetch → window 변수 타이밍 문제 → 개별 eval로 분리

### 문제 #2: screenshot + Read 토큰 낭비

**원인**: screenshot으로 PNG 파일 생성 후 Read tool로 열면 이미지 토큰 수천 개 소비. 금지 규칙이 없어서 3회 반복함.

**해결**:
```bash
# 금지: screenshot + Read (수천 토큰)
# 올바른 방법:
agent-browser eval "document.body.innerText.substring(0,200)"  # ~200B
```

### 문제 #3: 세션 끊김 감지/복구

**원인**: 장시간 미사용 또는 탭 닫힘으로 CDP 세션이 끊김. 에러 메시지: `CDP error: Session with given id not found`

**해결**:
```bash
# 헬스체크
agent-browser eval "document.title"
# 실패 시 →
agent-browser connect 9222
agent-browser tab list
agent-browser tab N
agent-browser eval "document.title"
```

### 문제 #4: eval click() isTrusted 차이

**원인**: `eval "querySelector('.btn').click()"` → `isTrusted: false`. 금융/보안 폼에서 무시됨.

**해결**:
```bash
# eval click 실패 시 → snapshot → click ref
agent-browser snapshot -i -c -s "form"
agent-browser click e5  # ref 번호
```

### 문제 #5: SPA 로딩 대기

**원인**: `document.readyState === 'complete'`는 DOM 로드 완료일 뿐, React/Vue hydration 완료 미보장.

**해결**:
```bash
agent-browser wait --load networkidle
# 또는
agent-browser eval "!!document.querySelector('타겟셀렉터')"  # 특정 요소 등장 체크
```

### 문제 #6~10: 명령어 미문서화

**해결**: references/agent-browser-명령어.md에 아래 추가:
```bash
# 시각적 피드백
agent-browser highlight ".selector"
agent-browser highlight @e5
agent-browser record start ./demo.webm
agent-browser record stop
agent-browser trace start
agent-browser trace stop ./trace.zip
agent-browser diff snapshot
agent-browser diff screenshot --baseline

# 요소 탐색 (snapshot 없이)
agent-browser find role button --name "Submit"
agent-browser find role link --name "자세히"

# SPA 대기
agent-browser wait --load networkidle
agent-browser wait ".target-element"
```

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

#### 의사결정 트리 확장 (28~41행 대체)

```
웹사이트 도착
│
├─ eval "document.title + ' | ' + location.href" 로 현재 상태 파악
│
├─ 정상 텍스트 반환 (일반 HTML / SPA)
│  ├─ 데이터 읽기 → eval 한 줄로 해결
│  ├─ 셀렉터를 알고 있다 → eval로 click/value 설정
│  │  ⚠️ eval click()은 isTrusted:false — 보안 폼에서 안 될 수 있음
│  │  → 안 되면 snapshot -i -c -s "form" → click ref
│  ├─ 셀렉터를 모른다
│  │  ├─ find role button --name "버튼명" (snapshot 없이 탐색)
│  │  └─ snapshot -i -c -s "관심영역" → ref 확보 → click/fill
│  └─ SPA 로딩 대기 필요
│     → wait --load networkidle 또는 eval "!!querySelector('타겟')" 체크
│
├─ "로딩 중입니다" or 빈 값 → Flutter/Canvas 의심
│  ├─ eval "!!querySelector('flt-semantics-placeholder')" → Flutter 확정
│  ├─ accessibility 활성화
│  │  ├─ eval "querySelector('flt-semantics-placeholder')?.click()"
│  │  └─ 안 되면 snapshot -i -c → click e2 (flutter-view)
│  ├─ 활성화 후 → snapshot -i -c로 ref 확보 → 메뉴 조작
│  ├─ ⚠️ 페이지 이동마다 accessibility 재활성화 필요
│  └─ **우회 전략 (권장)**: dart.js에서 API method 추출 → fetch 직접 호출
│     (references/Flutter-웹앱-패턴.md 참조)
│
├─ iframe 내부 접근 필요
│  → playwright-cli fallback (references/iframe-모달-패턴.md 참조)
│
└─ 세션 끊김 (CDP error: Session not found)
   → connect 9222 → tab list → tab N → eval "document.title"
```

#### 핵심 규칙 추가 (277~286행 이후)

```
10. **eval click()은 isTrusted:false** -- 보안 폼에서 무시될 수 있음. 안 되면 snapshot → click ref.
11. **Flutter 사이트는 API 직접 호출이 최강** -- dart.js에서 method 추출 → fetch 호출. UI 탐색 대비 토큰 99% 절약.
12. **세션 끊김 감지** -- eval 실패 시 connect 9222 재실행. 매번 connect 반복은 금지.
13. **screenshot + Read 절대 금지** -- 이미지 열기 = 수천 토큰. eval "body.innerText.substring(0,200)"으로 대체.
```

### 3-2. references/ 추가 (새 파일 2개)

#### references/Flutter-웹앱-패턴.md

핵심 내용:
- Flutter 판별법 (flt-semantics-placeholder 존재 확인)
- Accessibility 활성화 (placeholder 클릭 → flutter-view 클릭)
- 페이지 이동마다 재활성화 필요
- API 직접 호출 전략 (performance API → dart.js 파싱 → fetch)
- JS fetch monkey-patch 불가 (Dart HttpClient 사용)
- URL 해시 라우팅 불가
- Promise.all 금지 → 개별 eval 분리

#### references/토큰-최적화-실측데이터.md

핵심 내용:
- 명령별 실측 비교표 (Google/네이버/GitHub, 바이트 단위)
- 핵심 비율: eval title 19B vs snapshot 전체 107,583B
- 작업별 토큰 예산 가이드
- eval click vs click ref isTrusted 차이

### 3-3. references/agent-browser-명령어.md 보완

추가할 섹션:
- 시각적 피드백 (highlight, record, trace, diff)
- 요소 탐색 (find role --name)
- SPA 대기 (wait --load networkidle)

---

## 부록 A. Flutter 웹앱 패턴 — 상세 기술 자료

> references/Flutter-웹앱-패턴.md 생성 시 이 내용을 기반으로 한다.

### A-1. Flutter 웹앱 판별법

```bash
# 방법 1: eval로 텍스트 확인
agent-browser eval "document.body.innerText.substring(0,100)"
# → "로딩 중입니다" 또는 빈 문자열이면 Flutter 의심

# 방법 2: flt-semantics 태그 존재 확인
agent-browser eval "!!document.querySelector('flt-semantics-placeholder')"
# → true이면 Flutter 확정

# 방법 3: flutter_bootstrap.js 확인
agent-browser eval "!!document.querySelector('script[src*=flutter]')"
```

### A-2. Accessibility 활성화 (필수)

Flutter는 Canvas로 렌더링하므로 DOM 트리가 거의 없다.
flt-semantics-placeholder를 클릭하면 접근성 트리가 생성된다.

```bash
# 가장 확실한 방법
agent-browser eval "document.querySelector('flt-semantics-placeholder')?.click(); 'done'"

# 안 되면 flutter-view 전체 영역 클릭
agent-browser snapshot -i -c
# → [ref=e2] (flutter-view ...) 확인
agent-browser click e2
```

**핵심 주의사항:**
- **페이지 이동마다 accessibility가 리셋됨** → 매번 재활성화 필요
- 재활성화 비용: eval 1줄 (~50B) — 무시 가능 수준
- `click e1` (Enable accessibility 버튼)은 screen reader용이라 직접 클릭으로는 작동 안 함

### A-3. Flutter 메뉴 조작

```bash
# 1. accessibility 활성화 후 snapshot으로 메뉴 ref 확인
agent-browser snapshot -i -c
# → button "관리도구 버전 15.31.6" [ref=e2]
# → button "Easy Mesh 관리 컨트롤러" [ref=e3]

# 2. 메뉴 클릭
agent-browser click e2

# 3. 서브메뉴 펼치기 (좌측 사이드바)
agent-browser snapshot -i -c | grep "메뉴 펼치기"
# → button [ref=e2] (접힌 메뉴 버튼)
agent-browser click e2

# 4. eval로 메뉴 텍스트 확인 (snapshot보다 저토큰)
agent-browser eval "document.body.innerText.substring(0,500)"
```

**문제 발생 케이스:**
- VPN 설정 클릭 → 스냅샷 설정 페이지로 튕기는 현상
- 원인: Flutter 내부 라우팅이 ref 클릭 순서에 민감
- **우회: API 직접 호출이 훨씬 안정적**

### A-4. Flutter API 직접 호출 (핵심 우회 전략)

**이 방법이 Flutter 사이트에서 가장 효율적이고 안정적이다.**

#### 단계 1: API 엔드포인트 발견

```bash
agent-browser eval "performance.getEntriesByType('resource').map(function(r){return r.name}).filter(function(u){return u.includes('api') || u.includes('cgi') || u.includes('json')}).join('\n')"
```

ipTIME 실전 결과: `/cgi/service.cgi`가 핵심 API 엔드포인트

#### 단계 2: JS 번들에서 API method 추출

```bash
agent-browser eval "fetch('/ui/main.dart.js').then(function(r){return r.text()}).then(function(t){
  window.__apis = t.match(/\\\"[a-z][a-z0-9_]*\\/[a-z_\\/]+\\\"/gi);
  window.__vpn = window.__apis.filter(function(s){return s.match(/vpn|openvpn|pptp/i)})
    .filter(function(v,i,a){return a.indexOf(v)===i}).sort();
}); 'parsing'"

agent-browser eval "JSON.stringify(window.__vpn)"
```

#### 단계 3: 브라우저 내 fetch로 직접 호출

```bash
agent-browser eval "fetch('/cgi/service.cgi',{
  method:'POST',
  headers:{'Content-Type':'application/json'},
  body:JSON.stringify({jsonrpc:'2.0',id:1,method:'vpncli/server/list'})
}).then(function(r){return r.text()}).then(function(t){window.__result=t}); 'go'"

agent-browser eval "window.__result"
```

#### 단계 4: 주의사항

- `Promise.all`로 여러 fetch를 묶으면 window 변수 할당 타이밍 문제 → 개별 eval로 분리
- Flutter 페이지(`/easymesh/`)에서는 API가 응답하지 않는 경우 → 관리도구 페이지(`/ui/`)에서 호출
- 세션 쿠키(`efm_session_id`) 확인: `eval "document.cookie"`

### A-5. Flutter에서 JS fetch 가로채기가 안 되는 이유

```
시도: window.fetch를 monkey-patch하여 API 요청 body 캡처
결과: window.__log = [] (빈 배열)
원인: Flutter는 Dart HttpClient를 사용 — JS window.fetch를 우회
결론: dart.js에서 method를 추출하여 직접 호출하는 것이 정답
```

### A-6. Flutter 페이지 URL 라우팅 특성

```
/ui/           → Flutter 앱 진입점 (홈 or Easy Mesh로 자동 리다이렉트)
/ui/index.html → 동일
/easymesh/     → Easy Mesh 관리툴 (별도 Flutter 앱)
/ui/#vpn       → 해시 라우팅 안 먹힘 (Flutter가 자체 라우팅)

결론: URL로 직접 페이지 이동 불가 — 메뉴 클릭 or API 직접 호출만 가능
```

---

## 부록 B. 토큰 최적화 실측 데이터

> references/토큰-최적화-실측데이터.md 생성 시 이 내용을 기반으로 한다.

### B-1. 명령별 실측 비교표

3개 사이트 (Google, 네이버 뉴스, GitHub) 실측. 단위: 바이트.

| 명령 | Google | 네이버 뉴스 | GitHub | 비고 |
|------|--------|-----------|--------|------|
| `eval "document.title"` | 9B | 19B | 286B | **최소** |
| `eval "!!querySelector('.btn')"` | - | - | 5B | 존재 확인 |
| `eval "innerText.substring(0,200)"` | 153B | 478B | 222B | 제한 텍스트 |
| `eval JSON.stringify(links 10개)` | - | - | 923B | 목록 추출 |
| `snapshot -i -c -s "CSS"` | - | 57~63B | 60~378B | **CSS 범위 제한** |
| `snapshot -i -c` | 809B | **50,285B** | 11,967B | 인터랙티브+컴팩트 |
| `snapshot` (전체) | 1,391B | **107,583B** | 21,937B | **절대 금지** |
| `screenshot file.png` | 80B | 79B | 80B | 파일 경로만 (토큰 0) |
| `screenshot` + `Read` | 수천 | 수천 | 수천 | **절대 금지** |

### B-2. 핵심 비율 (네이버 뉴스 기준 — 최악 케이스)

| 방법 | 바이트 | 전체 대비 |
|------|--------|----------|
| `eval "document.title"` | 19B | **0.02%** |
| `snapshot -i -c -s CSS` | 57B | **0.05%** |
| `snapshot -i -c` | 50,285B | **47%** |
| `snapshot` 전체 | 107,583B | **100%** |

### B-3. 실전 토큰 예산 가이드

| 작업 유형 | 권장 예산 | 방법 |
|----------|----------|------|
| 페이지 확인 | < 300B | `eval "document.title + ' \| ' + location.href"` |
| 텍스트 읽기 | < 1,500B | `eval "body.innerText.substring(0,N)"` (N 조절) |
| 요소 존재 확인 | < 10B | `eval "!!querySelector('.target')"` |
| 목록 일괄 추출 | < 2,000B | `eval "JSON.stringify(Array.from(...).slice(0,10).map(...))"` |
| 클릭 대상 찾기 | < 400B | `snapshot -i -c -s "관심영역"` |
| Flutter API 호출 | < 500B | `eval "fetch(...).then(...)"` → `eval "window.__result"` |
| **금지** | 50,000B+ | `snapshot` 전체, `screenshot` + `Read` |

---

## 부록 C. 실전 실수 기록 — 절대 반복 금지

### 실수 1: screenshot + Read로 화면 확인 (3회)

```
낭비: ~10,000+ 토큰
올바른 방법: eval "body.innerText.substring(0,200)" (~200B)
비율: 50배 낭비
```

### 실수 2: Flutter 메뉴 클릭 반복 (10회+)

```
낭비: ~50,000+ 토큰 (snapshot 반복 + 시행착오)
올바른 방법: dart.js에서 API method 추출 → fetch 직접 호출 (~500B × 3회)
비율: 30배 낭비
```

### 실수 3: snapshot 전체 실행

```
낭비: 107,000B (네이버 뉴스 실측)
올바른 방법: snapshot -i -c -s "nav" (57B)
비율: 1,877배 낭비
```

### 실수 4: 탭 확인 없이 작업

```
낭비: 잘못된 페이지에서 작업 → 전체 재작업
올바른 방법: tab list → 탭 번호 확인 → tab N → eval "document.title"
```

### 실수 5: Flutter에서 JS fetch monkey-patch 시도

```
낭비: 인터셉터 설치 + VPN 클릭 + 로그 확인 = 5회 eval (각 ~200B)
결과: 빈 로그 (Flutter는 Dart HttpClient 사용)
올바른 방법: dart.js에서 직접 method 추출
교훈: Flutter는 JS API를 우회한다 — JS 레벨 가로채기 불가능
```

### 실수 6: connect 반복 실행

```
낭비: 매 명령마다 connect → 불필요한 오버헤드
올바른 방법: 1회 connect, 끊기면 헬스체크 후 재연결
```

---

## 부록 D. 카카오 디벨로퍼 실전 접근법 — eval만으로 해결한 사례

일반 HTML 사이트는 eval만으로 전부 해결 가능하다는 증거.

| 단계 | 방법 | 토큰 비용 |
|------|------|----------|
| 1 | `tab list` → 탭 번호 확인 | ~100B |
| 2 | `eval "document.body.innerText.substring(0,1500)"` | ~1,500B (앱 목록 전체) |
| 3 | `eval "JSON.stringify(Array.from(querySelectorAll('a[href*=console/app/]')).map(...))"` | ~400B (앱 링크 4개) |
| 4 | 각 앱 `open URL` → `eval "body.innerText.substring(0,2000)"` × 4 | ~8,000B |
| **합계** | snapshot 0회, screenshot 0회 | **~10,000B** |

핵심: 일반 HTML에서는 Tier1~2(eval)만으로 충분. snapshot이 필요한 경우는 없었다.

---

## 부록 E. 시각적 피드백 — Chrome에서 AI 조작을 보는 방법

### Chrome에서 보이는 것 vs 안 보이는 것

| 명령 | Chrome에서 보이는가 | 설명 |
|------|:---:|------|
| `open URL` | **O** | 페이지 이동 |
| `click ref` | **O** | 클릭 반응 |
| `fill ref "텍스트"` | **O** | 텍스트 입력 |
| `highlight ref` | **O** | 요소 하이라이트 |
| `scroll` | **O** | 스크롤 이동 |
| `eval` (DOM 변경) | **O** | 스타일/내용 변경 시 |
| `eval` (데이터 읽기) | X | 화면 변화 없음 |
| `snapshot` | X | AI 내부 처리 |
| `screenshot` | X | AI 내부 캡처 |

### 시각적 피드백 극대화 패턴

```bash
# 클릭 전 하이라이트로 "여기를 조작합니다" 표시
agent-browser highlight e5
agent-browser click e5
```

### 녹화

```bash
agent-browser record start ./session.webm
# ... 자동화 작업 수행 ...
agent-browser record stop
```

---

## 부록 F. 참조 사이트 정보

| 사이트 | URL | 유형 | 핵심 특징 |
|--------|-----|------|----------|
| ipTIME AX7800M-6E | `192.168.0.1` | Flutter 웹앱 | `/cgi/service.cgi` JSON-RPC, accessibility 수동 활성화, dart.js API 추출 가능 |
| 카카오 디벨로퍼 | `developers.kakao.com` | 일반 HTML | eval만으로 전부 해결, snapshot 불필요, 앱 4개 등록됨 |

---

## 4. 검증 시나리오

> **별도 문서로 분리됨**: `docs/스킬피드백/2026-04-12-peach-e2e-browse-검증시나리오.md`
>
> 검증 시나리오에는 아래 내용이 포함됨:
> - 사전 환경 체크 (agent-browser 설치, CDP 연결, Chrome 실행)
> - ipTIME 접속 정보 (URL, 장비, 펌웨어, API 엔드포인트, API 목록)
> - 카카오 접속 정보 (URL, 계정, 앱 4개 ID/이름/비즈 앱 여부)
> - 시나리오 A: ipTIME Flutter (7개 테스트)
> - 시나리오 B: 카카오 디벨로퍼 (5개 테스트)
> - 시나리오 C: 토큰 최적화 (2개 테스트)
> - 시나리오 D: 시각적 피드백 (2개 테스트)
> - 검증 결과 기록 템플릿 + 트러블슈팅 가이드

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

### 작업 1: 피치 하네스 원본 폴더 확인

```bash
# Windows
ls "D:/peachSolution2/peach-harness/skills/peach-e2e-browse/"
# macOS
ls ~/source/peachSolution2/peach-harness/skills/peach-e2e-browse/
```

### 작업 2: 현재 SKILL.md 상태 확인

```bash
cat skills/peach-e2e-browse/SKILL.md
```

28~41행 (의사결정 트리)과 277~286행 (핵심 규칙)을 확인한다.

### 작업 3: SKILL.md 수정

1. 28~41행 → "3. 스킬 업데이트 제안 > 3-1 > 의사결정 트리 확장" 내용으로 대체
2. 286행 이후 → 핵심 규칙 10~13번 추가

### 작업 4: references/ 새 파일 생성

1. `references/Flutter-웹앱-패턴.md` — "2. 해결 방법 > 문제 #1" 내용 기반
2. `references/토큰-최적화-실측데이터.md` — "시나리오 C-1" 실측 데이터 기반

### 작업 5: references/agent-browser-명령어.md 보완

"문제 #6~10 해결" 섹션의 명령어 추가

### 작업 6: 검증 시나리오 실행

`docs/스킬피드백/2026-04-12-peach-e2e-browse-검증시나리오.md`를 열고 시나리오를 순서대로 실행하여 변경 사항 확인

### 작업 7: 반영 기록 추가

이 문서 하단에 반영 기록 작성:
```markdown
## 반영 기록
- [날짜] {에이전트}: SKILL.md 행 XX~YY 수정, references/XX.md 추가
```

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| eval 결과가 항상 "로딩 중입니다" | Flutter accessibility 미활성화 | `flt-semantics-placeholder` 클릭 |
| CDP error: Session not found | 세션 끊김 | `connect 9222` → `tab list` → `tab N` |
| fetch 응답이 계속 pending | 잘못된 페이지에서 호출 | `eval "location.href"` 확인, `/ui/` 페이지에서 호출 |
| snapshot이 Enable accessibility만 | Flutter 로딩 미완료 or accessibility 미활성화 | `eval "document.readyState"` 확인 후 `click e2` |
| 카카오 디벨로퍼 로그인 페이지로 리다이렉트 | 세션 만료 | 사용자가 Chrome에서 수동 재로그인 |
| `open URL --new-tab` 후 탭 사라짐 | 해당 명령은 기존 탭 덮어씀 | `tab new "URL"` 사용 |
| Promise.all fetch 결과가 비어있음 | window 변수 할당 타이밍 문제 | 개별 eval로 분리하여 하나씩 호출 |
| 관리도구 VPN 메뉴 클릭 시 다른 페이지로 튕김 | Flutter 내부 라우팅 불일치 | API 직접 호출로 우회 (A-4 방법) |

---

## 반영 기록

- [2026-04-13] Claude Opus 4.6:
  - SKILL.md 의사결정 트리(28~55행) 교체: Flutter/SPA/세션끊김 분기 추가
  - SKILL.md 핵심 규칙 10~13번 추가(286~290행): isTrusted/Flutter API/세션복구/screenshot 금지
  - SKILL.md 참조 문서 테이블에 Flutter-웹앱-패턴.md, 토큰-최적화-실측데이터.md 추가
  - references/Flutter-웹앱-패턴.md 신규 생성
  - references/토큰-최적화-실측데이터.md 신규 생성
  - references/agent-browser-명령어.md 보완: find/wait/highlight/record/trace/diff 추가
  - peach-e2e-run SKILL.md: 세션 끊김 복구 흐름 추가
  - peach-e2e-convert SKILL.md: 세션 끊김 복구 흐름 추가
  - peach-e2e-convert references/프레임워크-대응.md: Flutter 비대상 안내 추가
