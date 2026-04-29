---
name: peach-release
description: |
  peach-harness 버전 업데이트 → CHANGELOG.md 자동 생성 → develop 커밋/푸시 → main PR 생성 → PR 머지 → GitHub Release 생성까지 일괄 처리하는 릴리스 스킬.
  변경 내용 분석 → CHANGELOG 초안 + 실행 계획을 한 번에 제시 → 대화로 보완 → 승인 1회 후 일괄 실행.
  "릴리스", "버전 업", "release", "main 머지", "배포 준비" 키워드로 트리거.
  peach-harness 저장소에서만 사용한다.
metadata:
  internal: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# peach-release — 릴리스 일괄 처리

peach-harness 저장소의 릴리스를 한 번에 처리한다.
두 버전 파일 동기화 → CHANGELOG.md 업데이트 → develop 커밋/푸시 → main PR 생성 → 머지 → GitHub Release 생성까지 자동화한다.

## 전제조건

- **peach-harness 저장소 루트**에서 실행
- `develop` 브랜치에 체크아웃된 상태
- `gh` CLI 인증 완료

---

## ⛔ 0단계: 민감 정보 사전 차단 (모든 단계의 최상위 게이트)

> **peach-harness는 PUBLIC GitHub 저장소다.**
> 한 번 푸시하면 BFG로 history를 재작성해도 fork·archive·검색 캐시에 영구 잔존한다.
> 릴리스 직전이 마지막 방어선이므로 **반드시 통과시킨다**.
> 1~5단계 어디서도 이 게이트를 건너뛰지 않는다. 상태 확인보다 먼저 실행한다.

> **방어선 구조**:
> - **1차 방어선**: `hooks/pre-commit-secrets.sh` — 커밋 시점에 staged diff 자동 차단 (`./hooks/install.sh`로 활성화)
> - **2차 방어선 (이 단계)**: 릴리스 직전 누적 변경(직전 Release ~ HEAD) 전체 재검사 + AI diff 휴리스틱 검토
> - hook이 1차에서 잡지 못한 한글·고유명사·코드네임은 이 단계에서 사람·AI가 직접 훑어 차단

### 차단 대상

| 카테고리 | 탐지 기준 | 대체 |
|---------|---------|-----|
| 내부 도메인 | 사내·고객사 실 도메인 (허용 화이트리스트 외 모든 `.co.kr/.com/.net/.io/.org`) | `*.example.com`, `*.example.co.kr` |
| DB 비밀번호 | `password=`, `passwd=`, `pwd=`, 특수문자 조합 시크릿 패턴 | `{DB_PASSWORD}` |
| API 키/토큰 | `AKIA[A-Z0-9]{16}`, `ghp_*`, `sk-*`, `Bearer [영숫자20+]` | `{API_KEY}`, `{TOKEN}` |
| 사업자번호 | `\d{3}-\d{2}-\d{5}` | `{BIZ_NUMBER}` |
| 개인 절대경로 | `/Users/<id>/...`, `/home/<id>/...`, `C:\\Users\\<id>\\...` | 상대 경로(`~/source/...` 등) |
| 사내 프로젝트 코드네임 | 짧은 영문 단어가 디렉토리·모듈명으로 등장 (자동 탐지 어려움 → AI 판단) | `{PROJECT}`, `my-project` |
| 사내 업무 도메인 한글 어휘 | 일반 사전에 없는 한글 합성어, 특정 업종 전문 용어 (자동 탐지 어려움 → AI 판단) | `{기능명}`, 일반 워크플로우 단어 |
| 사내 PK/식별 필드명 | 사내 명칭이 묻은 컬럼명·식별자 (자동 탐지 어려움 → AI 판단) | `{PK_FIELD}`, `id`, `pk` |
| 한글 회사명·앱명·서비스명 | 한글 고유명사 (`XX컴퍼니`, `XX솔루션`, `XX헬스` 등) | `{COMPANY_NAME}`, `{APP_NAME}` |

> 본 표에는 실제 사내 도메인·비밀번호 예시를 적지 않는다. 적는 순간 이 스킬 자체가 민감 정보 출처가 된다.

> **자동 탐지 한계**: 한글·고유명사·짧은 영문 코드네임은 정규식으로 잡히지 않는다.
> 자동 검사로 0건이 나와도 AI는 변경 diff를 직접 훑으며 위 5번 이하 카테고리 신호를 점검한다.
> 신호가 보이는데 사용자 확인이 어려우면 **보수적으로 차단**하고 릴리스를 멈춘다.

