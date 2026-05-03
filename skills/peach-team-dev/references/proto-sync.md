# proto 인자 자동 처리 절차

`peach-team-dev`가 `proto=<경로>` 인자를 받았을 때 수행하는 Spec 자동 복사 절차.

## 목차

- [목적](#목적)
- [입력](#입력)
- [절차](#절차-6단계)
- [검증 기준](#검증-기준-proto-모드)
- [에러 케이스](#에러-케이스)
- [검증](#검증)
- [비고](#비고)

## 목적

- ui-proto 저장소의 `_spec.md`를 본 프로젝트의 `docs/spec/...`로 자동 이전
- 사용자가 Spec 위치를 의식하지 않아도 동작하게 함
- 본 프로젝트가 dev 시점에 확정되므로 그 시점에 복사가 가장 자연스러움

## 입력

```bash
/peach-team-dev mode=... proto=<ui-proto 태스크 폴더 절대 경로>
```

예: `proto=<PROTO_REPO>/src/modules-task/2604/260427-<initial>-goods`
(`<PROTO_REPO>`: ui-proto 저장소 절대경로, `<initial>`: 작업자 이니셜)

## 절차 (6단계)

### 1. proto 경로 검증

```bash
# 폴더 존재 확인
[ -d "$PROTO_PATH" ] || error "proto 경로가 존재하지 않습니다: $PROTO_PATH"

# _spec.md 존재 확인
[ -f "$PROTO_PATH/_spec.md" ] || error "_spec.md가 없습니다. ui-proto에서 Spec을 먼저 작성하세요."

# _task-meta.ts 존재 확인 (메타 추출용)
[ -f "$PROTO_PATH/_task-meta.ts" ] || error "_task-meta.ts가 없습니다. ui-proto 표준 구조가 아닙니다."
```

검증 실패 시 즉시 중단하고 사용자에게 안내.

### 2. 메타 추출

`_task-meta.ts`에서 다음 필드를 읽는다:

```typescript
export const taskMeta = {
  date: '2026-04-27',         // YYYY-MM-DD
  planner: 'nettem',          // 개발자/기획자 ID
  title: '상품 관리',          // 한글 제목
  description: '...',
  modules: [...]
};
```

추출:
- `planner`
- `date` → `YYMMDD` 변환 (예: `2026-04-27` → `260427`)
- `title` → 파일명 안전 형태로 변환 (공백 → `-`, 특수문자 제거)

### 3. 대상 경로 산출

```
docs/spec/{YY}/{MM}/{planner}-{YYMMDD}-{title}.md

예: docs/spec/26/04/nettem-260427-상품관리.md
```

연/월 폴더가 없으면 자동 생성.

### 4. DB 기준 확인

`mode=backend|fullstack`이면 본 개발 전에 DB 스키마가 준비되어 있어야 한다.

대상 모듈/도메인은 사용자 입력, Spec, `_task-meta.ts`에서 확정한다. 값이 모호하면 전체 스키마 목록을 보고 임의 통과하지 말고 사용자에게 대상 스키마를 확인한다.

```bash
MODULE_NAME="<module-name>"
DOMAIN_NAME="<domain-name>"
TABLE_NAME="<table-name>"

TARGET_SCHEMA_CANDIDATES=(
  "api/db/schema/${DOMAIN_NAME}/${TABLE_NAME}.sql"
  "api/db/schema/${DOMAIN_NAME}/${MODULE_NAME}.sql"
  "api/db/schema/${MODULE_NAME}/${MODULE_NAME}.sql"
)

FOUND_SCHEMA=""
for schema in "${TARGET_SCHEMA_CANDIDATES[@]}"; do
  [ -f "$schema" ] && FOUND_SCHEMA="$schema" && break
done

[ -n "$FOUND_SCHEMA" ] || {
  find api/db/schema -name "*.sql" -type f 2>/dev/null
  echo "대상 모듈 DB 스키마가 없습니다. peach-gen-db를 먼저 실행하세요: module=${MODULE_NAME}, domain=${DOMAIN_NAME}, table=${TABLE_NAME}"
  exit 1
}
```

대상 모듈 스키마가 없으면 `peach-gen-db`를 먼저 실행하도록 안내하고 중단한다. `api/db/schema` 아래 다른 `.sql` 파일이 있어도 대상 스키마가 아니면 통과 처리하지 않는다. `peach-team-dev`는 마이그레이션 생성/적용을 담당하지 않는다.

### 5. 충돌 감지

대상 경로에 같은 파일이 이미 존재하면 사용자에게 선택을 요청한다.

```
⚠️ docs/spec/26/04/nettem-260427-상품관리.md 가 이미 존재합니다.

어떻게 처리할까요?
(a) 덮어쓰기 — proto의 _spec.md를 그대로 복사 (기존 내용 손실)
(b) 유지 — 기존 본 프로젝트의 Spec을 그대로 사용
(c) diff 보기 — 차이점을 보고 결정
```

각 선택의 동작:
- **(a) 덮어쓰기**: proto의 `_spec.md`를 그대로 복사. 기존 내용은 git history에 남음
- **(b) 유지**: 본 프로젝트 Spec을 그대로 사용. proto와 본 프로젝트가 동기화되어 있다고 가정
- **(c) diff 보기**: `diff <proto>/_spec.md docs/spec/.../*.md` 실행 후 다시 (a)/(b) 선택

### 6. 컨텍스트 주입

복사가 완료되면 다음을 서브에이전트 프롬프트에 주입한다. team-dev에서는 구현 참고와 코드 수준 검증 기준으로 사용하고, 실제 브라우저 흐름 부합 판정은 `peach-team-e2e`가 담당한다:

```
## 검증 기준 (proto 모드)

### Spec (비즈니스 규칙, 데이터 정확성, 예외)
경로: docs/spec/{YY}/{MM}/{planner}-{YYMMDD}-{title}.md
[Spec 본문 일부 인용]

### ui-proto 화면 (레이아웃, 인터랙션 흐름)
경로: <PROTO_PATH>/
파일 목록:
- _task-meta.ts
- _spec.md
- overview/pages/overview.vue (기획서 화면)
- {서브모듈}/pages/*.vue (UI 화면)

### 구현 기준 우선순위 규칙
- 화면 레이아웃, 인터랙션 흐름: ui-proto를 구현 참고 자료로 우선 사용
- 비즈니스 규칙, 데이터 정확성: Spec 기준으로 코드와 TDD 작성
- 둘 다 모호: 검증 불가로 보고
```

## 에러 케이스

| 상황 | 처리 |
|------|------|
| proto 경로 없음 | 즉시 중단, "proto 경로가 존재하지 않습니다" |
| `_spec.md` 없음 | 즉시 중단, "ui-proto에서 Spec을 먼저 작성하세요" 안내 |
| `_task-meta.ts` 없음 | 즉시 중단, "ui-proto 표준 구조가 아닙니다" |
| 파일명 추출 실패 (한글 깨짐 등) | 사용자에게 파일명 직접 입력 요청 |
| `mode=backend|fullstack`인데 대상 모듈 DB 스키마 없음 | 즉시 중단, `peach-gen-db` 선행 안내 |
| 대상 모듈/도메인 추출 실패 | 스키마 목록을 보고 사용자에게 대상 스키마 확인 요청 |
| 본 프로젝트에 `docs/spec/` 자체가 없음 | 자동 생성 |
| 충돌 발생 | 사용자 선택 요청 (3-옵션) |

## 검증

복사 완료 후 다음을 보고:

```
✅ Spec 자동 복사 완료
- 원본: <PROTO_PATH>/_spec.md
- 사본: docs/spec/{YY}/{MM}/{planner}-{YYMMDD}-{title}.md
- 메타: planner={planner}, date={date}, title={title}

구현 기준 컨텍스트 주입 완료. 서브에이전트가 Spec + ui-proto 화면을 구현 참고와 코드 수준 검증 기준으로 사용합니다.
```

## 비고

- proto의 modules-task 폴더(Vue 파일들)는 **복사하지 않는다**. ui-proto는 검토용 보관본으로 유지하고, 본 개발은 본 프로젝트의 modules에서 새로 생성한다.
- ui-proto의 `_spec.md`가 1차 Source of Truth이므로, 본 프로젝트의 Spec을 수정해도 proto 저장소에는 자동 반영되지 않는다. 큰 변경이 있으면 proto의 `_spec.md`도 별도 갱신해야 한다.
