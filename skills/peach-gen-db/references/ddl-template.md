# DDL 마이그레이션 템플릿

> **⚠️ 중요**: `api/src/environments/env.local.yml`의 DATABASE_URL을 확인하여 적절한 템플릿 사용

---

## PK 네이밍 규칙

- 형식: `"[테이블명]_seq"` — 테이블 전체 이름 사용
- 예시: `"notice_board_seq"`, `"common_file_hist_seq"`, `"staff_hist_seq"`
- ❌ 축약 금지: `"hist_seq"`, `"id"`, `"seq"`

---

## 테이블 성격별 공통 컬럼 적용 기준

| 테이블 성격 | is_use | is_delete | insert_* | update_* |
|------------|:------:|:---------:|:--------:|:--------:|
| 마스터 (코드, 설정) | 조건부 | O | O | O |
| 엔티티 (비즈니스 데이터) | 조건부 | O | O | O |
| 이력/로그 (*_hist, *_log) | X | X | O | X |

> 이력/로그 테이블은 INSERT 후 수정·삭제하지 않으므로 `is_use`, `is_delete`, `update_seq`, `update_date` 제외

### is_use 추가 조건

아래 중 하나를 만족할 때만 추가:
- 코드/설정 테이블 — 관리자가 항목을 활성/비활성 전환하는 용도
- 템플릿/마스터 테이블 — 공지 템플릿, 약관 버전 등
- `status` 컬럼이 없고 단순 ON/OFF만 필요한 경우

> `status` 컬럼이 이미 있는 테이블에는 `is_use` 추가 금지 (중복)

---

## 인덱스 전략

### 기본 원칙
- **최소한으로 설정**: 무분별한 인덱스는 INSERT/UPDATE 성능 저하
- **데이터량 기반 판단**: 소량 데이터는 인덱스 없이도 충분히 빠름
- **조회 패턴 분석**: 실제 쿼리 패턴 확인 후 필요시 추가

### 권장 사항
1. **초기 생성 시**: 인덱스 없이 테이블만 생성
2. **운영 중**: 느린 쿼리 발생 시 EXPLAIN으로 분석
3. **등록일자 범위 활용**: `WHERE insert_date >= ?` 조건으로 데이터 범위 좁히기
4. **선택적 추가**: 프로그램 특성과 데이터량에 따라 꼭 필요한 컬럼만 인덱스 생성

---

## PostgreSQL 템플릿

```sql
-- migrate:up
CREATE TABLE "[테이블명]" (
    -- PK (serial4 자동증가)
    "[테이블명]_seq" serial4 PRIMARY KEY,

    -- 핵심 컬럼 (FK 제약조건 없이 컬럼만)
    "[컬럼명]" [타입] [제약조건],

    -- 참조 컬럼 (FK 제약조건 절대 금지! 의미로만 참조)
    "member_seq" int4,  -- member 테이블 참조용

    -- 공통 컬럼 (테이블 성격에 따라 적용 — 위 "테이블 성격별 공통 컬럼 적용 기준" 참조)
    "is_use" CHAR(1) DEFAULT 'Y',      -- 조건부: is_use 추가 조건 충족 시만 포함
    "is_delete" CHAR(1) DEFAULT 'N',   -- 기본 포함 (이력/로그 제외)
    "insert_seq" int4,
    "insert_date" TIMESTAMP DEFAULT NOW(),
    "update_seq" int4,                 -- 이력/로그 제외
    "update_date" TIMESTAMP DEFAULT NOW()  -- 이력/로그 제외
);

-- 테이블 코멘트
COMMENT ON TABLE "[테이블명]" IS '[테이블 설명]';

-- 컬럼 코멘트 (상세하게! 선택값은 코드화!)
COMMENT ON COLUMN "[테이블명]"."[테이블명]_seq" IS '[테이블]번호(PK,자동증가)';
COMMENT ON COLUMN "[테이블명]"."status" IS '상태(A:활성,I:비활성,D:삭제)';
COMMENT ON COLUMN "[테이블명]"."is_use" IS '사용여부(Y:사용,N:미사용)';
COMMENT ON COLUMN "[테이블명]"."is_delete" IS '삭제여부(Y:삭제,N:미삭제)';
COMMENT ON COLUMN "[테이블명]"."insert_seq" IS '등록자(member_seq참조)';
COMMENT ON COLUMN "[테이블명]"."insert_date" IS '등록일(자동생성)';
COMMENT ON COLUMN "[테이블명]"."update_seq" IS '수정자(member_seq참조)';
COMMENT ON COLUMN "[테이블명]"."update_date" IS '수정일(자동갱신)';

-- 인덱스
-- 데이터량과 조회 패턴 분석 후 필요시 추가 (ALTER TABLE 또는 CREATE INDEX)
-- 권장: 등록일자 범위 조건으로 데이터를 좁혀 처리 (WHERE insert_date >= ?)

-- migrate:down
DROP TABLE IF EXISTS "[테이블명]";
```

