#!/bin/bash
# install.sh
# peach-harness 로컬 git hook 설치 — pre-commit-secrets.sh를 .git/hooks/pre-commit에 심볼릭 링크
#
# 사용: ./hooks/install.sh (저장소 루트에서)
# 효과: 이 저장소에서 git commit 시 시크릿 차단 게이트가 자동 실행
# 범위: 이 저장소만. clone마다 1회 실행 필요 (husky 미사용 — Node 종속성 없음)

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

ln -sf ../../hooks/pre-commit-secrets.sh .git/hooks/pre-commit
chmod +x hooks/pre-commit-secrets.sh

echo "✅ pre-commit hook 설치 완료"
echo "   → .git/hooks/pre-commit -> ../../hooks/pre-commit-secrets.sh"
echo ""
echo "테스트: 임의 변경을 stage 후 git commit 시도 → 정상이면 '✅ 시크릿 게이트 통과' 출력"
