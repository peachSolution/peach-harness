---
status: completed
target_skill: peach-e2e-suite
severity: 높음 3 / 중간 2 / 낮음 1
completed_at: 2026-04-29
applied_by: 스파이크
---

# peach-e2e-suite 피드백 — 2026-04-29

> **대상 스킬**: peach-e2e-suite
> **작성 근거**: {기능명} 항목 추가 E2E 검증(8개 시나리오) 전 과정에서 발견한 문제. 로컬(local.example.com) + 개발서버(dev.example.com) 두 도메인에서 시나리오를 실행하면서 스킬 문서의 공백이 다수 드러남.
> **심각도 요약**: 높음 3건 / 중간 2건 / 낮음 1건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 SKILL.md에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | 단위 시나리오 .js 파일에 도메인이 하드코딩되어 있어 다른 환경(개발서버)에서 실행 불가. E2E_BASE 환경변수 패턴이 스킬에 없음 | 높음 | X (없음) | — |
| 2 | SKILL.md는 "단위 시나리오 .js 파일은 수정하지 않는다"고 명시하나, 신규 시나리오를 만들 때 BASE 패턴을 적용하는 안내가 없어 결국 수정이 불가피함 | 높음 | X (없음) | 188 |
| 3 | 시나리오 .js 내부에 mysql 직접 접속 코드(DB config, dbQuery 함수)가 있어 E2E 환경이 아닌 곳에서 실행 불가(ENOENT). DB 코드는 시나리오에 넣지 말라는 안내 없음 | 높음 | X (없음) | — |
| 4 | {PK_FIELD}(PK) 추출 패턴 부재. 등록 후 PK를 얻는 방법을 DB로만 구현해 왔으나, 관리자 목록 DOM의 `input.pk_check[request_name]` 속성으로 PK를 안전하게 추출할 수 있음 | 중간 | X (없음) | — |
| 5 | suite-템플릿.md의 "Step N: 결과 검증"에 `DB 검증: {SQL}`이 Step 내 항목으로 포함됨. DB 검증은 시나리오 .js가 아니라 suite MD 말미의 선택 섹션으로만 두어야 하는데, 템플릿이 이를 구분하지 않아 구현자가 시나리오에 DB 코드를 넣게 유도함 | 중간 | X (없음) | suite-템플릿.md |
| 6 | suite 전체 실행 후 "어느 단계에서 누가 신규 등록되었는지" 요약이 없음. 각 시나리오가 자기 결과만 출력하고 종료되어, 오케스트레이터(AI)나 사용자가 실행 완료 시점에 등록된 데이터를 한눈에 파악할 수 없음 | 낮음 | X (없음) | — |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1, #2: 하드코딩된 도메인 / 수정 불가 원칙 충돌

**원인**: 시나리오 파일 최상단에 `const BASE = 'http://local.example.com'`이 박혀 있어 개발서버 실행 시 로컬 도메인으로 요청이 나감.

**해결**: 모든 시나리오 파일에 `E2E_BASE` 환경변수 패턴 적용.

```js
// 시나리오 파일 상단 (필수)
const BASE = process.env.E2E_BASE || 'http://local.example.com';
```

실행 시:
```bash
# 로컬 (기본값)
./e2e.sh run --tab N 시나리오/경로.js

# 개발서버 지정
E2E_BASE=https://dev.example.com ./e2e.sh run --tab N 시나리오/경로.js
```

suite MD에는 "도메인 설정" 섹션을 별도로 추가해 두 환경 실행법을 표로 정리:

