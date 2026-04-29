---
status: completed
target_skill: peach-db-query
severity: 높음 1 / 중간 1 / 낮음 0
completed_at: 2026-04-13
applied_by: Claude Sonnet 4.6
---

# peach-db-query 피드백 — 2026-04-13

> **대상 스킬**: peach-db-query
> **작성 근거**: PHP 프로젝트(Windows 환경)에서 DB SQL 조회 시 psql/mysql CLI가 없어 Docker로 우회 실행
> **심각도 요약**: 높음 1건 / 중간 1건 / 낮음 0건

---

## 1. 발견된 문제

| # | 문제 | 심각도 | 현재 스킬에 있는가 | SKILL.md 행 |
|---|------|:---:|:---:|-----|
| 1 | PHP 프로젝트는 `env.local.yml`이 없음 — DB 접속 정보를 `conf.php`에서 파싱해야 함 | 높음 | X (없음) | — |
| 2 | Windows에서 psql/mysql CLI 없을 때 Docker fallback 방법이 누락됨 | 중간 | X (없음) | — |

---

## 2. 해결 방법 / 우회 전략

### 문제 #1: PHP 프로젝트 DB 접속 정보 위치

**원인**: 스킬 문서가 `env.local.yml`의 `DATABASE_URL` 패턴만 안내함.
PHP 프로젝트는 `src/cfg/conf.php` 또는 `cfg/conf.php`에 DB 정보가 직접 기재됨.

**해결**: conf.php에서 grep으로 추출

```bash
# PHP 프로젝트 DB 접속 정보 탐색
grep -r "db_host\|db_port\|db_dbname\|db_user\|db_password" src/cfg/conf.php 2>/dev/null
# 또는
find . -name "conf.php" | xargs grep "db_host" 2>/dev/null
```

실제 발견된 conf.php 패턴:
```php
$config['db_host']     = '{DB_HOST}';
$config['db_port']     = '{DB_PORT}';
$config['db_dbname']   = '{DB_NAME}';
$config['db_user']     = '{DB_USER}';
$config['db_password'] = '{DB_PASSWORD}';
$config['db_division'] = 'pdo';  // pdo = MySQL
```

`db_division`이 `pdo`이면 MySQL로 판단한다.

---

### 문제 #2: Windows에서 CLI 없을 때 Docker fallback

**원인**: 스킬 문서에 CLI 미설치 시 macOS/Linux 설치 방법만 있음.
Windows Git Bash 환경에서는 brew/apt 없어 설치 불가.

**해결**: Docker로 mysql/psql 클라이언트 실행

```bash
# MySQL (Docker fallback)
docker run --rm mysql:8 mysql \
  -h [host] -P [port] -u [user] -p'[password]' [dbname] \
  -e "[SQL]"

# 실제 실행 예시
docker run --rm mysql:8 mysql \
  -h {DB_HOST} -P {DB_PORT} -u {DB_USER} -p'{DB_PASSWORD}' {DB_NAME} \
  -e "SELECT COUNT(*) FROM content WHERE division='funds';" 2>/dev/null

# PostgreSQL (Docker fallback)
docker run --rm postgres:16 psql \
  "postgresql://[user]:[password]@[host]:[port]/[dbname]" \
  -c "[SQL]"
```

**주의사항**:
- `-p'password'` 에서 따옴표 안에 패스워드 — 쉘 특수문자(`!`, `%`, `#` 등) 포함 시 필수
- `2>/dev/null` — Docker pull 진행 메시지 숨김
- Docker가 설치되어 있어야 함: `docker --version`으로 선확인

---

## 3. 스킬 업데이트 제안

### 3-1. SKILL.md 변경

#### [Step 1] DB 종류 판별 섹션에 PHP 프로젝트 탐지 추가

현재 (grep 대상이 yml만):
```bash
grep "DATABASE_URL" api/src/environments/env.local.yml 2>/dev/null || \
grep "DATABASE_URL" api/env.local.yml 2>/dev/null
```

변경 후:
```bash
# Node/Java 프로젝트: env.yml에서 DATABASE_URL
grep "DATABASE_URL" api/src/environments/env.local.yml 2>/dev/null || \
grep "DATABASE_URL" api/env.local.yml 2>/dev/null

# PHP 프로젝트: conf.php에서 db_* 변수
find . -name "conf.php" | xargs grep -l "db_host" 2>/dev/null | head -1 | \
  xargs grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" 2>/dev/null
# db_division = 'pdo' → MySQL
```

#### [Step 2] 프리플라이트 섹션에 Docker fallback 추가

