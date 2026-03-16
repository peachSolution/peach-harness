# Changelog

> [keep-a-changelog](https://keepachangelog.com) 포맷을 따릅니다.
> 버전은 [Semantic Versioning](https://semver.org)을 따릅니다.

---

## [v1.8.0] - 2026-03-17

### Added
- `peach-release` 스킬 추가 — 버전 업데이트 → CHANGELOG.md 생성 → 커밋/푸시 → PR → 머지 → GitHub Release 일괄 처리

### Changed
- `peach-gen-feature-docs` / `peach-gen-spec`: Context Pack 방식 전환 — 고정 4파일 선택 주입 → 폴더 통째 주입(AI 자동 선택)
- `peach-gen-spec`: 입력 시나리오 A/B/C 명시, 워크플로우 6단계 정형화, prd-template 플레이스홀더 보강
- `docs/02-SDD-가이드.md`: SDD 개념/피치솔루션 맥락/TDD 전략/3가지 시나리오/상세 절차/Context Pack 6개 섹션 추가
- `peach-setup-ui-proto`: `peach-setup-harness`와 동일 수준으로 SKILL.md 재작성, references 01~04 재구성, bounded-autonomy 추가
- `peach-setup-harness`: references 8개 → 5개 섹션(01~05) 단순화, 신규/수정 이중 경로 → 단일 플로우 통일

---

## [v1.7.0] - 2026-03-16

### Added
- `peach-setup-ui-proto` 스킬 분리 신설 — Frontend-Only UI Proto 프로젝트 전용 하네스 설정
- `docs/02-SDD-가이드.md` 신규 추가
- `docs/03-워크플로우.md` 신규 추가
- `docs/05-기본지침과-AI도구-전환.md` 신규 추가
- `docs/06-에이전트팀-설정.md` 신규 추가

### Changed
- `peach-harness-help` → `peach-help`로 스킬명 변경
- `peach-gen-prd` → `peach-gen-spec`으로 스킬명 변경
- `peach-ask` → `peach-help`로 통합
- `peach-evidence-gate` → `peach-qa-gate`로 스킬명 변경
- `docs/ARCHITECTURE.md` → `docs/01-아키텍처.md`로 이동
- `docs/DISTRIBUTION.md` → `docs/04-배포구조.md`로 이동
- `setup-harness` references: 네이밍 컨벤션 예시 컬럼 및 DB 마이그레이션 명령어 추가
- README: `peach-help`, `peach-setup-harness` 스킬 목록 반영, `npx skills add` 권고 및 `-g` 글로벌 설치 안내 추가

### Removed
- `docs/WORKFLOW.md` (→ `docs/03-워크플로우.md` 통합)
- `skills/peach-planning-gate/SKILL.md`

---

## [v1.5.0] - 2026-03-15

### Added
- 에이전트 팀 모델 오버라이드 기능 추가 (`model=opus/sonnet/haiku` 옵션)
- 에이전트 팀 설정 가이드 추가

### Changed
- `peach-setup-harness`: Frontend-Only 모듈 감지 일반화, 패키지 매니저 bun으로 통일
- `AGENTS.md` 최소화 원칙 적용 — grep 최소화, references 경량화
- README: 멀티 에이전트 설치/업데이트 방법 업데이트

---

## [v1.4.0] - 2026-03-15

### Added
- `peach-setup-harness` 스킬 신설 — 대상 프로젝트에 하네스 시스템 설정
- `.gitignore` 추가 (`settings.local.json` 제외)
- 팀 스킬 입력 검증 및 PR 코드리뷰 가이드 추가

### Changed
- Skills 2.0 frontmatter 개선 — `allowed-tools` 명시, description 트리거 키워드 강화
- 스킬 전체 패키지 매니저 bun 기본값 적용
- docs 구조 재편 및 스킬명 정리 (명확성 개선)
- evidence-gate 흐름 및 기능 문서 컨텍스트 설명 보완

---

## [v1.2.0] - 2026-03-15

### Added
- `peach-gen-ui-proto` 스킬 신설 — Mock 데이터 기반 UI 프로토타입 생성 (기획자/디자이너용)
- 전체 스킬에 references 및 assets 추가 (peach-backoffice에서 포팅)
- 팀 스킬 완료 파이프라인에 evidence-gate 단계 추가

---

## [v1.1.0] - 2026-03-14

### Added
- `peach-ask` 스킬 신설 — analyze+adapt 파이프라인 채택
- `AGENTS.md`에 버전 관리 규칙 추가

### Changed
- 플러그인 배포 구조를 planning-with-files 패턴과 동일한 flat layout으로 통일
