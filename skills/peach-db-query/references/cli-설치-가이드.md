# CLI 설치 가이드

psql / mysql CLI 설치 및 PATH 설정 방법.

---

## macOS — libpq (psql)

### 설치

```bash
brew install libpq
```

### keg-only 특성

brew는 libpq를 **keg-only**로 설치한다. 시스템 PATH에 자동 추가되지 않으므로 반드시 수동으로 PATH를 등록해야 한다.

설치 후 `psql`을 바로 실행하면 `command not found`가 뜨는 이유가 이것이다.

### PATH 등록

```bash
# ~/.zshrc에 영구 등록
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc

# 현재 세션 즉시 적용
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
```

### 설치 확인

```bash
which psql               # → /opt/homebrew/opt/libpq/bin/psql
psql --version           # → psql (PostgreSQL) 18.x
```

> **주의**: `which psql`이 `/usr/bin/psql`을 반환하면 macOS 내장 psql(구버전)이 사용되는 것.
> 위 PATH 등록 후 새 터미널을 열거나 `source ~/.zshrc`를 실행해야 최신 버전이 적용된다.

---

## macOS — mysql-client (mysql)

### 설치

```bash
brew install mysql-client
```

mysql-client도 keg-only로 설치된다.

### PATH 등록

```bash
echo 'export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"' >> ~/.zshrc
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
mysql --version   # 설치 확인
```

---

## Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y postgresql-client   # psql
sudo apt-get install -y mysql-client        # mysql
```

설치 후 PATH 등록 불필요. 즉시 사용 가능.

---

## 접속 테스트 표준 명령어

### PostgreSQL

```bash
PGPASSWORD='[password]' psql -h [host] -p [port] -U [user] -d [db] -c "SELECT 1;"
```

성공 시 출력:
```
 ?column?
----------
        1
(1 row)
```

### MySQL

```bash
mysql -h [host] -P [port] -u [user] -p'[password]' [db] -e "SELECT 1;"
```

성공 시 출력:
```
+---+
| 1 |
+---+
| 1 |
+---+
```

---

## 현재 세션 vs 영구 적용 차이

| 방법 | 범위 | 명령 |
|------|------|------|
| `export PATH=...` | 현재 터미널 세션만 | 터미널 닫으면 사라짐 |
| `~/.zshrc`에 추가 | 영구 (zsh 기본 셸) | 새 터미널마다 자동 적용 |
| `source ~/.zshrc` | 현재 세션에 즉시 반영 | ~/.zshrc 변경 후 재로드 |

**권장 순서**: `~/.zshrc` 등록 → `export`로 현재 세션 즉시 적용 → `which psql`로 확인
