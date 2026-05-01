---
name: peach-team-e2e
model: opus
description: |
  Spec과 ui-proto 기반으로 E2E 환경 세팅 + 단위 시나리오 자동 분할 + 통합 suite 생성 + 실행 + 부합 검증을 한 번에 처리하는 통합 팀 스킬.
  "e2e 검증해줘", "통합 검증", "전체 흐름 테스트", "팀 e2e", "스펙대로 동작하는지 확인",
  "ui-proto와 다른지 확인", "최종 검증", "릴리스 전 검증" 키워드로 트리거.
  peach-e2e-setup + peach-e2e-scenario + peach-e2e-suite 3개 스킬의 패턴을 흡수하고,
  검증 기준을 ui-proto 화면 + Spec 비즈니스 규칙으로 외부화한다.
  단순 코드 동작 검증을 넘어, 기획 의도와 부합하는지 자동 검증하는 게 핵심 차별점.
---

# Peach Team E2E

ui-proto 화면 흐름 + Spec 비즈니스 규칙을 검증 기준으로 삼아, E2E 시나리오를 자동 분할/조합/실행/검증/보완하는 통합 오케스트레이터.

## Overview

`peach-team-dev`로 본 개발이 끝난 시점에 호출한다. 다음을 한 번에 처리한다.

1. (필요시) E2E 환경 세팅
2. 검증 기준 로드 (ui-proto + Spec)
3. 단위 시나리오 자동 분할
4. 통합 suite 자동 생성
5. 실행 + 미스매치 분류
6. 보완 루프 (랄프루프 5/10회)

기존 `peach-e2e-setup`, `peach-e2e-scenario`, `peach-e2e-suite`는 단계별 단독 호출용 Tier 2로 그대로 유지된다. 이 스킬은 그 3단계를 통합하면서 **검증 기준을 ui-proto + Spec으로 외부화**하는 게 핵심 차별점.

> 의사결정 근거: `docs/05-스킬재구성-2026-04-27.md` 참조.
> 표준 워크플로우: `docs/03-워크플로우.md` 참조.

## TDD와 E2E의 책임 경계

team-e2e는 **사용자 경험 검증**만 담당한다. 로직 분기 검증은 backend/store TDD가 책임진다.

| 영역 | 책임 | 대상 |
|------|------|------|
| TDD (단위/통합) | 로직이 의도대로 동작하는가 | 분기 함수, DAO, 데이터 변환. `peach-gen-backend`/`peach-gen-store`의 TDD 게이트가 처리 |
| E2E (team-e2e) | 사용자가 보는 그대로 동작하는가 | UI 흐름, 인터랙션, 비즈니스 규칙의 외부 가시 결과 |

운영 규칙:

- 단위 시나리오 안에서 DB 직접 접근(읽기/쓰기 모두), 마이그레이션, 서버/앱 재시작을 발견하면 fixture/suite Step 또는 `peach-db-query`로 분리시킨 뒤 진행한다.
- ui-proto/Spec 모호 영역에서 "이건 TDD에서 검증해야 한다" 판단이 서면 보완 루프로 끌고 가지 말고, backend/store 측 TDD 추가를 권고한다.
- 미스매치 분류 시 "로직 버그"는 team-e2e가 직접 고치지 않고 backend/store 쪽으로 넘긴다.

## 핵심 차별점 — 검증 기준의 외부화

기존 E2E는 "코드가 동작하는지"만 검증했다. 이 스킬은 **"기획 의도와 부합하는지"**를 검증한다.

| 검증 항목 | 1차 기준 | 2차 기준 |
|----------|---------|---------|
| 화면 레이아웃, 컴포넌트 배치 | ui-proto 화면 | (없으면 Spec) |
| 사용자 인터랙션 흐름 | ui-proto 화면 | Spec |
| 비즈니스 규칙 (검증, 권한, 분기) | Spec | (없으면 검증 불가 → 보고) |
| 데이터 정확성 (API 응답값) | Spec | (없으면 검증 불가 → 보고) |
| 에러/예외 처리 | Spec | - |

**핵심 원칙**: ui-proto가 있으면 ui-proto, 없거나 모호하면 Spec, 둘 다 모호하면 보고.

> ui-proto는 본질적으로 Mock이라 100% 구현되지 않을 수 있다.
> 시각적 흐름 + 인터랙션 시퀀스만 ui-proto 기준, 데이터 정확성은 Spec 기준.

## Inputs

```bash
/peach-team-e2e [proto=<경로>] [model=opus|sonnet|haiku]

# 옵션
# proto=<경로>      ui-proto 태스크 폴더 절대 경로 (검증 기준 1차)
# model=...         서브에이전트 모델 override (기본 sonnet)
```

