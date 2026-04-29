#!/bin/bash
# pre-commit-secrets.sh
# peach-harness PUBLIC 저장소 민감 정보 차단 게이트 (1차 방어선)
#
# 검사 대상: staged 변경(`git diff --cached`)의 추가 라인
# 차단 항목: 사내 도메인 / 비밀번호·토큰 / 사업자번호 / 개인 절대경로
#
# 설치: hooks/install.sh 실행 (또는 cp hooks/pre-commit-secrets.sh .git/hooks/pre-commit && chmod +x)
#
# 우회: 정말 필요하면 git commit --no-verify (지양)

set -u

RED='\033[0;31m'
YEL='\033[0;33m'
GRN='\033[0;32m'
NC='\033[0m'

DIFF=$(git diff --cached --no-color -U0 -- skills/ docs/ agents/ hooks/ templates/ '*.md' '*.json' '*.sh' 2>/dev/null || true)

if [ -z "$DIFF" ]; then
  exit 0
fi

ADDED=$(echo "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+')

FAILED=0
report() {
  local label="$1"
  local hits="$2"
  if [ -n "$hits" ]; then
    echo -e "${RED}🚫 [$label] 차단${NC}"
    echo "$hits" | sed 's/^/   /'
    echo ""
    FAILED=1
  fi
}

# 1) 내부 도메인 — 화이트리스트 외 모든 .co.kr/.com/.net/.io/.org
DOMAIN_HITS=$(echo "$ADDED" \
  | grep -iE '[a-z0-9-]+\.(co\.kr|com|net|io|org)' \
  | grep -vE 'example\.com|example\.co\.kr|github\.com|githubusercontent|google\.com|figma\.com|npmjs|playwright\.dev|anthropic|claude\.ai|nuxt|tailwindcss|kakao|naver|daum|w3\.org|semver\.org|keepachangelog\.com|spec\.openapis|jsonschema|mozilla|wikipedia|claude\.com' \
  || true)
report "내부 도메인 의심" "$DOMAIN_HITS"

# 2) 비밀번호 / API 키 / 토큰
SECRET_HITS=$(echo "$ADDED" \
  | grep -iE 'password[[:space:]]*[=:]|passwd[[:space:]]*[=:]|pwd[[:space:]]*[=:]|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|Bearer[[:space:]]+[A-Za-z0-9]{20,}' \
  | grep -vE '`password=`|`passwd=`|`pwd=`|\{DB_PASSWORD\}' \
  || true)
report "비밀번호·토큰" "$SECRET_HITS"

# 3) 사업자번호 (xxx-xx-xxxxx)
BIZ_HITS=$(echo "$ADDED" | grep -E '[0-9]{3}-[0-9]{2}-[0-9]{5}' || true)
report "사업자번호" "$BIZ_HITS"

# 4) 개인 절대경로
PATH_HITS=$(echo "$ADDED" | grep -E '/Users/[a-zA-Z0-9._-]+/|/home/[a-zA-Z0-9._-]+/|C:\\\\Users\\\\[a-zA-Z0-9._-]+\\\\' || true)
report "개인 절대경로" "$PATH_HITS"

if [ $FAILED -ne 0 ]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}커밋 차단 — peach-harness는 PUBLIC 저장소입니다.${NC}"
  echo -e "${YEL}대체값 예시: {DB_HOST} / {API_KEY} / {BIZ_NUMBER} / ~/source/{project} / *.example.com${NC}"
  echo -e "${YEL}오탐이 확실하면 화이트리스트(스크립트 1번 grep -vE)에 패턴 추가 후 재커밋하세요.${NC}"
  echo -e "${YEL}자동 탐지 한계: 한글 사내 어휘·짧은 영문 코드네임은 잡히지 않으니 직접 diff를 훑어 주세요.${NC}"
  exit 1
fi

echo -e "${GRN}✅ 시크릿 게이트 통과${NC}"
exit 0
