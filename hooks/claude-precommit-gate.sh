#!/bin/bash
# claude-precommit-gate.sh
# Claude Code의 PreToolUse(Bash) 훅에서 호출되는 헬퍼.
#
# 입력: stdin으로 Claude Code가 JSON 페이로드 전달
#   {
#     "tool_name": "Bash",
#     "tool_input": { "command": "git commit ...", ... },
#     ...
#   }
# 동작: tool_input.command에 `git commit`이 포함되면 pre-commit-secrets.sh를 실행.
#       시크릿이 탐지되면 exit 2로 Claude 도구 호출 자체를 차단.
#       그 외 명령에는 영향 없음(exit 0).
# 의존: jq (Git for Windows / macOS / Linux 모두 jq 패키지 설치 필요)

set -u

# stdin 소비. tty면 Claude 외부에서 직접 호출된 것으로 간주하고 통과.
if [ -t 0 ]; then
  exit 0
fi

PAYLOAD="$(cat)"

# jq 미설치 환경 안전장치 (게이트가 없는 것보다 단순 grep으로라도 검사)
if command -v jq >/dev/null 2>&1; then
  COMMAND="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
else
  # jq 없으면 페이로드 raw 텍스트에서 검사
  COMMAND="$PAYLOAD"
fi

# git commit 명령이 아니면 즉시 통과
if ! echo "$COMMAND" | grep -qE 'git[[:space:]]+commit'; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

GATE="$REPO_ROOT/hooks/pre-commit-secrets.sh"
if [ ! -f "$GATE" ]; then
  exit 0
fi

# 게이트 실행. 실패(=시크릿 탐지)면 exit 2로 Claude 도구 호출 차단
bash "$GATE" || exit 2
exit 0
