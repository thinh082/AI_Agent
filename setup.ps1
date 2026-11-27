<#
.SYNOPSIS
  Noi bo quy trinh AI Agent (repo AI_Agent) vao 1 du an (vd HIS) tren may hien tai.

.DESCRIPTION
  - Tao junction trong du an tro ve repo AI_Agent:
      .agents\skills, .agents\templates, plans\_template, UI_PLAN\_template
    => sua skill/template o AI_Agent la du an dung ban moi ngay.
  - Copy AGENTS.md vao goc du an, tu sua dong KNOWLEDGE_ROOT theo vi tri AI_Agent tren may nay.
  - Them cac muc can an vao .git/info/exclude cua du an (KHONG sua .gitignore cong ty).
  - Chay lai bao nhieu lan cung duoc (idempotent). Khong xoa thu muc/file that nao cua du an.

.PARAMETER HisPath
  Duong dan thu muc goc du an (repo git), vd D:\Code\HIS.

.PARAMETER Update
  Chi copy lai AGENTS.md (dung khi vua sua luat trong AI_Agent).

.EXAMPLE
  .\setup.ps1 -HisPath D:\Code\HIS
  .\setup.ps1 -HisPath D:\Code\HIS -Update
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HisPath,
    [switch]$Update
)

$ErrorActionPreference = 'Stop'
$AgentRoot = $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$warnings = New-Object System.Collections.Generic.List[string]