### 자동 검사 명령

릴리스에 포함될 모든 변경(직전 Release 커밋 ~ HEAD)에 대해 검사한다.

```bash
CURRENT_VER=$(grep -m1 '"version"' .claude-plugin/plugin.json | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
RELEASE_COMMIT=$(git log --oneline --all | grep "Release v${CURRENT_VER}" | head -1 | awk '{print $1}')

# 민감 도메인 검사 (허용 도메인 화이트리스트 외 모두 탐지)
git diff ${RELEASE_COMMIT}..HEAD -- skills/ docs/ 'AGENTS.md' 'CLAUDE.md' 'README.md' \
  | grep -E "^\+" \
  | grep -vE "^\+\+\+" \
  | grep -iE "[a-z0-9-]+\.(co\.kr|com|net|io|org)" \
  | grep -vE "example\.com|example\.co\.kr|github\.com|githubusercontent|google\.com|figma\.com|npmjs|playwright\.dev|anthropic|claude\.ai|nuxt|tailwindcss|kakao|naver|daum|w3\.org|semver\.org|keepachangelog\.com|spec\.openapis|jsonschema|mozilla|wikipedia"

# 비밀번호/시크릿 패턴 검사 (실제 시크릿 문자열은 패턴으로만 표현)
git diff ${RELEASE_COMMIT}..HEAD | grep -E "^\+" \
  | grep -iE "password[[:space:]]*[=:]|passwd[[:space:]]*[=:]|pwd[[:space:]]*[=:]|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|Bearer[[:space:]]+[A-Za-z0-9]{20,}"

# 사업자번호 패턴
git diff ${RELEASE_COMMIT}..HEAD | grep -E "^\+" | grep -E "[0-9]{3}-[0-9]{2}-[0-9]{5}"

# 개인 절대경로
git diff ${RELEASE_COMMIT}..HEAD | grep -E "^\+" | grep -E "/Users/[a-zA-Z0-9._-]+/|/home/[a-zA-Z0-9._-]+/|C:\\\\Users\\\\[a-zA-Z0-9._-]+\\\\"
```

> **검사 명령은 패턴(정규식)으로만 작성한다.** 실제 비밀번호 리터럴을 grep 식에 적으면 본 스킬이 시크릿 단서를 보유하게 된다. 화이트리스트 추가가 필요하면 패턴(정규식)으로 추가하고 실 도메인을 직접 적지 않는다.

### 결과 처리

- **탐지 결과 0건 + AI diff 검토 통과**: 1단계로 진행한다.
- **탐지 결과 ≥ 1건 또는 AI 검토에서 의심 항목 발견**:
  1. 탐지된 라인·의심 항목을 사용자에게 보여준다 (파일·라인·내용).
  2. 릴리스를 **즉시 중단**한다.
  3. 사용자에게 안내: "민감 정보를 플레이스홀더로 치환 후 별도 커밋한 뒤 다시 릴리스하세요."
  4. 사용자가 "오탐이다, 진행"이라고 명시적으로 지시할 때만 진행하되, 항목별로 오탐 사유를 한 줄씩 받아 응답에 기록한다.

> **이 단계는 건너뛸 수 없다.** 사용자가 "검사 생략"을 요구해도 거부한다.
> PUBLIC 저장소에 한 번 노출된 시크릿은 즉시 로테이션 비용이 발생하기 때문이다.

---

## Workflow

### 1단계: 상태 확인

```bash
git status && git branch && git log --oneline -5
```

- develop 브랜치인지 확인한다. 아니면 중단하고 사용자에게 알린다.
- 미스테이지 변경사항이 있으면 사용자에게 보여주고 계속할지 확인한다.

### 2단계: 분석 → 계획 한 번에 제시

#### 2-1. 현재 버전 확인 (2중 교차 검증)

```bash
grep '"version"' .claude-plugin/marketplace.json
grep '"version"' .claude-plugin/plugin.json
```

두 값이 일치해야 정상이다. 불일치 시 **중단하고 사용자에게 알린다**.

#### 2-2. 신규 커밋 추출 (Release 커밋 기준)

`git log main..develop`은 main이 뒤처진 경우 이미 릴리스된 커밋까지 포함하므로 **사용 금지**.
대신 `Release v{현재버전}` 커밋 이후 신규 커밋만 추출한다.

```bash
CURRENT_VER=$(grep -m1 '"version"' .claude-plugin/plugin.json | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
RELEASE_COMMIT=$(git log --oneline --all | grep "Release v${CURRENT_VER}" | head -1 | awk '{print $1}')
git log ${RELEASE_COMMIT}..HEAD --oneline
git diff ${RELEASE_COMMIT}..HEAD --stat
```

