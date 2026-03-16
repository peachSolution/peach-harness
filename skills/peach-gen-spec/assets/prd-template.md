# FEATURE_NAME_KR

> DESCRIPTION

---

# Part A: Visual Overview (사람용)

이 섹션은 시각적 이해를 위한 다이어그램입니다. Mermaid 코드도 텍스트로 읽어 구조 파악에 활용됩니다.

---

## 시스템 아키텍처

```mermaid
flowchart TB
    subgraph Frontend["Frontend (Vue 3)"]
        UI[UI Components]
        Store[Pinia Store]
    end

    subgraph Backend["Backend (Koa)"]
        Controller[Controller]
        Service[Service]
        DAO[DAO]
    end

    subgraph Database["Database"]
        Table[(TABLE_NAME)]
    end

    UI --> Store
    Store -->|HTTP| Controller
    Controller --> Service
    Service --> DAO
    DAO --> Table
```

---

## 데이터 흐름

DATA_FLOW_DIAGRAM

---

## UI 흐름도

UI_FLOW_DIAGRAM

---

## ER 다이어그램

```mermaid
erDiagram
    TABLE_NAME {
        PK_TYPE TABLE_NAME_seq PK
SCHEMA_ER_COLUMNS
        CHAR is_use
        CHAR is_delete
        FK_TYPE insert_seq
        DATETIME_TYPE insert_date
        FK_TYPE update_seq
        DATETIME_TYPE update_date
    }
ER_RELATIONS
```

---

# Part B: Detailed Spec (AI용)

이 섹션은 AI 코드 생성을 위한 상세 명세입니다.

---

## 메타
- 모듈명: MODULE_NAME
- 테이블명: TABLE_NAME
- 한글 기능명: FEATURE_NAME_KR
- 한줄 설명: DESCRIPTION
- UI 패턴: UI_PATTERN
- 파일 업로드: FILE_UPLOAD_YN
- 저장 방식: STORAGE_TYPE
- 설계 메모: DESIGN_MEMO

---

## 1. 기능 범위

### CRUD 기능
| 기능 | 적용 | 메서드명 | 설명 |
|------|------|----------|------|
| 페이징 목록 | CRUD_PAGING | findPaging | 페이지네이션 포함 목록 조회 |
| 키워드 검색 | CRUD_LIST | findList | Selectbox용 전체 목록 |
| 상세 조회 | CRUD_DETAIL | detailOne / findOne | 단건 상세 정보 |
| 등록 | CRUD_INSERT | insert | 신규 데이터 생성 |
| 수정 | CRUD_UPDATE | update | 기존 데이터 수정 |
| 사용여부 변경 | CRUD_UPDATE_USE | updateUse | is_use 플래그 토글 |
| 논리 삭제 | CRUD_SOFT_DELETE | softDelete | is_delete='Y' 처리 |

### 파일 기능
| 기능 | 적용 |
|------|------|
| 일반 파일 | FILE_GENERAL_YN |
| 이미지 | FILE_IMAGE_YN |
| 저장 방식 | STORAGE_TYPE |

---

## 2. UI 구성

### 패턴: UI_PATTERN_FULL_NAME

### 검색 조건
SEARCH_CONDITIONS

### 목록 컬럼
LIST_COLUMNS

### 화면별 필드 구분
FIELD_MAPPING

### 화면 구성
UI_SCREEN_COMPOSITION

### 검증
UI_VALIDATION_RULES

### 테스트 시나리오
TEST_SCENARIOS

---

## 3. DB 스키마

### DB 종류: DB_TYPE

### 테이블: TABLE_NAME

<!-- PostgreSQL 타입 사용 시 -->
<!-- | TABLE_NAME_seq | serial4 | Y | PK | - | 자동증가 | -->
<!-- | insert_seq | int4 | Y | 등록자 | - | - | -->
<!-- | insert_date | TIMESTAMP | Y | 등록일 | - | - | -->

<!-- MySQL 타입 사용 시 -->
<!-- | TABLE_NAME_seq | BIGINT | Y | PK | - | AUTO_INCREMENT | -->
<!-- | insert_seq | BIGINT | Y | 등록자 | - | - | -->
<!-- | insert_date | DATETIME | Y | 등록일 | - | - | -->

| 컬럼 | 타입 | 필수 | 설명 | 선택값 | 기본값 |
|------|------|------|------|--------|--------|
| TABLE_NAME_seq | PK_TYPE | Y | PK | - | PK_DEFAULT |
SCHEMA_COLUMNS
| is_use | CHAR(1) | Y | 사용여부 | Y:사용,N:미사용 | Y |
| is_delete | CHAR(1) | Y | 삭제여부 | Y:삭제,N:정상 | N |
| insert_seq | FK_TYPE | Y | 등록자 | - | - |
| insert_date | DATETIME_TYPE | Y | 등록일 | - | - |
| update_seq | FK_TYPE | Y | 수정자 | - | - |
| update_date | DATETIME_TYPE | Y | 수정일 | - | - |

### 인덱스
```sql
SCHEMA_INDEXES
```

### 참조 관계 (FK 생성 안함)
REFERENCE_RELATIONS

---

## 4. 파일 목록

### Backend
```
api/src/modules/MODULE_NAME/
├── type/
│   └── MODULE_NAME.type.ts
├── dao/
│   └── MODULE_NAME.dao.ts
├── service/
│   ├── MODULE_NAME.service.ts
│   └── MODULE_NAME-tdd.service.ts
├── controller/
│   ├── MODULE_NAME.validator.ts
│   └── MODULE_NAME.controller.ts
└── test/
    └── MODULE_NAME.test.ts
```

### Frontend
```
front/src/modules/MODULE_NAME/
├── type/
│   └── MODULE_NAME.type.ts
├── store/
│   └── MODULE_NAME.store.ts
├── pages/
│   ├── list.vue
│   ├── list-search.vue
│   └── list-table.vue
├── modals/
FRONTEND_MODAL_FILES
└── test/
    └── MODULE_NAME.test.ts (선택)
```

---

## 5. 참조
- 가이드 코드:
  - Backend: `api/src/modules/test-data/`
  - Frontend: `front/src/modules/test-data/FRONTEND_GUIDE_PATH`