| 인자 | 역할 |
|------|------|
| `proto` | 선택. ui-proto 저장소의 태스크 폴더 절대 경로 |
| `model` | 선택. 서브에이전트 모델 override |

`proto` 인자가 없으면 본 프로젝트의 `docs/spec/...`만 검증 기준으로 사용한다.

## Preconditions

- `peach-team-dev`로 본 개발이 완료된 상태 (또는 동등한 코드 존재)
- 본 프로젝트의 `docs/spec/{년}/{월}/...`에 Spec 파일 존재 (또는 `proto` 인자로 ui-proto 경로 제공)
- E2E 환경이 미세팅이면 자동 세팅 진입 (e2e/ 폴더, Chrome Beta CDP 등)

## 강제 게이트

- `./e2e.sh status`로 탭 목록을 확인하고 사용자가 실행 탭을 지정하기 전에는 실행 명령(`./e2e.sh run`, `agent-browser eval`, 탭 전환)을 시작하지 않는다.
- Google 로그인, OAuth, 관리자 콘솔, 결제, 기존 Chrome Beta 프로필 세션 유지가 핵심인 작업은 시나리오 생성/분석까지만 진행하고, 실제 실행은 사용자 확인 후 시작한다.
- `agent-browser` 디버깅이 비정상이면 OS 레벨 브라우저 우회(`open -a`, 다른 브라우저, 다른 프로필 경로)를 하지 않는다.
- 로그인/2차 인증은 사용자가 Chrome Beta 고정 프로필에서 먼저 인증을 완료하도록 안내한다.

## 워크플로우

### 0. 입력 검증

#### 에이전트 팀 기능 활성화 확인

```bash
cat ~/.claude/settings.json | grep -i "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"
```

설정이 없거나 `"1"`이 아니면 즉시 중단하고 안내. (peach-team-dev와 동일)

#### 검증 기준 가용성 확인

```
proto 인자 있음 + _spec.md 존재 → 표준 검증 모드 (ui-proto + Spec)
proto 인자 없음 + docs/spec/... 존재 → Spec-only 검증 모드
proto 인자 없음 + docs/spec/... 없음 → 사용자에게 검증 기준 입력 요청
```

마지막 케이스에서는 다음 중 선택:
- (a) `/peach-gen-spec`으로 사후 Spec 작성 후 재진입 (권장)
- (b) 자연어로 검증 기준 직접 입력 ("로그인 → 게시판 작성 → 저장 → 목록 확인" 같은 흐름)
- (c) 코드 동작 검증만 진행 (검증 기준 외부화 포기, 비권장)

### 1. E2E 환경 세팅 (필요시)

`peach-e2e-setup`의 패턴을 흡수한다.

```bash
# e2e/ 폴더 존재 확인
[ -d "e2e" ] && echo "✅ e2e/ 존재" || echo "❌ e2e/ 없음 — 세팅 필요"

# 기본 도구 확인
command -v agent-browser && command -v node && echo "✅ 도구 설치됨"

# Chrome Beta 확인
ls "/Applications/Google Chrome Beta.app" 2>/dev/null || echo "❌ Chrome Beta 미설치"

# CDP 연결 확인
curl -s http://127.0.0.1:9222/json/version > /dev/null && echo "✅ CDP 연결" || echo "❌ CDP 미연결"
```

미세팅이면 다음 자동 진행:

1. `e2e/` 폴더 없음 → `peach-e2e-setup` 인프라 코드 배포
2. 도구 미설치 → 사용자에게 설치 안내 (자동 설치 금지)
3. Chrome Beta 미설치 → 사용자 안내 후 중단
4. CDP 미연결 → `cd e2e && ./e2e.sh chrome &` 자동 실행 후 재확인

상세는 `references/e2e-setup-흡수.md` 참조.

### 2. 검증 기준 로드

#### 표준 검증 모드 (proto + Spec)

```bash
# proto 경로의 Spec과 화면 폴더 분석
cat <PROTO_PATH>/_spec.md
ls <PROTO_PATH>/                              # 서브모듈 폴더 목록
find <PROTO_PATH> -name "*.vue" -type f       # 화면 파일 목록

# 본 프로젝트 Spec 사본 확인
ls docs/spec/{년}/{월}/

# 두 Spec이 일치하는지 확인 (불일치 시 사용자 확인)
diff <PROTO_PATH>/_spec.md docs/spec/{년}/{월}/{기능명}.md 2>/dev/null
```