```markdown
## 도메인 설정

| 환경 | 도메인 | 실행 방법 |
|------|--------|-----------|
| 로컬 (기본값) | `http://local.example.com` | `./e2e.sh run --tab N 시나리오/...` |
| 개발서버 | `https://dev.example.com` | `E2E_BASE=https://dev.example.com ./e2e.sh run --tab N 시나리오/...` |
```

### 문제 #3: 시나리오 내 DB 접속 코드

**원인**: PK 추출을 mysql 직접 접속으로 구현. e2e.sh가 NODE_PATH를 설정하지만 mysql 클라이언트 라이브러리는 별도 설치가 필요해 ENOENT 발생.

**해결**: 시나리오 내 DB 코드 전면 제거. PK는 아래 DOM 추출 패턴으로 대체.

```js
// 등록 후 관리자 list에서 {PK_FIELD} 추출
await page.goto(`${BASE}/admin/taxi/singo/income_agent/list`, { waitUntil: 'domcontentloaded' });
await page.waitForFunction(() => typeof searchFormSubmit === 'function', { timeout: 10000 });
await page.evaluate((name) => { $('#page_keyword').val(name); searchFormSubmit(); }, TEST_NAME);
await page.waitForTimeout(1500);
const N = await page.evaluate((name) => {
    const el = document.getElementById('list_inner_html') || document.body;
    const cb = el.querySelector(`input.pk_check[request_name="${name}"]`);
    return cb ? parseInt(cb.value, 10) : null;
}, TEST_NAME);
```

저장된 값 검증도 화면(DOM)으로:

```js
// 저장·복원 검증: DB SELECT 대신 화면 입력값 확인
const restored = await iframe.evaluate(() => ({
    apply: (document.getElementById('marriage_apply')||{}).value,
    date:  (document.getElementById('marriage_singo_date')||{}).value,
}));
ok('화면: marriage_apply=Y 복원', restored.apply === 'Y', restored);
ok(`화면: date=${TEST_DATE} 복원`, restored.date === TEST_DATE, restored);
```

DB 검증이 필요한 경우 suite MD 말미 "DB 검증 (선택)" 섹션에만 SQL을 기재하고 `peach-db-query` 스킬로 별도 실행.

### 문제 #4: PK 추출 패턴

**원인**: 시나리오가 DB에 의존해 PK를 가져옴.

**해결**: 관리자 list 체크박스 DOM 속성으로 PK 추출 (위 문제 #3 해결책과 동일 패턴). 이 패턴이 suite MD와 시나리오 모두에서 표준 추출 방식이 되어야 함.

핵심 발견:
- `input.pk_check` 클래스를 가진 체크박스가 각 row의 PK를 `value`에, 이름을 `request_name` 속성에 가짐
- 이름 기반 검색(`$('#page_keyword').val(name); searchFormSubmit();`) 후 DOM에서 바로 추출 가능
- DB 조회 불필요

### 문제 #5: suite-템플릿.md의 DB 검증 위치

**원인**: 템플릿의 Step N에 `DB 검증: {SQL}` 항목이 포함되어, Step = 시나리오 .js 실행이라는 맥락에서 구현자가 DB 코드를 시나리오 파일에 넣도록 유도.

**해결**: 템플릿에서 Step 내 DB 검증 항목 제거. 대신 문서 말미에 선택 섹션으로 분리:

```markdown
## DB 검증 (선택)

E2E 시나리오는 화면 기준으로만 검증한다. DB 정합성이 의심될 때 `peach-db-query` 스킬로 직접 확인한다.

