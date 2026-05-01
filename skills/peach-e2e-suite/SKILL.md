---
name: peach-e2e-suite
description: |
  E2E 단위 시나리오를 조합한 통합 테스트 시나리오를 md로 생성·관리·실행하는 스킬.
  "통합 시나리오", "e2e suite", "통합 테스트", "시나리오 조합",
  "e2e 통합", "전체 흐름 테스트" 키워드로 트리거.
---

# E2E 통합 시나리오 오케스트레이터

단위 시나리오(.js)를 비즈니스 플로우 단위로 조합한 **통합 테스트 시나리오를 md로 생성**하고,
md를 읽어 **순차 실행 + 단계별 검증 + 코드/DB 검증**까지 처리한다.

peach-e2e-scenario(단위 실행)의 상위 오케스트레이션 레이어.

## 모드

| 모드 | 트리거 | 동작 |
|------|--------|------|
| `auto` (기본) | `/peach-e2e-suite [설명]` | 생성 + 실행 |
| `create` | `/peach-e2e-suite create [설명]` | 통합 시나리오 md 생성만 |
| `run` | `/peach-e2e-suite run [md 파일명]` | 기존 md를 읽어 실행 |
| `recheck` | `/peach-e2e-suite recheck` | 소스 변경 감지 → 관련 시나리오만 선별 재실행 |

## 생성 파일 경로

```
docs/e2e-suite/
└── {업무흐름}-{핵심동작}.md
    예: 주문-결제-검증.md
        신규주문-전체흐름.md
        회원가입-로그인-검증.md
```

## Chrome Beta 실행 불변 규칙

Chrome Beta를 CDP 모드로 실행할 때는 고정 프로필 옵션이 필수다. 프로필 옵션이 빠진 실행은 세션 유지 실패로 간주한다.

- 허용: `cd e2e && ./e2e.sh chrome`
- 직접 실행 시 필수 옵션: `--remote-debugging-port=9222`, `--remote-allow-origins=*`, `--user-data-dir=$HOME/.chrome-beta-e2e-profile`, `--disable-extensions`
- 금지: `open -a "Google Chrome Beta"` 단독 실행, `--user-data-dir` 없는 Chrome Beta 실행, 다른 프로필 경로 임의 사용, 기본 Chrome 또는 다른 브라우저 우회

## 워크플로우

### 공통: 환경 확인

```bash
cd e2e && ./e2e.sh setup
cd e2e && ./e2e.sh status
```

`status`에서 `❌ Chrome CDP 미연결`이 보이면 아래 순서로 자동 복구를 먼저 시도한다.

1. `cd e2e && ./e2e.sh chrome &` 실행
2. `sleep 4` 대기
3. `cd e2e && ./e2e.sh status` 재확인
4. 여전히 미연결이면 사용자에게 `cd e2e && ./e2e.sh chrome` 수동 실행을 안내한다

> `./e2e.sh chrome`은 고정 프로필(`$HOME/.chrome-beta-e2e-profile`)로 Chrome Beta를 실행하는 표준 경로다. 이 명령 대신 직접 Chrome을 실행할 때도 `--user-data-dir` 옵션을 생략하지 않는다.

탭 목록을 사용자에게 보여주고 탭 번호 확인.

> Google/OAuth/관리자/결제/기존 Chrome Beta 프로필 세션 유지가 핵심인 통합 흐름은
> md 생성/분석까지만 진행하고, 실제 Step 실행은 사용자 승인 후 시작한다.

> **탭 드리프트 방지**: 탭 번호 응답 후 `agent-browser tab N` 직후
> `agent-browser eval "document.title + ' | ' + location.href"` 로 재검증한다.
> 예상과 다르면 `./e2e.sh status` 재출력 후 재선택.

> **파일 업로드 Step 포함 시**: OS 네이티브 파일 다이얼로그 차단을 위해
> `Page.setInterceptFileChooserDialog` 방식을 사용한다.
> (상세: `peach-e2e-browse/references/SPA-프레임워크-입력패턴.md §3`)

### create 모드

1. **요청 파악** — 사용자의 자연어 요청에서 테스트 대상 업무 플로우 파악
2. **단위 시나리오 탐색** — 기존 시나리오 목록 확인
   ```bash
   cd e2e && ./e2e.sh list
   ls e2e/시나리오/**/*.js
   ```
