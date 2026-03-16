---
name: peach-release
description: |
  peach-harness 버전 업데이트 → CHANGELOG.md 자동 생성 → develop 커밋/푸시 → main PR 생성 → PR 머지 → GitHub Release 생성까지 일괄 처리하는 릴리스 스킬.
  semver 기준(patch/minor/major) 자동 판단 또는 사용자 지정.
  "릴리스", "버전 업", "release", "main 머지", "배포 준비" 키워드로 트리거.
  peach-harness 저장소에서만 사용한다.
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

## Workflow

### 1단계: 상태 확인

```bash
git status && git branch && git log --oneline -5
```

- develop 브랜치인지 확인한다. 아니면 중단하고 사용자에게 알린다.
- 미스테이지 변경사항이 있으면 사용자에게 보여주고 계속할지 확인한다.

### 2단계: 현재 버전 파악

`.claude-plugin/marketplace.json`의 `plugins[0].version`을 읽는다.

### 3단계: 버전 타입 결정

사용자가 버전 타입을 명시하지 않은 경우, `git log main..develop --oneline`과 `git diff main..develop --stat`으로 변경 내용을 분석하여 아래 기준으로 자동 판단한다.

| 변경 유형 | 버전 타입 | 판단 기준 |
|----------|---------|---------|
| 문서 수정, 오타, 버그 수정 | **patch** (x.x.+1) | SKILL.md 내용 수정, 참조 경로 수정 |
| 스킬/에이전트 추가, 기능 개선 | **minor** (x.+1.0) | 새 스킬 파일 추가, 워크플로우 변경 |
| 하위호환 파괴, 구조 변경 | **major** (+1.0.0) | 배포 구조 변경, 스킬 인터페이스 변경 |

자동 판단한 버전 타입과 새 버전 번호를 사용자에게 제시하고 확인을 받는다.
사용자가 다른 타입을 원하면 그에 따른다.

**계산 예시**: 현재 `1.7.0`에서 minor → `1.8.0`, patch → `1.7.1`, major → `2.0.0`

### 4단계: 두 버전 파일 동시 업데이트

반드시 두 파일을 동시에 같은 버전으로 업데이트한다. 불일치 시 auto update가 실패한다.

- `.claude-plugin/marketplace.json` → `plugins[0].version`
- `.claude-plugin/plugin.json` → `version`

### 5단계: CHANGELOG.md 자동 업데이트

`git log main..develop`의 커밋 메시지와 `git diff main..develop --stat`의 파일 변경 내역을 분석하여 변경 사항을 분류한 뒤 `CHANGELOG.md`에 새 버전 블록을 **맨 위에** 추가한다.

#### CHANGELOG.md 포맷 (keep-a-changelog 표준)

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

- 해당 섹션이 없으면 생략한다 (빈 섹션 작성 금지).
- 각 항목은 한 줄 한국어로 간결하게 작성한다.
- `CHANGELOG.md`가 없으면 신규 생성한다. 파일 상단에 아래 헤더를 포함한다:

```markdown
# Changelog

> [keep-a-changelog](https://keepachangelog.com) 포맷을 따릅니다.
> 버전은 [Semantic Versioning](https://semver.org)을 따릅니다.

```

#### 분류 기준

| 커밋 prefix / 파일 변화 | 섹션 |
|----------------------|------|
| `feat:`, 새 SKILL.md 추가 | Added |
| `refactor:`, 기존 SKILL.md 수정, references 재구성 | Changed |
| 파일 삭제 | Removed |
| `fix:`, 오타 수정 | Fixed |

### 6단계: 커밋 확인 후 실행

변경될 파일 목록과 커밋 메시지를 사용자에게 보여준다.

커밋 메시지 형식: `Release v{버전}`

사용자 승인 후 커밋한다.

```bash
git add .claude-plugin/marketplace.json .claude-plugin/plugin.json CHANGELOG.md
# (스테이지되지 않은 다른 변경사항이 있다면 함께 스테이징할지 사용자에게 확인)
git commit -m "Release v{버전}"
```

### 7단계: develop 푸시 확인 후 실행

```
develop → origin/develop 푸시하시겠습니까?
```

사용자 승인 후 푸시한다.

```bash
git push origin develop
```

### 8단계: main PR 생성

PR을 생성한다. base는 `main`, head는 `develop`.
PR body는 CHANGELOG.md에 방금 작성한 버전 블록 내용을 그대로 사용한다.

```bash
gh pr create \
  --base main \
  --head develop \
  --title "Release v{버전}" \
  --body "$(cat <<'EOF'
## Release v{버전}

### 변경 사항
{CHANGELOG.md 해당 버전 블록의 내용}

### 버전
- {이전 버전} → {새 버전}
- 변경 유형: {patch/minor/major}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR URL을 사용자에게 보여준다.

### 9단계: PR 머지 확인 후 실행

```
PR #{번호}를 main에 머지하시겠습니까?
```

사용자 승인 후 머지한다. `--merge` (3-way merge, --no-ff 유지)를 사용한다.

```bash
gh pr merge {PR번호} --merge --delete-branch=false
```

> `--delete-branch=false`: develop 브랜치는 삭제하지 않는다.

### 10단계: GitHub Release 생성 확인 후 실행

```
GitHub Release v{버전}을 생성하시겠습니까?
```

사용자 승인 후 태그 + 릴리즈를 생성한다.
릴리즈 노트는 CHANGELOG.md 해당 버전 블록을 그대로 사용한다.

```bash
gh release create v{버전} \
  --title "v{버전}" \
  --notes "{CHANGELOG.md 해당 버전 블록 내용}" \
  --target main
```

### 11단계: 완료 보고

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
- 각 단계(커밋/푸시/머지/릴리즈)마다 사용자 승인을 받는다. 자동으로 진행하지 않는다.
- 두 버전 파일은 항상 동일한 버전으로 유지한다.
- CHANGELOG.md는 항상 최신 버전이 맨 위에 위치한다.
- PR body와 GitHub Release 노트는 CHANGELOG.md 내용을 기준으로 작성한다 (중복 작성 금지).
- PR diff 확인: `gh pr diff {번호} --stat`으로 실제 변경 내용을 확인하고 Summary에 반영한다.
