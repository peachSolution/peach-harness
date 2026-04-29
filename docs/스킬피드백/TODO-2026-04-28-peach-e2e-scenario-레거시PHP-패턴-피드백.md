---
status: pending
target_skill: peach-e2e-scenario
severity: 높음 2 / 중간 5 / 낮음 3
completed_at:
applied_by:
---

# peach-e2e-scenario 피드백 — 2026-04-28

> **대상 스킬**: peach-e2e-scenario
> **작성 근거**: {PROJECT} {기능명} 항목추가 E2E 작업 — PHP 레거시 MVC + jQuery UI + hash 라우터 환경에서 8개 시나리오 작성·실행하며 발견
> **심각도 요약**: 높음 2건 / 중간 5건 / 낮음 3건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md / references 위치 |
|---|------|:---:|:---:|-----|
| 1 | jQuery UI Dialog + iframe에서 `frameLocator()` 또는 `waitForFunction()`이 parent context 차이로 실패 | 높음 | 부분 (프레임워크-대응.md 9행 — `page.frameLocator()` 패턴만 있고 **폴링 방식 없음**) | 프레임워크-대응.md:9 |
| 2 | 시나리오 번호가 의존성 순서와 반대로 설계되어 실행 불가 (01이 02에서 생성된 PK 필요) | 높음 | X (없음) | — |
| 3 | 서버 사이드 이력 조건(change_info 비면 histInsert 안 함) — 동일값 재저장 시 이력 미생성 오탐 | 중간 | X (없음) | — |
| 4 | AJAX 결과 폴링 — `waitForTimeout()` 고정 대기로는 느린 응답 시 오탐 | 중간 | X (없음, 자동수정-판단트리.md:117에 navigation timeout만 있음) | 자동수정-판단트리.md:117 |
| 5 | 다단계 시나리오 간 PK 공유 패턴 (독립 프로세스 간 상태 전달) | 중간 | X (없음, peach-e2e-suite SKILL.md에 env var 방식만 있음) | — |
| 6 | CDP UA 변경 후 다음 시나리오에서 "Target page, context or browser has been closed" 에러 | 중간 | X (없음, 자동수정-판단트리.md:107에 에러 패턴만 있고 UA 원인 명시 없음) | 자동수정-판단트리.md:107 |
| 7 | E2E_BYPASS captcha 우회 패턴 (서버 측 isAdmin() || random_code 조건 활용) | 중간 | X (없음) | — |
| 8 | localStorage 기반 searchParam 복원 — `eval(setItem)` 먼저 후 `goto` 순서 필수 | 낮음 | X (없음) | — |
| 9 | 테스트 데이터 식별자 — 한글 2자+숫자4자 랜덤 이름으로 실 데이터와 구분 | 낮음 | X (없음) | — |
| 10 | 테스트 데이터 이력 유지(DELETE 금지) — finally DELETE 시 관리자 목록에서 데이터 사라져 교차 검증 실패 | 낮음 | X (없음) | — |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: jQuery UI Dialog iframe — page.frames() 폴링 패턴

**원인**: `page.frameLocator('iframe[src*=...]')` 방식은 iframe이 완전히 로드되기 전이거나 jQuery UI가 동적으로 생성한 iframe의 경우 실패. `waitForFunction()`도 parent page context에서만 실행되어 iframe 내부 DOM 미탐지.

**해결**: list 페이지로 강제 goto 후 `page.frames()` 배열 폴링 방식.

```javascript
async function openAdminIframe(page, singoNum) {
    // 매번 list로 강제 goto — 이전 iframe 잔류 문제 방지
    await page.goto(`${BASE}/admin/.../list`, { waitUntil: 'domcontentloaded' });
    // 부모 페이지 JS 함수 로드 대기
    await page.waitForFunction(() => typeof updateAction === 'function', { timeout: 10000 });
    await page.waitForTimeout(300);
    // jQuery UI dialog + iframe 트리거
    await page.evaluate((n) => { updateAction(n); }, singoNum);
    // page.frames() 폴링 — frameLocator 대신
    let iframe = null;
    for (let i = 0; i < 20; i++) {
        await page.waitForTimeout(500);
        iframe = page.frames().find(f => f.url().includes(`{PK_FIELD}=${singoNum}`));
        if (iframe) break;
    }
    if (!iframe) throw new Error(`iframe not found for {PK_FIELD}=${singoNum}`);
    await iframe.waitForSelector('#target_element', { timeout: 10000 });
    return iframe;
}
```