---

## MySQL 템플릿

```sql
-- migrate:up
CREATE TABLE `[테이블명]` (
    -- PK (AUTO_INCREMENT 방식)
    `[테이블명]_seq` INT AUTO_INCREMENT PRIMARY KEY COMMENT '[테이블]번호(PK,자동증가)',

    -- 핵심 컬럼 (FK 제약조건 없이 컬럼만)
    `[컬럼명]` [타입] [제약조건] COMMENT '[설명]',

    -- 참조 컬럼 (FK 제약조건 절대 금지!)
    `member_seq` INT COMMENT '회원번호(member참조,FK없음)',

    -- 공통 컬럼 (테이블 성격에 따라 적용 — 위 "테이블 성격별 공통 컬럼 적용 기준" 참조)
    `is_use` CHAR(1) DEFAULT 'Y' COMMENT '사용여부(Y:사용,N:미사용)',       -- 조건부: is_use 추가 조건 충족 시만 포함
    `is_delete` CHAR(1) DEFAULT 'N' COMMENT '삭제여부(Y:삭제,N:미삭제)',   -- 기본 포함 (이력/로그 제외)
    `insert_seq` INT COMMENT '등록자(member_seq참조)',
    `insert_date` DATETIME DEFAULT NOW() COMMENT '등록일(자동생성)',
    `update_seq` INT COMMENT '수정자(member_seq참조)',                      -- 이력/로그 제외
    `update_date` DATETIME DEFAULT NOW() ON UPDATE NOW() COMMENT '수정일(자동갱신)'  -- 이력/로그 제외
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='[테이블 설명]';

-- 인덱스: 데이터량과 조회 패턴 분석 후 필요시 추가
-- 권장: 등록일자 범위 조건으로 데이터를 좁혀 처리 (WHERE insert_date >= ?)

-- migrate:down
DROP TABLE IF EXISTS `[테이블명]`;
```

---

## PostgreSQL 완전한 예시

### 입력
```
테이블명: notice_board
설명: 공지사항 게시판
컬럼:
- title: VARCHAR(200) NOT NULL - 제목(필수,최대200자)
- content: TEXT - 내용(HTML허용)
- view_count: INTEGER DEFAULT 0 - 조회수(기본값:0,자동증가)
- status: CHAR(1) DEFAULT 'A' - 상태(A:활성,I:비활성,D:삭제)
- notice_type: CHAR(1) DEFAULT 'N' - 공지유형(N:일반,I:중요,E:긴급)
- is_top: CHAR(1) DEFAULT 'N' - 상단고정여부(Y:고정,N:미고정)
- start_date: TIMESTAMP - 게시시작일(NULL이면즉시게시)
- end_date: TIMESTAMP - 게시종료일(NULL이면무기한)
- category_seq: INTEGER - 카테고리번호(category참조,FK없음)
```

### 출력

