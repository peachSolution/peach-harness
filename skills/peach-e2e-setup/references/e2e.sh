#!/bin/bash
# e2e — E2E 테스트 통합 CLI
# 사용법: ./e2e.sh <command> [args]
#
# Commands:
#   setup               환경 체크 + 자동 설치/설정 (처음 실행 시 먼저 실행)
#   chrome              Chrome Beta CDP 모드 실행
#   list                시나리오 목록 출력
#   run [N|all|파일명]   시나리오 실행
#   record [URL]        Playwright codegen 녹화
#   status              CDP 연결 상태 확인
#   help                도움말
#
# 탭 선택:
#   사용자가 로그인한 탭을 그대로 사용.
#   selector TUI 또는 --tab N으로 탭 지정.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CDP_PORT=9222
CDP_URL="http://127.0.0.1:${CDP_PORT}"
SCENARIOS_DIR="${SCRIPT_DIR}/시나리오"
STATE_FILE="${SCRIPT_DIR}/.e2e-state.json"

# ─── OS 감지 ──────────────────────────────────────────────
case "$(uname -s)" in
  Darwin*)
    CHROME_BETA="/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta"
    PROFILE_DIR="$HOME/.chrome-beta-e2e-profile"
    PYTHON_CMD="python3"
    _chrome_installed() { [ -d "/Applications/Google Chrome Beta.app" ]; }
    _chrome_install_msg() {
      echo "📥 설치: https://www.google.com/chrome/beta/"
      echo "💡 기본 Chrome과 동시 실행 가능. E2E 전용으로 분리 사용."
    }
    ;;
  MINGW*|MSYS*)
    CHROME_BETA="/c/Program Files/Google/Chrome Beta/Application/chrome.exe"
    # Chrome은 Windows 네이티브 경로 필요 — cygpath로 변환
    PROFILE_DIR="$(cygpath -w "$HOME/.chrome-beta-e2e-profile")"
    PYTHON_CMD="python"
    _chrome_installed() { [ -f "$CHROME_BETA" ]; }
    _chrome_install_msg() {
      echo "📥 설치: https://www.google.com/chrome/beta/"
      echo "💡 기본 Chrome과 동시 실행 가능. E2E 전용으로 분리 사용."
    }
    ;;
  *)
    echo "❌ 지원하지 않는 OS: $(uname -s)" >&2
    exit 1
    ;;
esac

# 전역 npm 모듈 경로 설정 (playwright-core 전역 설치 대응)
export NODE_PATH="${NODE_PATH:+${NODE_PATH}:}$(npm root -g 2>/dev/null || echo "")"

# ─── 공통 함수 ─────────────────────────────────────────────

check_cdp() {
  curl -s "${CDP_URL}/json/version" > /dev/null 2>&1
}

require_cdp() {
  if ! check_cdp; then
    echo "❌ Chrome Beta CDP가 연결되지 않았습니다."
    echo "   실행: ./e2e.sh chrome"
    exit 1
  fi
}

# CDP /json에서 비-chrome 페이지 탭 목록 (status/--tab 공통 기준)
# 출력: JSON 배열 [{url, title}, ...]
get_page_tabs() {
  curl -s "${CDP_URL}/json" | $PYTHON_CMD -c "
import json, sys
tabs = json.load(sys.stdin)
pages = [t for t in tabs if t.get('type') == 'page' and not t.get('url', '').startswith('chrome')]
for t in pages:
    print(json.dumps({'url': t.get('url',''), 'title': t.get('title','')}, ensure_ascii=False))
" 2>/dev/null || true
}