function Info($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Skip($msg) { Write-Host "  [--]   $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "  [!!]   $msg" -ForegroundColor Yellow; $warnings.Add($msg) }

# ---------- 0. Kiem tra dau vao ----------
if (-not (Test-Path -LiteralPath $HisPath -PathType Container)) { throw "Khong thay thu muc: $HisPath" }
$HisPath = (Resolve-Path -LiteralPath $HisPath).Path.TrimEnd('\')
if ($HisPath -ieq $AgentRoot.TrimEnd('\')) { throw "HisPath dang tro vao chinh repo AI_Agent. Hay chi vao thu muc du an." }

$gitTop = (& git -C $HisPath rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $gitTop) { throw "$HisPath khong phai repo git." }
$gitTop = (Resolve-Path -LiteralPath $gitTop).Path.TrimEnd('\')
if ($gitTop -ine $HisPath) { throw "HisPath phai la thu muc GOC cua repo ($gitTop)." }

foreach ($p in '.agents\skills', '.agents\templates', 'plans\_template', 'UI_PLAN\_template', 'AGENTS.md', '.agents\knowledge\INDEX.md') {
    if (-not (Test-Path -LiteralPath (Join-Path $AgentRoot $p))) { throw "Repo AI_Agent thieu '$p' (dang chay script tu $AgentRoot)." }
}

function Test-Tracked($rel) {
    $out = & git -C $HisPath ls-files -- $rel 2>$null
    return [bool]$out
}

Write-Host ""
Write-Host "AI_Agent : $AgentRoot"
Write-Host "Du an    : $HisPath"
Write-Host ""

# ---------- 1. Junction ----------
if (-not $Update) {
    Write-Host "1) Junction"
    $links = [ordered]@{
        '.agents\skills'    = '.agents\skills'
        '.agents\templates' = '.agents\templates'
        'plans\_template'   = 'plans\_template'
        'UI_PLAN\_template' = 'UI_PLAN\_template'
    }
    foreach ($rel in $links.Keys) {
        $link = Join-Path $HisPath $rel
        $target = (Resolve-Path -LiteralPath (Join-Path $AgentRoot $links[$rel])).Path

        if (Test-Tracked ($rel -replace '\\', '/')) {
            Warn "$rel dang duoc git cong ty theo doi -> KHONG tao junction. Hoi lai truoc khi xu ly."
            continue
        }
        $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($item) {
            if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
                $cur = @($item.Target)[0]
                if ($cur -and ((Resolve-Path -LiteralPath $cur -ErrorAction SilentlyContinue).Path -ieq $target)) {
                    Skip "$rel da tro dung -> $target"
                } else {
                    Warn "$rel dang tro sang '$cur' (khac AI_Agent) -> giu nguyen. Muon doi thi tu xoa link roi chay lai."
                }
            } else {
                Warn "$rel da ton tai la thu muc/file THAT -> giu nguyen, khong ghi de. Tu doi ten/sao luu roi chay lai."
            }
            continue
        }
        $parent = Split-Path -Parent $link
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        Info "$rel -> $target"
    }
}

# ---------- 2. AGENTS.md ----------
Write-Host "2) AGENTS.md"
$dest = Join-Path $HisPath 'AGENTS.md'
if (Test-Tracked 'AGENTS.md') {
    Warn "Du an da co AGENTS.md do git cong ty theo doi -> KHONG ghi de. Can gop luat thu cong."
} else {
    $kbRoot = Join-Path $AgentRoot '.agents\knowledge'
    $content = [System.IO.File]::ReadAllText((Join-Path $AgentRoot 'AGENTS.md'), $Utf8NoBom)
    $pattern = '(\*\*`KNOWLEDGE_ROOT` = `)[^`]+(`\*\*)'
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, { param($m) $m.Groups[1].Value + $kbRoot + $m.Groups[2].Value })
    } else {
        Warn "Khong tim thay dong KNOWLEDGE_ROOT trong AGENTS.md -> copy nguyen ban, nho tu sua duong dan kho."
    }
    if (Test-Path -LiteralPath $dest) {
        $old = [System.IO.File]::ReadAllText($dest, $Utf8NoBom)
        if ($old -ceq $content) {
            Skip "AGENTS.md da la ban moi nhat"
            $content = $null
        } else {
            $bak = "$dest.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -LiteralPath $dest -Destination $bak
            Info "Da sao luu AGENTS.md cu -> $(Split-Path -Leaf $bak)"
        }
    }
    if ($null -ne $content) {
        [System.IO.File]::WriteAllText($dest, $content, $Utf8NoBom)
        Info "AGENTS.md (KNOWLEDGE_ROOT = $kbRoot)"
    }
}

# ---------- 3. .git/info/exclude ----------
if (-not $Update) {
    Write-Host "3) .git/info/exclude"
    $excludeRel = (& git -C $HisPath rev-parse --git-path info/exclude).Trim()
    $exclude = if ([System.IO.Path]::IsPathRooted($excludeRel)) { $excludeRel } else { Join-Path $HisPath $excludeRel }
    $excludeDir = Split-Path -Parent $exclude
    if (-not (Test-Path -LiteralPath $excludeDir)) { New-Item -ItemType Directory -Path $excludeDir | Out-Null }
    $existing = @()
    if (Test-Path -LiteralPath $exclude) { $existing = Get-Content -LiteralPath $exclude | ForEach-Object { $_.Trim() } }

    $wanted = 'AGENTS.md', 'AGENTS.md.bak-*', '.agents/', 'plans/', 'UI_PLAN/', 'tasks/', 'graphify-out/', '.graphifyignore'
    $missing = @($wanted | Where-Object { $existing -notcontains $_ })
    if ($missing.Count -eq 0) {
        Skip "Da co du cac muc can an"
    } else {
        $text = ''
        if ((Test-Path -LiteralPath $exclude) -and ((Get-Item -LiteralPath $exclude).Length -gt 0)) {
            $raw = [System.IO.File]::ReadAllText($exclude)
            if (-not $raw.EndsWith("`n")) { $text += "`n" }
        }
        $text += "# AI_Agent workflow (setup.ps1)`n" + (($missing -join "`n") + "`n")
        [System.IO.File]::AppendAllText($exclude, $text, $Utf8NoBom)
        Info "Them: $($missing -join ', ')"
    }
    foreach ($rel in 'plans', 'UI_PLAN', '.agents', 'tasks') {
        if (Test-Tracked $rel) { Warn "Git cong ty dang theo doi file trong '$rel/' -> exclude khong an duoc cac file do." }
    }
}

# ---------- 4. Ket qua ----------
Write-Host ""
$status = & git -C $HisPath status --porcelain -- AGENTS.md .agents plans UI_PLAN 2>$null
if ($status) { Warn "git status van thay thay doi trong cac muc tren:`n$status" } else { Info "git status sach cho AGENTS.md / .agents / plans / UI_PLAN" }

Write-Host ""
if ($warnings.Count -gt 0) {
    Write-Host "Xong, co $($warnings.Count) canh bao can xem lai (o tren)." -ForegroundColor Yellow
} else {
    Write-Host "Xong, khong co canh bao." -ForegroundColor Green
}
Write-Host "Nho: mo PHIEN MOI cua CLI (codex: /skills, agy: /) de kiem tra da thay cac skill."
