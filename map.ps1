<#
.SYNOPSIS
  Tao / cap nhat ban do Graphify cho du an (vd HIS) KHONG can AI, KHONG ton token.

.DESCRIPTION
  - Tu xac dinh nhanh hien tai tach tu nhanh goc v2 hay v3 (dung -BaseV2 / -BaseV3).
    Khong ro -> DUNG, khong ghi lon ban do.
  - Lan dau (hoac -Full): graphify extract . --code-only   (tree-sitter, khong goi model)
    Cac lan sau        : graphify update .                  (chi doc lai file code da doi, khong goi model)
  - Copy graph.json / GRAPH_REPORT.md / graph.html vao graphify-out\<master2|master3>\ + ghi META.md (commit, nhanh, ngay).
  - Tao .graphifyignore mac dinh (neu chua co) va an no trong .git/info/exclude.
  - KHONG chay `graphify hook install` (sua .gitattributes cong ty) va KHONG chay `graphify label` (ton token).
  - KHONG xoa thu muc cua version con lai, KHONG dong vao ENDPOINT_MAP.md cua skill ask-map.

.EXAMPLE
  .\map.ps1 -HisPath D:\Code\HIS
  .\map.ps1 -HisPath D:\Code\HIS -Full
  .\map.ps1 -HisPath D:\Code\HIS -BaseV2 master2 -BaseV3 master3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HisPath,
    [string]$BaseV2 = 'master_2',
    [string]$BaseV3 = 'master_3',
    [switch]$Full
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Info($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Note($msg) { Write-Host "  [..]   $msg" -ForegroundColor DarkGray }
function Stop-Map($msg) { Write-Host "  [DUNG] $msg" -ForegroundColor Red; exit 1 }

# ---------- 0. Kiem tra ----------
if (-not (Get-Command graphify -ErrorAction SilentlyContinue)) {
    Stop-Map "Chua cai graphify. Chay: uv tool install graphifyy   (hoac: pip install graphifyy)"
}
if (-not (Test-Path -LiteralPath $HisPath -PathType Container)) { Stop-Map "Khong thay thu muc: $HisPath" }
$HisPath = (Resolve-Path -LiteralPath $HisPath).Path.TrimEnd('\')
$top = (& git -C $HisPath rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $top) { Stop-Map "$HisPath khong phai repo git." }
if ((Resolve-Path -LiteralPath $top).Path.TrimEnd('\') -ine $HisPath) { Stop-Map "HisPath phai la thu muc GOC cua repo ($top)." }

function Resolve-Base($name) {
    foreach ($ref in $name, "origin/$name") {
        & git -C $HisPath rev-parse --verify --quiet "$ref^{commit}" *> $null
        if ($LASTEXITCODE -eq 0) { return $ref }
    }
    Stop-Map "Khong tim thay nhanh goc '$name' (ca local lan origin/). Kiem tra lai -BaseV2 / -BaseV3."
}

# ---------- 1. Xac dinh version ----------
Write-Host ""
Write-Host "1) Xac dinh version"
$branch = (& git -C $HisPath branch --show-current).Trim()
$ref2 = Resolve-Base $BaseV2
$ref3 = Resolve-Base $BaseV3
$c2 = [int](& git -C $HisPath rev-list --count "$ref2..HEAD")
$c3 = [int](& git -C $HisPath rev-list --count "$ref3..HEAD")
Note "Nhanh: $branch | $ref2..HEAD = $c2 | $ref3..HEAD = $c3"

$ver = $null
if ($branch -ieq $BaseV2) { $ver = 'master2' }
elseif ($branch -ieq $BaseV3) { $ver = 'master3' }
else {
    $min = [Math]::Min($c2, $c3); $max = [Math]::Max($c2, $c3)
    if ($c2 -eq $c3 -or ($min -gt 0 -and $min * 2 -gt $max)) {
        Stop-Map "Khong ro nhanh tach tu $BaseV2 hay $BaseV3 (2 khoang cach gan bang nhau). Khong ghi ban do."
    }
    $ver = if ($c2 -lt $c3) { 'master2' } else { 'master3' }
}
$suffix = if ($branch -match '(?i)_M([23])$') { "master$($Matches[1])" } else { $null }
if ($suffix -and $suffix -ne $ver) { Stop-Map "Ten nhanh '$branch' ($suffix) mau thuan voi git ancestry ($ver). Khong ghi ban do." }
Info "Version = $ver  ->  graphify-out\$ver\"

# ---------- 2. .graphifyignore + exclude ----------
Write-Host "2) .graphifyignore"
$ignore = Join-Path $HisPath '.graphifyignore'
$tracked = & git -C $HisPath ls-files -- .graphifyignore
if ($tracked) {
    Note ".graphifyignore dang duoc git cong ty theo doi -> giu nguyen"
} elseif (-not (Test-Path -LiteralPath $ignore)) {
    $default = @('bin/', 'obj/', 'node_modules/', 'wwwroot/lib/', '*.min.js', '*.min.css', '*.map',
                 'graphify-out/', 'tasks/', 'plans/', 'UI_PLAN/', '.agents/', 'AGENTS.md*') -join "`n"
    [System.IO.File]::WriteAllText($ignore, $default + "`n", $Utf8NoBom)
    Info "Tao .graphifyignore mac dinh (bin, obj, wwwroot/lib, *.min.js, ...)"
} else { Note "Da co .graphifyignore" }

$exRel = (& git -C $HisPath rev-parse --git-path info/exclude).Trim()
$exclude = if ([System.IO.Path]::IsPathRooted($exRel)) { $exRel } else { Join-Path $HisPath $exRel }
$lines = @(); if (Test-Path -LiteralPath $exclude) { $lines = Get-Content -LiteralPath $exclude | ForEach-Object { $_.Trim() } }
$need = @('.graphifyignore', 'graphify-out/') | Where-Object { $lines -notcontains $_ }
if ($need) {
    $raw = if (Test-Path -LiteralPath $exclude) { [System.IO.File]::ReadAllText($exclude) } else { '' }
    $pre = if ($raw -and -not $raw.EndsWith("`n")) { "`n" } else { '' }
    [System.IO.File]::AppendAllText($exclude, $pre + "# AI_Agent map.ps1`n" + (($need -join "`n") + "`n"), $Utf8NoBom)
    Info "Them vao .git/info/exclude: $($need -join ', ')"
}

# ---------- 3. Chay graphify (khong goi model) ----------
Write-Host "3) Graphify (code-only, khong ton token)"
$live = Join-Path $HisPath 'graphify-out\graph.json'
$isNew = $Full -or -not (Test-Path -LiteralPath $live)
Push-Location $HisPath
try {
    if ($isNew) {
        $gArgs = @('extract', '.', '--code-only'); if ($Full) { $gArgs += '--force' }
        Note "graphify $($gArgs -join ' ')"
        & graphify @gArgs
    } else {
        Note "graphify update ."
        & graphify update .
    }
    if ($LASTEXITCODE -ne 0) { Stop-Map "graphify loi (exit $LASTEXITCODE)." }
} finally { Pop-Location }
if (-not (Test-Path -LiteralPath $live)) { Stop-Map "Khong thay graphify-out\graph.json sau khi chay." }

# ---------- 4. Copy vao dung thu muc version ----------
Write-Host "4) Luu ban do"
$target = Join-Path $HisPath "graphify-out\$ver"
if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target | Out-Null }
foreach ($f in 'graph.json', 'GRAPH_REPORT.md', 'graph.html') {
    $src = Join-Path $HisPath "graphify-out\$f"
    if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $target $f) -Force; Info "graphify-out\$ver\$f" }
}
$commit = (& git -C $HisPath rev-parse --short HEAD).Trim()
$mode = if ($isNew) { 'extract --code-only' } else { 'update' }
$meta = @(
    "# META - graphify-out/$ver",
    "",
    "- Nhanh: ``$branch`` (tach tu ``$(if ($ver -eq 'master2') { $BaseV2 } else { $BaseV3 })``)",
    "- Commit: ``$commit``",
    "- Ngay: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    "- Che do: ``graphify $mode`` (code-only, khong goi model)",
    "",
    "> Kiem tra ban do con moi: ``git diff --name-only $commit..HEAD`` -- file lien quan task da doi thi mo file that de xac nhan."
) -join "`n"
[System.IO.File]::WriteAllText((Join-Path $target 'META.md'), $meta + "`n", $Utf8NoBom)
Info "graphify-out\$ver\META.md (commit $commit)"

Write-Host ""
Write-Host "Xong. Ban do $ver da cap nhat tai commit $commit (khong ton token AI)." -ForegroundColor Green
