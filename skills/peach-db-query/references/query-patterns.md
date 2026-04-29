# DB 조회 패턴 모음

> PeachSolution 프로젝트 DB 특성 반영 (PostgreSQL + MySQL 지원)
> PK: `[테이블명]_seq`, 감사컬럼: `is_use/is_delete/insert_seq/insert_date/update_seq/update_date`

---

## 1. 테이블 탐색

```sql
-- [PG] 전체 테이블 목록 + 코멘트
SELECT c.relname AS table_name, obj_description(c.oid) AS comment
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r' ORDER BY c.relname;

-- [PG] 컬럼 구조 + 코멘트
SELECT column_name, data_type, character_maximum_length, column_default, is_nullable,
       col_description(('[테이블명]')::regclass::oid, ordinal_position) AS comment
FROM information_schema.columns WHERE table_name = '[테이블명]' ORDER BY ordinal_position;

-- [MySQL] 컬럼 구조 + 코멘트
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT, IS_NULLABLE, COLUMN_COMMENT
FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '[테이블명]'
ORDER BY ORDINAL_POSITION;

-- [공통] 인덱스 확인
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = '[테이블명]'; -- PG
SHOW INDEX FROM [테이블명]; -- MySQL
```

---

## 2. 기본 데이터 확인

```sql
-- 최근 등록 데이터 (기본 20건)
SELECT * FROM [테이블명] ORDER BY insert_date DESC LIMIT 20;

-- 특정 상태 + 미삭제 데이터
SELECT * FROM [테이블명] WHERE status = 'A' AND is_delete = 'N' LIMIT 100;

-- 상태별 건수 집계
SELECT status, COUNT(*) AS cnt FROM [테이블명] WHERE is_delete = 'N'
GROUP BY status ORDER BY status;

-- 특정 seq 단건 조회
SELECT * FROM [테이블명] WHERE [테이블명]_seq = [값];

-- 코드 테이블 조회
SELECT code_value, code_name, sort_order FROM common_code
WHERE group_code = '[그룹코드]' AND is_use = 'Y' ORDER BY sort_order;
```

---

## 3. 감사 컬럼 활용 패턴

```sql
-- 최근 N일 내 등록/수정 데이터
SELECT * FROM [테이블명]
WHERE insert_date >= NOW() - INTERVAL '7 days'  -- PG: INTERVAL '7 days' / MySQL: INTERVAL 7 DAY
  AND is_delete = 'N'
ORDER BY insert_date DESC LIMIT 50;

-- 특정 사용자의 최근 수정 이력
SELECT t.*, m.member_name AS updater
FROM [테이블명] t
JOIN member m ON m.member_seq = t.update_seq
WHERE t.update_seq = [member_seq] AND t.is_delete = 'N'
ORDER BY t.update_date DESC LIMIT 20;

-- 기간별 일별 등록 통계
SELECT DATE(insert_date) AS day, COUNT(*) AS cnt
FROM [테이블명]
WHERE insert_date BETWEEN '2026-01-01' AND '2026-03-31' AND is_delete = 'N'
GROUP BY DATE(insert_date) ORDER BY day;

-- 기간별 월별 통계
SELECT TO_CHAR(insert_date, 'YYYY-MM') AS month, COUNT(*) AS cnt -- PG
-- DATE_FORMAT(insert_date, '%Y-%m') AS month, COUNT(*) AS cnt  -- MySQL
FROM [테이블명] WHERE is_delete = 'N'
GROUP BY TO_CHAR(insert_date, 'YYYY-MM') ORDER BY month DESC;

-- 소프트 삭제 데이터 포함 분석 (삭제 현황)
SELECT is_delete, COUNT(*) AS cnt FROM [테이블명] GROUP BY is_delete;
```

---

## 4. 이력 테이블 패턴 (*_hist)

```sql
-- 특정 레코드의 전체 변경 이력
SELECT h.*, m.member_name AS changer
FROM [테이블명]_hist h
LEFT JOIN member m ON m.member_seq = h.insert_seq
WHERE h.[테이블명]_seq = [값]
ORDER BY h.insert_date DESC;

-- [PG] 상태 전이 분석 (LAG로 이전 상태 확인)
SELECT [테이블명]_seq, status AS current_status,
       LAG(status) OVER (PARTITION BY [테이블명]_seq ORDER BY insert_date) AS prev_status,
       insert_date AS changed_at
FROM [테이블명]_hist
WHERE [테이블명]_seq = [값]
ORDER BY insert_date;

-- [PG] 이력 없는 현재 데이터 확인 (고아 데이터 탐지)
SELECT t.[테이블명]_seq FROM [테이블명] t
LEFT JOIN [테이블명]_hist h ON h.[테이블명]_seq = t.[테이블명]_seq
WHERE h.[테이블명]_seq IS NULL AND t.is_delete = 'N';
```

