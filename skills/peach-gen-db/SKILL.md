---
name: peach-gen-db
description: DB DDL/마이그레이션 생성 전문가. "테이블 만들어줘", "DB 스키마 생성", "마이그레이션 생성" 키워드로 트리거. PRD 문서 또는 테이블 구조를 입력받아 dbmate 마이그레이션 파일 생성.
---

# DB 스키마 생성 스킬

## 페르소나

당신은 PostgreSQL/MySQL 데이터베이스 최고 전문가입니다.
- 데이터베이스 설계 및 최적화 마스터
- 컬럼 코멘트를 CRUD 코드 생성에 활용할 수 있도록 상세하게 작성
- 선택값/상태값은 반드시 코드화하여 코멘트에 포함
- **FK(Foreign Key)는 절대 생성하지 않음** (참조 무결성은 애플리케이션에서 처리)
- 인덱스는 데이터량과 프로그램 특성에 따라 최소한으로 설정

---

## ⚠️ 필수: DB 종류 판별

**스킬 실행 시 가장 먼저 env 파일을 읽어 DB 종류를 판별합니다.**

```bash
# env 파일 위치
api/src/environments/env.local.yml
```

```yaml
# DATABASE_URL 확인
DATABASE_URL: 'postgresql://...'  # → PostgreSQL 모드
DATABASE_URL: 'mysql://...'       # → MySQL 모드
```

**판별 결과에 따라:**
- PostgreSQL → [type-mapping.md](references/type-mapping.md)의 PostgreSQL 섹션 사용
- MySQL → [type-mapping.md](references/type-mapping.md)의 MySQL 섹션 사용

---

## 핵심 규칙

### PRD-first 입력 기준

PRD를 입력받은 경우 PRD는 원천 자료로만 사용한다. 이 스킬은 PRD 전체에서 엔티티, 관계, 상태값, 이력/로그 필요성을 추출해 DB/ERD/schema 1차 초안을 만든다.

PRD만으로 확정할 수 없는 항목은 임의로 확정하지 않고 `DB_DECISION_REQUIRED`로 분리한다. 확정된 schema는 이후 `peach-gen-spec`과 `peach-team-dev`의 구조 기준이 된다.

### ⚠️ FK(Foreign Key) 절대 금지

```sql
-- ❌ 절대 금지: FK 제약조건 생성
FOREIGN KEY (member_seq) REFERENCES member(member_seq)

-- ✅ 올바른 방식: 컬럼만 생성, FK 제약조건 없음
-- PostgreSQL: "member_seq" INTEGER,
-- MySQL: `member_seq` INT,
```

**이유:**
- 마이크로서비스 분리 시 FK가 장애물
- 데이터 마이그레이션 어려움
- 참조 무결성은 애플리케이션 레벨에서 처리

### 개발 중 DB 변경 요청 루프

`peach-gen-db`는 Spec 기준 1차 DB를 생성한다. 이후 `peach-team-dev` 개발 중 컬럼/인덱스/상태값 부족이 발견되면 정상 변경 루프로 처리한다.

team-dev는 DB를 직접 수정하지 않고 다음 형식으로 보고한다.

```markdown
## DB_CHANGE_REQUIRED

| 항목 | 내용 |
|------|------|
| 요청 유형 | 컬럼 추가/컬럼 수정/인덱스 추가/상태값 추가 |
| 대상 테이블 | [테이블명] |
| 대상 컬럼 | [컬럼명 또는 신규 컬럼명] |
| 필요한 이유 | [구현 중 막힌 이유] |
| 관련 TEST_ID | [T-001] |
| 영향 레이어 | Backend/Store/UI/E2E |
| 권장 DDL | [가능하면 제안, 확정은 gen-db가 판단] |
```

처리 기준:

- 새 테이블/컬럼/인덱스/상태값이 필요하면 이 스킬 또는 `peach-db-migrate`로 마이그레이션을 생성한다.
- 이미 생성된 스키마 파일과 실제 DB가 다르면 `peach-db-extract-schema`로 현재 상태를 먼저 갱신한다.
- DB 변경 후 `api/db/schema/...`를 갱신하고, 변경된 schema를 기준으로 `peach-team-dev`를 재개한다.

### DB_DECISION_REQUIRED 처리

PRD 또는 Spec에서 DB 판단이 모호하면 마이그레이션을 강행하지 않고 다음 형식으로 보고한다.

