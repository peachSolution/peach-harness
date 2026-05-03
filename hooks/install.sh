#!/bin/bash
# install.sh
# peach-harness 로컬 git hook 설치 (macOS / Linux / Git Bash)
#
# 사용: ./hooks/install.sh (저장소 루트에서)
# 효과: 이 저장소에서 git commit 시 시크릿 차단 게이트가 자동 실행
# 범위: 이 저장소만. clone마다 1회 실행 필요 (husky 미사용 — Node 종속성 없음)
#
# Windows: hooks/install.ps1 사용

set -e

cd "$(git rev-parse --show-toplevel)"

if [ ! -f hooks/pre-commit-secrets.sh ]; then
  echo "❌ hooks/pre-commit-secrets.sh 가 없습니다. 저장소 루트에서 실행하세요."
  exit 1
fi

mkdir -p .git/hooks

if [ -e .git/hooks/pre-commit ] && [ ! -L .git/hooks/pre-commit ]; then
  echo "⚠️  기존 .git/hooks/pre-commit (실파일)이 발견되어 .bak으로 백업합니다."
  mv .git/hooks/pre-commit .git/hooks/pre-commit.bak
fi

# 심볼릭 링크 시도 → 실패 시 복사로 폴백 (Windows Git Bash 등 ln 권한 없는 환경)
if ln -sf ../../hooks/pre-commit-secrets.sh .git/hooks/pre-commit 2>/dev/null; then
  MODE="symlink"
else
  cp -f hooks/pre-commit-secrets.sh .git/hooks/pre-commit
  MODE="copy (재설치 필요 시 본 스크립트 재실행)"
fi

chmod +x hooks/pre-commit-secrets.sh .git/hooks/pre-commit 2>/dev/null || true

echo "✅ pre-commit hook 설치 완료 ($MODE)"
echo "   → .git/hooks/pre-commit"
echo ""
echo "테스트: 임의 변경을 stage 후 git commit 시도 → 정상이면 '✅ 시크릿 게이트 통과' 출력"