**핵심 포인트**:
- `page.frames()` 는 현재 페이지에 로드된 모든 Frame 배열 반환
- URL 패턴으로 특정 iframe 식별 (`f.url().includes(...)`)
- 매 호출마다 list로 goto → 이전 iframe 잔류/중복 문제 방지

---

### 문제 #2: 시나리오 번호 의존성 설계 규칙

**원인**: 01-수정-저장이 `admin.{PK_FIELD}`(state.json)를 필요로 하는데, 이를 생성하는 02-신규등록보다 번호가 앞에 있어 단독 실행 불가.

**해결**: 파일명 재번호 부여 (02-신규등록 → 01, 03-변경이력 → 02, 01-수정-저장 → 03)

**설계 규칙**:
```
데이터 생성(PK 생성) → 데이터 조회/검증 → 데이터 수정 → 데이터 정리
     01                     02                  03              04
```

---

### 문제 #3: 서버 사이드 이력 조건 — 테스트 전 상태 초기화

**원인**: 서버 `histInsert`가 `change_info`(변경된 필드 목록)가 빈 경우 INSERT를 하지 않음. 이전 실행에서 `Y` 상태로 남아있으면 `Y→Y` 재저장 시 변경 없음으로 이력이 생기지 않아 테스트 오탐.

**해결**: 이력 생성을 검증하는 시나리오 시작 전 대상 필드를 NULL(미선택)로 초기화.

```javascript
// [0] 이전 실행 상태 초기화 — NULL→Y 변경을 보장하기 위해 먼저 리셋
let iframe = await openAdminIframe(page, SINGO);
await clickIframeSave(page, iframe, '', '');  // 미선택으로 초기화
await page.waitForTimeout(300);

// [1] 이제 Y로 저장 → NULL→Y 변경 → histInsert 보장
iframe = await openAdminIframe(page, SINGO);
const save1 = await clickIframeSave(page, iframe, 'Y', TEST_DATE);
```

---

### 문제 #4: AJAX 결과 폴링 패턴

**원인**: `waitForTimeout(1500)` 고정 대기는 서버 응답이 느린 경우 "검색결과가 없습니다" 상태에서 텍스트를 읽어 오탐.

**해결**: 특정 텍스트 사라질 때까지 폴링 (최대 5초, 500ms 간격).

```javascript
async function waitForAjaxResult(iframe, elementId, emptyText = '검색결과가 없습니다', maxTries = 10) {
    for (let i = 0; i < maxTries; i++) {
        await iframe.waitForTimeout(500);
        const text = await iframe.evaluate((id) => {
            const el = document.getElementById(id);
            return el ? el.innerText : '';
        }, elementId);
        if (text && !text.includes(emptyText)) return text;
    }
    // 최대 대기 후에도 빈 결과면 그대로 반환 (검증에서 실패 처리)
    return await iframe.evaluate((id) => {
        const el = document.getElementById(id);
        return el ? el.innerText : '';
    }, elementId);
}

// 사용
const histText = await waitForAjaxResult(iframe, 'hist_list_html');
```

---

### 문제 #5: 다단계 시나리오 PK 공유 — state.json 패턴

**원인**: 단위 시나리오는 독립 node 프로세스로 실행 → 메모리 공유 불가. 환경변수 주입(`E2E_VAR=xxx`)은 AI가 직접 실행 명령에 포함해야 해서 자동화 어려움.

**해결**: `e2e/.tmp/e2e_{기능명}_state.json` 파일로 PK/이름 전달.

```javascript
// 02-등록 시나리오 마지막에 저장
const STATE_FILE = path.join(__dirname, '../../../.tmp/e2e_state.json');
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
state.user = { {PK_FIELD}: N, name: TEST_NAME, pw: PW, date: TEST_DATE };
fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
console.log(`💾 상태 저장: user.{PK_FIELD}=${N}`);

// 03-수정 시나리오 시작에서 로드
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
const SINGO = state.user?.{PK_FIELD}
    ? String(state.user.{PK_FIELD})
    : (process.env.E2E_SINGO_NUMBER || null);
if (!SINGO) throw new Error('state.json 없음. 02-등록 시나리오를 먼저 실행하세요.');
```