검증 기준 컨텍스트로 다음을 추출:
- **시각/흐름 기준 (ui-proto)**: 페이지 진입 → 사용자 액션 시퀀스 → 화면 전환 → 결과 확인
- **비즈니스 규칙 기준 (Spec)**: 입력 검증 규칙, 권한 분기, 상태 전이, 에러 케이스
- **데이터 정확성 기준 (Spec)**: API 응답 형태, DB 상태 변화

#### Spec-only 검증 모드

ui-proto가 없으면 Spec에서 화면 흐름까지 추출한다 (ui-proto만큼 정확하지는 않음).

상세는 `references/검증기준-로드.md` 참조.

### 3. 팀 구성 다이어그램

```
e2e-scenario-dev ──→ e2e-scenario-qa
       │                    │
       └──→ e2e-suite-dev ──→ e2e-suite-qa
                              │
                              └──→ 실행 + 미스매치 분류
                                          │
                                          └──→ (분류 결과 기반 보완 루프)
```

| 역할 | 책임 | references |
|------|------|-----------|
| e2e-scenario-dev | 단위 시나리오 자동 분할 + 작성 | references/scenario-dev-agent.md |
| e2e-scenario-qa | 단위 시나리오 문법 + 단독 실행 검증 | references/scenario-qa-agent.md |
| e2e-suite-dev | 단위 시나리오 조합 + suite md 생성 | references/suite-dev-agent.md |
| e2e-suite-qa | suite 실행 + ui-proto/Spec 부합 검증 | references/suite-qa-agent.md |

오케스트레이터(이 스킬)가 각 역할의 결과를 받아 다음 단계로 분배한다.

### 4. 팀 생성 및 작업 등록

```
TeamCreate: team_name="[기능명]-e2e-team"

TaskCreate:
1. "단위 시나리오 분할 작성" (owner: e2e-scenario-dev)
2. "단위 시나리오 검증" (blockedBy: Task1, owner: e2e-scenario-qa)
3. "통합 suite 생성" (blockedBy: Task2, owner: e2e-suite-dev)
4. "통합 suite 실행 + 부합 검증" (blockedBy: Task3, owner: e2e-suite-qa)
```

### 5. 단위 시나리오 자동 분할

`peach-e2e-scenario`의 패턴을 흡수한다.

검증 기준에서 **사용자 액션 단위**로 시나리오를 분할한다.

예: 게시판 관리 기능
```
검증 기준 (ui-proto + Spec):
  로그인 → 게시판 목록 진입 → 검색 → 상세 보기 → 수정 → 저장 → 목록 복귀

단위 시나리오 분할:
  1-로그인.js
  2-게시판-목록.js
  3-게시판-검색.js
  4-게시판-상세.js
  5-게시판-수정.js
  6-게시판-저장-확인.js
```

분할 기준:
- **단일 사용자 액션**: 1개 시나리오 = 1개 명확한 결과
- **데이터 의존성 표시**: 다음 시나리오에 전달할 데이터 명시 (예: orderId)
- **재사용 가능성**: 다른 통합 흐름에서도 재사용 가능한 단위로 분할
- **실패 격리**: 한 시나리오 실패가 다른 시나리오에 전파되지 않도록 독립 실행 가능

기존 시나리오 코드 패턴은 `peach-e2e-scenario/references/` 참조.

### 6. 통합 suite 자동 생성

`peach-e2e-suite`의 패턴을 흡수한다.

단위 시나리오를 비즈니스 흐름 단위로 조합한 통합 suite md를 생성한다.

```
docs/e2e-suite/{기능명}-{핵심동작}.md
```

생성 내용:
- frontmatter (name, module, created)
- 사전조건 (CDP 연결, 로그인, 시작 페이지)
- Step별 시나리오 흐름
- 단계별 검증 포인트
- 데이터 전달 방식
- 코드/DB 검증 (필요시)
- **검증 우선순위 규칙 적용 결과** (ui-proto/Spec 기준 매핑)
- 최종 통합 기준

템플릿은 `peach-e2e-suite/references/suite-템플릿.md` 참조.

### 7. 실행 + 미스매치 분류

suite md를 순차 실행하면서 각 Step의 결과를 검증 기준과 대조한다.

#### 실행 절차

각 Step마다:
1. 단위 시나리오 실행: `cd e2e && ./e2e.sh run --tab N 시나리오/경로`
2. 검증 포인트 확인: `agent-browser eval`로 DOM/URL 상태 검증
3. 검증 기준과 대조 (ui-proto 화면 / Spec 비즈니스 규칙)
4. 전달 데이터 추출/주입

#### 미스매치 분류

