---
status: completed
target_skill: peach-e2e-suite
severity: 중간 1 / 낮음 1
completed_at: 2026-04-15
applied_by: Claude Sonnet 4.6 (스파이크)
---

# peach-e2e-suite 피드백 — 2026-04-15

> **대상 스킬**: peach-e2e-suite
> **작성 근거**: E2E suite 실행 후 suite md 파일의 last_run/status가 자동 업데이트되어 git에 커밋되는 문제 발견
> **심각도 요약**: 중간 1건 / 낮음 1건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | suite md의 `last_run`/`status` 업데이트가 git에 불필요한 커밋을 반복 발생시킴 | 중간 | O (행 83, 128~130) | 83, 128~130 |
| 2 | `last_run`/`status`는 git log에 이미 기록되는 중복 정보임에도 frontmatter 필드로 관리 중 | 낮음 | O (행 128~130) | 128~130 |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1/#2: last_run/status 필드 제거

**원인**: SKILL.md 행 83에서 run 모드 마지막 단계로 "frontmatter의 `last_run`, `status`, 실행 이력 테이블 갱신"을 명시하고 있음. 이로 인해 E2E 실행마다 suite md 파일이 변경되어 git 커밋 대상이 됨. git log에 이미 실행 시각과 결과가 기록되므로 완전한 중복 정보임.

**해결**: suite md 파일의 frontmatter에서 `last_run`/`status` 필드를 제거하고, run 모드 8단계(md 업데이트)를 삭제한다.

실행 이력이 필요한 경우 대안:
```bash
# 실행 이력을 .gitignore 처리된 별도 로그 파일로 관리
docs/e2e-suite/.run-log/{suite명}.log   # .gitignore에 추가
```

**적용한 임시 조치**: 기존 suite md(`docs/e2e-suite/직원등록-경력증명서-전체흐름.md`)에서 `last_run`/`status` 필드를 직접 제거함.

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

**행 83 수정** — run 모드 8단계 삭제:
```
# 현재 (행 83)
8. **md 업데이트** — frontmatter의 `last_run`, `status`, 실행 이력 테이블 갱신

# 변경 후 → 이 줄 전체 삭제
```

**행 128~130 수정** — frontmatter 예시에서 `last_run`/`status` 제거:
```yaml
# 현재
---
name: 주문-결제-검증
module: {PROJECT}
created: 2026-04-14
last_run:
status: pending    # pending | pass | fail
---

# 변경 후
---
name: 주문-결제-검증
module: {PROJECT}
created: 2026-04-14
---
```

### 3-2. references/suite-템플릿.md 수정

`references/suite-템플릿.md` 내 frontmatter 예시에도 `last_run`/`status` 필드가 있을 경우 동일하게 제거.

```bash
grep -n "last_run\|status" ~/source/peachSolution2/peach-harness/skills/peach-e2e-suite/references/suite-템플릿.md
```

### 3-3. (선택) 실행 이력 로그 분리 안내 추가

run 모드 결과 보고(현재 행 82) 뒤에 아래 안내 추가 (선택 사항):

```markdown
> 실행 이력은 git log에서 확인한다. suite md 파일은 시나리오 정의만 포함하며 실행 결과로 변경되지 않는다.
```

---

## 4. 검증 시나리오

### 시나리오 1: frontmatter 필드 미존재 확인

**목적**: 수정 후 신규 생성되는 suite md에 `last_run`/`status` 필드가 없는지 확인
**전제**: SKILL.md 수정 완료
```bash
# 단계 1: suite md 신규 생성 실행
# /peach-e2e-suite create [테스트용 흐름 이름]

# 단계 2: 생성된 파일 frontmatter 확인
grep -n "last_run\|status" docs/e2e-suite/{생성된파일}.md
```
**기대 결과**: 출력 없음 (두 필드 모두 존재하지 않음)
**통과 기준**: grep 결과가 빈 값

### 시나리오 2: run 모드 실행 후 md 파일 미변경 확인

**목적**: run 모드 실행 후 suite md 파일이 git 변경 대상이 되지 않는지 확인
**전제**: SKILL.md 행 83 삭제 완료
```bash
# 단계 1: git status 기록 (실행 전)
git status docs/e2e-suite/

# 단계 2: /peach-e2e-suite run [md파일] 실행

# 단계 3: git status 재확인
git status docs/e2e-suite/
```
**기대 결과**: 실행 전후 git status 동일 (suite md 파일이 modified 목록에 없음)
**통과 기준**: `docs/e2e-suite/*.md` 파일이 변경되지 않음

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. 피치 하네스 원본 폴더 확인
   - macOS: `~/source/peachSolution2/peach-harness/`

2. 대상 스킬 현재 상태 확인
   ```bash
   cat ~/source/peachSolution2/peach-harness/skills/peach-e2e-suite/SKILL.md
   ```

3. 이 문서의 "3. 스킬 업데이트 제안"을 순서대로 반영
   - SKILL.md 행 83 삭제 (`**md 업데이트**` 단계 전체)
   - SKILL.md 행 128~130 수정 (frontmatter에서 `last_run`/`status` 제거)
   - `references/suite-템플릿.md` 내 동일 필드 확인 후 제거

4. 검증 시나리오(4장) 실행하여 변경 사항 확인

5. 변경 완료 후:
   - frontmatter의 `status`를 `completed`로 변경, `completed_at`과 `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거 (`git mv`로 rename)
   - 하단에 반영 기록 추가

---

## 반영 기록

- [2026-04-15] Claude Sonnet 4.6 (스파이크):
  - `SKILL.md` 행 83 삭제 (`**md 업데이트**` 단계)
  - `SKILL.md` 행 128~130 수정 (`last_run`/`status` frontmatter 제거)
  - `SKILL.md` 핵심 원칙 마지막 줄 수정 (실행 이력 → git log 안내)
  - `references/suite-템플릿.md` frontmatter 예시에서 `last_run`/`status` 제거
  - `references/suite-템플릿.md` 작성 규칙 7항 수정 (실행 이력 → git log 안내)