---

## 5. Window Function 패턴

```sql
-- [PG/MySQL8+] ROW_NUMBER: 그룹 내 순위 (중복 없음)
SELECT *, ROW_NUMBER() OVER (PARTITION BY group_id ORDER BY insert_date DESC) AS rn
FROM [테이블명] WHERE is_delete = 'N';

-- [PG/MySQL8+] 그룹별 최신 1건 추출
WITH ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY group_id ORDER BY insert_date DESC) AS rn
  FROM [테이블명] WHERE is_delete = 'N'
)
SELECT * FROM ranked WHERE rn = 1;

-- [PG/MySQL8+] RANK / DENSE_RANK: 동점 처리 포함
SELECT member_seq, score,
       RANK() OVER (ORDER BY score DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY score DESC) AS dense_rank
FROM [테이블명] WHERE is_delete = 'N';

-- [PG/MySQL8+] 누적 합계
SELECT insert_date, amount,
       SUM(amount) OVER (ORDER BY insert_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative
FROM [테이블명] WHERE is_delete = 'N' ORDER BY insert_date;

-- [PG/MySQL8+] 전월 대비 증감 (LAG/LEAD)
SELECT month, cnt,
       LAG(cnt) OVER (ORDER BY month) AS prev_cnt,
       cnt - LAG(cnt) OVER (ORDER BY month) AS diff
FROM (
  SELECT TO_CHAR(insert_date, 'YYYY-MM') AS month, COUNT(*) AS cnt  -- PG
  FROM [테이블명] WHERE is_delete = 'N'
  GROUP BY TO_CHAR(insert_date, 'YYYY-MM')
) sub ORDER BY month;
```

---

## 6. CTE (WITH) 패턴

```sql
-- [PG/MySQL8+] 다단계 집계
WITH monthly_stats AS (
  SELECT TO_CHAR(insert_date, 'YYYY-MM') AS month, status, COUNT(*) AS cnt
  FROM [테이블명] WHERE is_delete = 'N'
  GROUP BY TO_CHAR(insert_date, 'YYYY-MM'), status
),
total_per_month AS (
  SELECT month, SUM(cnt) AS total FROM monthly_stats GROUP BY month
)
SELECT s.month, s.status, s.cnt, t.total,
       ROUND(s.cnt::NUMERIC / t.total * 100, 1) AS pct  -- PG: ::NUMERIC / MySQL: CAST AS DECIMAL
FROM monthly_stats s JOIN total_per_month t ON t.month = s.month
ORDER BY s.month, s.status;

-- [PG] 재귀 CTE: 트리 구조 (부모-자식)
WITH RECURSIVE tree AS (
  SELECT [테이블명]_seq, parent_seq, name, 0 AS depth
  FROM [테이블명] WHERE parent_seq IS NULL AND is_use = 'Y'
  UNION ALL
  SELECT c.[테이블명]_seq, c.parent_seq, c.name, p.depth + 1
  FROM [테이블명] c JOIN tree p ON p.[테이블명]_seq = c.parent_seq
  WHERE c.is_use = 'Y'
)
SELECT * FROM tree ORDER BY depth, [테이블명]_seq;

-- [MySQL8+] 재귀 CTE (동일 구문 지원)
```

---

## 7. PostgreSQL JSONB 패턴

```sql
-- JSONB 특정 키 값 추출 (->: JSON 객체, ->>: 텍스트)
SELECT [테이블명]_seq, extra_info->>'key_name' AS key_val
FROM [테이블명] WHERE extra_info IS NOT NULL AND is_delete = 'N';

-- JSONB 조건 검색 (@>: 포함 여부)
SELECT * FROM [테이블명]
WHERE extra_info @> '{"status": "active"}'::jsonb AND is_delete = 'N';

-- JSONB 배열 요소 펼치기 (jsonb_array_elements)
SELECT t.[테이블명]_seq, item->>'code' AS code, item->>'name' AS item_name
FROM [테이블명] t, jsonb_array_elements(t.items_json) AS item
WHERE t.is_delete = 'N';

-- JSONB 변경 전/후 비교 (이력 컬럼 활용)
SELECT [테이블명]_seq,
       before_info->>'position' AS before_pos,
       after_info->>'position'  AS after_pos
FROM [테이블명]_hist
WHERE before_info->>'position' IS DISTINCT FROM after_info->>'position'
ORDER BY insert_date DESC LIMIT 20;
```

---

## 8. MySQL JSON 패턴

