---
status: completed
target_skill: peach-e2e-scenario, peach-e2e-suite, peach-e2e-browse
severity: 중간 1
completed_at: 2026-04-21
applied_by: 스파이크
---

# peach-e2e-* Chrome CDP 자동실행 피드백 — 2026-04-21

> **대상 스킬**: peach-e2e-scenario (주), peach-e2e-suite, peach-e2e-browse
> **작성 근거**: CDP 미연결 시 매번 사용자에게 수동 실행을 안내하는 패턴이 반복 발견됨
> **심각도 요약**: 중간 1건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | `./e2e.sh status`에서 "CDP 미연결" 감지 시 AI가 자동으로 `./e2e.sh chrome`을 실행하지 않고 사용자에게 수동 실행을 안내만 함 | 중간 | O (안내만 있음) | scenario 50, suite 39~40, browse 130 |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: CDP 미연결 시 사용자 개입 필요

**원인**:
- `peach-e2e-scenario` SKILL.md 50행: `CDP 미연결이면: ./e2e.sh chrome 실행 요청.` — "요청"이라는 표현이 AI가 사용자에게 안내만 하도록 해석됨
- `peach-e2e-suite` SKILL.md 39~40행: `./e2e.sh setup` / `./e2e.sh status` 만 명시되어 있고, CDP 미연결 대응 로직이 없음
- `peach-e2e-browse` SKILL.md 130행: `CDP 미연결이면 아래 명령으로 직접 실행한다.` — "직접 실행"이 사용자가 실행해야 한다는 의미로 해석됨

**해결**:
AI가 CDP 미연결을 감지하면 자동으로 `./e2e.sh chrome`을 실행한 뒤 재확인한다.
최종적으로도 미연결이면 그때 사용자에게 안내한다.

```bash
# 1. status 확인
cd e2e && ./e2e.sh status

# 2. CDP 미연결이면 자동 실행 (e2e/ 폴더가 있는 경우)
cd e2e && ./e2e.sh chrome &
sleep 4

# 3. 재확인
cd e2e && ./e2e.sh status

# 4. 여전히 미연결이면 사용자 안내
echo "⚠️ Chrome Beta CDP 자동 실행에 실패했습니다. 수동으로 아래 명령을 실행해 주세요:"
echo "  cd e2e && ./e2e.sh chrome"
```

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

#### peach-e2e-scenario — 행 43~54 ("공통: 환경 확인 + 탭 확인" 섹션)

현재 (50행):
```
CDP 미연결이면: `./e2e.sh chrome` 실행 요청.
```

변경 후:
```
CDP 미연결이면:
1. `cd e2e && ./e2e.sh chrome` 백그라운드 실행 (`&`)
2. 4초 대기 (`sleep 4`)
3. `./e2e.sh status` 재확인
4. 여전히 미연결이면 사용자에게 수동 실행 안내
```

구체적으로 43~54행을 아래 내용으로 교체:

```markdown
### 공통: 환경 확인 + 탭 확인

```bash
cd e2e && ./e2e.sh setup
```

`setup`이 모든 환경(Chrome Beta, agent-browser, playwright-cli, CDP 연결)을 자동 체크/설치한다.

CDP 미연결이면:
1. `cd e2e && ./e2e.sh chrome` 직접 실행 (백그라운드 `&`)
2. 4초 대기 (`sleep 4`)
3. `cd e2e && ./e2e.sh status` 재확인
4. 여전히 미연결이면 사용자에게 안내:
   `! cd {e2e폴더} && ./e2e.sh chrome` 명령을 직접 실행해 주세요

```bash
cd e2e && ./e2e.sh status
```
```

#### peach-e2e-suite — 행 36~41 ("공통: 환경 확인" 섹션)

현재 (38~40행):
```bash
cd e2e && ./e2e.sh setup
cd e2e && ./e2e.sh status
```

변경 후 — setup/status 사이에 CDP 자동 복구 로직 설명 추가:

```markdown
### 공통: 환경 확인

```bash
cd e2e && ./e2e.sh setup
cd e2e && ./e2e.sh status
```

탭 목록을 사용자에게 보여주고 탭 번호 확인.

`status`에서 "CDP 미연결" 감지 시:
1. `cd e2e && ./e2e.sh chrome` 백그라운드 실행 (`&`)
2. 4초 대기
3. `./e2e.sh status` 재확인
4. 여전히 미연결이면 사용자에게 수동 실행 안내
```

#### peach-e2e-browse — 행 118~160 ("1단계: 환경 확인" 섹션)

현재 (130행):
```
CDP 미연결이면 아래 명령으로 직접 실행한다.
```

