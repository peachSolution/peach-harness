---
status: completed
target_skill: peach-db-query
severity: 높음 1 / 중간 1 / 낮음 0
completed_at: 2026-04-15
applied_by: 스파이크
---

# peach-db-query 피드백 — 2026-04-15

> **대상 스킬**: peach-db-query
> **작성 근거**: macOS 환경에서 psql 미설치 상태임에도 Docker fallback으로 진행하다가,
> 사용자가 직접 "psql 설치하자"고 요청한 뒤에야 brew install libpq를 실행함.
> macOS에서는 CLI 설치가 간단하고 빠른데 Docker를 먼저 시도한 것이 비효율적이었음.
> **심각도 요약**: 높음 1건 / 중간 1건 / 낮음 0건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | macOS에서 CLI 미설치 시 Docker fallback으로 넘어가 버림. macOS는 brew install libpq 한 방으로 해결되는데 Docker 이미지(~400MB) 다운로드를 시도함 | 높음 | X (OS 분기 없이 fallback 처리) | 92~119 |
| 2 | 프리플라이트에서 CLI 미설치 확인 후 "설치 안내"만 하고 **실제 설치를 자동 진행하지 않음** — 사용자가 직접 명령어를 터미널에 쳐야 하는 마찰 발생 | 중간 | X (안내만 있고 자동설치 없음) | 70~91 |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: macOS에서 Docker fallback 대신 CLI 설치 우선

**원인**: 프리플라이트 섹션이 "CLI 미설치 → 설치 안내 → Docker fallback" 순서로 구성되어 있으나,
OS 분기 없이 Docker를 대안으로 제시함. macOS는 brew로 즉시 설치 가능하므로 Docker가 필요 없음.

**해결**: 이번 대화에서 수동으로 아래 순서로 진행:
```bash
# 1. CLI 설치 여부 확인
which psql || echo "psql 없음"

# 2. macOS이므로 brew install 진행 (사용자 승인 후)
brew install libpq

# 3. PATH 등록
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# 4. 접속 확인
PGPASSWORD='{DB_PASSWORD}' psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {DB_NAME} -c "SELECT 1;"
```

**결과**: psql 18.3 설치 완료, DB 접속 성공. Docker 불필요.

### 문제 #2: 프리플라이트에서 자동 설치 미진행

**원인**: 스킬 문서가 설치 명령어를 "안내"만 하도록 작성됨.
**해결**: macOS 감지 시 `brew install libpq` + PATH 등록을 **자동으로 실행**하도록 변경 필요.
사용자 확인(승인) 후 설치 진행하는 패턴이 적절함.

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

**변경 위치**: 행 60~119 (프리플라이트 + CLI 미설치 섹션 전체 재작성)

**현재 (행 60~119)**:
```
## 프리플라이트: CLI 확인
which psql || echo "psql 없음"
which mysql || echo "mysql 없음"

### CLI 미설치 시 설치 안내
macOS (Homebrew): brew install libpq ...

### CLI 미설치 + Windows 환경 — Docker fallback
(macOS도 포함되어 Docker를 대안으로 제시)
```

**변경 후** — OS별 명확한 분기 + macOS 자동 설치:

```markdown
## 프리플라이트: CLI 확인 + 자동 설치

### Step P-1: OS 감지

```bash
uname -s   # Darwin=macOS, Linux, MINGW/MSYS=Windows
```

### Step P-2: CLI 확인 및 설치

**macOS — CLI 직접 설치 (권장, Docker 불필요)**

```bash
# psql 확인
if which psql > /dev/null 2>&1; then
  echo "✅ psql 설치됨: $(psql --version)"
else
  echo "❌ psql 미설치 → brew install libpq 로 설치합니다 (승인 요청)"
  # 사용자 승인 후 실행:
  brew install libpq
  echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
  echo "✅ psql 설치 완료: $(psql --version)"
fi

# mysql 확인
if which mysql > /dev/null 2>&1; then
  echo "✅ mysql 설치됨: $(mysql --version)"
else
  echo "❌ mysql 미설치 → brew install mysql-client 로 설치합니다 (승인 요청)"
  # 사용자 승인 후 실행:
  brew install mysql-client
  echo 'export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
fi
```

> **macOS 설치 후 주의**: brew는 libpq를 keg-only로 설치하므로 반드시 PATH에 추가해야 함.
> PATH 추가 없이 `psql`을 실행하면 "command not found"가 뜸.
> 현재 세션에 즉시 적용: `export PATH="/opt/homebrew/opt/libpq/bin:$PATH"`

**Linux — 패키지 매니저로 설치**

```bash
sudo apt-get install -y postgresql-client   # PostgreSQL
sudo apt-get install -y mysql-client        # MySQL
```

**Windows (Git Bash) — Docker fallback (CLI 설치 불가 환경)**

```bash
# Docker 확인 후 fallback
docker --version && echo "Docker 사용 가능" || echo "Docker 없음 — CLI 직접 설치 필요"