실패 시 **3가지로 분류**한다.

| 분류 | 원인 | 처리 |
|------|------|------|
| **(a) Spec 비즈니스 규칙 위반** | 본 프로젝트 코드가 Spec과 다르게 동작 | 본 프로젝트 코드 수정 (peach-team-dev 호출) |
| **(b) ui-proto 화면 흐름과 다름** | 본 프로젝트 화면이 ui-proto와 다르게 구현됨 | 본 프로젝트 코드 수정 (peach-team-dev mode=ui) |
| **(c) 시나리오 자체 오류** | 시나리오 코드의 셀렉터/로직 오류 | 시나리오 수정 (e2e-scenario 자동수정 패턴) |

분류 판단:
- 검증 기준(ui-proto/Spec)에 명시된 동작과 다름 → (a) 또는 (b)
- 검증 기준에는 맞지만 시나리오가 잘못 작성됨 → (c)
- 모호한 경우 사용자에게 보고

상세는 `references/미스매치-분류.md` 참조.

### 8. 보완 루프 (랄프루프 5/10회)

분류 결과에 따라 다음으로 분기한다.

#### (a)/(b) 본 프로젝트 코드 수정

**소규모 자율 수정** (아래 조건 모두 충족 시 AI가 자율 처리):
- 단일 파일 변경
- Spec/ui-proto에 명확한 근거가 있음
- 변경 범위가 10줄 이내

```
미스매치 분류 → Spec/proto 근거 확인
  → 소규모(단일 파일·명확 근거·10줄 이내): 자율 수정 → 재실행 → 보완 루프 계속
  → 그 외: 미스매치 보고 → 사용자 확인 → /peach-team-dev로 수정 위임 → 재실행
```

소규모 자율 수정 시 보고 형식:
```
🔧 자율 수정: {파일경로} — {Spec 근거 한 줄}
```

#### (c) 시나리오 수정

```
peach-e2e-scenario 자동수정 패턴 적용 → 재실행 (최대 3회)
```

상세는 `peach-e2e-scenario/references/자동수정-판단트리.md` 참조.

#### 랄프루프 상한

| 변경 규모 | 상한 |
|----------|------|
| 단순 시나리오 수정 (자동수정 가능 범위) | 3회 (e2e-scenario 기준) |
| Spec/proto 부합 검증 + 코드 수정 (소규모) | 5회 |
| Spec/proto 부합 검증 + 코드 수정 (중대규모) | 10회 |

상한 도달 시:
```
⚠️ Ralph Loop 상한 도달

미스매치 이력:
[분류별 실패 내역]

권고:
- (a)/(b) 미해결: peach-team-dev로 코드 수정 후 재진입
- (c) 미해결: peach-e2e-scenario로 단위 시나리오 직접 디버깅
- 검증 기준 자체에 모호함이 있으면 Spec/ui-proto 보강 필요
```

## QA 판정 처리

`peach-team-dev`와 동일한 3단계(APPROVED / CONDITIONAL / REJECTED).

- **APPROVED**: 모든 단위 시나리오 + 통합 suite 통과 + 검증 기준 부합
- **CONDITIONAL**: 일부 단계는 통과했으나 부분적으로 기준 미부합 (오케스트레이터 판단)
- **REJECTED**: 검증 기준 위반 + 자동수정 불가 → 랄프루프 진입

상세는 `peach-team-dev/SKILL.md`의 "QA 판정 처리" 섹션과 동일한 패턴 적용.

## Completion

모든 검증 통과 후:

### 1. 증거 수집

```
- 단위 시나리오 파일 목록 + 실행 결과
- 통합 suite md 경로
- 미스매치 분류 이력 (있었다면)
- 검증 기준 부합 결과 (ui-proto/Spec 매핑)
```

### 2. 팀 정리

```
SendMessage(shutdown_request) → 모든 팀원에게
TeamDelete → 팀 정리
```

## 완료 보고 형식

### 표준 검증 모드 (proto + Spec)

```
🎉 E2E 통합 검증 완료 (표준 모드)

기능: [기능명]
proto: [proto 경로]
검증 기준: ui-proto + Spec

생성된 산출물:
- 단위 시나리오: e2e/시나리오/[카테고리]/*.js (X개)
- 통합 suite: docs/e2e-suite/[기능명]-[핵심동작].md
- 실행 보고: docs/qa/{년}/{월}/[기능명]-e2e-{날짜}.md

검증 결과:
✅ 화면 레이아웃: ui-proto 일치
✅ 인터랙션 흐름: ui-proto 일치
✅ 비즈니스 규칙: Spec 부합
✅ 데이터 정확성: Spec 부합
✅ 에러/예외 처리: Spec 부합

(검증 불가 항목이 있으면 보고)

Ralph Loop 이력:
- 분류 (a) Spec 위반: X건 → 수정 완료
- 분류 (b) proto 불일치: X건 → 수정 완료
- 분류 (c) 시나리오 오류: X건 → 자동수정 완료

다음 단계:
→ 릴리스 가능
```