변경 후 — 130행을 아래로 교체:
```
CDP 미연결이면:
1. e2e/ 폴더가 있는 경우 → `cd e2e && ./e2e.sh chrome &` 실행 후 `sleep 4` → `./e2e.sh status` 재확인
2. e2e/ 폴더가 없는 경우 → 아래 OS별 직접 실행 명령 자동 실행 후 `sleep 5` → `curl -s http://127.0.0.1:9222/json/version` 재확인
3. 재확인 후에도 미연결이면 사용자에게 수동 실행 안내
```

### 3-2. references/ 추가/수정

변경 없음. 기존 references/에 별도 파일 불필요. SKILL.md 본문 수정만으로 충분.

### 3-3. 공통 패턴 정의

세 스킬 모두 동일한 로직이므로, 각 SKILL.md에 동일한 "CDP 자동 복구 4단계" 패턴을 삽입한다.

---

## 4. 검증 시나리오

### 시나리오 1: e2e/ 폴더가 있는 프로젝트에서 CDP 미연결 자동 복구

**목적**: CDP 미연결 감지 후 AI가 자동으로 `./e2e.sh chrome`을 실행하는지 확인
**전제**:
- `e2e/` 폴더와 `e2e.sh`가 존재하는 프로젝트
- Chrome Beta가 CDP 없이 실행 중이거나 미실행 상태

```bash
# 단계 1: CDP 없는 상태 확인
curl -s http://127.0.0.1:9222/json/version || echo "❌ CDP 미연결"

# 단계 2: status에서 미연결 메시지 확인
cd e2e && ./e2e.sh status
# → "❌ Chrome CDP 미연결" 메시지 포함 여부 확인

# 단계 3: AI가 자동으로 아래를 실행해야 함
cd e2e && ./e2e.sh chrome &
sleep 4

# 단계 4: 재확인
cd e2e && ./e2e.sh status
# → "✅ CDP 연결됨" 및 탭 목록 출력
```

**기대 결과**: AI가 사용자 개입 없이 4단계를 자동 수행하고 탭 목록 출력
**통과 기준**: "몇 번 탭에서 실행할까요?" 단계까지 사용자 개입 없이 도달

### 시나리오 2: 자동 복구 실패 시 사용자 안내

**목적**: 자동 실행 후에도 CDP 미연결 상태가 지속될 때 적절한 안내 메시지 제공 여부 확인
**전제**:
- Chrome Beta 설치 경로가 비표준이거나, 포트 충돌이 발생한 상황

```bash
# 단계 1: chrome 자동 실행 후 재확인
cd e2e && ./e2e.sh chrome &
sleep 4
curl -s http://127.0.0.1:9222/json/version || echo "❌ 여전히 미연결"

# 단계 2: 사용자에게 다음 형식의 안내가 출력되어야 함
# "⚠️ Chrome Beta CDP 자동 실행에 실패했습니다.
#  수동으로 아래 명령을 실행해 주세요:
#  ! cd {e2e폴더경로} && ./e2e.sh chrome"
```

**기대 결과**: 안내 메시지 출력 및 수동 명령어 제시
**통과 기준**: 사용자가 명령어를 복붙하여 실행 가능한 형태로 안내

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. 피치 하네스 원본 폴더 확인
   - Windows: `D:\peachSolution2\peach-harness\`
   - macOS: `~/source/peachSolution2/peach-harness/`

2. 대상 스킬 현재 상태 확인
   ```bash
   cat skills/peach-e2e-scenario/SKILL.md
   cat skills/peach-e2e-suite/SKILL.md
   cat skills/peach-e2e-browse/SKILL.md
   ```

3. 이 문서의 "3. 스킬 업데이트 제안"을 순서대로 반영
   - `peach-e2e-scenario/SKILL.md` 43~54행 수정 (50행 "실행 요청" → 4단계 자동 복구 로직)
   - `peach-e2e-suite/SKILL.md` 36~50행 수정 (status 이후 CDP 자동 복구 로직 추가)
   - `peach-e2e-browse/SKILL.md` 130행 수정 ("직접 실행" → 자동 실행 후 재확인 흐름)

4. 검증 시나리오(4장) 실행하여 변경 사항 확인
   - 시나리오 1: CDP 미연결 상태에서 스킬 실행 → 자동 복구 확인
   - 시나리오 2: 자동 복구 실패 시 안내 메시지 확인

5. 변경 완료 후:
   - frontmatter의 `status`를 `completed`로 변경, `completed_at`과 `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거 (`git mv`로 rename)
   - 하단에 반영 기록 추가:
   ```markdown
   ## 반영 기록
   - [날짜] {에이전트}: SKILL.md 수정 — peach-e2e-scenario 50행, peach-e2e-suite 39~40행, peach-e2e-browse 130행
   ```

## 반영 기록

- [2026-04-21] 스파이크: SKILL.md 수정 — `peach-e2e-scenario`, `peach-e2e-suite`, `peach-e2e-browse`에 CDP 자동 복구 흐름 반영, `peach-e2e-scenario` 중복 안내 블록 제거
