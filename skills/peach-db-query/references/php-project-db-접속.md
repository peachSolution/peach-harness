# PHP 프로젝트 DB 접속 정보 탐색

> PeachSolution PHP 프로젝트 특성 반영
> Node/Java 프로젝트는 `env.local.yml` → `DATABASE_URL` 패턴 사용 (SKILL.md Step 1 참조)

---

## 접속 정보 위치

| 프로젝트 유형 | 파일 위치 | 키 패턴 |
|-------------|---------|--------|
| Node / Java | `api/src/environments/env.local.yml` | `DATABASE_URL` |
| PHP | `src/cfg/conf.php` 또는 `cfg/conf.php` | `$config['db_*']` |

---

## 탐색 명령

```bash
# 우선 탐색 (일반적인 PHP 프로젝트 경로)
grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" src/cfg/conf.php 2>/dev/null || \
grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" cfg/conf.php 2>/dev/null

# fallback: 전체 탐색 (경로가 다른 경우)
find . -name "conf.php" | xargs grep -l "db_host" 2>/dev/null | head -1 | \
  xargs grep "db_host\|db_port\|db_dbname\|db_user\|db_password\|db_division" 2>/dev/null
```

---

## conf.php 패턴 예시

```php
$config['db_host']     = '{DB_HOST}';
$config['db_port']     = '{DB_PORT}';
$config['db_dbname']   = '{DB_NAME}';
$config['db_user']     = '{DB_USER}';
$config['db_password'] = '{DB_PASSWORD}';
$config['db_division'] = 'pdo';  // pdo = MySQL
```

---

## db_division 해석

| 값 | DB 종류 |
|----|--------|
| `pdo` | MySQL |
| `mysqli` | MySQL |
| `postgresql` | PostgreSQL |

---

## 접속 정보 추출 후 실행

### MySQL (CLI)
```bash
mysql -h [db_host] -P [db_port] -u [db_user] -p'[db_password]' [db_dbname] -e "[SQL]"
```

### MySQL (Docker fallback — Windows/CLI 미설치)
```bash
docker run --rm mysql:8 mysql \
  -h [db_host] -P [db_port] -u [db_user] -p'[db_password]' [db_dbname] \
  -e "[SQL]" 2>/dev/null
```

> `-p'password'` — 특수문자(`!%#` 등) 포함 시 반드시 따옴표로 감싸기

### PostgreSQL (CLI)
```bash
PGPASSWORD='[db_password]' psql -h [db_host] -p [db_port] -U [db_user] -d [db_dbname] -c "[SQL]"
```

### PostgreSQL (Docker fallback — Windows/CLI 미설치)
```bash
docker run --rm postgres:18 psql \
  "postgresql://[db_user]:[url_encoded_password]@[db_host]:[db_port]/[db_dbname]" \
  -c "[SQL]" 2>/dev/null
```

> PostgreSQL Docker는 connection string URL 방식 사용
> 패스워드 특수문자 URL 인코딩 필요: `!` → `%21`, `%` → `%25`, `#` → `%23`

---

## 주의사항

- PHP 프로젝트 DB 비밀번호는 특수문자 포함 빈도가 높다 (`!`, `%`, `#` 등 쉘 특수문자)
- MySQL `-p'password'` 따옴표 누락 시 특수문자가 쉘에서 해석되어 인증 실패
- PostgreSQL Docker URL에서는 URL 인코딩 유지 (디코딩하지 않음)
- `2>/dev/null` — Docker pull 진행 메시지 및 MySQL 경고 메시지 숨김