> **핵심 원칙**: 분석 대상은 `Release v{현재버전}` 커밋 이후 신규 커밋만이다.
> `Release v{현재버전}` 커밋 자체는 분석에서 제외한다.

> 신규 커밋이 0개이면 "릴리스할 변경사항이 없습니다"를 출력하고 중단한다.

#### 2-3. 분석 + 계획 통합 출력

AI는 커밋을 분석하여 버전 타입을 결정하고, CHANGELOG 초안과 실행 계획을 **한 번에** 출력한다.

**버전 판단 기준** — 핵심: **"핵심 기능 영향도 + 호환성"**으로 구분한다.

신규 파일이나 신규 스킬이 있다는 이유만으로 minor를 선택하지 않는다.
사용자 관점에서 하네스의 핵심 워크플로우가 확장됐는지, 아니면 보조 도구가 추가됐는지 먼저 판단한다.

핵심 스킬:
- `peach-team`, `peach-team-*`
- `peach-gen-backend`, `peach-gen-db`, `peach-gen-store`, `peach-gen-ui`, `peach-gen-ui-proto`, `peach-gen-spec`

보조/유틸 스킬:
- 문서화, 분석, 변환, 조회, 보조 생성, 편의 도구 성격의 스킬
- 예: `peach-gen-diagram`, `peach-markitdown`, `peach-help`, `peach-skill-feedback`, DB 조회/추출 보조 스킬

| 변경 유형 | 버전 | 예시 |
|----------|------|------|
| 문서 수정, 오타, 버그 수정 | **patch** | SKILL.md 오류 수정, 참조 경로 수정 |
| 기존 스킬 개선, references 추가/재구성, 워크플로우 보완 | **patch** | OS별 분기 추가, 경계선 강화, 가이드 문서 추가 |
| 보조/유틸 스킬 추가 | **patch** | 다이어그램 생성, 문서 변환, 도움말, 조회 보조 스킬 추가 |
| 핵심 스킬 추가/개선, 에이전트 신규 역할 추가 | **minor** | 새 핵심 `gen-*` 스킬, 새 `team-*` 스킬, 에이전트 협업 로직 변경 |
| 하위호환 파괴, 구조 변경 | **major** | 배포 구조 변경, 스킬 인터페이스 변경 |

판단이 애매하면 patch를 우선한다. minor는 사용자가 새 핵심 개발 워크플로우를 사용할 수 있게 된 경우에만 선택한다.

```
🚀 Release v{새버전} 계획
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
버전 검증:
  plugin.json      : v{현재버전}
  marketplace.json : v{현재버전}  ← 일치 ✅

커밋 ({N}개):
  {커밋 해시} {커밋 메시지}
  ...

버전: {현재버전} → {새버전} ({patch/minor/major})
이유: {판단 근거 한 줄}

📝 CHANGELOG.md 추가 내용:
## [v{새버전}] - {YYYY-MM-DD}

### Added
- ...

### Changed
- ...

### Removed
- ...

### Fixed
- ...

📦 실행 순서:
  1. marketplace.json / plugin.json 버전 업데이트
  2. CHANGELOG.md 맨 위에 블록 추가
  3. git commit -m "Release v{새버전}"
  4. git push origin develop
  5. gh pr create --base main --head develop --title "Release v{새버전}"
  6. gh pr merge {PR번호} --merge --delete-branch=false
  7. gh release create v{새버전} --target main
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
진행할까요? 수정이 필요하면 말씀해 주세요.
```

**대화 보완**: 사용자가 버전 변경·CHANGELOG 수정·항목 추가 등을 요청하면 해당 부분만 수정하여 위 계획을 다시 출력한다. 승인("진행")이 올 때까지 반복한다.

사용자가 **진행**을 승인하면 3단계를 순서대로 실행한다. **취소**하면 중단한다.

### 3단계: 일괄 실행

승인 후 아래 작업을 순서대로 실행한다. 각 단계 완료 시 진행 상황을 출력한다.

#### 4-1. 두 버전 파일 동시 업데이트

반드시 두 파일을 동시에 같은 버전으로 업데이트한다. 불일치 시 auto update가 실패한다.

- `.claude-plugin/marketplace.json` → `plugins[0].version`
- `.claude-plugin/plugin.json` → `version`

#### 4-2. CHANGELOG.md 업데이트