```sql
-- 예시
SELECT column1, column2 FROM table WHERE pk IN (상태파일_PK_목록);
```
```

### 문제 #6: suite 실행 후 등록 요약 부재

**원인**: 각 단위 시나리오 .js가 독립 프로세스로 실행되고 자기 결과만 stdout으로 출력한 뒤 종료. suite 레벨에서 "신규 등록 발생 단계 + 이름 + PK + 시각"을 통합해서 보여주는 메커니즘이 없음.

**해결**: 신규 등록이 발생하는 시나리오에서 상태 파일의 `registrations[]` 배열에 이력을 누적하고, suite 실행 완료 후 오케스트레이터(AI)가 이 파일을 읽어 표로 요약한다.

**state 파일 스키마 (`e2e/.tmp/e2e_marriage_state.json` 예시)**:

```json
{
  "registrations": [
    {
      "step": "사용자 02",
      "scenario": "사용자/02-등록-검증.js",
      "{PK_FIELD}": 1785,
      "name": "석변7706",
      "registered_at": "2026-04-29 07:34:56",
      "marriage_apply": "Y",
      "marriage_singo_date": "2025-03-15"
    },
    {
      "step": "관리자 01",
      "scenario": "관리자/01-신규등록-검증.js",
      "{PK_FIELD}": 1786,
      "name": "정문7656",
      "registered_at": "2026-04-29 07:35:25",
      "marriage_apply": "Y",
      "marriage_singo_date": "2025-03-15"
    }
  ]
}
```

**시나리오 .js 에서의 누적 패턴** (신규 등록이 발생하는 시나리오만 적용):

```js
// 등록 성공 후 state 파일에 이력 누적 (기존 user/admin 키는 그대로 유지)
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
if (!Array.isArray(state.registrations)) state.registrations = [];
state.registrations.push({
    step: '사용자 02',                          // suite MD의 단계명
    scenario: '사용자/02-등록-검증.js',         // 시나리오 파일 경로
    {PK_FIELD}: N,
    name: TEST_NAME,
    registered_at: new Date().toISOString().replace('T', ' ').slice(0, 19),
    marriage_apply: 'Y',
    marriage_singo_date: TEST_DATE,
});
fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
```

**suite MD에 추가할 "실행 후 등록 요약" 섹션** (최종 통합 기준 앞):

```markdown
## 실행 후 등록 요약

suite 전체 실행 완료 후 오케스트레이터(AI)가 아래 상태 파일을 읽어 표로 요약한다.

**상태 파일**: `e2e/.tmp/e2e_marriage_state.json`
**신규 등록이 발생하는 단계**: [단계 목록] (나머지는 기존 PK 재사용)

| 필드 | 내용 |
|------|------|
| `registrations[].step` | suite 단계명 |
| `registrations[].scenario` | 실행된 시나리오 파일 경로 |
| `registrations[].{PK_FIELD}` | 등록된 PK |
| `registrations[].name` | 등록된 이름 |
| `registrations[].registered_at` | 등록 시각 |
```

**일반화 원칙**: 이 패턴은 모든 suite에 적용 가능하다. 시나리오별로 등록 단계·처리 결과를 state 파일에 누적하고, suite 실행 완료 시 오케스트레이터가 요약 표를 생성한다. state 파일 키와 필드명은 도메인에 맞게 자유롭게 정의하되, `registrations[]` 배열 구조는 표준으로 유지한다.

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

**추가 위치**: "핵심 원칙" 섹션 (현재 행 188 부근) 바로 앞에 "도메인 설정 패턴" 섹션 삽입.

```markdown
## 도메인 설정 패턴 (E2E_BASE)

단위 시나리오 .js 파일은 **반드시** 파일 최상단에 `E2E_BASE` 환경변수 패턴을 사용한다.
하드코딩된 도메인은 다중 환경 실행을 차단하는 안티패턴이다.

```js
// 시나리오 파일 최상단 필수
const BASE = process.env.E2E_BASE || 'http://local.example.com';
```

suite MD에는 "도메인 설정" 섹션을 추가한다 (references/suite-템플릿.md 참조).

