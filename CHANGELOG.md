# Changelog

> [keep-a-changelog](https://keepachangelog.com) 포맷을 따릅니다.
> 버전은 [Semantic Versioning](https://semver.org)을 따릅니다.

---

## [Unreleased]

### Added
- peach-review-ux 스킬 추가 — Laws of UX와 GeekNews 요약을 피치 백오피스 관점으로 재구성한 읽기전용 UX 리뷰 스킬
- docs/분석/2026-05-02-peach-review-ux-보강분석.md 추가 — UX 스킬 보강 근거와 향후 통합 기준 정리

### Changed
- 워크플로우/도움말/README에 `peach-review-ux`를 선택적 UX 리뷰 스킬로 안내

---

## [v1.18.2] - 2026-04-29

### Added
- pre-commit 시크릿 차단 게이트 도입 (`hooks/pre-commit-secrets.sh`, `hooks/install.sh`)
- peach-e2e-scenario: jQuery UI Dialog iframe `page.frames()` 폴링 패턴 추가
- peach-e2e-scenario: 다단계 번호 설계 규칙, `state.json` PK 공유 패턴, `finally` DELETE 금지 패턴 추가
- peach-e2e-scenario: 서버 사이드 이력 조건 초기화 패턴, captcha 우회 정책 추가
- peach-e2e-scenario: AJAX 결과 폴링, CDP UA 컨텍스트 닫힘 패턴 추가
- peach-e2e-scenario: 테스트 데이터 식별자, localStorage setItem 순서 패턴 추가

### Changed
- `release` 스킬 이름 변경 (`peach-release` → `release`) — internal 스킬 전용이므로 네임스페이스 접두어 불필요
- peach-e2e-browse: Chrome Beta 고정 프로필 규칙 강화
- peach-e2e-scenario: 자율 보완 루프 강화
- peach-e2e-setup, peach-e2e-suite, peach-team-e2e: 워크플로우 보완

---

## [v1.18.1] - 2026-04-29

### Security
- 작업트리 전체에서 사내 식별 정보 제거 — 도메인/DB 접속 정보/포트/사용자명/회사명/사업자번호/사내 코드네임/업무 도메인 어휘/PK 필드명/개인 절대경로를 플레이스홀더로 치환
- git history 리셋 — orphan branch로 main/develop을 단일 커밋으로 재구성하여 과거 커밋의 사내 정보 노출 차단

### Changed
- peach-skill-feedback 스킬 보강 — 민감 정보 금지 규칙을 진입부 최상단으로 이동, 5개 카테고리 추가(사내 코드네임/업무 어휘/PK 필드명/한글 회사명/개인 절대경로), 한글·고유명사 판단 휴리스틱 도입, Write 직전 자동 검사 4종 강화
- peach-release 스킬 보강 — 민감 정보 사전 차단을 0단계로 격상(1단계보다 먼저 실행), 동일 5개 카테고리 추가, AI diff 직접 검토 의무화
- 스킬 본체에서 사내 도메인 예시 정리 — peach-db-query/peach-wiki/peach-e2e-suite/peach-e2e-scenario/peach-doc-feature

---

## [v1.18.0] - 2026-04-27

### Added
- peach-team-dev 통합 스킬 신설 — 풀스택 개발 통합. 표준(proto+Spec)/Spec만/prompt 3가지 입력 모드 지원, proto 자동 복사, prompt 모드 자동 분기(소/중/대 규모)
- peach-team-e2e 통합 스킬 신설 — E2E 검증 통합. ui-proto 화면 흐름 + Spec 비즈니스 규칙으로 검증 기준 외부화, 미스매치 3가지 분류(Spec 위반/proto 불일치/시나리오 오류)
- docs/분석/2026-04-27-스킬재구성-분석.md 신설 — 검증 기준 외부화 의사결정, gen-* 흡수 vs 호출 결정, skill-creator 4대 원칙 차용
- peach-gen-ui-proto 팀 모드 신설 — Spec 입력 시 proto-ui-dev + proto-ui-qa 자동 진입, 랄프루프 5/10회

### Changed
- peach-gen-ui-proto 조건부 팀화 — Spec 입력 시 팀 모드 자동, 없으면 단독 모드 유지(기획자 직접 작업 케이스 보존)
- peach-gen-design 사용 방향 안내 추가 — 일반적 컨설팅 참고용으로 유지, 본체는 ui-proto 저장소 내부로
- peach-help SKILL.md를 3-Tier 빠른 참조표로 재구성 — 표준 플로우/단계별/보조 분리
- docs/03-워크플로우.md 전면 재작성 — 4단계 직선형 + 6가지 사용 패턴(A~F) + prompt 모드 안내
- README.md 스킬 인벤토리 갱신 — 통합 스킬 반영, 서브에이전트 6개 추가(proto-ui-dev/qa, e2e-scenario-dev/qa, e2e-suite-dev/qa)

### Removed
- peach-team 스킬 폐기 — peach-team-dev로 흡수 통합
- peach-team-refactor 스킬 폐기 — AI Plan 모드 + Edit으로 처리
- peach-refactor-backend 스킬 폐기 — 동일
- peach-refactor-frontend 스킬 폐기 — 동일

---

## [v1.17.2] - 2026-04-25

### Changed
- peach-gen-feature-docs를 peach-doc-feature로 변경하여 기존 기능 문서화 스킬명을 간결하게 정리
- peach-gen-diagram 형식 선택 기준을 개선하여 조건 분기·합류·계층 구조는 Mermaid를 우선하도록 조정
- 워크플로우, SDD, 아키텍처 문서의 다이어그램과 스킬 참조를 peach-doc-feature 기준으로 정리
- AGENTS.md의 다이어그램 지침을 peach-gen-diagram 참조 중심으로 단순화

---

## [v1.17.1] - 2026-04-24

### Added
- peach-gen-diagram 스킬 추가 — Unicode box-drawing 기본 제안과 Mermaid/D2 기반 워크플로우·아키텍처·구조 다이어그램 생성 지원

### Changed
- peach-release 버전 판단 기준 개선 — 보조/유틸 스킬 추가는 patch, 핵심 개발 워크플로우 확장은 minor로 구분

---

## [v1.17.0] - 2026-04-23

### Added
- peach-wiki 스킬 통합 — Karpathy LLM Wiki 패턴 기반 누적형 지식베이스 구축·유지 (코드 프로젝트 + Obsidian 지원)
- docs/위키스킬/ 신설 — LLM Wiki 배경 이론 문서 7개 (원문·패턴분석·구성도·qmd가이드·종합분석·통합분석)
- docs/08-wiki-feature-docs-경계규칙.md — wiki/feature-docs 경계 규칙 및 AGENTS.md 소유권 분리 정의

### Changed
- AGENTS.md — 경계규칙·위키스킬 문서 참조 추가
- README — peach-wiki 스킬 목록 추가, 마이그레이션 안내(플러그인/skills.sh 제거 방법) 추가

---

## [v1.16.6] - 2026-04-21

### Changed
- peach-e2e-browse: Chrome CDP 미연결 시 e2e.sh 기반 자동 복구 절차를 추가했습니다.
- peach-e2e-scenario, peach-e2e-suite: CDP 미연결 시 자동 복구 후 재확인 흐름을 반영했습니다.
- peach-e2e Chrome 자동 실행 피드백 문서를 추가했습니다.
- README에 macOS/Windows skills.sh 설치 안내를 보강했습니다.

---

## [v1.16.5] - 2026-04-19

### Added
- peach-e2e-browse: 고정 프로필 강제 게이트 패턴 reference 추가
- peach-e2e-browse: 강제 게이트 관련 피드백 문서 추가

### Changed
- peach-e2e-browse: Chrome Beta 고정 프로필 전제와 탭 선택 선행 규칙을 강제 게이트로 명문화
- peach-e2e-scenario, peach-e2e-suite: 민감 세션·고정 프로필 흐름에서 실행 전 사용자 승인 규칙 추가
- peach-e2e-setup 및 관련 references: 강제 게이트 패턴에 맞춰 실행 가이드 보강

---

## [v1.16.4] - 2026-04-19

### Changed
- peach-e2e-browse: SPA 파일 업로드 인터셉트 패턴 추가 (XHR/Fetch 가로채기 방식)
- peach-e2e-browse: SPA 제어 피드백 문서 추가 (입력 패턴 가이드)
- peach-e2e-scenario, peach-e2e-suite: SPA 인터셉트 패턴 전파

---

## [v1.16.3] - 2026-04-15

### Changed
- peach-e2e-suite: last_run/status 필드 제거 및 실행 이력 정책 변경 (스위트 피드백 문서 추가, 템플릿 수정)

---

## [v1.16.2] - 2026-04-15

### Changed
- peach-erd: mmd 수정 여부 기반 PNG/SVG 재생성 분기 로직 추가
- peach-erd: Git 후속 처리(스테이징·커밋·푸시) 단계 추가
- peach-erd: 피드백 문서(peach-erd-피드백.md) 추가

---

## [v1.16.1] - 2026-04-15

### Changed
- peach-skill-feedback: 스킬 파일 수정 금지 경계선 강화 (Must Follow 명확화)
- peach-db-query: OS별 CLI 설치 전략 분리 (macOS/Windows/Linux 분기)
- peach-release: 버전 판단 기준 개선 — 기존 스킬 개선은 patch, 신규 추가만 minor로 명확화

### Added
- peach-db-query: cli-설치-가이드 references 문서 추가
- peach-db-query: 피드백 references 문서 추가
- peach-skill-feedback: 피드백 references 문서 추가

---

## [v1.16.0] - 2026-04-14

### Added
- peach-e2e-scenario 스킬 — run + convert 통합, auto/create/run 3모드 + 자동수정 루프(최대 3회)
- peach-e2e-suite 스킬 — 통합 테스트 시나리오 md 생성/실행 (docs/e2e-suite/)
- references 신규 3개: 자동수정-판단트리, 시나리오-생성-패턴, validation-통과-패턴
- suite-템플릿.md — 통합 시나리오 md 생성 템플릿
- connect.js에 setDialogHandler 유틸 보강

### Changed
- e2e dialog 자동 닫힘 대응 — 스킬 전면 개정 + references 보강
- README, 워크플로우, wiki, e2e.sh 문서를 새 스킬 체계에 맞춰 업데이트
- native-dialog-주의사항.md 대폭 보강 (CDP race condition, daemon 잔류 대응)

### Removed
- peach-e2e-run 스킬 삭제 → peach-e2e-scenario run 모드에 흡수
- peach-e2e-convert 스킬 삭제 → peach-e2e-scenario create 모드에 흡수

---

## [v1.15.3] - 2026-04-14

### Added
- peach-e2e-browse/references/native-dialog-주의사항.md: CDP 상주 세션 점검 절차 공통 레퍼런스
- peach-e2e-browse/references/외부서비스-링크전환-패턴.md: load+지연+fallback 패턴 레퍼런스
- peach-e2e-browse/references/탭-선택-패턴.md: --tab N vs E2E_TAB_ID 선택 기준 레퍼런스

### Changed
- peach-e2e-browse: CDP 상주 세션(agent-browser daemon)이 native dialog를 자동 dismiss하는 문제 점검 절차 추가 (규칙 14~17번)
- peach-e2e-run: native dialog 규칙, 외부 서비스 전환 fallback, E2E_TAB_ID 우선 탭 선택 섹션 추가
- peach-e2e-convert: exitCode 패턴 적용, node --check 저장 직후 문법 검증 규칙 추가
- peach-e2e-setup: 수동 dialog 검증 전 daemon 점검 주의사항 추가
- AGENTS.md: qmd --index 분리 운영 패턴 적용
- docs: skills.sh 설치 안내 간결화, 플러그인 네임스페이스 중복 표시 동작 문서화

---

## [v1.15.2] - 2026-04-13

### Added
- peach-skill-feedback 스킬 신규 추가 (스킬 사용 문제점과 개선 노하우 문서화)

### Changed
- peach-db-query: PHP 프로젝트 conf.php 탐지와 Windows Docker fallback 가이드 추가
- peach-e2e-browse: 검증 시나리오 문서와 Flutter·agent-browser 레퍼런스 보강

## [v1.15.1] - 2026-04-13

### Changed
- README, CLAUDE.md, 배포구조 문서: --skill '*' 제거 및 내부 전용 스킬 배포 제외 메커니즘 문서화

### Fixed
- peach-release: SKILL.md에 metadata.internal: true 추가로 skills.sh 배포 시 자동 제외

## [v1.15.0] - 2026-04-13

### Added
- peach-markitdown 스킬 신규 추가 (문서/HWPX/PDF → Markdown 변환)
- peach-skill-feedback 스킬 신규 추가 (스킬 피드백 수집·관리)
- docs/wiki/ 초기화 (WIKI-AGENTS, skill-architecture, project-overview 등)
- peach-e2e-browse references: Flutter 패턴, 브라우저 명령어, 목 데이터 문서 추가

### Changed
- peach-team-analyze: Codex 교차검증 개선 + TODO- 피드백 관리 워크플로우 추가
- peach-e2e-browse: Flutter/SPA/세션끊김 대응 + 토큰 최적화 규칙 추가
- peach-e2e-browse: 검증시나리오 및 피드백 문서 대폭 보강
- peach-release: 릴리스 계획을 한 번에 제시하도록 워크플로우 개선
- AGENTS.md: Semver 기준 핵심 스킬(team/gen-*) 중심으로 세분화
- README.md: 누락 스킬 추가 및 스킬피드백 섹션 이동

### Removed
- wiki-code 스킬 제거

### Fixed
- peach-e2e-run/convert: 세션 끊김 복구 로직 + Flutter 비대상 안내 추가

---

## [v1.14.2] - 2026-04-12

### Changed
- architect/reviewer(team-3a) 모델 sonnet → opus 변경 (설계·판정 역할 품질 강화)
- Ralph Loop 5~7회 구간에 codex:codex-rescue 진단 투입 (peach-team, peach-team-refactor, peach-team-3a 공통)
- team-3a REJECTED 2회 연속 시 즉시 Codex 투입 조건 추가
- team-analyze Codex 교차검증: adversarial-review → codex-rescue 인라인 방식 전환
- team-analyze model override 옵션 추가 + critic/Codex 순서 정의 + 피드백 루프 종료 조건
- AGENTS.md 축소 (202→151줄) — Ralph Loop 상세 표 제거, Source of Truth를 각 SKILL.md로 이관
- 문서 설치 정책과 배포 가이드 정리

---

## [v1.14.1] - 2026-04-11

### Added
- peach-db-query 스킬 신규 추가 (개발 DB SELECT 조회 전문, 3단계 Tier 안전 규칙)
- peach-db-query references/query-patterns.md (12섹션 55개+ 고급 쿼리 패턴)
- peach-setup-harness references/06-db-query.md (§6 DB조회 선택 섹션 소스)

### Changed
- peach-setup-harness SKILL.md에 §6 DB조회 섹션 감지·주입 로직 추가

## [v1.14.0] - 2026-04-09

### Added
- peach-team-3a 신규 스킬 추가 (Architect/Builder/Reviewer 3-에이전트 구조)
- wiki-code 스킬에 qmd guidance 추가

### Changed
- peach-team, peach-team-refactor QA 에이전트에 3단계 판정 체계 도입 (APPROVED/CONDITIONAL/REJECTED)
- peach-team-3a 문서 검증 기준 보강 (architect/builder/reviewer-agent 상세화)
- peach-team backend-dev, store-dev, ui-dev 에이전트 검증 기준 보강
- peach-team-refactor backend/frontend 리팩토링 에이전트 검증 기준 보강
- AGENTS.md, README.md, 아키텍처 문서 업데이트

---

## [v1.13.2] - 2026-04-07

### Fixed
- peach-release: git log main..develop 대신 Release 커밋 해시 기준으로 신규 커밋 추출하도록 수정
- peach-release: PR 중복 생성 방어 (기존 열린 PR 재사용)
- peach-release: GitHub Release 중복 생성 방어 (존재 시 건너뜀)
- peach-release: CHANGELOG 분류 기준에 docs: prefix → Changed 섹션 명시 추가
- peach-e2e-browse: macOS Chrome Beta 실행 옵션 인용부호 추가

---

## [v1.13.1] - 2026-04-07

### Fixed
- peach-e2e-browse: Chrome Beta 직접 실행 시 --disable-extensions 누락 수정 (macOS)
- peach-e2e-browse: 옵션 따옴표 방식 및 줄바꿈 정렬을 e2e.sh 기준으로 통일
- peach-e2e-browse: CDP 직접 실행 가이드 및 프로필 경로 고정 규칙 문서화

---

## [v1.13.0] - 2026-04-07

### Added
- 신규 peach-setup-project 스킬: 프로젝트 모듈 구조 + _common 기본 구성 세팅 (초기 1회)
- Bounded Autonomy에 May Suggest 계층 신설: AI가 구조 제안 → 사용자 확인 후 적용
- gen-backend/store/ui/ui-proto 4개 스킬에 May Suggest 적용
- peach-team 오케스트레이터에 구조 제안(May Suggest) 단계 추가
- 워크플로우 다이어그램에 setup-harness 추가 + 순서 이유 섹션 추가
- 스킬 커스터마이징 가이드 문서 신규 작성 (docs/07)
- README.md에 누락 스킬 추가 (setup-project, team-analyze, DB도구) + 스킬 유형 분류

### Changed
- AGENTS.md 300줄→150줄 정리: 대상 프로젝트 규칙 분리, 워크플로우 포인터 추가, 스킬 목록 제거
- setup-project AI 추천 분석 근거 보강 (스키마 내용 참조 + 증거 불충분 시 폴백)
- 에이전트 정의 SOT를 references/*-agent.md로 통일
- peach-team 서브에이전트 references 경로 역할별 분리 주입
- 워크플로우 mermaid 도형 줄바꿈 호환성 수정, SDD 가이드 다이어그램 통합

### Fixed
- 스킬 예시에서 내부 프로젝트명 제거 (익명화)
- 스킬명 오류 수정 (peach-agent-team → peach-team)
- NuxtUI 버전 불일치 수정 (ui-dev-agent v3 → v4)
- 워크플로우 중규모/대규모 요약에 setup-project 누락 추가

---

## [v1.12.0] - 2026-04-05

### Changed
- commands/ 폴더 제거, skills/ 단일 체계로 통일 (skills.sh + 플러그인 양쪽 지원)
- peach-release 스킬 UX 단순화: AI가 버전 결정, 사용자는 진행 여부만 답변
- 배포구조 문서에 슬래시 커맨드 정책 및 user-invocable 검증 결과 추가

### Removed
- commands/*.md 14개 파일 (db-erd, db-extract-schema, db-migrate, e2e-browse, e2e-convert, e2e-run, e2e-setup, gen-feature-docs, gen-spec, help, qa-gate, team-analyze, team-refactor, team)

---

## [v1.11.1] - 2026-04-04

### Fixed
- 플러그인 설치 명령어 오타 수정: peach-harness-plugin → peach (CLAUDE.md, README.md, docs/04-배포구조.md)

---

## [v1.11.0] - 2026-04-04

### Added
- commands/ 디렉터리에 단축 커맨드 7개 추가 (gen-feature-docs, gen-spec, help, qa-gate, team-analyze, team-refactor, team)
- peach-e2e-browse: Windows 크로스플랫폼 지원 추가

### Changed
- 스킬명 단순화: peach-agent-team → peach-team, peach-agent-team-refactor → peach-team-refactor, peach-agent-team-analyze → peach-team-analyze
- peach-e2e-setup: e2e.sh, selector.js, connect.js, 파일목록.js 크로스플랫폼 개선
- peach-release: AI 권장 버전 판단 및 불일치 시 이유 질문 기능 추가
- AGENTS.md 구조 개선
- commands/db-schema.md → db-extract-schema.md 이름 변경

### Fixed
- peach-e2e-browse: selector NEW_TAB 버그 수정
- peach-e2e-browse: gmail 시나리오 개선

---

## [v1.10.1] - 2026-04-04

### Fixed
- E2E 라이트 모드 강제 적용을 페이지 load 이벤트로 변경 (신규 탭 초기화 시 evaluate 실패 방지)

---

## [v1.10.0] - 2026-04-04

### Added
- peach-think-team: 범용 에이전트 팀 오케스트레이터 스킬 추가 (조사·분석·검토·결과도출, tmux/Codex 자동 연동)
- peach-e2e-browse: E2E 브라우저 자동화 스킬 추가
- peach-e2e-convert: Playwright 코드 변환 스킬 추가
- peach-e2e-run: E2E 시나리오 실행 스킬 추가
- peach-e2e-setup: E2E 환경 설정 스킬 추가
- peach-db-migrate: dbmate 마이그레이션 관리 스킬 추가
- peach-db-extract-schema: DB 스키마 추출 스킬 추가
- peach-erd: Mermaid ERD 생성/수정/저장 스킬 추가
- commands/: e2e 4개, db 3개 네임스페이스 커맨드 추가

### Changed
- peach-agent-team: 에이전트 정의 파일을 skills/references/ 하위로 이전
- peach-gen-backend, peach-gen-ui, peach-gen-store 등 기존 스킬 references 대폭 보강

### Removed
- docs/07-에이전트팀-실전경험-E2E이식.md (peach-think-team 스킬로 이식 완료)
- peach-handoff, peach-planning-gate 스킬 제거

### Fixed
- peach-gen-prd → peach-gen-spec 스킬명 변경
- peach-ask → peach-help 스킬명 변경

---

## [v1.9.3] - 2026-04-03

### Changed
- peach-gen-db: PK 네이밍 규칙 및 테이블 성격별 공통 컬럼 적용 기준 추가
- peach-gen-db: is_use 조건부 적용 규칙 명시 (status 중복 금지 포함)
- peach-gen-db: 상태/코드 타입 선택 가이드 및 JSONB 활용 패턴 추가
- peach-gen-db: 참조 컬럼 코멘트 규칙 추가 ([참조테이블]참조,FK없음 형식)
- peach-gen-db: 워크플로우에 플로우 검증 단계 추가

---

## [v1.9.2] - 2026-03-22

### Fixed
- `peach-gen-feature-docs`: Context Pack 파일명 형식을 `{기능명}-{주제}.md` 패턴으로 명확히 정의 (예: `결제연동-개요.md`, `결제연동-TDD-가이드.md`)

---

## [v1.9.1] - 2026-03-19

### Changed
- `AGENTS.md` 및 setup 스킬 references에 주석 원칙 추가 (비즈니스 로직·매직넘버·상태 전이·환경 제한 조건)
- `peach-release` 스킬 개선: 단일 승인 일괄 실행 + 사용자 버전 선택 방식으로 변경
- `peach-agent-team` Bounded Autonomy 분석 단계 강화

### Removed
- `agents/` 디렉토리 제거 — 에이전트 정의를 `skills/*/references/`로 통합

---

## [v1.9.0] - 2026-03-19

### Changed
- `peach-agent-team` / `peach-agent-team-refactor`: 에이전트 정의를 `agents/` 디렉토리에서 `skills/*/references/*-agent.md`로 이전 — 스킬별 단일 Source of Truth 확립
- `peach-agent-team` / `peach-agent-team-refactor`: Bounded Autonomy 분석 단계 강화 — 가이드 코드 참조 후 도메인 분석 절차 명시
- `AGENTS.md`: 서브에이전트 위치 및 역할 분리 정책 업데이트

### Removed
- `agents/` 디렉토리 및 하위 에이전트 파일 8개 제거 (`backend-dev.md`, `backend-qa.md`, `frontend-qa.md`, `refactor-backend.md`, `refactor-frontend.md`, `store-dev.md`, `ui-dev.md`)

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