**주의사항**:
- `.tmp/` 폴더는 `e2e/.gitignore`에 추가 필수 (실행마다 내용 바뀜)
- state.json 없을 때 fallback: `process.env.E2E_SINGO_NUMBER` → 단독 실행 지원

---

### 문제 #6: CDP UA 변경 후 컨텍스트 닫힘

**원인**: 모바일 UA 설정(`page.setExtraHTTPHeaders` 또는 CDP `Network.setUserAgentOverride`) 후 다음 시나리오가 같은 탭 컨텍스트를 재사용하면 "Target page, context or browser has been closed" 에러 발생.

**해결**: 재실행 1회로 자동 복구됨 (`connect()`가 열린 탭 중 유효한 것을 재선택). 자동수정 루프 대상.

**예방책**: UA 변경 시나리오 마지막에 UA 원복.

```javascript
// finally 블록에서 UA 복원
} finally {
    try {
        const client = await page.context().newCDPSession(page);
        await client.send('Network.setUserAgentOverride', { userAgent: '' }); // 기본값 복원
    } catch (_) {}
    process.exit(process.exitCode || 0);
}
```

---

### 문제 #7: E2E_BYPASS captcha 우회

**원인**: 사용자 측 insertSubmit에 captcha가 있어 E2E 등록이 불가. 서버에 `isAdmin() || $_POST['random_code'] === 'E2E_BYPASS'` 조건으로 우회 로직이 있음.

**해결**: page.evaluate에서 fetch로 직접 POST 시 `random_code: 'E2E_BYPASS'` 포함.

```javascript
const insertResp = await page.evaluate(({ fields, bypass }) => {
    const fd = new FormData();
    // ... 필수 필드 채우기 ...
    fd.append('random_code', bypass);  // captcha 우회
    fd.append('agree', 'Y');
    return fetch('/taxi/agent/income/insertSubmit', { method: 'POST', body: fd })
        .then(r => r.text().then(t => ({ status: r.status, body: t })));
}, { fields: formData, bypass: 'E2E_BYPASS' });
```

**전제**: 서버 코드에 E2E_BYPASS 허용 조건이 구현되어 있어야 함. 없으면 서버 개발자에게 추가 요청.

---

### 문제 #8: localStorage 기반 searchParam 복원

**원인**: PHP 기본값(`date('Y')-1`)이 페이지 초기화 시 먼저 실행되고, 이후 JS의 `searchParam.get(key)`가 localStorage 값으로 덮어씀 → localStorage가 우선. 잘못된 값이 localStorage에 남아 있으면 복원 후에도 엉뚱한 값 표시.

**해결**: `eval(localStorage.setItem)` 먼저 실행 후 `goto`.

```javascript
// ❌ 잘못된 순서 — goto 후 setItem은 다음 페이지 로드에 반영됨
await page.goto(targetUrl);
await page.evaluate((y) => localStorage.setItem('key', y), value);

// ✅ 올바른 순서 — setItem 먼저, 그 다음 goto
await page.evaluate((y) => {
    try { localStorage.setItem('singo_income_agent_tax_year', String(y)); } catch(_) {}
}, targetYear);
await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
// goto 후 페이지 JS가 localStorage를 읽어 올바른 값 적용됨
```

---

### 문제 #9: 테스트 데이터 식별자

**목적**: 실 운영 데이터와 E2E 테스트 데이터를 목록에서 즉시 구분.

**해결**: 한글 2자 + 숫자 4자 랜덤 이름 생성.

```javascript
const KR_CHARS = '김이박최정강조윤장임한오서신권황안송류전홍고문양손배조백허유남심노정하곽성차주우구신임나전민유류진방엄채원천방공강현함변염양변여추도소신석기방편권';
const e2eRandName = () => {
    const c = (arr) => arr[Math.floor(Math.random() * arr.length)];
    const chars = Array.from(KR_CHARS);
    return c(chars) + c(chars) + String(Math.floor(Math.random() * 9000) + 1000);
};
const TEST_NAME = e2eRandName(); // 예: '홍길1234', '정서5154'
```