실행 예:
```bash
# 로컬
./e2e.sh run --tab N 시나리오/경로.js

# 개발서버
E2E_BASE=https://dev.example.com ./e2e.sh run --tab N 시나리오/경로.js
```
```

**행 188 수정**: "단위 시나리오 .js 파일은 수정하지 않는다" 뒤에 단서 추가.

현재:
```
- 단위 시나리오 .js 파일은 수정하지 않는다 — 통합 시나리오 md가 조합만 정의
```

수정:
```
- 단위 시나리오 .js 파일은 실행 로직 변경 없이 수정하지 않는다 — 단, 신규 시나리오 작성 시 E2E_BASE 패턴과 DB-free 설계를 반드시 적용한다 (아래 참조)
```

**추가**: "시나리오 설계 원칙" 섹션 신설 (핵심 원칙 섹션 내 또는 별도 섹션).

```markdown
## 시나리오 설계 원칙

### DB-free 설계

시나리오 .js 파일에는 DB 직접 접속 코드(mysql, dbQuery 등)를 넣지 않는다.

| 목적 | 금지 | 권장 |
|------|------|------|
| PK 추출 | `SELECT {PK_FIELD} FROM table WHERE name='...'` | 관리자 list DOM `input.pk_check[request_name]` 속성 |
| 저장 검증 | `SELECT column FROM table WHERE pk=N` | 화면 reload 후 입력 요소 `.value` 확인 |
| DB 정합성 | 시나리오 내 SQL | suite MD "DB 검증 (선택)" 섹션 + peach-db-query 스킬 |

이유:
- mysql 클라이언트는 e2e.sh NODE_PATH에 포함되지 않아 ENOENT 발생
- DB 접속 정보가 시나리오에 포함되면 환경 이식성이 0이 됨
- 화면 검증이 E2E 목적(사용자 경험 보증)에 더 부합

### PK 추출 표준 패턴

등록 후 PK({PK_FIELD} 등)를 관리자 list DOM에서 추출하는 표준 패턴:

```js
await page.evaluate((name) => { $('#page_keyword').val(name); searchFormSubmit(); }, TEST_NAME);
await page.waitForTimeout(1500);
const N = await page.evaluate((name) => {
    const el = document.getElementById('list_inner_html') || document.body;
    const cb = el.querySelector(`input.pk_check[request_name="${name}"]`);
    return cb ? parseInt(cb.value, 10) : null;
}, TEST_NAME);
if (!N || N <= 0) throw new Error('{PK_FIELD} 추출 실패');
```

전제: 관리자 list에 `input.pk_check` 체크박스가 있고, `request_name` 속성에 이름, `value`에 PK가 있어야 함.
```

**추가**: "실행 후 요약 출력" 항목을 "run 모드" 워크플로우 8번 스텝 뒤에 삽입.

```markdown
9. **실행 후 등록 요약** — state 파일(`e2e/.tmp/*.json`)의 `registrations[]`를 읽어 표로 출력한다.
   등록이 발생한 단계·이름·PK·시각을 한 표로 정리하여 사용자에게 보고한다.
   state 파일이 없거나 `registrations`가 비어 있으면 "신규 등록 없음"으로 표시한다.
```

### 3-2. references/suite-템플릿.md 변경

**변경 1**: Step 내 "DB 검증" 항목 제거, 화면 검증으로 대체.

현재:
```markdown
### Step N: 결과 검증
- 실행: 없음 (AI가 직접 확인)
- DB 검증: `{SQL}` → {기대값}
- 코드 검증: `{파일경로}` — {확인할 로직}
```

수정:
```markdown
### Step N: 결과 검증
- 실행: 없음 (AI가 직접 확인)
- 화면 검증: `{페이지 URL}` → `{DOM 선택자}.value === {기대값}`
- 코드 검증: `{파일경로}` — {확인할 로직}
```

**변경 2**: "도메인 설정" 섹션을 템플릿에 추가 (## 사전조건 앞).

```markdown
## 도메인 설정

시나리오는 `E2E_BASE` 환경변수로 도메인을 지정한다. 미지정 시 기본값 사용.