3. **시나리오 코드 분석** — 관련 단위 시나리오 .js 파일을 읽어 동작/입출력 파악
4. **DOM 선조사** (필요시) — agent-browser eval로 페이지 구조 확인
5. **정보 확인** — 사용자에게 확인:
   - 통합 시나리오 이름 (한글, kebab-case)
   - 포함할 단위 시나리오 목록 + 순서
   - 각 단계별 검증 포인트
   - 코드/DB 검증 항목 (있으면)
6. **md 생성** — `references/suite-템플릿.md` 참조하여 작성
7. **저장** — `docs/e2e-suite/{이름}.md`
   - 폴더 없으면 자동 생성
8. **완료 보고**

### run 모드

0. **state.json 초기화** (클린 실행 보장)
   ```bash
   rm -f e2e/.tmp/e2e_*_state.json
   ```
1. **md 파일 선택**
   ```bash
   ls docs/e2e-suite/*.md
   ```
   사용자가 파일 지정하거나, 목록에서 선택
2. **md 파싱** — frontmatter + 시나리오 흐름 읽기
3. **사전조건 확인** — md의 사전조건 섹션을 읽고 충족 여부 확인
4. **실행 승인 확인** — 민감 세션/고정 프로필 유지 흐름이면 실제 Step 실행 전 사용자 승인 확인
5. **순차 실행 루프** — 각 Step마다:
   a. 단위 시나리오 실행: `cd e2e && ./e2e.sh run --tab N 시나리오/경로`
   b. 실패 시: peach-e2e-scenario의 자동수정 패턴 적용 (에러 파싱 → DOM 확인 → 수정 → 재실행, 최대 3회)
   c. 검증 포인트 확인: agent-browser eval로 DOM/URL 상태 검증
   d. 전달 데이터 추출: 다음 Step에 필요한 데이터를 컨텍스트에 보관 (예: orderId)
   e. 데이터 주입: 다음 Step 실행 시 환경변수로 전달 (`E2E_ORDER_ID=xxx`)
6. **코드 검증** (md에 섹션이 있으면) — 해당 파일을 Read/Grep으로 확인
7. **DB 검증** (md에 섹션이 있으면) — peach-db-query 스킬 또는 직접 SQL 실행
   - **읽기(SELECT) 전용**. INSERT/UPDATE/DELETE는 검증이 아니라 fixture이므로 별도 fixture Step으로 분리한다.
8. **실행 후 등록 요약** — state 파일(`e2e/.tmp/*.json`)의 `registrations[]`를 읽어 표로 출력한다.
   등록이 발생한 단계·이름·PK·시각을 한 표로 정리하여 사용자에게 보고한다.
   state 파일이 없거나 `registrations`가 비어 있으면 "신규 등록 없음"으로 표시한다.
9. **suite 완료 보고** — 아래 표준 형식으로 출력 (실행 로그 전체 출력 금지)

```
✅ suite 완료 — {기능명} ({통과수}/{전체수})

| 시나리오 | 결과 | 비고 |
|---|---|---|
| {그룹명} 01~0N | ✅ 전체 통과 | |
| {그룹명} 0N | ✅ | 신규 PK={값} ({이름}) |
| {그룹명} 0N | ❌ | {실패 원인 1줄} |

AI 판단:
- 자동 수정: {있으면 "XX 수정 (N회)" / 없으면 "없음"}
- 잔여 이슈: {있으면 1줄 / 없으면 "없음"}

팀장 확인 필요: {있으면만 표시, 없으면 이 줄 생략}
```

### recheck 모드

프로그램 소스 변경 후 관련 시나리오만 선별 재실행한다. 전체 suite를 돌리는 것보다 토큰·시간 절약.

1. **변경 파일 감지**
   ```bash
   git diff --name-only HEAD~1 HEAD -- src/
   ```
2. **관련 시나리오 선별**

   | 변경 파일 패턴 | 실행 대상 |
   |---|---|
   | `lib/*/dao/` | 해당 모듈 전체 시나리오 |
   | `lib/*/service/` | 해당 모듈 전체 시나리오 |
   | `skin/.../insert.php` | 등록 시나리오 |
   | `skin/.../update.php` | 수정 시나리오 |
   | `controller/` | 해당 URL 관련 시나리오 전체 |