### Spec-only 검증 모드

```
✅ E2E 통합 검증 완료 (Spec-only 모드)

기능: [기능명]
검증 기준: Spec (ui-proto 없음)

검증 결과:
✅ Spec 부합 결과
⚠️ 화면 레이아웃: ui-proto 없음 → 시각 검증 생략

다음 단계:
→ ui-proto가 추후 생성되면 시각 검증 추가 가능
→ 릴리스 가능
```

### 검증 기준 부재 모드 (자연어 입력)

```
⚠️ E2E 검증 완료 (검증 기준 약함)

검증 기준: 사용자 자연어 입력
주의: ui-proto/Spec 없이 진행되어 검증 신뢰도가 낮습니다.

다음 단계:
→ /peach-gen-spec으로 사후 Spec 작성 권장
→ 사용자가 결과를 직접 확인 필수
```

## Examples

```bash
# === 표준 모드 (proto 사용) ===

# proto 경로로 검증 기준 자동 로드
/peach-team-e2e proto=<PROTO_REPO>/src/modules-task/2604/260427-<initial>-goods

# opus 모델로 서브에이전트 실행
/peach-team-e2e proto=<PROTO_REPO>/.../260427-<initial>-goods model=opus

# === Spec-only 모드 ===

# proto 없이 docs/spec/... 만 사용
/peach-team-e2e

# === 검증 기준 부재 모드 (비권장) ===

# Spec/proto 없이 자연어 검증 기준 입력
/peach-team-e2e
# → "검증 기준이 없습니다. 어떻게 할까요?" 안내 후 (b) 자연어 입력 선택
```

## 도구 역할 분담

| 용도 | 도구 |
|------|------|
| 단위 시나리오 실행 | `./e2e.sh run` |
| 검증 포인트 확인 | `agent-browser eval` |
| 코드 검증 | Read, Grep |
| DB 검증 | peach-db-query 또는 직접 SQL |
| iframe 검증 | `./e2e/pwc.sh eval` (fallback) |

## 관련 스킬

- `peach-team-dev` — 본 개발 (이 스킬의 선행 단계)
- `peach-e2e-setup` — E2E 환경 단독 세팅 (Tier 2)
- `peach-e2e-scenario` — 단위 시나리오 단독 작성/실행/자동수정 (Tier 2)
- `peach-e2e-suite` — 통합 suite md 단독 생성/실행 (Tier 2)
- `peach-e2e-browse` — 브라우저 탐색/디버깅 (검증 중 보조)

> 이 스킬은 위 4개 e2e-* 스킬과 **같은 가이드 패턴을 흡수한다**.
> 진짜 SoT는 시나리오 코드 패턴(`peach-e2e-scenario/references/`)과 e2e 인프라 코드(`peach-e2e-setup/references/`).
> Tier 2 스킬과 본 스킬은 같은 패턴을 두 가지 호출 방식으로 사용한다.
> `browse/scenario/suite`는 병합 대상이 아니라 연결 대상이다. 수명주기가 다르므로 Tier 2 단독 호출성을 유지한다.

| 스킬 | 수명주기 |
|------|----------|
| `peach-e2e-browse` | 일회성 탐색/디버깅 |
| `peach-e2e-scenario` | 반복 가능한 단위 회귀 검증 |
| `peach-e2e-suite` | 업무 흐름 단위 통합 검증 |
| `peach-team-e2e` | Spec/ui-proto 기준 최종 부합 검증 |

## 핵심 원칙

- 검증 기준은 **ui-proto + Spec**에서 외부화 (코드 동작 검증을 넘어 기획 의도 부합 검증)
- ui-proto가 1차, Spec이 2차 (단, 비즈니스 규칙은 Spec이 1차)
- 미스매치는 **3가지로 분류** (Spec 위반 / proto 불일치 / 시나리오 오류)
- 코드 수정은 **자동 위임 금지** — 사용자 확인 후 peach-team-dev 호출
- 시나리오 수정은 **3회 자동수정** (peach-e2e-scenario 패턴)
- 랄프루프 상한 5/10회 (변경 규모 기반)
- 검증 기준이 없거나 모호하면 **사용자에게 보고**, 강제 진행 금지
