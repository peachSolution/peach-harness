# DB 타입 매핑 규칙

> **⚠️ 중요**: `api/src/environments/env.local.yml`의 DATABASE_URL을 확인하여 적절한 섹션 사용

---

## PostgreSQL 타입 매핑

| 용도 | PostgreSQL 타입 | 코멘트 예시 |
|------|-----------------|-------------|
| PK | serial4 PRIMARY KEY | [테이블]번호(PK,자동증가) |
| 문자열 (짧음) | VARCHAR(n) | 제목(필수,최대200자) |
| 문자열 (긺) | TEXT | 내용(HTML허용) |
| 정수 | int4 | 조회수(기본값:0) |
| 큰 정수 | int8 | 금액(단위:원) |
| 소수 | NUMERIC(14,2) | 가격(소수점2자리) |
| 상태/코드 | CHAR(1) or VARCHAR(n) | 상태(A:활성,I:비활성) |
| 여부 | CHAR(1) | 사용여부(Y:사용,N:미사용) |
| 날짜시간 | TIMESTAMP | 등록일(자동생성) |
| 날짜 | DATE | 생년월일 |
| JSON | JSONB | 추가정보(JSON형식) |
| 참조(FK) | int4 | 회원번호(member참조,FK없음) |

### 상태/코드 타입 선택 가이드

| 코드 범위 | 권장 타입 | 예시 |
|-----------|----------|------|
| 1자리 (A/I/D, Y/N) | CHAR(1) | 사용여부, 성별 |
| 2자리 (01~99) | VARCHAR(2) | 상태코드, 직위코드 |
| 3자리 이상 (REG/CHG/DIS) | VARCHAR(10) | 이벤트유형, 결재유형 |

### JSONB 활용 패턴

| 용도 | 코멘트 예시 |
|------|-------------|
| 변경 전/후 비교 | 변경전정보(CHG시,JSON형식,{position:"01",phone:"010-..."}) |
| 동적 옵션 | 추가옵션(JSON형식,키-값쌍) |
| 외부 API 응답 | API응답원본(JSON형식,디버깅용) |

### PostgreSQL 공통 컬럼

```sql
"is_use" CHAR(1) DEFAULT 'Y',        -- 사용여부(Y:사용,N:미사용)
"is_delete" CHAR(1) DEFAULT 'N',     -- 삭제여부(Y:삭제,N:미삭제)
"insert_seq" int4,                   -- 등록자(member_seq참조)
"insert_date" TIMESTAMP DEFAULT NOW(), -- 등록일(자동생성)
"update_seq" int4,                   -- 수정자(member_seq참조)
"update_date" TIMESTAMP DEFAULT NOW()  -- 수정일(자동갱신)
```

### PostgreSQL 문법 특징

- 식별자 따옴표: `"컬럼명"` (쌍따옴표)
- 자동증가: `serial4` (PK용)
- 정수: `int4` (일반 정수, FK 참조용)
- 현재시간: `NOW()`
- JSON: `JSONB` (바이너리 JSON, 인덱싱 가능)

---

## MySQL 타입 매핑

| 용도 | MySQL 타입 | 코멘트 예시 |
|------|-----------|-------------|
| PK | INT AUTO_INCREMENT | [테이블]번호(PK,자동증가) |
| 문자열 (짧음) | VARCHAR(n) | 제목(필수,최대200자) |
| 문자열 (긺) | TEXT | 내용(HTML허용) |
| 정수 | INT | 조회수(기본값:0) |
| 큰 정수 | BIGINT | 금액(단위:원) |
| 소수 | DECIMAL(14,2) | 가격(소수점2자리) |
| 상태/코드 | CHAR(1) or VARCHAR(n) | 상태(A:활성,I:비활성) |
| 여부 | CHAR(1) | 사용여부(Y:사용,N:미사용) |
| 날짜시간 | DATETIME | 등록일(자동생성) |
| 날짜 | DATE | 생년월일 |
| JSON | JSON | 추가정보(JSON형식) |
| 참조 | INT | 회원번호(member참조,FK없음) |

### 상태/코드 타입 선택 가이드

| 코드 범위 | 권장 타입 | 예시 |
|-----------|----------|------|
| 1자리 (A/I/D, Y/N) | CHAR(1) | 사용여부, 성별 |
| 2자리 (01~99) | VARCHAR(2) | 상태코드, 직위코드 |
| 3자리 이상 (REG/CHG/DIS) | VARCHAR(10) | 이벤트유형, 결재유형 |

### MySQL 공통 컬럼

```sql
`is_use` CHAR(1) DEFAULT 'Y' COMMENT '사용여부(Y:사용,N:미사용)',
`is_delete` CHAR(1) DEFAULT 'N' COMMENT '삭제여부(Y:삭제,N:미삭제)',
`insert_seq` INT COMMENT '등록자(member_seq참조)',
`insert_date` DATETIME DEFAULT NOW() COMMENT '등록일(자동생성)',
`update_seq` INT COMMENT '수정자(member_seq참조)',
`update_date` DATETIME DEFAULT NOW() ON UPDATE NOW() COMMENT '수정일(자동갱신)'
```

### MySQL 문법 특징

- 식별자 따옴표: `` `컬럼명` `` (백틱)
- 자동증가: `AUTO_INCREMENT`
- 현재시간: `NOW()`
- JSON: `JSON` (MySQL 5.7+)
- 코멘트: 컬럼 정의에 `COMMENT '설명'` 인라인 작성
- 자동갱신: `ON UPDATE NOW()` (update_date에 사용)

---

## 타입 비교표

| 용도 | PostgreSQL | MySQL |
|------|-----------|-------|
| PK 자동증가 | `serial4` | `INT AUTO_INCREMENT` |
| 정수 | `int4` | `INT` |
| 큰 정수 | `int8` | `BIGINT` |
| 소수 | `NUMERIC(14,2)` | `DECIMAL(14,2)` |
| 날짜시간 | `TIMESTAMP` | `DATETIME` |
| JSON | `JSONB` | `JSON` |
| 식별자 | `"name"` | `` `name` `` |
| 코멘트 | 별도 `COMMENT ON` 문 | 인라인 `COMMENT` |