**효과**: 목록에서 `홍길1234`처럼 짧고 숫자가 포함된 이름이 E2E 테스트 건임을 직관적으로 식별 가능.

---

### 문제 #10: 테스트 데이터 이력 유지 (DELETE 금지)

**원인**: `finally` 블록에서 `DELETE` 또는 `dbQuery(DELETE ...)` 로 테스트 데이터를 정리하면, 관리자 목록 교차 검증에서 데이터가 사라져 "목록 미노출" 오탐 발생.

**해결**: E2E 시나리오에서 테스트 데이터를 삭제하지 않음. 대신 등록 이력 로그로 기록.

```javascript
// ❌ 하지 말 것
} finally {
    if (N) dbQuery(`DELETE FROM taxi_singo_income WHERE {PK_FIELD}=${N}`);
    process.exit(process.exitCode || 0);
}

// ✅ 올바른 방식
} finally {
    console.log(`\n📌 등록 이력 유지: {PK_FIELD}=${N} (${TEST_NAME})`);
    process.exit(process.exitCode || 0);
}
```

**운영 정리**: 테스트 데이터는 주기적으로 운영자가 수동 정리하거나, 별도 정리 스크립트로 일괄 처리.

---

## 3. 스킬 업데이트 제안

### 3-1. `references/프레임워크-대응.md` 수정 (높음)

**위치**: 기존 "레거시 (PHP + jQuery UI Dialog + iframe)" 섹션 (9행) 하단에 추가.

**추가 내용**: "jQuery UI Dialog iframe — page.frames() 폴링 패턴" 섹션

```markdown
### jQuery UI Dialog iframe — page.frames() 폴링 패턴

`frameLocator()`나 `waitForFunction()`이 실패할 때 사용하는 안정적 대안.
jQuery UI가 동적으로 생성한 iframe은 URL로 식별하는 폴링 방식이 더 신뢰할 수 있다.

**실패 원인**:
- `page.frameLocator('iframe[src*=...]')`: jQuery UI가 iframe을 동적 생성하면 타이밍 실패
- `page.waitForFunction()`: parent page context에서만 실행되어 iframe 내부 DOM 미탐지

**해결: page.frames() 폴링**

\`\`\`javascript
async function openModalIframe(page, pk) {
    // 매번 list로 강제 goto — 이전 iframe 잔류 방지
    await page.goto(`${BASE}/admin/module/list`, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => typeof updateAction === 'function', { timeout: 10000 });
    await page.waitForTimeout(300);
    await page.evaluate((n) => { updateAction(n); }, pk);
    // URL 패턴으로 대상 iframe 탐색 (최대 10초)
    let iframe = null;
    for (let i = 0; i < 20; i++) {
        await page.waitForTimeout(500);
        iframe = page.frames().find(f => f.url().includes(`pk=${pk}`));
        if (iframe) break;
    }
    if (!iframe) throw new Error(`iframe not found for pk=${pk}`);
    await iframe.waitForSelector('#target_element', { timeout: 10000 });
    return iframe;
}
\`\`\`
```

---

### 3-2. `references/시나리오-생성-패턴.md` 수정 (높음 + 중간)

