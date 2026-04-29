---
status: completed
target_skill: peach-e2e-browse
severity: 높음 2 / 중간 3 / 낮음 1
completed_at: 2026-04-19
applied_by: Claude Sonnet 4.6
---

# peach-e2e-browse 피드백 — 2026-04-19

> **대상 스킬**: peach-e2e-browse
> **작성 근거**: NotebookLM(Angular 기반 SPA)을 agent-browser로 제어하면서 발견한 실전 제어 실패 패턴 6가지.
> Angular/React 같은 SPA 프레임워크 사이트를 제어할 때 다른 사이트에도 그대로 적용된다.
> **심각도 요약**: 높음 2건 / 중간 3건 / 낮음 1건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 SKILL.md에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | `agent-browser fill ref "텍스트"` 가 Angular ngModel, React controlled input에서 제출 버튼을 활성화하지 못함 | 높음 | X (없음) | — |
| 2 | `document.querySelector('input[type=file]')` 로 숨겨진 file input을 못 찾음 — SPA에서 file input이 shadow-like 방식으로 숨겨져 있을 때 | 높음 | X (없음) | — |
| 3 | `tab list` 후 사용자가 탭 번호를 응답하는 사이 탭이 닫히거나 번호가 바뀌면 재확인 없이 잘못된 탭에서 작업하게 됨 | 중간 | 부분 (세션 끊김만 언급) | 규칙 12 (재연결만 기술) |
| 4 | Angular/React SPA에서 `eval`로 value 직접 설정 후 이벤트를 발행하지 않으면 버튼 활성화 안 됨 — 현재 의사결정 트리가 "SPA → 로딩 대기"만 다루고 "입력 이벤트 발행" 케이스가 없음 | 중간 | X (없음) | 의사결정 트리 40-41행 |
| 5 | DOM.setFileInputFiles (CDP 직접 제어) 후 OS 파일 선택 다이얼로그가 추가로 열리는 사이트가 있음 — 인터셉트 없이 직접 주입하면 다음 명령이 막힘 | 중간 | X (없음) | — |
| 6 | CDP `Input.insertText` 로 SPA 입력을 우회하는 방법이 스킬 문서에 전혀 언급 없음 — eval + 이벤트 발행으로 안 될 때 다음 단계를 모름 | 낮음 | X (없음) | — |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: Angular ngModel / React controlled input에서 fill 실패

**원인**: `agent-browser fill` 또는 `eval element.value = 'text'`는 DOM 값만 바꾸고
프레임워크의 change/input 이벤트를 트리거하지 않아 버튼이 비활성 상태로 남음.

**해결 — 3단계 시도**:

```bash
# 1단계: focus 먼저
agent-browser eval "document.querySelector('textarea[aria-label=\"쿼리 상자\"]').focus()"

# 2단계: fill 시도 (성공하면 끝)
agent-browser fill ref "입력할 텍스트"

# 3단계: fill이 안 되면 → eval value 설정 + 이벤트 발행
agent-browser eval "document.querySelector('textarea').value = '입력값'"
agent-browser eval "document.querySelector('textarea').dispatchEvent(new Event('input', {bubbles:true}))"
agent-browser eval "document.querySelector('textarea').dispatchEvent(new Event('change', {bubbles:true}))"
```

**판별법**: fill 후 `agent-browser snapshot -i -c` 에서 버튼이 여전히 `[disabled]`이면 이벤트 미발행.