# PostgreSQL (Docker)
docker run --rm postgres:16 psql \
  "postgresql://[user]:[encoded_pw]@[host]:[port]/[db]" \
  -c "[SQL]" 2>/dev/null

# MySQL (Docker)
docker run --rm mysql:8 mysql \
  -h [host] -P [port] -u [user] -p'[password]' [db] \
  -e "[SQL]" 2>/dev/null
```

> Docker fallback은 **Windows 전용**. macOS/Linux는 CLI 설치가 간단하므로 Docker 사용 금지.
> Docker 이미지 최초 다운로드: postgres:16 ~300MB, mysql:8 ~500MB.
```

### 3-2. 의사결정 트리 추가

SKILL.md 상단(프리플라이트 섹션 직전)에 OS별 전략 트리 추가:

```markdown
## CLI 설치 전략 (OS별)

| OS | 전략 | 이유 |
|----|------|------|
| macOS | `brew install libpq` 직접 설치 후 진행 | 5분 이내, Docker 불필요 |
| Linux | `apt-get install postgresql-client` | 패키지 매니저 즉시 설치 |
| Windows | Docker fallback | Git Bash 환경에서 CLI 설치 복잡 |

**macOS에서 Docker로 psql 실행하지 말 것** — brew가 훨씬 빠르고 이후에도 재사용 가능.
```

### 3-3. references/ 추가

새 파일: `references/cli-설치-가이드.md`

내용:
- macOS libpq keg-only 특성 및 PATH 설정 방법
- PATH 적용 즉시 확인 방법 (`which psql` vs `/opt/homebrew/opt/libpq/bin/psql`)
- 현재 세션 즉시 적용 vs ~/.zshrc 영구 등록 차이 설명
- psql 접속 테스트 표준 명령어

---

## 4. 검증 시나리오

### 시나리오 1: macOS CLI 자동 설치 흐름

**목적**: 수정된 스킬이 macOS에서 psql 미설치 시 자동으로 brew 설치를 제안하는지 확인
**전제**: macOS, psql 미설치 상태 (테스트용으로 PATH에서 제거)

```bash
# 단계 1: OS 확인
uname -s   # → Darwin 출력 확인

# 단계 2: psql 미설치 시뮬레이션
which psql 2>/dev/null || echo "psql 없음"

# 단계 3: brew install 실행 (스킬이 자동 제안해야 함)
brew install libpq

# 단계 4: PATH 등록
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# 단계 5: 동작 확인
psql --version   # → psql (PostgreSQL) 18.x 출력
```

**기대 결과**: psql 설치 완료, Docker 없이 DB 조회 가능
**통과 기준**: `psql --version` 정상 출력 + SELECT 1 접속 성공

### 시나리오 2: Windows Docker fallback (변경 없음 확인)

**목적**: Windows 환경에서는 여전히 Docker fallback이 동작하는지 확인
**전제**: Windows Git Bash, Docker Desktop 실행 중

```bash
uname -s   # → MINGW64_NT 출력 → Docker 분기 진입 확인
docker run --rm postgres:16 psql "postgresql://..." -c "SELECT 1;" 2>/dev/null
```

**기대 결과**: Docker로 SELECT 1 정상 실행
**통과 기준**: `connected = 1` 출력

---

## 5. 다음 에이전트를 위한 작업 지시

이 문서를 읽은 AI 에이전트는 아래 순서로 작업한다:

1. **피치 하네스 원본 폴더 확인**
   ```bash
   ls ~/source/peachSolution2/peach-harness/skills/peach-db-query/
   ```

2. **현재 SKILL.md 행 60~119 확인**
   ```bash
   sed -n '60,119p' ~/source/peachSolution2/peach-harness/skills/peach-db-query/SKILL.md
   ```

3. **SKILL.md 수정** — 이 문서 "3. 스킬 업데이트 제안" 내용 반영
   - 행 60~119: 프리플라이트 섹션을 OS별 분기 + macOS 자동 설치 패턴으로 교체
   - 프리플라이트 섹션 직전: OS별 전략 트리 표 추가
   - Docker fallback 섹션: "Windows 전용" 명시

4. **references/cli-설치-가이드.md 신규 작성**
   - macOS libpq keg-only 특성 및 PATH 설정 방법 포함

5. **검증 시나리오(4장) 실행** — macOS 시나리오 1 통과 확인

6. **완료 처리**
   - 이 파일 frontmatter: `status: completed`, `completed_at: 날짜`, `applied_by: 에이전트명`
   - 파일명에서 `TODO-` 제거:
     ```bash
     git mv "docs/스킬피드백/TODO-2026-04-15-peach-db-query-피드백.md" \
            "docs/스킬피드백/2026-04-15-peach-db-query-피드백.md"
     ```
   - 하단 반영 기록 추가