현재: macOS/Linux 설치 안내만 있음

추가할 내용:
```markdown
### CLI 미설치 시 — Docker fallback (Windows/설치 불가 환경)

Docker가 설치되어 있다면 CLI 없이도 DB 접속 가능:

```bash
# Docker 설치 확인
docker --version && echo "✅ Docker 사용 가능" || echo "❌ Docker 없음"

# MySQL (Docker)
docker run --rm mysql:8 mysql -h [host] -P [port] -u [user] -p'[password]' [db] -e "[SQL]" 2>/dev/null

# PostgreSQL (Docker)
docker run --rm postgres:16 psql "postgresql://[user]:[password]@[host]:[port]/[db]" -c "[SQL]" 2>/dev/null
```

> `-p'password'` 특수문자 포함 시 반드시 따옴표로 감싸기
> `2>/dev/null` Docker pull 메시지 숨김
```

### 3-2. references/ 추가

`references/php-project-db-접속.md` 신규 생성:

```markdown
# PHP 프로젝트 DB 접속 정보 탐색

## 접속 정보 위치
- Node/Java: `env.local.yml` → `DATABASE_URL`
- PHP: `src/cfg/conf.php` 또는 `cfg/conf.php` → `$config['db_*']`

## 탐색 명령
```bash
find . -name "conf.php" | xargs grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" 2>/dev/null
```

## db_division 해석
| 값 | DB 종류 |
|----|--------|
| pdo | MySQL |
| mysqli | MySQL |
| postgresql | PostgreSQL |
```

---

## 4. 검증 시나리오

### 시나리오 1: PHP 프로젝트에서 DB 접속 정보 자동 탐지

**목적**: conf.php에서 DB 접속 정보를 자동 추출하는지 확인
**전제**: PHP 프로젝트 루트 디렉토리에서 실행

```bash
# 단계 1: conf.php 탐색
find . -name "conf.php" | xargs grep -l "db_host" 2>/dev/null | head -1

# 단계 2: 접속 정보 추출
find . -name "conf.php" | xargs grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" 2>/dev/null
```

**기대 결과**: `$config['db_host']`, `$config['db_port']` 등이 출력됨
**통과 기준**: host, port, dbname, user, password 5개 값 모두 추출

---

### 시나리오 2: Docker fallback으로 MySQL 조회

**목적**: CLI 없는 Windows 환경에서 Docker로 SQL 실행
**전제**: Docker Desktop 설치, MySQL DB 접근 가능

```bash
# 단계 1: Docker 확인
docker --version

# 단계 2: 연결 테스트
docker run --rm mysql:8 mysql -h [host] -P [port] -u [user] -p'[password]' [db] -e "SELECT 1;" 2>/dev/null

# 단계 3: 실제 쿼리
docker run --rm mysql:8 mysql -h [host] -P [port] -u [user] -p'[password]' [db] -e "SHOW TABLES;" 2>/dev/null
```

**기대 결과**: 테이블 목록 출력
**통과 기준**: SQL 결과가 정상 출력되고 Docker 에러 메시지 없음

---

## 5. 다음 에이전트를 위한 작업 지시

1. 피치 하네스 원본 폴더 확인
   - Windows: `D:\peachSolution2\peach-harness\`
   - macOS: `~/source/peachSolution2/peach-harness/`

2. 대상 스킬 현재 상태 확인
   ```bash
   cat skills/peach-db-query/SKILL.md
   ```

3. 이 문서의 "3. 스킬 업데이트 제안"을 순서대로 반영
   - SKILL.md: Step 1 DB 종류 판별 + Step 2 프리플라이트 섹션 수정
   - references/php-project-db-접속.md 신규 생성

4. 검증 시나리오(4장) 실행하여 변경 사항 확인

5. 변경 완료 후:
   - frontmatter의 `status`를 `completed`로 변경, `completed_at`과 `applied_by` 기입
   - 파일명에서 `TODO-` 접두어 제거
   - 하단에 반영 기록 추가

---

## 반영 기록

- [2026-04-13] Claude Sonnet 4.6:
  - SKILL.md 프리플라이트: Docker fallback 섹션 추가 (postgres:18, mysql:8)
  - SKILL.md Step 1: PHP conf.php db_* 탐지 분기 추가 (db_division 해석 포함)
  - references/php-project-db-접속.md 신규 생성
  - Docker 방식: `docker run --rm` 신규 컨테이너 생성 방식 채택 (외부 개발 서버 DB 접속 기준)
  - PostgreSQL Docker 이미지: postgres:18