# --tab N → CDP 조회 후 해당 탭의 targetId를 E2E_TAB_ID로 설정
resolve_tab_index() {
  local tab_index="$1"
  local result
  result=$(curl -s "${CDP_URL}/json" | $PYTHON_CMD -c "
import json, sys
tabs = json.load(sys.stdin)
pages = [t for t in tabs if t.get('type') == 'page' and not t.get('url', '').startswith('chrome')]
idx = int(sys.argv[1])
if 0 <= idx < len(pages):
    t = pages[idx]
    print(t.get('id', ''))
    print(t.get('title', '') or t.get('url', ''))
else:
    print('')
" "$tab_index" 2>/dev/null || echo "")

  local tab_id tab_title
  tab_id=$(echo "$result" | head -1)
  tab_title=$(echo "$result" | tail -1)

  if [ -z "$tab_id" ]; then
    echo "❌ ${tab_index}번 탭이 없습니다."
    echo "   ./e2e.sh status 로 탭 목록을 확인하세요."
    exit 1
  fi

  export E2E_TAB_ID="$tab_id"
  echo "🎯 ${tab_index}번 탭: ${tab_title}"
}

# 시나리오 목록 수집
collect_scenarios() {
  find "$SCENARIOS_DIR" -name "*.js" -type f 2>/dev/null | sort
}

print_scenarios() {
  local i=1
  while IFS= read -r file; do
    local rel="${file#$SCENARIOS_DIR/}"
    echo "  ${i}) ${rel}"
    i=$((i + 1))
  done <<< "$(collect_scenarios)"
}

get_scenario_by_number() {
  local num=$1
  collect_scenarios | sed -n "${num}p"
}

get_scenario_count() {
  collect_scenarios | wc -l | tr -d ' '
}

# ─── chrome: Chrome Beta CDP 실행 ──────────────────────────

cmd_chrome() {
  if check_cdp; then
    echo "✅ Chrome CDP가 이미 실행 중입니다 (포트: ${CDP_PORT})"
    curl -s "${CDP_URL}/json/version" | grep -o '"Browser"[^,]*' | head -1 || true
    return 0
  fi

  if ! _chrome_installed; then
    echo "❌ Chrome Beta가 설치되어 있지 않습니다."
    echo ""
    _chrome_install_msg
    return 1
  fi

  echo "🚀 Chrome Beta CDP 모드 실행..."
  echo "   포트: ${CDP_PORT}"
  echo "   프로파일: ${PROFILE_DIR}"
  echo "   규칙: 고정 프로필(--user-data-dir) 필수"

  # --disable-extensions: 확장 프로그램이 웹 콘텐츠에 다크모드를 강제 적용하는 문제 방지
  "$CHROME_BETA" \
    --remote-debugging-port=${CDP_PORT} \
    --remote-allow-origins=* \
    --user-data-dir="${PROFILE_DIR}" \
    --disable-extensions &

  echo "⏳ CDP 연결 대기..."
  for i in $(seq 1 20); do
    if check_cdp; then
      echo "✅ Chrome Beta CDP 연결 성공!"
      echo ""
      echo "💡 Chrome Beta 고정 프로필에서 로그인/필요한 인증을 완료한 뒤 시나리오를 실행하세요:"
      echo "   인증은 사용자가 직접 처리하고, AI는 완료된 세션을 이어받습니다."
      echo "   직접 Chrome을 실행할 때도 --user-data-dir=${PROFILE_DIR} 옵션을 생략하지 마세요."
      echo "   ./e2e.sh run"
      return 0
    fi
    sleep 0.5
  done

  echo "❌ CDP 연결 실패."
  return 1
}

# ─── status: CDP 상태 확인 ──────────────────────────────────

cmd_status() {
  if check_cdp; then
    echo "✅ Chrome CDP 연결됨 (포트: ${CDP_PORT})"
    curl -s "${CDP_URL}/json/version" | grep -o '"Browser"[^,]*' | head -1 || true
    echo ""
    echo "열린 탭:"
    curl -s "${CDP_URL}/json" | $PYTHON_CMD -c "
import json, sys
tabs = json.load(sys.stdin)
pages = [t for t in tabs if t.get('type') == 'page' and not t.get('url', '').startswith('chrome')]
for i, t in enumerate(pages):
    url = t.get('url', '')
    title = t.get('title', '') or url
    print(f'  [{i}] {title[:60]}')
    print(f'        {url[:80]}')
    if i >= 9: break
" || true
  else
    echo "❌ Chrome CDP 미연결"
    echo "   실행: ./e2e.sh chrome"
  fi
}

# ─── list: 시나리오 목록 ────────────────────────────────────

cmd_list() {
  local count
  count=$(get_scenario_count)

  if [ "$count" -eq 0 ]; then
    echo "📭 시나리오가 없습니다."
    return 0
  fi

  echo "=== 시나리오 목록 (${count}개) ==="
  echo ""
  print_scenarios
}

# ─── Node.js 실시간 한글 검색 선택기 ──────────────────────

_node_selector_run() {
  local selector="${SCRIPT_DIR}/lib/selector.js"

  if [ ! -f "$selector" ]; then
    echo "❌ selector.js 를 찾을 수 없습니다: ${selector}"
    return 1
  fi

  # selector.js 실행 — stderr: TUI 화면, stdout: "TAB_ID=id\nSCENARIO=경로"
  local output
  output=$(node "$selector" "$SCENARIOS_DIR" "$STATE_FILE" </dev/tty) || true

  if [ -z "$output" ]; then
    return 0
  fi

  # 결과 파싱
  local tab_id scenario
  tab_id=$(echo "$output"  | grep '^TAB_ID='   | head -1 | cut -d= -f2-)
  scenario=$(echo "$output" | grep '^SCENARIO=' | head -1 | cut -d= -f2-)

  if [ -z "$scenario" ]; then
    return 0
  fi

  # 탭 ID 설정
  if [ -n "$tab_id" ]; then
    export E2E_TAB_ID="$tab_id"
  fi

  local filepath="${SCENARIOS_DIR}/${scenario}"
  echo ""
  echo "▶ 실행: ${scenario}"
  echo "────────────────────────────────"
  cd "$SCRIPT_DIR" && node "$filepath"
  echo "────────────────────────────────"
}

# ─── run: 시나리오 실행 ─────────────────────────────────────

cmd_run() {
  require_cdp

  # --tab 옵션 파싱
  local tab_index=""
  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --tab)
        tab_index="$2"
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  # --tab N → CDP 조회 후 URL로 변환
  if [ -n "$tab_index" ]; then
    resolve_tab_index "$tab_index"
  fi

  local arg="${args[0]:-}"

  # 인자 없으면 시나리오 선택
  if [ -z "$arg" ]; then
    case "$(uname -s)" in
      MINGW*|MSYS*)
        # Windows: TUI 미지원 — 목록 출력 + 사용법 안내
        cmd_list
        echo ""
        echo "💡 사용법: ./e2e.sh run <번호>     예) ./e2e.sh run 1"
        echo "         ./e2e.sh run all         전체 실행"
        echo "         ./e2e.sh run 1-3         범위 실행"
        return 0
        ;;
      *)
        _node_selector_run
        return $?
        ;;
    esac
  fi

  # all: 전체 순차 실행
  if [ "$arg" = "all" ]; then
    echo "🚀 전체 시나리오 순차 실행"
    echo ""
    local i=1
    while IFS= read -r file; do
      local rel="${file#$SCENARIOS_DIR/}"
      echo "▶ [${i}] ${rel}"
      echo "────────────────────────────────"
      cd "$SCRIPT_DIR" && node "$file"
      echo "────────────────────────────────"
      echo ""
      i=$((i + 1))
    done <<< "$(collect_scenarios)"
    echo "✅ 전체 실행 완료"
    return 0
  fi

  # 숫자: N번째 시나리오
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    local file
    file=$(get_scenario_by_number "$arg")
    if [ -z "$file" ]; then
      echo "❌ ${arg}번 시나리오가 없습니다."
      return 1
    fi
    local rel="${file#$SCENARIOS_DIR/}"
    echo "▶ 실행: ${rel}"
    echo "────────────────────────────────"
    cd "$SCRIPT_DIR" && node "$file"
    echo "────────────────────────────────"
    return $?
  fi

  # 범위: N-M
  if [[ "$arg" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    local start="${BASH_REMATCH[1]}"
    local end="${BASH_REMATCH[2]}"
    echo "🚀 시나리오 ${start}~${end} 순차 실행"
    echo ""
    for i in $(seq "$start" "$end"); do
      local file
      file=$(get_scenario_by_number "$i")
      if [ -n "$file" ]; then
        local rel="${file#$SCENARIOS_DIR/}"
        echo "▶ [${i}] ${rel}"
        echo "────────────────────────────────"
        cd "$SCRIPT_DIR" && node "$file"
        echo "────────────────────────────────"
        echo ""
      fi
    done
    echo "✅ 실행 완료"
    return 0
  fi

  # 파일 경로
  local filepath="$arg"
  if [ ! -f "$filepath" ]; then
    filepath="${SCENARIOS_DIR}/${arg}"
  fi
  if [ ! -f "$filepath" ]; then
    echo "❌ 시나리오를 찾을 수 없습니다: ${arg}"
    return 1
  fi

  local rel="${filepath#$SCENARIOS_DIR/}"
  echo "▶ 실행: ${rel}"
  echo "────────────────────────────────"
  cd "$SCRIPT_DIR" && node "$filepath"
  echo "────────────────────────────────"
}

# ─── setup: 환경 체크 + 자동 설치/설정 ────────────────────────

cmd_setup() {
  echo "🔧 E2E 환경 체크"
  echo "════════════════════════════════════════"
  local all_ok=true

  # 1. Chrome Beta 설치 여부
  if _chrome_installed; then
    echo "✅ Chrome Beta 설치됨"
  else
    echo "❌ Chrome Beta 미설치"
    _chrome_install_msg
    all_ok=false
  fi

  # 2. playwright-core 전역 설치 여부
  # playwright-core: API만 포함 (~2MB). 브라우저 바이너리 없음.
  # CDP 모드에서는 Chrome Beta를 직접 사용하므로 브라우저 포함된 playwright(~50MB+) 불필요.
  if node -e "require('playwright-core')" 2>/dev/null; then
    local pw_ver
    pw_ver=$(node -e "console.log(require('playwright-core/package.json').version)" 2>/dev/null || echo '?')
    echo "✅ playwright-core 설치됨 (${pw_ver})"
  else
    echo "⚙️  playwright-core 전역 설치 중..."
    if npm install -g playwright-core; then
      echo "✅ playwright-core 설치 완료"
    else
      echo "❌ playwright-core 설치 실패"
      echo "   수동 실행: npm install -g playwright-core"
      all_ok=false
    fi
  fi

  # 3. agent-browser 전역 설치 여부 (탐색/검증/확인용 기본 도구)
  if command -v agent-browser &> /dev/null; then
    echo "✅ agent-browser 설치됨 ($(agent-browser --version 2>/dev/null || echo '버전 확인 불가'))"
  else
    echo "⚙️  agent-browser 설치 중..."
    if npm install -g agent-browser; then
      echo "✅ agent-browser 설치 완료"
    else
      echo "❌ agent-browser 설치 실패"
      echo "   수동 실행: npm install -g agent-browser"
      all_ok=false
    fi
  fi

  # 4. playwright-cli 전역 설치 여부 (시나리오 실행 + iframe fallback용)
  if command -v playwright-cli &> /dev/null; then
    echo "✅ playwright-cli 설치됨 ($(playwright-cli --version 2>/dev/null || echo '버전 확인 불가'))"
  else
    echo "⚙️  playwright-cli 설치 중..."
    if npm install -g @playwright/cli; then
      echo "✅ playwright-cli 설치 완료"
    else
      echo "❌ playwright-cli 설치 실패"
      echo "   수동 실행: npm install -g @playwright/cli"
      all_ok=false
    fi
  fi

  # 5. ~/.playwright/cli.config.json 설정 파일 존재 여부
  local CONFIG_FILE="$HOME/.playwright/cli.config.json"
  if [ -f "$CONFIG_FILE" ]; then
    echo "✅ playwright-cli 설정 파일 존재 (${CONFIG_FILE})"
  else
    echo "⚙️  playwright-cli 설정 파일 생성 중..."
    mkdir -p "$HOME/.playwright"
    cat > "$CONFIG_FILE" << 'PCONFIG'
{
  "browser": {
    "cdpEndpoint": "http://localhost:9222",
    "isolated": false
  }
}
PCONFIG
    echo "✅ 설정 파일 생성됨: ${CONFIG_FILE}"
    echo "   (cdpEndpoint: http://localhost:9222, isolated: false)"
  fi

  # 5. CDP 연결 상태
  echo "────────────────────────────────────────"
  if check_cdp; then
    echo "✅ Chrome CDP 연결됨 (포트: ${CDP_PORT})"
  else
    echo "⚠️  Chrome CDP 미연결"
    echo "   실행: ./e2e.sh chrome  →  브라우저 로그인 후 E2E 사용 가능"
    all_ok=false
  fi

  echo "════════════════════════════════════════"
  if $all_ok; then
    echo "✨ 환경 설정 완료! E2E를 시작할 수 있습니다."
    echo "   탭 확인:  ./e2e.sh status"
    echo "   탐색:     agent-browser connect 9222 && agent-browser eval \"document.title\""
    echo "   시나리오:  ./e2e.sh run"
  else
    echo "⚠️  위 항목을 해결한 후 다시 ./e2e.sh setup 을 실행하세요."
  fi
}

# ─── record: Playwright codegen 녹화 ───────────────────────

cmd_record() {
  local url="${1:-}"

  echo "🎬 Playwright 녹화 시작"
  echo ""
  echo "   새 브라우저 창이 열립니다."
  echo "   브라우저에서 조작하면 코드가 자동 생성됩니다."
  echo "   녹화 창을 닫으면 종료됩니다."
  echo ""
  echo "💡 녹화 완료 후:"
  echo "   1. 생성된 코드를 복사"
  echo "   2. Claude Code에서 /peach-e2e-scenario create 스킬에 전달"
  echo "   3. CDP 시나리오 파일로 자동 변환"
  echo ""

  cd "$SCRIPT_DIR"

  if [ -n "$url" ]; then
    npx playwright codegen --target javascript --color-scheme light "$url"
  else
    npx playwright codegen --target javascript --color-scheme light
  fi
}

# ─── help: 도움말 ──────────────────────────────────────────

cmd_help() {
  cat << 'EOF'
e2e — E2E 테스트 통합 CLI

사용법: ./e2e.sh <command> [args]

Commands:
  setup                              환경 체크 + 자동 설치/설정 (처음 실행 시 먼저 실행)
  chrome                             Chrome Beta CDP 모드 실행
  status                             CDP 연결 상태 + 열린 탭 확인
  list                               시나리오 목록 출력
  run                                한글 실시간 검색 선택 UI (탭 선택 → 시나리오 선택)
  run [--tab N] <시나리오>            시나리오 직접 실행
  run [--tab N] all                  전체 시나리오 순차 실행
  run [--tab N] <N-M>                N~M번 범위 순차 실행
  record [URL]                       Playwright codegen 녹화
  help                               이 도움말

탭 선택:
  사용자가 로그인한 탭을 그대로 사용합니다.
  --tab N   status에서 확인한 N번 탭 지정 (0부터 시작)
  미지정    selector TUI에서 탭 선택 또는 자동 탐지

워크플로우:
  0. ./e2e.sh setup                      최초 환경 구성
  1. ./e2e.sh chrome                     Chrome Beta CDP 실행
  2. 브라우저에서 로그인                  (사람이 1회)
  3. ./e2e.sh status                     탭 번호 확인
  4. ./e2e.sh run                        TUI에서 탭/시나리오 선택 실행
  또는
  4. ./e2e.sh run --tab 1 1              1번 탭에서 1번 시나리오 실행
  또는
  3. ./e2e.sh record [URL]               녹화 → /peach-e2e-scenario create로 변환

playwright-cli CDP 래퍼:
  ./e2e/pwc.sh <command>   playwright-cli --config=~/.playwright/cli.config.json 래퍼
  예: ./e2e/pwc.sh snapshot
      ./e2e/pwc.sh click e10
      ./e2e/pwc.sh eval "document.title"

Claude Code 스킬:
  /peach-e2e-browse       AI가 agent-browser로 현재 탭 탐색
  /peach-e2e-scenario     시나리오 생성/실행/자동수정
  /peach-e2e-suite        통합 테스트 시나리오 관리/실행
EOF
}

# ─── 메인 ──────────────────────────────────────────────────

COMMAND="${1:-help}"
shift 2>/dev/null || true

case "$COMMAND" in
  setup)    cmd_setup "$@" ;;
  chrome)   cmd_chrome "$@" ;;
  status)   cmd_status "$@" ;;
  list)     cmd_list "$@" ;;
  run)      cmd_run "$@" ;;
  record)   cmd_record "$@" ;;
  help|-h|--help) cmd_help ;;
  *)
    echo "❌ 알 수 없는 명령: ${COMMAND}"
    echo "   ./e2e.sh help 로 사용법을 확인하세요."
    exit 1
    ;;
esac