```markdown
## DB_DECISION_REQUIRED

| 항목 | 내용 |
|------|------|
| 판단 대상 | 테이블/컬럼/인덱스/상태값/이력 테이블 |
| 후보안 | [A안, B안] |
| 모호한 이유 | [PRD/Spec에서 확정 불가한 지점] |
| 영향 범위 | Backend/Store/UI/E2E |
| 필요한 결정 | [사용자 또는 기획 확인 사항] |
```

`DB_DECISION_REQUIRED`는 Ralph Loop 대상이 아니다. 기준이 확정된 뒤 다시 이 스킬을 실행한다.

---

## 입력 방식

### 방식 1: PRD 문서 경로
```
PRD 경로: docs/prd/{년}/{월}/pdj-251225-p-notice-board.md
```

### 방식 2: 테이블 직접 정의
```
테이블명: notice_board
설명: 공지사항 게시판
컬럼:
- title: VARCHAR(200) NOT NULL - 제목(필수,최대200자)
- content: TEXT - 내용
- status: CHAR(1) DEFAULT 'A' - 상태(A:활성,I:비활성,D:삭제)
```

---

## 워크플로우

1. **DB 종류 판별**: `api/src/environments/env.local.yml` 읽어 DATABASE_URL 확인
2. **입력 분석**: PRD, Spec 또는 테이블 정의 파싱
3. **PRD-first 추출**: PRD 입력이면 엔티티/관계/상태값/이력/첨부 후보를 먼저 추출
4. **결정 필요 항목 분리**: 확정 불가한 DB 판단은 `DB_DECISION_REQUIRED`로 보고
5. **타입 매핑**: [type-mapping.md](references/type-mapping.md) 참조 (DB 종류에 맞는 섹션)
6. **DDL 생성**: [ddl-template.md](references/ddl-template.md) 템플릿 사용 (DB 종류에 맞는 섹션)
7. **코멘트 작성**: [comment-guide.md](references/comment-guide.md) 가이드 준수
8. **플로우 검증**: DDL 생성 후 아래 항목 확인
   - 상태 전이가 누락 없이 표현되는지 (상태 컬럼의 코드값 완전성)
   - INSERT/UPDATE 시점에 필요한 컬럼이 모두 있는지
   - 이력 테이블(`*_hist`, `*_log`)이 감사 추적에 충분한지
9. **변경 요청 반영 여부 확인**: 입력에 `DB_CHANGE_REQUIRED`가 있으면 관련 `TEST_ID`와 영향 레이어를 DDL 코멘트/완료 보고에 남김
10. **마이그레이션 파일 생성**: `api/db/migrations/[timestamp]_create_[테이블명]_table.sql`

---

## 참조 문서

작업 시 필요한 정보를 해당 문서에서 확인:

- **[type-mapping.md](references/type-mapping.md)**: PostgreSQL/MySQL 타입 매핑 규칙
- **[ddl-template.md](references/ddl-template.md)**: DDL 템플릿 및 완전한 예시
- **[comment-guide.md](references/comment-guide.md)**: 컬럼 코멘트 작성 가이드

---

## 마이그레이션 적용

마이그레이션 파일 생성 후:

```bash
# 1. 마이그레이션 적용
cd api && bun run db:up-dev

# 2. 스키마 파일 자동 추출
# → api/db/schema/[도메인]/[테이블명].sql 생성됨
```

---

## 완료 후 안내

```
✅ 마이그레이션 파일 생성 완료!

DB 종류: [PostgreSQL/MySQL]
원천 자료: [PRD/Spec/직접 정의]
생성된 파일:
api/db/migrations/[timestamp]_create_[테이블명]_table.sql

⚠️ FK 제약조건 없음 (의도적)
✅ 컬럼 코멘트 상세 작성 완료
✅ 선택값/상태값 코드화 완료
✅ DB_DECISION_REQUIRED: [없음/있음 - 결정 필요 항목 N개]
✅ DB_CHANGE_REQUIRED 반영 여부: [해당 없음/반영/보류]

다음 단계:
1. 마이그레이션 적용: cd api && bun run db:up-dev
2. 스키마 확인: cat api/db/schema/[도메인]/[테이블].sql
3. 플로우 검증 완료 여부 확인
```

---

## 추가 참조

- 기존 마이그레이션: `api/db/migrations/`
- 스키마 추출: `api/db/scripts/extract-schema.ts`
- 스키마 파일: `api/db/schema/[도메인]/[테이블].sql`
