# install.ps1
# peach-harness 로컬 git hook 설치 (Windows PowerShell)
#
# 사용: .\hooks\install.ps1 (저장소 루트에서)
# 효과: 이 저장소에서 git commit 시 시크릿 차단 게이트(pre-commit-secrets.sh)가 자동 실행
# 범위: 이 저장소만. clone마다 1회 실행 필요
#
# macOS / Linux: hooks/install.sh 사용
# 전제: Git for Windows 설치 (Git Bash가 .sh 훅을 자동 실행)

$ErrorActionPreference = 'Stop'

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Host "❌ git 저장소 루트를 찾을 수 없습니다." -ForegroundColor Red
    exit 1
}
Set-Location $repoRoot

$source = Join-Path $repoRoot 'hooks/pre-commit-secrets.sh'
$target = Join-Path $repoRoot '.git/hooks/pre-commit'

if (-not (Test-Path $source)) {
    Write-Host "❌ hooks/pre-commit-secrets.sh 가 없습니다." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null

# 기존 실파일 백업
if ((Test-Path $target) -and -not ((Get-Item $target).LinkType)) {
    Write-Host "⚠️  기존 .git/hooks/pre-commit 백업 → pre-commit.bak" -ForegroundColor Yellow
    Move-Item -Force $target "$target.bak"
}

# 심볼릭 링크 시도 → 권한 부족이면 복사 폴백
$mode = $null
try {
    if (Test-Path $target) { Remove-Item -Force $target }
    New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null
    $mode = 'symlink'
} catch {
    Copy-Item -Force $source $target
    $mode = 'copy (재설치 필요 시 본 스크립트 재실행)'
}

Write-Host "✅ pre-commit hook 설치 완료 ($mode)" -ForegroundColor Green
Write-Host "   → .git/hooks/pre-commit"
Write-Host ""
Write-Host "테스트: 임의 변경을 stage 후 git commit 시도 → 정상이면 '✅ 시크릿 게이트 통과' 출력"
