# claude-precommit-gate.ps1
# Claude Code의 PreToolUse(Bash) 훅에서 호출되는 헬퍼 (Windows 수동 호출용).
#
# 정식 경로는 .claude/settings.json이 bash hooks/claude-precommit-gate.sh를 호출하는 것이다.
# 이 .ps1은 디버깅·수동 검증용으로 유지한다.
#
# 입력: stdin JSON 페이로드 (Claude Code가 PreToolUse 훅에 전달하는 형식)
#   { "tool_input": { "command": "git commit ..." } }

$ErrorActionPreference = 'Continue'

# stdin이 비어 있으면 (직접 호출) 즉시 통과
if ([Console]::IsInputRedirected -eq $false) { exit 0 }

$payload = [Console]::In.ReadToEnd()

$command = $null
try {
    $obj = $payload | ConvertFrom-Json
    $command = $obj.tool_input.command
} catch {
    $command = $payload
}

if (-not $command) { exit 0 }
if ($command -notmatch 'git\s+commit') { exit 0 }

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { exit 0 }

$gate = Join-Path $repoRoot 'hooks/pre-commit-secrets.sh'
if (-not (Test-Path $gate)) { exit 0 }

& bash $gate
if ($LASTEXITCODE -ne 0) { exit 2 }
exit 0