3. **state.json 초기화**
   ```bash
   rm -f e2e/.tmp/e2e_*_state.json
   ```
4. **선별된 시나리오만 순차 실행** (자동수정 루프 포함)
5. **suite 완료 보고** (표준 형식, 실행 제외 시나리오 명시)

### auto 모드 (기본)

create → run 연속 실행. 생성 후 바로 실행하여 검증.

## AI 자율 처리 범위

AI가 스스로 판단·처리하는 것과 사용자 확인이 필요한 것을 명확히 구분한다.

| 상황 | AI 자율 처리 | 사용자 확인 필요 |
|---|:---:|:---:|
| 시나리오 실행 | ✅ | |
| 오류 원인 분석 | ✅ | |
| 시나리오 코드 수정 (3회 이내) | ✅ | |
| 3회 수정 후도 실패 | | ✅ |
| suite 전체 통과 → 완료 보고 | ✅ | ✅ 피드백 |
| 일부 실패 + 자동수정 성공 → 보고에 수정내역 포함 | ✅ | ✅ 피드백 |
| 커밋·푸시 | | ✅ 항상 |
| 시나리오 파일 신규 생성·삭제 | | ✅ 항상 |

## 단계별 실패 처리

| 상황 | 처리 |
|------|------|
| 단위 시나리오 실행 실패 | 자동수정 루프 3회 시도 (peach-e2e-scenario 패턴) |
| 자동수정 3회 실패 | 해당 Step에서 중단, 실패 보고 |
| 검증 포인트 불일치 (suite md 오류) | 실행 결과 기반으로 suite md 자율 보정 → 재실행 |
| 전달 데이터 경로 오류 (suite md 오류) | 실제 DOM/URL 확인 후 suite md 자율 보정 → 재실행 |
| 코드/DB 검증 실패 | 불일치 내용 보고, 사용자 판단 요청 |

### suite md 자율 보정 범위

AI가 자율로 보정 가능:
- 검증 포인트 (DOM 선택자, URL 패턴, 기대값)
- 전달 데이터 추출 방법
- 사전 주입 환경변수명

사용자 확인 필요:
- Step 순서 변경
- 시나리오 파일 추가·삭제
- 사전조건 변경

> Step 실패 시 후속 Step은 실행하지 않는다 (데이터 의존성 때문).
> suite 실패는 전체 suite를 바로 반복하지 않는다.
> 실패한 Step의 단위 시나리오를 `peach-e2e-scenario run` 기준으로 먼저 재현/수정하고,
> 통과 후 suite를 재개한다.

## 데이터 전달 방식

단위 시나리오는 독립 프로세스(`node`)로 실행되어 메모리 공유 불가.
두 가지 방식을 상황에 맞게 사용한다.

### 방식 A: state.json 파일 (다단계 시나리오 PK 공유 — 권장)

```javascript
// 01-등록 시나리오 마지막에 저장
const STATE_FILE = path.join(__dirname, '../../.tmp/e2e_{기능명}_state.json');
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
state.user = { {PK_FIELD}: N, name: TEST_NAME };
fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));

// 02-수정 시나리오 시작에서 로드
let state = {};
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) {}
const PK = state.user?.{PK_FIELD}
    ? String(state.user.{PK_FIELD})
    : (process.env.E2E_PK || null);  // 단독 실행 fallback
if (!PK) throw new Error('state.json 없음. 01-등록 시나리오를 먼저 실행하세요.');
```

> `e2e/.gitignore`에 `.tmp/` 반드시 추가. run 모드 시작 전 자동 초기화.

### 방식 B: 환경변수 주입 (단순 값 전달)

```bash
# Step 1에서 orderId 추출
agent-browser eval "location.pathname.split('/').pop()"
# → orderId = "12345"

# Step 2에 주입
cd e2e && E2E_ORDER_ID=12345 ./e2e.sh run --tab 0 시나리오/2-결제.js
```

> 단위 시나리오 .js 코드에서 `process.env.E2E_ORDER_ID`로 접근 가능.

## md 구조

`references/suite-템플릿.md` 참조.

### frontmatter

```yaml
---
name: 주문-결제-검증
module: {PROJECT}
created: 2026-04-14
---
```

### 본문 구조

