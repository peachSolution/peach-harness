# Validation 통과 패턴

E2E 시나리오 실행 중 form validation 실패를 해결하는 패턴 모음.
실제 프로젝트에서 발생한 사례를 기반으로 작성.

---

## 1. 필수 필드 자동 채우기

form submit 시 필수 필드가 비어있으면 validation 에러가 발생한다.
시나리오에서 해당 필드를 채우거나, 이미 채워져 있는지 확인 후 진행한다.

### 패턴: 조건부 입력

```javascript
// 필드가 비어있을 때만 입력
const value = await page.locator('#field').inputValue();
if (!value) {
  await page.locator('#field').fill('기본값');
}
```

### 패턴: select 필수 선택

```javascript
// 선택되지 않은 경우만 첫 번째 옵션 선택
const selected = await page.locator('#select').inputValue();
if (!selected) {
  await page.locator('#select').selectOption({ index: 1 }); // 0은 보통 placeholder
}
```

---

## 2. 미사용 데이터 삭제

목록에서 불필요한 항목이 남아있으면 validation에 걸릴 수 있다.
예: 미사용 항목이 남아있어 "미사용 항목을 삭제하세요" 경고 발생.

### 패턴: 미사용 항목 삭제 후 진행

```javascript
// 미사용 항목 삭제 버튼이 있으면 모두 클릭
const deleteButtons = await page.locator('.unused-item .delete-btn').all();
for (const btn of deleteButtons) {
  await btn.click();
  await page.waitForTimeout(300); // 삭제 애니메이션 대기
}
```

### 패턴: 경고 다이얼로그 확인 후 삭제

```javascript
// 삭제 시 confirm 다이얼로그가 뜨는 경우
const handler = setDialogHandler(page, defaultDialogHandler, async (dialog) => {
  if (dialog.message().includes('삭제')) {
    await dialog.accept();
  }
});

await page.locator('.delete-btn').click();

// handler 복원
setDialogHandler(page, handler, defaultDialogHandler);
```

---

## 3. 기본값 자동 세팅 대응

서버가 특정 필드에 기본값을 자동 세팅하면, 시나리오의 기대값과 불일치할 수 있다.
예: 포장재가 자동으로 "기본 포장"으로 세팅됨 → 기대값이 "없음"이면 실패.

### 해결 전략

1. **기대값을 실제 기본값에 맞춤** — 서버 기본값이 정상 동작이면 기대값을 수정
2. **기본값을 명시적으로 변경** — 시나리오에서 원하는 값으로 직접 설정

```javascript
// 전략 1: 기대값 수정
const packaging = await page.locator('#packaging').inputValue();
console.log(`📝 포장재 현재값: ${packaging}`); // 기본값 확인 후 기대값 조정

// 전략 2: 명시적 설정
await page.locator('#packaging').selectOption('원하는값');
```

---

## 4. checkbox / radio 강제 선택

체크되지 않은 필수 checkbox나 radio가 있으면 validation 실패.

### 패턴: 체크 상태 확인 후 선택

```javascript
// checkbox
const isChecked = await page.locator('#agree').isChecked();
if (!isChecked) {
  await page.locator('#agree').check();
}

// radio — 아무것도 선택되지 않은 경우
const radioChecked = await page.locator('input[name="type"]:checked').count();
if (radioChecked === 0) {
  await page.locator('input[name="type"]').first().check();
}
```

---

## 5. 날짜 필드 처리

날짜 필드는 빈 값이면 validation 실패하는 경우가 많다.

```javascript
// 오늘 날짜 입력
const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
await page.locator('#date-field').fill(today);

// 또는 dispatchEvent로 날짜 변경 이벤트 발생
await page.locator('#date-field').fill(today);
await page.locator('#date-field').dispatchEvent('change');
```

---

## 6. 동적 validation 에러 메시지 확인

validation 실패 원인을 파악하기 위해 에러 메시지를 수집한다.

```bash
# DOM에서 validation 에러 메시지 수집
agent-browser eval "JSON.stringify(Array.from(document.querySelectorAll('.error,.invalid,.validation-error,[class*=error]')).map(function(e){return e.innerText}).filter(Boolean))"

# form의 validity 상태 확인
agent-browser eval "JSON.stringify(Array.from(document.querySelectorAll('input:invalid,select:invalid,textarea:invalid')).map(function(e){return {name:e.name,msg:e.validationMessage}}))"
```

이 결과를 기반으로 어떤 필드가 validation에 걸리는지 파악하고, 위 패턴을 적용한다.

---

## 7. 서버 사이드 이력 조건 — 테스트 전 상태 초기화

서버가 **값이 변경될 때만** 이력/로그를 기록하는 로직인 경우,
이전 실행에서 같은 값이 남아 있으면 재저장해도 이력이 생기지 않아 테스트 오탐 발생.

**증상**: "이력 없음" / "검색결과가 없습니다"가 연속 실행 시 반복적으로 나타남

**해결**: 검증 전 대상 필드를 중립값(NULL/미선택)으로 초기화.

```javascript
// [0] 이전 실행 상태 초기화 (NULL로 리셋)
let iframe = await openModalIframe(page, pk);
await iframe.locator('select[name="status"]').selectOption('');  // NULL/미선택
await iframe.locator('button[type=submit]').click();
await page.waitForTimeout(300);

// [1] 이제 Y로 저장 → NULL→Y 변경 → 이력 생성 보장
iframe = await openModalIframe(page, pk);
await iframe.locator('select[name="status"]').selectOption('Y');
await iframe.locator('button[type=submit]').click();
```

> 위 셀렉터(`select[name="status"]`, submit 버튼)는 예시. 실제 폼 구조에 맞게 교체.

---

## 8. captcha가 포함된 화면

captcha가 있는 등록/제출 화면은 시나리오 작성 시 백엔드와 우회 방안을 먼저 협의한다.
스킬 차원의 표준 우회 코드는 제공하지 않는다 — 서버 측 분기가 영구적 백도어가 될 위험이 있어,
프로젝트별 보안 정책에 맞춰 별도로 결정한다.