```sql
-- migrate:up
CREATE TABLE "notice_board" (
    "notice_board_seq" serial4 PRIMARY KEY,

    "title" VARCHAR(200) NOT NULL,
    "content" TEXT,
    "view_count" int4 DEFAULT 0,
    "status" CHAR(1) DEFAULT 'A',
    "notice_type" CHAR(1) DEFAULT 'N',
    "is_top" CHAR(1) DEFAULT 'N',
    "start_date" TIMESTAMP,
    "end_date" TIMESTAMP,
    "category_seq" int4,

    "is_use" CHAR(1) DEFAULT 'Y',
    "is_delete" CHAR(1) DEFAULT 'N',
    "insert_seq" int4,
    "insert_date" TIMESTAMP DEFAULT NOW(),
    "update_seq" int4,
    "update_date" TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE "notice_board" IS '공지사항 게시판';

COMMENT ON COLUMN "notice_board"."notice_board_seq" IS '공지사항번호(PK,자동증가)';
COMMENT ON COLUMN "notice_board"."title" IS '제목(필수,최대200자)';
COMMENT ON COLUMN "notice_board"."content" IS '내용(HTML허용)';
COMMENT ON COLUMN "notice_board"."view_count" IS '조회수(기본값:0,자동증가)';
COMMENT ON COLUMN "notice_board"."status" IS '상태(A:활성,I:비활성,D:삭제)';
COMMENT ON COLUMN "notice_board"."notice_type" IS '공지유형(N:일반,I:중요,E:긴급)';
COMMENT ON COLUMN "notice_board"."is_top" IS '상단고정여부(Y:고정,N:미고정)';
COMMENT ON COLUMN "notice_board"."start_date" IS '게시시작일(NULL이면즉시게시)';
COMMENT ON COLUMN "notice_board"."end_date" IS '게시종료일(NULL이면무기한)';
COMMENT ON COLUMN "notice_board"."category_seq" IS '카테고리번호(category참조,FK없음)';
COMMENT ON COLUMN "notice_board"."is_use" IS '사용여부(Y:사용,N:미사용)';
COMMENT ON COLUMN "notice_board"."is_delete" IS '삭제여부(Y:삭제,N:미삭제)';
COMMENT ON COLUMN "notice_board"."insert_seq" IS '등록자(member참조)';
COMMENT ON COLUMN "notice_board"."insert_date" IS '등록일(자동생성)';
COMMENT ON COLUMN "notice_board"."update_seq" IS '수정자(member참조)';
COMMENT ON COLUMN "notice_board"."update_date" IS '수정일(자동갱신)';

-- migrate:down
DROP TABLE IF EXISTS "notice_board";
```

---

## MySQL 완전한 예시

### 동일 입력으로 MySQL 출력

```sql
-- migrate:up
CREATE TABLE `notice_board` (
    `notice_board_seq` INT AUTO_INCREMENT PRIMARY KEY COMMENT '공지사항번호(PK,자동증가)',

    `title` VARCHAR(200) NOT NULL COMMENT '제목(필수,최대200자)',
    `content` TEXT COMMENT '내용(HTML허용)',
    `view_count` INT DEFAULT 0 COMMENT '조회수(기본값:0,자동증가)',
    `status` CHAR(1) DEFAULT 'A' COMMENT '상태(A:활성,I:비활성,D:삭제)',
    `notice_type` CHAR(1) DEFAULT 'N' COMMENT '공지유형(N:일반,I:중요,E:긴급)',
    `is_top` CHAR(1) DEFAULT 'N' COMMENT '상단고정여부(Y:고정,N:미고정)',
    `start_date` DATETIME COMMENT '게시시작일(NULL이면즉시게시)',
    `end_date` DATETIME COMMENT '게시종료일(NULL이면무기한)',
    `category_seq` INT COMMENT '카테고리번호(category참조,FK없음)',

    `is_use` CHAR(1) DEFAULT 'Y' COMMENT '사용여부(Y:사용,N:미사용)',
    `is_delete` CHAR(1) DEFAULT 'N' COMMENT '삭제여부(Y:삭제,N:미삭제)',
    `insert_seq` INT COMMENT '등록자(member참조)',
    `insert_date` DATETIME DEFAULT NOW() COMMENT '등록일(자동생성)',
    `update_seq` INT COMMENT '수정자(member참조)',
    `update_date` DATETIME DEFAULT NOW() ON UPDATE NOW() COMMENT '수정일(자동갱신)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='공지사항 게시판';

-- migrate:down
DROP TABLE IF EXISTS `notice_board`;
```