```markdown
# {통합 시나리오 이름}

## 사전조건
- Chrome Beta CDP 연결, 로그인 완료
- {필요한 데이터/상태}
- 탭: {시작 페이지}

## 시나리오 흐름

### Step 1: {단계명}
- 실행: `시나리오/{경로}.js`
- 검증:
  - {DOM/URL 검증 포인트}
- 전달 데이터: `{변수명}` ({추출 방법})

### Step 2: {단계명}
- 실행: `시나리오/{경로}.js`
- 사전 주입: `E2E_{변수명}=${값}`
- 검증:
  - {검증 포인트}

### Step N: 결과 검증
- 실행: 없음 (AI가 직접 확인)
- DB 검증: `{SQL}` → {기대값}
- 코드 검증: `{파일경로}` — {확인할 로직}

## 최종 통합 기준
- {전체 통과 조건}

## 실행 이력
| 일시 | 결과 | 비고 |
|------|------|------|
```

## 도메인 설정 패턴 (E2E_BASE)

시나리오 실행 시 `E2E_BASE` 환경변수로 도메인을 지정한다. 미지정 시 시나리오 파일의 기본값 사용.

```bash
# 로컬 (기본값)
./e2e.sh run --tab N 시나리오/경로.js

# 개발서버 지정
E2E_BASE=https://dev.example.com ./e2e.sh run --tab N 시나리오/경로.js
```

suite MD에 "도메인 설정" 섹션을 두 환경 실행법을 표로 정리한다 (`references/suite-템플릿.md` 참조).

## TDD와 E2E의 책임 경계

suite는 비즈니스 플로우 단위 검증을 조립하는 레이어다. 다음 분리 원칙을 강제한다.

- **단위 시나리오(.js)**: UI 조작과 UI 결과 검증만 담당. **DB 읽기·쓰기 모두 금지**(시나리오 실행 환경에 DB 클라이언트가 없어 require 자체가 ENOENT). DB 정합성 확인이 필요하면 suite md의 DB 검증 단계 또는 `peach-db-query` 스킬에서만 수행한다.
- **DB 사전조건/시드 데이터**: suite md의 **fixture Step**으로 분리한다. 단위 시나리오 안에 절대 두지 않는다.
- **재시작/세션 리셋**: suite md의 별도 Step으로 분리한다. 단위 시나리오 안에서 처리하지 않는다.
- **로직 단위 검증**: suite가 아니라 backend/store TDD에서 처리한다(`peach-gen-backend`/`peach-gen-store` 참조). suite로 로직 분기 케이스를 모두 커버하려 하지 않는다.

위반 사례(시나리오 내부 DB 읽기/쓰기, 시나리오 안 재시작)를 발견하면 사용자에게 알리고 fixture/Step 분리를 먼저 제안한다.

## 핵심 원칙

- 단위 시나리오 .js의 신규 생성·구조 변경은 peach-e2e-scenario를 거친다. suite는 조합 정의 + 실행 + 자동수정 루프(3회)를 통한 .js 보완을 수행한다.
- 실행은 반드시 `e2e.sh run`을 통해 — 직접 `node` 호출 금지
- 검증 포인트는 자연어로 기술 — AI가 해석하여 agent-browser eval로 확인
- Step 실패 시 후속 Step 실행 금지 (데이터 의존성)
- 실행 이력은 git log에서 확인한다. suite md 파일은 시나리오 정의만 포함하며 실행 결과로 변경되지 않는다.

## 도구 역할 분담

| 용도 | 도구 |
|------|------|
| 단위 시나리오 실행 | `./e2e.sh run` |
| 검증 포인트 확인 | `agent-browser eval` |
| 코드 검증 | Read, Grep |
| DB 검증 | peach-db-query 또는 직접 SQL |
| iframe 검증 | `./e2e/pwc.sh eval` (fallback) |

## 참조 문서

| 문서 | 용도 | 로드 조건 |
|------|------|-----------|
| `references/suite-템플릿.md` | md 생성 템플릿 | create, auto |

## 완료 후 안내

```
통합 시나리오가 완료되었습니다.

📄 파일: docs/e2e-suite/{이름}.md

**관련 스킬:**
- `/peach-e2e-scenario` — 단위 시나리오 생성/실행/자동수정
- `/peach-e2e-browse` — DOM 탐색/디버깅
- `/peach-e2e-suite run {파일명}` — 이 통합 시나리오 재실행
```