| 환경 | 도메인 | 실행 방법 |
|------|--------|-----------|
| 로컬 (기본값) | `http://local.example.com` | `./e2e.sh run --tab N 시나리오/...` |
| 개발서버 | `https://dev.example.com` | `E2E_BASE=https://dev.example.com ./e2e.sh run --tab N 시나리오/...` |
```

**변경 3**: "실행 후 등록 요약" 섹션을 ## 최종 통합 기준 앞에 추가.

```markdown
## 실행 후 등록 요약

suite 전체 실행 완료 후 오케스트레이터(AI)가 `e2e/.tmp/{state파일}.json`의
`registrations[]`를 읽어 아래 표 형태로 요약한다.

**신규 등록이 발생하는 단계**: {단계 목록}

| 단계 | 시나리오 | 이름 | PK | 등록 시각 | 주요 항목 |
|------|---------|------|:---:|---------|------|
| (state.registrations 데이터로 채움) | | | | | |

> 나머지 단계는 기존 PK를 재사용하며 신규 등록 없음.
```

**변경 4**: "DB 검증 (선택)" 섹션을 ## 최종 통합 기준 다음에 추가.

```markdown
## DB 검증 (선택)

E2E 시나리오는 화면 기준으로만 검증한다. DB 정합성이 의심될 때 `peach-db-query` 스킬로 직접 확인한다.

```sql
-- 예시: 등록건 확인
SELECT pk_column, key_columns
FROM table_name
WHERE pk_column IN (상태파일_PK_목록);
```
```

---

## 4. 검증 시나리오

### 시나리오 1: E2E_BASE 패턴 신규 시나리오 생성 확인

**목적**: 새로 생성된 시나리오가 E2E_BASE 패턴을 사용하는지 확인

**전제**: peach-e2e-scenario 스킬로 새 시나리오 생성 후

```bash
# 생성된 시나리오 파일에서 BASE 선언 확인
head -5 e2e/시나리오/{새로생성된}.js
```

**기대 결과**:
```js
const BASE = process.env.E2E_BASE || 'http://local.example.com';
```

**통과 기준**: `process.env.E2E_BASE` 패턴이 존재하고 `BASE`가 하드코딩되지 않음

---

### 시나리오 2: DB-free 설계 검증

**목적**: 새로 생성된 시나리오에 DB 코드가 없는지 확인

**전제**: peach-e2e-scenario 스킬로 새 시나리오 생성 후

```bash
# 시나리오 파일에서 DB 관련 코드 검색
grep -n "mysql\|dbQuery\|dbExec\|createConnection\|require.*mysql" e2e/시나리오/**/*.js
```

**기대 결과**: 아무것도 출력되지 않음 (DB 코드 없음)

**통과 기준**: mysql/DB 관련 import 또는 함수가 0건

---

### 시나리오 3: suite-템플릿.md 도메인 설정 섹션 확인

**목적**: 업데이트된 템플릿에 도메인 설정 섹션이 포함되었는지 확인

```bash
grep -n "E2E_BASE\|도메인 설정" skills/peach-e2e-suite/references/suite-템플릿.md
```

**기대 결과**: `E2E_BASE`와 `도메인 설정` 섹션이 출력됨

**통과 기준**: 두 키워드 모두 1건 이상

---

### 시나리오 4: SKILL.md DB-free 안내 확인

```bash
grep -n "DB-free\|DB 직접\|mysql\|dbQuery" skills/peach-e2e-suite/SKILL.md
```

**기대 결과**: DB-free 원칙 안내 텍스트가 출력됨

**통과 기준**: "DB-free" 또는 "DB 직접 접속 코드" 관련 경고 문구 존재

---

### 시나리오 5: registrations[] 누적 및 요약 확인

**목적**: 신규 등록 시나리오가 state 파일에 이력을 기록하고, suite 실행 후 오케스트레이터가 표를 출력하는지 확인

**전제**: suite 전체 실행 후

```bash
# state 파일에 registrations 배열 존재 확인
cat e2e/.tmp/{state파일}.json | grep -c '"step"'
```

**기대 결과**: 신규 등록 단계 수와 동일한 숫자 출력 (예: {기능명} suite → 3)

**통과 기준**: `registrations[]`에 step, scenario, name, {PK_FIELD}, registered_at 필드가 모두 존재

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. **피치 하네스 원본 폴더 확인**
   - Windows: `D:\peachSolution2\peach-harness\`
   - macOS: `~/source/peachSolution2/peach-harness/`

2. **대상 스킬 현재 상태 확인**
   ```bash
   cat skills/peach-e2e-suite/SKILL.md
   cat skills/peach-e2e-suite/references/suite-템플릿.md
   ```

3. **이 문서의 "3. 스킬 업데이트 제안"을 순서대로 반영**
   - `skills/peach-e2e-suite/SKILL.md` 수정:
     - "도메인 설정 패턴 (E2E_BASE)" 섹션 추가
     - 행 188 "단위 시나리오 .js 파일은 수정하지 않는다" 문구 수정
     - "시나리오 설계 원칙" 섹션(DB-free + PK 추출 패턴) 추가
   - `skills/peach-e2e-suite/references/suite-템플릿.md` 수정:
     - "도메인 설정" 섹션 추가 (사전조건 앞)
     - Step 내 "DB 검증" → "화면 검증"으로 교체
     - "실행 후 등록 요약" 섹션 추가 (최종 통합 기준 앞)
     - "DB 검증 (선택)" 섹션 추가 (최종 통합 기준 뒤)

4. **검증 시나리오(4장) 실행하여 변경 사항 확인**

5. **변경 완료 후**:
   - frontmatter의 `status`를 `completed`로 변경, `completed_at`과 `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거 (`git mv`로 rename)
   - 하단에 반영 기록 추가