**추가 섹션 1**: "다단계 시나리오 번호 설계 규칙" (문제 #2)

```markdown
## 8. 다단계 시나리오 번호 설계 규칙

의존 관계가 있는 시나리오는 **데이터 흐름 순서**로 번호를 부여한다.

```
원칙: 데이터 생성 → 생성 직후 검증 → 수정/활용 → 독립 검증
번호:     01             02              03             04
```

**잘못된 예 (의존성 역전)**:
```
01-수정-저장-검증.js   ← admin PK 필요 (state.json 의존)
02-신규등록-검증.js   ← admin PK 생성 (state.json 저장)
```

**올바른 예**:
```
01-신규등록-검증.js   ← PK 생성 + state.json 저장
02-변경이력-검증.js   ← 01의 PK 재활용
03-수정-저장-검증.js  ← 01의 PK 재활용
04-목록필터-검증.js   ← 독립 시나리오
```

번호가 의존성 역전 상태로 생성되었다면 `git mv`로 rename한다.
```

**추가 섹션 2**: "다단계 시나리오 PK 공유 — state.json 패턴" (문제 #5)

```markdown
## 9. 다단계 시나리오 PK 공유 — state.json 패턴

단위 시나리오는 독립 node 프로세스 → 메모리 공유 불가.
`e2e/.tmp/e2e_{기능명}_state.json` 파일로 PK/이름 전달한다.

**저장 (PK 생성 시나리오)**:
\`\`\`javascript
const STATE_FILE = path.join(__dirname, '../../.tmp/e2e_기능명_state.json');
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
state.user = { {PK_FIELD}: N, name: TEST_NAME };
fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
\`\`\`

**로드 (이후 시나리오)**:
\`\`\`javascript
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
const PK = state.user?.{PK_FIELD}
    ? String(state.user.{PK_FIELD})
    : (process.env.E2E_PK || null);                     // 단독 실행 fallback
if (!PK) throw new Error('state.json 없음. 01-등록 시나리오를 먼저 실행하세요.');
\`\`\`

**필수**: `e2e/.gitignore`에 `.tmp/` 추가.
```

**추가 섹션 3**: "테스트 데이터 이력 유지 (DELETE 금지)" (문제 #10)

```markdown
## 10. 테스트 데이터 이력 유지 — finally DELETE 금지

`finally` 블록에서 테스트 데이터를 DELETE하면 이후 시나리오의 교차 검증(관리자 목록 노출 확인 등)에서
데이터가 사라져 오탐이 발생한다.

\`\`\`javascript
// ❌ 하지 말 것
} finally {
    if (N) dbQuery(`DELETE FROM table WHERE pk=${N}`);
}

// ✅ 이력 유지 + 로그 출력
} finally {
    console.log(`\n📌 등록 이력 유지: pk=${N} (${TEST_NAME})`);
    process.exit(process.exitCode || 0);
}
\`\`\`
```

---

### 3-3. `references/validation-통과-패턴.md` 수정 (중간)

**추가 섹션 1**: "서버 사이드 이력 조건 — 테스트 전 상태 초기화" (문제 #3)

```markdown
## 7. 서버 사이드 이력 조건 — 테스트 전 상태 초기화

서버가 **값이 변경될 때만** 이력/로그를 기록하는 로직인 경우,
이전 실행에서 같은 값이 남아 있으면 재저장해도 이력이 생기지 않아 테스트 오탐 발생.

**증상**: "이력 없음" / "검색결과가 없습니다"가 계속 나타남

**해결**: 검증 전 대상 필드를 중립값(NULL/미선택)으로 초기화.

\`\`\`javascript
// [0] 이전 실행 상태 초기화 (NULL로 리셋)
let iframe = await openAdminIframe(page, pk);
await saveIframeForm(page, iframe, '');  // 미선택/NULL
await page.waitForTimeout(300);

// [1] 이제 Y로 저장 → NULL→Y 변경 → 이력 생성 보장
iframe = await openAdminIframe(page, pk);
const result = await saveIframeForm(page, iframe, 'Y');
\`\`\`
```

**추가 섹션 2**: "E2E_BYPASS captcha 우회 패턴" (문제 #7)

```markdown
## 8. E2E_BYPASS captcha 우회 패턴

서버에 `isAdmin() || $_POST['random_code'] === 'E2E_BYPASS'` 조건이 구현된 경우,
E2E 시나리오에서 captcha 없이 등록 가능.

\`\`\`javascript
const insertResp = await page.evaluate(({ formData, bypass }) => {
    const fd = new FormData();
    Object.entries(formData).forEach(([k, v]) => fd.append(k, v));
    fd.append('random_code', bypass);  // E2E_BYPASS
    fd.append('agree', 'Y');
    return fetch('/module/insertSubmit', { method: 'POST', body: fd })
        .then(r => r.text().then(t => ({ status: r.status, body: t })));
}, { formData: fields, bypass: 'E2E_BYPASS' });

let j = {}; try { j = JSON.parse(insertResp.body); } catch (_) {}
ok('등록 성공', j.type === 'ok', j);
\`\`\`

**전제**: 서버 코드에 `E2E_BYPASS` 허용 조건 구현 필요. 없으면 백엔드 개발자에게 추가 요청.
```

---

### 3-4. `references/자동수정-판단트리.md` 수정 (중간)

**추가 섹션 1**: "AJAX 결과 폴링 — 고정 대기 오탐" (문제 #4)

```markdown
## 7. AJAX 결과 로딩 지연 (고정 대기 오탐)

### 에러 패턴
```
✅ 처럼 보이지만 실제로는 "검색결과가 없습니다" 텍스트 읽음
이력/목록이 있어야 하는데 항상 빈 결과 반환
```

### 원인
`waitForTimeout(N)` 고정 대기 중 AJAX 응답이 아직 도착하지 않은 상태에서 텍스트를 읽음.

### 수정 전략
특정 "빈 결과" 텍스트가 사라질 때까지 폴링.

```javascript
async function waitForAjaxResult(frame, elementId, emptyText = '검색결과가 없습니다', maxTries = 10) {
    for (let i = 0; i < maxTries; i++) {
        await frame.waitForTimeout(500);
        const text = await frame.evaluate((id) => {
            const el = document.getElementById(id);
            return el ? el.innerText : '';
        }, elementId);
        if (text && !text.includes(emptyText)) return text;
    }
    return await frame.evaluate((id) => {
        const el = document.getElementById(id);
        return el ? el.innerText : '';
    }, elementId);
}
```

### 수정 불가 기준
- 데이터 자체가 없는 경우 (서버 조건 문제 → 문제 #3 참조)
```

**추가 섹션 2**: "CDP UA 변경 후 컨텍스트 닫힘" (문제 #6)

```markdown
## 8. CDP UA 변경 후 컨텍스트 닫힘

### 에러 패턴
```
page.goto: Target page, context or browser has been closed
```
앞 시나리오에서 모바일 UA를 설정한 뒤 다음 시나리오 실행 시 발생.

### 원인
CDP `Network.setUserAgentOverride`로 UA를 변경한 탭이 다음 연결 시 컨텍스트 불일치.

### 수정 전략
1. **재실행 1회**로 자동 복구됨 (`connect()`가 유효한 탭을 재선택)
2. **예방**: UA 변경 시나리오 finally에서 UA 복원

```javascript
} finally {
    try {
        const client = await page.context().newCDPSession(page);
        await client.send('Network.setUserAgentOverride', { userAgent: '' });
    } catch (_) {}
    process.exit(process.exitCode || 0);
}
```

### 수정 불가 기준
- Chrome CDP 자체 문제 → Chrome Beta 재시작 필요
```

---

### 3-5. `references/코드패턴.md` 수정 (낮음)

**추가 섹션 1**: "테스트 데이터 식별자 패턴" (문제 #9)

```markdown
## 테스트 데이터 식별자 패턴

실 운영 데이터와 E2E 테스트 데이터를 목록에서 즉시 구분하기 위한 이름 생성.

```javascript
const KR_CHARS = '김이박최정강조윤장임한오서신권황안송류전홍고문양손배조백허유남심노정하곽성차주우구신임나전민유류진방엄채원천방공강현함변염양변여추도소신석기방편권';
const e2eRandName = () => {
    const c = (arr) => arr[Math.floor(Math.random() * arr.length)];
    const chars = Array.from(KR_CHARS);
    return c(chars) + c(chars) + String(Math.floor(Math.random() * 9000) + 1000);
};
const TEST_NAME = e2eRandName(); // 예: '홍길1234', '정서5154'
```

결과 형태: `홍길1234`, `정서5154` — 한글 성+이름 2자 + 숫자 4자.
```

**추가 섹션 2**: "localStorage 기반 파라미터 복원 패턴" (문제 #8)

```markdown
## localStorage 기반 파라미터 복원 패턴

PHP 서버 기본값보다 클라이언트 JS의 `localStorage.getItem()`이 나중에 실행되어 우선 적용됨.
파라미터 복원 시 **setItem 먼저 → goto** 순서 필수.

```javascript
// ✅ 올바른 순서
await page.evaluate((val) => {
    try { localStorage.setItem('param_key', String(val)); } catch(_) {}
}, targetValue);
await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
// goto 후 JS가 localStorage를 읽어 올바른 값 적용

// ❌ 잘못된 순서 (goto 후 setItem → 이번 페이지 로드에는 미반영)
await page.goto(targetUrl);
await page.evaluate((val) => localStorage.setItem('key', val), targetValue);
```
```

---

## 4. 검증 시나리오

### 시나리오 1: jQuery UI Dialog iframe 폴링 패턴 검증

**목적**: `프레임워크-대응.md`에 추가된 폴링 패턴이 실제 동작하는지 확인
**전제**: peach-harness 프로젝트의 PHP + jQuery UI 환경, Chrome CDP 연결

```bash
# {PROJECT} 환경
cd ~/source/{PROJECT}/solution/e2e
./e2e.sh run 시나리오/{기능명}/관리자/03-수정-저장-검증.js
```

**기대 결과**: `iframe not found` 에러 없이 관리자 iframe이 정상 로드됨
**통과 기준**: `✨ 모든 검증 통과` 출력

---

### 시나리오 2: state.json PK 공유 검증

**목적**: 다단계 시나리오에서 01→02→03 순으로 state.json을 통해 PK가 정상 전달되는지 확인

```bash
cd ~/source/{PROJECT}/solution/e2e
rm -f .tmp/e2e_state.json

# 1단계: PK 생성
./e2e.sh run 시나리오/{기능명}/관리자/01-신규등록-검증.js
cat .tmp/e2e_state.json  # admin.{PK_FIELD} 확인

# 2단계: PK 재활용
./e2e.sh run 시나리오/{기능명}/관리자/02-변경이력-검증.js

# 3단계: PK 재활용
./e2e.sh run 시나리오/{기능명}/관리자/03-수정-저장-검증.js
```

**기대 결과**: 각 시나리오가 동일한 {PK_FIELD}로 동작
**통과 기준**: 3개 시나리오 모두 `✨ 모든 검증 통과` 출력

---

### 시나리오 3: 서버 사이드 이력 조건 초기화 검증

**목적**: 동일값 재저장 시에도 이력이 정상 생성되는지 확인

```bash
cd ~/source/{PROJECT}/solution/e2e
# 여러 번 연속 실행해도 변경이력 검증이 통과되어야 함
./e2e.sh run 시나리오/{기능명}/관리자/02-변경이력-검증.js
./e2e.sh run 시나리오/{기능명}/관리자/02-변경이력-검증.js  # 재실행
```

**기대 결과**: 2회 모두 `✨ 모든 검증 통과` — "검색결과가 없습니다" 오탐 없음
**통과 기준**: `이력에 '{기능명} 여부' 표시 ✅`

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. **피치 하네스 원본 폴더 확인**
   ```bash
   ls ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/
   ```

2. **대상 파일 현재 상태 확인**
   ```bash
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/프레임워크-대응.md
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/시나리오-생성-패턴.md
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/validation-통과-패턴.md
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/자동수정-판단트리.md
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-scenario/references/코드패턴.md
   ```

3. **이 문서의 "3. 스킬 업데이트 제안" 섹션을 순서대로 반영**
   - 3-1: `프레임워크-대응.md` — jQuery UI Dialog iframe 폴링 패턴 추가 (높음)
   - 3-2: `시나리오-생성-패턴.md` — 번호 설계 규칙, state.json, DELETE 금지 섹션 추가 (높음/중간)
   - 3-3: `validation-통과-패턴.md` — 이력 초기화, E2E_BYPASS 섹션 추가 (중간)
   - 3-4: `자동수정-판단트리.md` — AJAX 폴링, UA 컨텍스트 닫힘 섹션 추가 (중간)
   - 3-5: `코드패턴.md` — 테스트 식별자, localStorage 패턴 추가 (낮음)

4. **검증 시나리오(4장) 실행하여 변경 사항 확인**
   ```bash
   cd ~/source/{PROJECT}/solution/e2e
   rm -f .tmp/e2e_state.json
   ./e2e.sh run 시나리오/{기능명}/관리자/01-신규등록-검증.js
   ./e2e.sh run 시나리오/{기능명}/관리자/02-변경이력-검증.js
   ./e2e.sh run 시나리오/{기능명}/관리자/03-수정-저장-검증.js
   ```

5. **변경 완료 후**
   - frontmatter의 `status`를 `completed`로 변경, `completed_at`과 `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거 (`git mv`로 rename)
   - 하단에 반영 기록 추가

---

## 반영 기록

(미반영)
