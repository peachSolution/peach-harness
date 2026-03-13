#!/bin/bash
# pre-commit-gate.sh
# Backend/Frontend 품질 게이트 — 실패 시 커밋 차단
# 설치: cp hooks/pre-commit-gate.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

FAILED=0

# Backend 검증 (api/ 존재 시)
if [ -d "api" ]; then
  echo "=== Backend 품질 검증 ==="

  echo "[1/3] bun test..."
  if ! bun test 2>&1; then
    echo "❌ Backend 테스트 실패"
    FAILED=1
  fi

  echo "[2/3] bun run lint:fixed..."
  if ! bun run lint:fixed 2>&1; then
    echo "❌ Backend 린트 실패"
    FAILED=1
  fi

  echo "[3/3] bun run build..."
  if ! bun run build 2>&1; then
    echo "❌ Backend 빌드 실패"
    FAILED=1
  fi
fi

# Frontend 검증 (front/ 존재 시)
if [ -d "front" ]; then
  echo "=== Frontend 품질 검증 ==="

  echo "[1/3] npx vue-tsc --noEmit..."
  if ! (cd front && npx vue-tsc --noEmit) 2>&1; then
    echo "❌ Frontend 타입 체크 실패"
    FAILED=1
  fi

  echo "[2/3] bun run lint:fix..."
  if ! (cd front && bun run lint:fix) 2>&1; then
    echo "❌ Frontend 린트 실패"
    FAILED=1
  fi

  echo "[3/3] bun run build..."
  if ! (cd front && bun run build) 2>&1; then
    echo "❌ Frontend 빌드 실패"
    FAILED=1
  fi
fi

# api/와 front/ 모두 없으면 스킵
if [ ! -d "api" ] && [ ! -d "front" ]; then
  echo "⏭️ api/, front/ 디렉토리 없음 — 품질 게이트 스킵"
  exit 0
fi

if [ $FAILED -ne 0 ]; then
  echo ""
  echo "🚫 품질 게이트 실패 — 커밋이 차단되었습니다."
  echo "위 오류를 수정한 후 다시 커밋하세요."
  exit 1
fi

echo ""
echo "✅ 품질 게이트 통과"
exit 0