**마지막 수단**: 자동화 스크립트(Node.js CDP 직접 접속)에서 `Input.insertText` 사용 (아래 #6 참조).

---

### 문제 #2: 숨겨진 file input 탐색 실패

**원인**: SPA에서 file input이 `display:none` 또는 프레임워크 컴포넌트 내부에 있으면
`document.querySelector('input[type=file]')` 가 null 반환.

**해결 — TreeWalker 탐색**:

```bash
# querySelector 대신 TreeWalker로 전체 DOM 순회
agent-browser eval "
(function(){
  var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT);
  var node;
  while(node = walker.nextNode()) {
    if (node.tagName === 'INPUT' && node.type === 'file')
      return 'found: accept=' + node.accept + ' visible=' + (node.offsetWidth > 0);
  }
  return 'not found';
})()"
```

**실전 결과**: NotebookLM, Google Drive 업로드 등 Angular SPA에서 TreeWalker로만 탐색 가능했음.

---

### 문제 #3: tab list 후 탭 변경 감지

**원인**: 사용자가 탭 번호를 응답하는 사이(수 초~수십 초) Chrome에서 탭이 닫히거나
페이지가 새로고침 되면 번호가 달라짐.

**해결 — tab N 직후 재확인 필수**:

```bash
# 1. 사용자가 "2번 탭"이라고 응답한 뒤
agent-browser tab 2

# 2. 즉시 재확인 (탭이 바뀌지 않았는지)
agent-browser eval "document.title + ' | ' + location.href"

# 3. 예상한 사이트가 아니면 tab list 다시 출력 후 재선택
agent-browser tab list
```

**규칙**: `tab N` 직후 반드시 `eval document.title`로 탭 상태를 검증한다. 예상과 다르면 재확인.

---

### 문제 #4: SPA 입력 후 버튼 비활성 — 의사결정 트리 분기 누락

**원인**: 현재 의사결정 트리는 "SPA → 로딩 대기"만 안내하고,
"입력 성공인데 버튼 비활성" 케이스를 다루지 않음.

**판별 흐름**:

```
fill 또는 eval value 설정 후 버튼이 [disabled]이면
  → snapshot -i -c 에서 버튼 상태 재확인
  → [disabled] 유지 → 이벤트 미발행 의심
  → eval dispatchEvent(new Event('input', {bubbles:true})) 추가 시도
  → 여전히 [disabled] → change 이벤트도 발행
  → 여전히 [disabled] → CDP Input.insertText 시도 (스크립트 필요)
```

---

### 문제 #5: DOM.setFileInputFiles 후 OS 다이얼로그 잔존

**원인**: 일부 SPA(Angular 포함)는 CDP로 file input에 파일을 주입해도
OS 파일 선택 다이얼로그를 추가로 트리거함. 다이얼로그가 열린 채로 다음 명령을 보내면 실패.

**해결 — Page.setInterceptFileChooserDialog로 OS 다이얼로그 자체 차단**:

```bash
# 1. 인터셉트 활성화
Page.setInterceptFileChooserDialog(enabled:true)

# 2. agent-browser click 으로 업로드 버튼 클릭
#    eval click()은 isTrusted:false 라 SPA가 무시할 수 있음

# 3. Page.fileChooserOpened 이벤트에서 backendNodeId 수신

# 4. DOM.setFileInputFiles({ files, backendNodeId }) 실행
```

**주의**: macOS 파일 다이얼로그는 Chrome 바깥 XPC 서비스로 떠서
`agent-browser press Escape` 와 CDP `Input.dispatchKeyEvent(Escape)` 모두 무효다.
처음 시도하는 사이트에서는 직접 주입보다 인터셉트 방식을 기본값으로 사용한다.

---

### 문제 #6: CDP Input.insertText 경로 미기술

**원인**: eval + 이벤트 발행으로도 안 될 때 다음 단계가 없음.

**해결 — 자동화 스크립트 내에서 CDP Input.insertText**:

```javascript
// Node.js + CDP WebSocket 직접 제어 스크립트에서만 사용 가능
// agent-browser CLI로는 이 명령을 직접 호출할 수 없음

// 1. textarea focus
await page.evaluate(() => document.querySelector('textarea').focus());

// 2. CDP Input.insertText 전송
const cdpSession = await page.context().newCDPSession(page);
await cdpSession.send('Input.insertText', { text: '입력할 텍스트' });

// → Angular ngModel, React controlled input 모두 정상 트리거됨
```

**사용 조건**: Playwright/CDP 자동화 스크립트가 있을 때만 가능.
순수 agent-browser CLI 환경에서는 eval + 이벤트 발행 방식까지만 시도.

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 의사결정 트리 보강 (35~41행 근처)

현재 SPA 분기:
```
└─ SPA 로딩 대기 필요
   → wait --load networkidle 또는 eval "!!querySelector('타겟')" 체크
```

추가할 분기:
```
└─ SPA 로딩 대기 필요
   → wait --load networkidle 또는 eval "!!querySelector('타겟')" 체크
└─ SPA 입력 후 버튼이 [disabled] 유지
   → 이벤트 미발행 의심
   → eval dispatchEvent(new Event('input', {bubbles:true}))
   → 여전히 안 되면 CDP Input.insertText (자동화 스크립트 필요)
```

### 3-2. 핵심 규칙에 2개 추가 (현재 17개 규칙 뒤에)

```markdown
18. **Angular/React fill 실패 → 이벤트 발행 추가** — fill 후 버튼이 [disabled]이면
    eval dispatchEvent(new Event('input', {bubbles:true}))를 반드시 시도한다.
19. **tab N 직후 title 재확인** — tab list → 사용자 응답 → tab N 후 반드시
    eval document.title로 탭이 맞는지 검증한다.
```

### 3-3. 새 레퍼런스 파일 추가

`references/SPA-프레임워크-입력패턴.md` 신규 생성 권장:
- Angular ngModel 입력 우회 패턴
- React controlled input 이벤트 발행
- file input TreeWalker 탐색
- Page.setInterceptFileChooserDialog 기반 OS 다이얼로그 차단
- CDP Input.insertText 사용 조건

---

## 4. 검증 시나리오

### 시나리오 1: Angular SPA 텍스트 입력 검증 (NotebookLM 기준)

**목적**: fill 실패 → 이벤트 발행 fallback 흐름이 작동하는지 확인
**전제**: Chrome Beta CDP 연결됨, NotebookLM 탭이 열려있음

```bash
# 1. 탭 확인
agent-browser tab list
agent-browser tab 1  # NotebookLM 탭 번호

# 2. 제목 재확인 (규칙 19 검증)
agent-browser eval "document.title + ' | ' + location.href"

# 3. fill 시도
agent-browser snapshot -i -c
agent-browser fill e22 "테스트 입력"  # ref는 실제 스냅샷 결과 참고

# 4. 버튼 상태 확인
agent-browser snapshot -i -c 2>&1 | grep "제출"
# [disabled] 이면 → 5단계

# 5. 이벤트 발행 시도
agent-browser eval "document.querySelector('textarea[aria-label=\"쿼리 상자\"]').dispatchEvent(new Event('input', {bubbles:true}))"

# 6. 버튼 재확인
agent-browser snapshot -i -c 2>&1 | grep "제출"
```

**통과 기준**: 5~6단계 후 버튼에서 `[disabled]` 가 사라짐.

---

### 시나리오 2: TreeWalker file input 탐색

**목적**: 숨겨진 file input을 querySelector 대신 TreeWalker로 찾는지 확인

```bash
# 1. 일반 querySelector 시도 (실패 예상)
agent-browser eval "document.querySelector('input[type=file]') ? '있음' : '없음'"

# 2. TreeWalker로 탐색 (성공 예상)
agent-browser eval "(function(){ var w = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT); var n; while(n=w.nextNode()){if(n.tagName==='INPUT'&&n.type==='file')return 'found';} return 'not found'; })()"
```

**통과 기준**: 1단계 '없음', 2단계 'found' 반환.

---

### 시나리오 3: tab 번호 재확인 흐름

**목적**: tab N 후 예상치 못한 탭에 연결됐을 때 감지할 수 있는지 확인

```bash
# 1. tab list 출력 후 탭 전환
agent-browser tab list
agent-browser tab 0

# 2. 즉시 title 재확인
agent-browser eval "document.title + ' | ' + location.href"
# 예상한 사이트 URL인지 확인 → 아니면 tab list 다시 출력
```

**통과 기준**: title 확인 후 예상과 다를 때 재선택 절차를 진행할 수 있음.

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. 피치 하네스 원본 폴더 확인
   - macOS: `~/source/peachSolution2/peach-harness/`

2. 대상 스킬 현재 상태 확인
   ```bash
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-browse/SKILL.md
   ```

3. 이 문서의 "3. 스킬 업데이트 제안" 순서대로 반영:
   - SKILL.md 의사결정 트리 35~41행 근처에 SPA 입력 이벤트 분기 추가
   - 핵심 규칙 18, 19번 추가
   - `references/SPA-프레임워크-입력패턴.md` 신규 생성

4. 4장 검증 시나리오 3개 실행하여 확인

5. 완료 후:
   - frontmatter `status: completed`, `completed_at`, `applied_by` 기입
   - 파일명에서 `TODO-` 제거 (`git mv`)
   - 하단 반영 기록 추가

---

## 참고: 기존 peach-e2e-browse 피드백과의 관계

- `2026-04-14-peach-e2e-browse-피드백.md` — native dialog, CDP daemon 상주, 외부 링크 전환 패턴 (반영 완료)
- **이 문서** — SPA 프레임워크 입력 제어, 숨겨진 file input, tab 재확인 패턴 (신규, 반영 대기)

두 문서는 다른 문제를 다루며 중복 없음.

---

## 반영 기록

- **반영일**: 2026-04-19
- **반영자**: Claude Sonnet 4.6

### 검증 결과 (실전 — Chrome Beta CDP + .m4a 파일 2개 업로드)

| 시나리오 | 결과 | 비고 |
|----------|:----:|------|
| 시나리오 3: tab N 직후 title 재확인 (규칙 19) | ✅ 통과 | |
| 시나리오 2: querySelector file input 탐색 | ✅ 바로 탐색됨 | TreeWalker는 fallback — 사이트마다 다름 |
| 시나리오 1: fill → 버튼 활성화 | ✅ fill만으로 활성화 | 이벤트 발행은 fallback — 사이트마다 다름 |
| 문제 #5: OS 파일 다이얼로그 처리 | ❌→✅ | 재분석 후 올바른 해법 도출 (아래 참조) |

### 신규 발견 — 문제 #5 해법 수정 (규칙 20 승격)

**TODO에 기술된 해법(Escape 전송)은 동작하지 않음** — 실전에서 확인됨.

- CDP `Input.dispatchKeyEvent(Escape)` → 무효
- `agent-browser press Escape` → 무효
- **이유**: macOS 파일 다이얼로그는 Chrome 바깥 XPC 서비스(`com.apple.appkit.xpc.openAndSavePanelService`)로 뜨므로 CDP 키 이벤트 범위 밖

**올바른 해법**: `Page.setInterceptFileChooserDialog(enabled:true)` 로 OS 다이얼로그 자체를 차단.
어떤 사이트에서든 동일하게 적용되며, 재사용 가능한 스크립트 템플릿이 `references/SPA-프레임워크-입력패턴.md §3`에 수록됨.

### 변경 파일

- `SKILL.md` — 의사결정 트리 파일 업로드 분기 추가, 규칙 18·19·20 추가, 참조 테이블 1행 추가
- `references/SPA-프레임워크-입력패턴.md` — 신규 생성
  - §1: Angular/React fill 실패 → 이벤트 발행 fallback (범용)
  - §2: 숨겨진 file input TreeWalker 탐색 fallback (범용)
  - §3: OS 파일 다이얼로그 완전 차단 — Page.setInterceptFileChooserDialog 방식 + 재사용 스크립트 템플릿
  - §4: CDP Input.insertText 최후 수단
  - §5: tab N 직후 title 재확인
