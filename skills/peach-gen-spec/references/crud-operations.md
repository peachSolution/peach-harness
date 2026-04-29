# CRUD 기능 가이드

Backend API에서 제공하는 표준 CRUD 기능 목록 및 설명

---

## 개요

모듈 개발 시 선택 가능한 7가지 CRUD 기능

---

## CRUD 기능 목록

| 기능 | 설명 | 사용 시기 |
|------|------|----------|
| **페이징 목록** (findPaging) | 페이지네이션 포함 목록 조회 | 일반적인 관리자 목록 화면, 검색/정렬 기능 필요 |
| **키워드 검색** (findList) | 전체 목록 조회 (페이징 없음) | Selectbox 데이터, 참조 데이터 선택, 소량 데이터 (<100건) |
| **상세 조회** (detailOne / findOne) | 단건 상세 정보 조회 | 상세 페이지, 수정 시 기존 데이터 로드 |
| **등록** (insert) | 신규 데이터 생성 | 등록 모달/페이지, 신규 데이터 입력 |
| **수정** (update) | 기존 데이터 수정 | 수정 모달/페이지, 데이터 변경 |
| **사용여부 변경** (updateUse) | is_use 플래그 토글 ('Y' ↔ 'N') | 목록에서 빠른 활성화/비활성화 토글 |
| **논리 삭제** (softDelete) | is_delete='Y' 처리 (복구 가능) | 데이터 삭제 (물리 삭제는 일반적으로 사용 안함) |

---

## 상세 설명

### 1. 페이징 목록 (findPaging)

**목적**: 페이지 번호 기반 목록 조회

**주요 파라미터**:
- page: 페이지 번호 (1부터 시작)
- row: 페이지당 행 수
- sortBy: 정렬 컬럼
- sortType: asc / desc
- keyword: 검색 키워드 (선택)
- startDate, endDate: 날짜 범위 (선택)
- isUse: 사용여부 필터 (선택)

**반환**: `{ data: Array<Entity>, totalRow: number }`

---

### 2. 키워드 검색 (findList)

**목적**: 전체 목록 조회 (페이징 없음)

**주요 파라미터**:
- keyword: 검색 키워드 (선택)
- isUse: 사용여부 필터 (선택)

**반환**: `{ data: Array<Entity> }`

**주의**: 소량 데이터 (권장 100건 미만)에만 사용

---

### 3. 상세 조회 (detailOne / findOne)

**목적**: 단건 상세 정보 조회

**메서드명 선택**:
- **detailOne**: 상세 페이지용, 추가 정보 포함 (파일, 관계 데이터 등)
- **findOne**: 단순 조회용, 테이블 데이터만

**파라미터**: seq (PK 값)

**반환**: `{ data: Entity }`

---

### 4. 등록 (insert)

**목적**: 신규 데이터 생성

**파라미터**: 엔티티 데이터 + 파일 UUID (옵션)

**반환**: `{ seq: number }` (생성된 PK)

**특이사항**:
- 파일 업로드 포함 시 파일 연결 로직 포함
- 공통 컬럼 자동 설정 (insert_seq, insert_date 등)

---

### 5. 수정 (update)

**목적**: 기존 데이터 수정

**파라미터**: seq + 수정할 필드 + 파일 UUID (옵션)

**특이사항**:
- 파일 업로드 포함 시 파일 재연결 로직 포함
- 공통 컬럼 자동 갱신 (update_seq, update_date)

---

### 6. 사용여부 변경 (updateUse)

**목적**: is_use 플래그만 토글

**파라미터**: seq + isUse ('Y' | 'N')

**사용 예**:
- 게시글 활성화/비활성화
- 계정 활성화/비활성화
- 상품 판매 중지/재개

---

### 7. 논리 삭제 (softDelete)

**목적**: is_delete='Y' 처리 (물리 삭제 아님)

**파라미터**: seq

**특이사항**:
- 데이터 복구 가능
- 파일 포함 시 파일도 함께 삭제 (is_delete='Y')
- 물리 삭제는 일반적으로 사용하지 않음

---

## 공통 컬럼 규칙

모든 테이블에 포함되는 표준 컬럼:

### PostgreSQL
```sql
"is_use" CHAR(1) DEFAULT 'Y',        -- 사용여부(Y:사용,N:미사용)
"is_delete" CHAR(1) DEFAULT 'N',     -- 삭제여부(Y:삭제,N:미삭제)
"insert_seq" int4,                   -- 등록자(member_seq참조)
"insert_date" TIMESTAMP DEFAULT NOW(), -- 등록일(자동생성)
"update_seq" int4,                   -- 수정자(member_seq참조)
"update_date" TIMESTAMP DEFAULT NOW()  -- 수정일(자동갱신)
```

### MySQL
```sql
`is_use` CHAR(1) DEFAULT 'Y' COMMENT '사용여부(Y:사용,N:미사용)',
`is_delete` CHAR(1) DEFAULT 'N' COMMENT '삭제여부(Y:삭제,N:미삭제)',
`insert_seq` BIGINT COMMENT '등록자(member_seq참조)',
`insert_date` DATETIME DEFAULT NOW() COMMENT '등록일(자동생성)',
`update_seq` BIGINT COMMENT '수정자(member_seq참조)',
`update_date` DATETIME DEFAULT NOW() ON UPDATE NOW() COMMENT '수정일(자동갱신)'
```

---

## PRD 작성 시 선택 가이드

| 화면 유형 | 권장 CRUD 조합 |
|-----------|---------------|
| 기본 관리 화면 | paging + detail + insert + update + updateUse + softDelete |
| 코드 관리 | paging + list + insert + update + softDelete |
| 읽기 전용 | paging + detail |
| 간단한 설정 | list + update |
| Selectbox 데이터 | list만 |

---

## 예제

### 공지사항 게시판 (전체 기능)
```markdown
| 기능 | 적용 |
|------|------|
| 페이징 목록 | Y |
| 키워드 검색 | Y |
| 상세 조회 | Y |
| 등록 | Y |
| 수정 | Y |
| 사용여부 변경 | Y |
| 논리 삭제 | Y |
```

### 코드 관리 (간소화)
```markdown
| 기능 | 적용 |
|------|------|
| 페이징 목록 | Y |
| 키워드 검색 | Y |
| 상세 조회 | N |
| 등록 | Y |
| 수정 | Y |
| 사용여부 변경 | N |
| 논리 삭제 | Y |
```

### Selectbox용 참조 데이터
```markdown
| 기능 | 적용 |
|------|------|
| 페이징 목록 | N |
| 키워드 검색 | Y |
| 상세 조회 | N |
| 등록 | N |
| 수정 | N |
| 사용여부 변경 | N |
| 논리 삭제 | N |
```

---

## 참조

- Backend 가이드 코드: `api/src/modules/test-data/`
- Frontend 가이드 코드: `front/src/modules/test-data/`