---

## 참고: 이번 세션에서 수정한 실제 파일

이 피드백 문서 작성의 근거가 된 실제 변경 파일 목록:

| 파일 | 변경 내용 |
|------|-----------|
| `e2e/시나리오/{기능명}/사용자/01~04-*.js` | `E2E_BASE` 패턴 적용, DB 코드 제거 |
| `e2e/시나리오/{기능명}/관리자/01~04-*.js` | `E2E_BASE` 패턴 적용, DB 코드 제거, PK 추출 → DOM 방식으로 교체 |
| `docs/e2e-suite/{기능명}-항목추가-검증.md` | "도메인 설정" 섹션 + "실행 후 등록 요약" 섹션 + "DB 검증 (선택)" 섹션 추가 |
| `e2e/시나리오/{기능명}/사용자/02-등록-검증.js` | state.registrations[] 누적 추가 |
| `e2e/시나리오/{기능명}/관리자/01-신규등록-검증.js` | state.registrations[] 누적 추가 |
| `e2e/시나리오/{기능명}/관리자/04-귀속년도-목록필터-검증.js` | fs/path import 추가 + state.registrations[] 누적 추가 |

수정 후 로컬 도메인에서 8개 시나리오 전체 통과 확인 (2026-04-29, 2회).

---

## 반영 기록

- 반영일: 2026-04-29
- 적용자: 스파이크
- 반영 파일:
  - `peach-e2e-scenario/SKILL.md` — "시나리오 설계 원칙" 섹션 추가 (E2E_BASE 패턴, DB-free 원칙, PK DOM 추출 표준 패턴). 피드백 문서는 suite에 명시했으나 시나리오 생성 책임 위치 기준으로 e2e-scenario에 배치.
  - `peach-e2e-suite/SKILL.md` — 도메인 설정 패턴 섹션 추가, line 275 핵심 원칙 advisor안으로 수정, run 모드 8번 스텝 registrations 요약 추가
  - `peach-e2e-suite/references/suite-템플릿.md` — 도메인 설정 섹션, Step N DB검증→화면검증 교체, 실행 후 등록 요약 섹션, DB 검증(선택) 섹션 추가