3단계에서 작성한 버전 블록을 `CHANGELOG.md` **맨 위에** 추가한다.

- 해당 섹션이 없으면 생략한다 (빈 섹션 작성 금지).
- 각 항목은 한 줄 한국어로 간결하게 작성한다.
- `CHANGELOG.md`가 없으면 신규 생성한다. 파일 상단에 아래 헤더를 포함한다:

```markdown
# Changelog

> [keep-a-changelog](https://keepachangelog.com) 포맷을 따릅니다.
> 버전은 [Semantic Versioning](https://semver.org)을 따릅니다.

```

CHANGELOG.md 포맷 (keep-a-changelog 표준):

```markdown
## [v{버전}] - {YYYY-MM-DD}

### Added
- 새로 추가된 스킬, 기능, 파일

### Changed
- 기존 기능 개선, 워크플로우 변경, 구조 개편

### Removed
- 제거된 스킬, 파일, 기능

### Fixed
- 버그 수정, 오타 수정
```

분류 기준:

| 커밋 prefix / 파일 변화 | 섹션 |
|----------------------|------|
| `feat:`, 새 SKILL.md 추가 | Added |
| `refactor:`, `docs:`, 기존 SKILL.md 수정, references 재구성 | Changed |
| 파일 삭제, 이전 | Removed |
| `fix:`, 오타 수정 | Fixed |

#### 4-3. 커밋

```bash
git add .claude-plugin/marketplace.json .claude-plugin/plugin.json CHANGELOG.md
git commit -m "Release v{버전}"
```

#### 4-4. develop 푸시

```bash
git push origin develop
```

#### 4-5. main PR 생성

실행 전 기존 PR 여부를 확인한다. 이미 열린 PR이 있으면 생성을 건너뛰고 해당 번호를 사용한다.

```bash
PR_NUM=$(gh pr list --base main --head develop --state open --json number --jq '.[0].number')
if [ -z "$PR_NUM" ]; then
  gh pr create \
    --base main \
    --head develop \
    --title "Release v{버전}" \
    --body "..."
  PR_NUM=$(gh pr list --base main --head develop --state open --json number --jq '.[0].number')
fi
```

PR body는 CHANGELOG.md에 방금 작성한 버전 블록 내용을 그대로 사용한다.

```
## Release v{버전}

### 변경 사항
{CHANGELOG.md 해당 버전 블록의 내용}

### 버전
- {이전 버전} → {새 버전}
- 변경 유형: {patch/minor/major}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

#### 4-6. PR 머지

```bash
gh pr merge {PR_NUM} --merge --delete-branch=false
```

> `--delete-branch=false`: develop 브랜치는 삭제하지 않는다.

#### 4-7. GitHub Release 생성

실행 전 동일 버전 Release가 이미 존재하는지 확인한다. 존재하면 생성을 건너뛴다.

```bash
if ! gh release view v{버전} > /dev/null 2>&1; then
  gh release create v{버전} \
    --title "v{버전}" \
    --notes "..." \
    --target main
else
  echo "ℹ️ Release v{버전} 이미 존재 — 건너뜀"
fi
```

릴리즈 노트는 CHANGELOG.md 해당 버전 블록을 그대로 사용한다.

### 5단계: 완료 보고

```
✅ Release v{버전} 완료
- develop 커밋: {커밋 해시}
- PR: {PR URL}
- main 머지: 완료
- GitHub Release: {Release URL}
```

---

## 규칙

- **develop 브랜치에서만** 버전을 업데이트한다. main 직접 작업 금지.
- 버전 타입(major/minor/patch)은 **핵심 기능 영향도 + 호환성 기준으로 AI가 분석하여 결정**한다.
- 신규 스킬 추가라도 보조/유틸 성격이면 patch를 우선한다. minor는 핵심 개발 워크플로우 또는 에이전트 협업 능력이 확장된 경우에만 사용한다.
- 분석 → CHANGELOG 초안 → 실행 계획을 **한 번에** 출력한다. 분석과 계획을 별도로 나눠 묻지 않는다.
- 사용자가 수정을 요청하면 해당 부분만 고쳐 계획을 다시 출력한다. 승인("진행")이 올 때까지 대화로 보완한다.
- 승인은 **1회만** 받는다. 단계별 개별 승인 금지.
- 두 버전 파일은 항상 동일한 버전으로 유지한다.
- CHANGELOG.md는 항상 최신 버전이 맨 위에 위치한다.
- PR body와 GitHub Release 노트는 CHANGELOG.md 내용을 기준으로 작성한다 (중복 작성 금지).