```sql
-- JSON 키 값 추출
SELECT [테이블명]_seq,
       JSON_UNQUOTE(JSON_EXTRACT(extra_info, '$.key_name')) AS key_val
FROM [테이블명] WHERE extra_info IS NOT NULL AND is_delete = 'N';

-- JSON 조건 검색
SELECT * FROM [테이블명]
WHERE JSON_EXTRACT(extra_info, '$.status') = 'active' AND is_delete = 'N';

-- JSON 배열 펼치기 (MySQL 8.0+ JSON_TABLE)
SELECT t.[테이블명]_seq, j.code, j.item_name
FROM [테이블명] t,
     JSON_TABLE(t.items_json, '$[*]'
       COLUMNS (code VARCHAR(10) PATH '$.code', item_name VARCHAR(100) PATH '$.name')
     ) AS j
WHERE t.is_delete = 'N';

-- GROUP_CONCAT: 그룹별 값 나열
SELECT group_id, GROUP_CONCAT(name ORDER BY sort_order SEPARATOR ', ') AS names
FROM [테이블명] WHERE is_delete = 'N' GROUP BY group_id;
```

---

## 9. 집계 + HAVING 패턴

```sql
-- 특정 건수 이상인 그룹만 조회
SELECT member_seq, COUNT(*) AS cnt
FROM [테이블명] WHERE is_delete = 'N' AND status = 'A'
GROUP BY member_seq HAVING COUNT(*) >= 5
ORDER BY cnt DESC;

-- 다중 상태 분포 (CASE 집계)
SELECT
  COUNT(*) FILTER (WHERE status = 'A') AS active_cnt,   -- PG
  COUNT(*) FILTER (WHERE status = 'I') AS inactive_cnt,
  -- MySQL: SUM(IF(status='A',1,0)) AS active_cnt
  COUNT(*) AS total_cnt
FROM [테이블명] WHERE is_delete = 'N';

-- 평균 이상인 항목
SELECT * FROM [테이블명]
WHERE score > (SELECT AVG(score) FROM [테이블명] WHERE is_delete = 'N')
  AND is_delete = 'N'
ORDER BY score DESC LIMIT 20;
```

---

## 10. LATERAL JOIN (PostgreSQL)

```sql
-- 각 부모에 대해 최신 자식 N건 조회
SELECT p.parent_seq, p.name, c.child_seq, c.title, c.insert_date
FROM parent_table p
CROSS JOIN LATERAL (
  SELECT child_seq, title, insert_date
  FROM child_table
  WHERE parent_seq = p.parent_seq AND is_delete = 'N'
  ORDER BY insert_date DESC LIMIT 3
) c
WHERE p.is_delete = 'N' ORDER BY p.parent_seq;
```

---

## 11. 성능 진단 패턴

```sql
-- [PG] 쿼리 실행계획 분석 (BUFFERS 포함)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM [테이블명] WHERE status = 'A' AND is_delete = 'N' LIMIT 100;

-- [PG] 테이블 크기 확인
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size
FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- [MySQL] 실행계획
EXPLAIN FORMAT=JSON SELECT * FROM [테이블명] WHERE status = 'A' AND is_delete = 'N' LIMIT 100;

-- [MySQL] 테이블 크기 확인
SELECT TABLE_NAME, ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS size_mb
FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;
```

---

## 12. 개발/디버깅 패턴

```sql
-- 최근 N건 이력 조회
SELECT * FROM [테이블명]_hist ORDER BY insert_date DESC LIMIT 20;

-- 설정값 확인
SELECT config_key, config_value FROM common_config WHERE config_key LIKE '[키패턴]%';

-- NULL 컬럼 분포 확인
SELECT COUNT(*) AS total,
       COUNT([컬럼명]) AS non_null,
       COUNT(*) - COUNT([컬럼명]) AS null_cnt
FROM [테이블명];

-- 중복 데이터 탐지
SELECT [유니크_기준_컬럼], COUNT(*) AS cnt
FROM [테이블명] WHERE is_delete = 'N'
GROUP BY [유니크_기준_컬럼] HAVING COUNT(*) > 1
ORDER BY cnt DESC;
```

---

## 주의사항

- 모든 조회에 `LIMIT` 명시 (기본 100, 대량 테이블 50 이하)
- 대량 테이블은 `WHERE insert_date >= NOW() - INTERVAL '7 days'` 조건으로 범위 제한
- Window Function / CTE / JSON_TABLE: MySQL 8.0+ 필요 (5.7 이하 불가)
- `EXPLAIN ANALYZE`는 실제 실행되므로 UPDATE/DELETE에 사용 금지
- JSONB 연산자 (`@>`, `->`, `->>`)는 PostgreSQL 전용
