# 컬럼 코멘트 작성 가이드

## 기본 형식

```sql
COMMENT ON COLUMN "테이블"."컬럼" IS '[한글설명]';
```

## 선택값/상태값 코멘트 (필수!)

선택값이 있는 컬럼은 반드시 코드와 값을 함께 기록:

```sql
COMMENT ON COLUMN "notice"."status" IS '상태(A:활성,I:비활성,D:삭제)';
COMMENT ON COLUMN "notice"."notice_type" IS '공지유형(N:일반,I:중요,E:긴급)';
COMMENT ON COLUMN "member"."gender" IS '성별(M:남성,F:여성)';
COMMENT ON COLUMN "order"."pay_method" IS '결제방법(C:카드,B:계좌이체,P:포인트,M:복합)';
```

## CRUD 코드 활용을 위한 상세 코멘트

### ✅ 좋은 예시
CRUD 코드에서 바로 활용 가능:

```sql
COMMENT ON COLUMN "notice"."title" IS '제목(필수,최대200자)';
COMMENT ON COLUMN "notice"."view_count" IS '조회수(기본값:0,자동증가)';
COMMENT ON COLUMN "notice"."start_date" IS '게시시작일(NULL허용,NULL이면즉시게시)';
COMMENT ON COLUMN "notice"."display_order" IS '표시순서(오름차순정렬,기본값:0)';
```

### ❌ 나쁜 예시
정보 부족:

```sql
COMMENT ON COLUMN "notice"."title" IS '제목';
COMMENT ON COLUMN "notice"."status" IS '상태';
```

## 참조 컬럼 코멘트 규칙

형식: `[한글설명]([참조테이블]참조,FK없음)`

✅ 좋은 예시:
```sql
COMMENT ON COLUMN "order"."category_seq" IS '카테고리번호(category참조,FK없음)';
COMMENT ON COLUMN "post"."writer_seq" IS '작성자(member참조,FK없음)';
COMMENT ON COLUMN "approval"."linked_seq" IS '연결된결재건(approval참조,FK없음)';
```

❌ 나쁜 예시:
```sql
COMMENT ON COLUMN "order"."category_seq" IS '카테고리';               -- 참조 정보 없음
COMMENT ON COLUMN "post"."writer_seq" IS '작성자 member_seq';          -- 컬럼명 그대로 사용
```

---

## 작성 원칙

1. **필수/선택 명시**: (필수) 또는 (NULL허용)
2. **길이 제약**: (최대200자)
3. **기본값**: (기본값:0)
4. **자동 처리**: (자동증가), (자동생성)
5. **선택값 코드화**: (A:활성,I:비활성)
6. **비즈니스 규칙**: (NULL이면즉시게시)
