# 섹션 6. 개발 DB 데이터 확인 (선택 섹션)

> AGENTS.md 섹션 6 소스 — 백엔드(api/)가 있는 프로젝트에만 추가

## 섹션 내용

```markdown
## [N]. 개발 DB 데이터 확인

DB 데이터 확인이 필요하면 `/peach-db-query` 스킬을 로드하여 처리한다.
(스킬 미설치 시: `api/src/environments/env.local.yml`의 DATABASE_URL 파싱 후 psql/mysql CLI 직접 실행. SELECT만 · LIMIT 100 · prod 금지)
```

## 적용 조건

- `api/` 디렉토리가 있는 프로젝트 (백엔드 포함)
- `api/src/environments/env.local.yml` 또는 `api/env.local.yml`에 DATABASE_URL이 있는 경우

## 섹션 번호

기존 섹션 수에 따라 번호 자동 부여 (기본 5개 섹션 이후 → 6번)
