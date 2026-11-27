<#
.SYNOPSIS
  Kiem tra MAY MOC (khong dung AI) cho 1 task truoc khi ban giao / kiem duyet.

.DESCRIPTION
  Doc tasks\<task>\PLAN.md cua du an (vd HIS) va so code hien tai voi "Base commit" ghi trong plan:
    [FAIL] nhanh sai (dang dung tren nhanh goc, sai goc, hau to _M2/_M3 mau thuan, khong khop version trong plan)
    [FAIL] Base commit khong nam trong lich su nhanh
    [FAIL] sua appsettings*.json / Web.config / .env
    [FAIL] script SQL dung ham cam (GREATEST, LEAST, GENERATE_SERIES)
    [FAIL] task v2+v3 ma thieu cap script _v2 / _v3 (va DEPLOY_CHECKLIST.md khong nhac ten file thieu)
    [WARN] file bi sua nhung khong co trong PLAN.md (kem goi y: co trong plan cua task khac?)
    [WARN] dong them moi co chuoi fallback `?? ... ??`
    [WARN] thieu Base commit / PROGRESS.md / ban sao PLAN.revN.md
  Ghi ket qua:
    tasks\<task>\CHECK_REPORT.md   (tong hop - Tester / Coder doc file nay)
    tasks\<task>\CHECK_DELETED.md  (100% dong bi xoa, theo tung file - phuc vu Cong 1)
  Exit code: 0 = khong co FAIL, 1 = co FAIL.

.EXAMPLE
  .\check.ps1 -HisPath D:\Code\HIS -Task 2026-11-27_HIS-1240
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HisPath,
    [Parameter(Mandatory = $true)][string]$Task,
    [string]$BaseV2 = 'master_2',
    [string]$BaseV3 = 'master_3'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$results = New-Object System.Collections.Generic.List[object]
function Add-Result($level, $group, $msg) { $results.Add([pscustomobject]@{ Level = $level; Group = $group; Msg = $msg }) }
function Invoke-HisGit { & git -C $HisPath -c core.quotepath=off @args }

# ---------- 0. Dau vao ----------
if (-not (Test-Path -LiteralPath $HisPath -PathType Container)) { throw "Khong thay thu muc: $HisPath" }
$HisPath = (Resolve-Path -LiteralPath $HisPath).Path.TrimEnd('\')
$taskDir = if (Test-Path -LiteralPath $Task -PathType Container) { (Resolve-Path -LiteralPath $Task).Path } else { Join-Path $HisPath "tasks\$Task" }
$planPath = Join-Path $taskDir 'PLAN.md'
if (-not (Test-Path -LiteralPath $planPath)) { throw "Khong thay PLAN.md: $planPath" }
$plan = [System.IO.File]::ReadAllText($planPath, $Utf8NoBom)

# ---------- 1. Doc PLAN.md ----------
$baseCommit = if ($plan -match '\*\*Base commit:\*\*\s*`?([0-9a-fA-F]{7,40})`?') { $Matches[1] } else { $null }
$rev = if ($plan -match 'plan:\*\*\s*`?Rev\s*(\d+)') { [int]$Matches[1] } else { 1 }
$head = ($plan -split "`n" | Select-Object -First 40) -join "`n"
$planVers = @()
if ($head -match '(?i)\[x\]\s*master_?2') { $planVers += 'master2' }
if ($head -match '(?i)\[x\]\s*master_?3') { $planVers += 'master3' }

$pathRegex = '`([^`\s]+\.(?:cs|cshtml|razor|js|ts|css|scss|html|sql|json|xml|config|csproj|resx))`'
$planFiles = @([regex]::Matches($plan, $pathRegex) | ForEach-Object { $_.Groups[1].Value.Replace('\', '/').ToLowerInvariant() } | Sort-Object -Unique)

# ---------- 2. Nhanh ----------
function Resolve-Base($name) {
    foreach ($ref in $name, "origin/$name") {
        Invoke-HisGit rev-parse --verify --quiet "$ref^{commit}" *> $null
        if ($LASTEXITCODE -eq 0) { return $ref }
    }
    return $null
}
$branch = (Invoke-HisGit branch --show-current).Trim()
$ref2 = Resolve-Base $BaseV2; $ref3 = Resolve-Base $BaseV3
$branchVer = $null
if (-not $ref2 -or -not $ref3) {
    Add-Result 'FAIL' 'Nhanh' "Khong tim thay nhanh goc '$BaseV2' / '$BaseV3' (ca local lan origin/)."
} elseif ($branch -ieq $BaseV2 -or $branch -ieq $BaseV3) {
    Add-Result 'FAIL' 'Nhanh' "Dang dung truc tiep tren nhanh goc '$branch' (Luat 6)."
} else {
    $c2 = [int](Invoke-HisGit rev-list --count "$ref2..HEAD"); $c3 = [int](Invoke-HisGit rev-list --count "$ref3..HEAD")
    $min = [Math]::Min($c2, $c3); $max = [Math]::Max($c2, $c3)
    if ($c2 -eq $c3 -or ($min -gt 0 -and $min * 2 -gt $max)) {
        Add-Result 'FAIL' 'Nhanh' "Khong ro '$branch' tach tu $BaseV2 hay $BaseV3 ($BaseV2..HEAD=$c2, $BaseV3..HEAD=$c3)."
    } else {
        $branchVer = if ($c2 -lt $c3) { 'master2' } else { 'master3' }
        $suffix = if ($branch -match '(?i)_M([23])$') { "master$($Matches[1])" } else { $null }
        if ($suffix -and $suffix -ne $branchVer) { Add-Result 'FAIL' 'Nhanh' "Ten nhanh '$branch' ($suffix) mau thuan voi git ancestry ($branchVer)." }
        elseif ($planVers.Count -gt 0 -and $planVers -notcontains $branchVer) { Add-Result 'FAIL' 'Nhanh' "Nhanh '$branch' la $branchVer nhung PLAN.md chi ap dung: $($planVers -join ', ')." }
        else { Add-Result 'OK' 'Nhanh' "'$branch' tach tu $(if ($branchVer -eq 'master2') { $BaseV2 } else { $BaseV3 }) ($branchVer)." }
    }
}

# ---------- 3. Base commit ----------
# Uu tien 'Base commit v2:' / 'Base commit v3:' (Porter ghi cho nhanh port) theo version cua nhanh hien tai
if ($branchVer) {
    $vn = $branchVer.Substring($branchVer.Length - 1)
    if ($plan -match ('\*\*Base commit v' + $vn + ':\*\*\s*`?([0-9a-fA-F]{7,40})`?')) { $baseCommit = $Matches[1] }
}
$diffBase = 'HEAD'
if (-not $baseCommit) {
    Add-Result 'WARN' 'Base commit' "PLAN.md chua co 'Base commit' -> tam so voi HEAD (thay doi cua task khac chua commit se bi lan vao)."
} else {
    Invoke-HisGit merge-base --is-ancestor $baseCommit HEAD *> $null
    if ($LASTEXITCODE -eq 0) { $diffBase = $baseCommit; Add-Result 'OK' 'Base commit' "So sanh tu $baseCommit." }
    else { Add-Result 'FAIL' 'Base commit' "Base commit $baseCommit khong nam trong lich su nhanh hien tai." }
}

# ---------- 4. File thay doi ----------
$changed = New-Object System.Collections.Generic.List[object]
foreach ($line in @(Invoke-HisGit diff --name-status $diffBase)) {
    if (-not $line) { continue }
    $parts = $line -split "`t"
    $changed.Add([pscustomobject]@{ Status = $parts[0].Substring(0, 1); Path = $parts[-1] })
}
foreach ($p in @(Invoke-HisGit ls-files --others --exclude-standard)) { if ($p) { $changed.Add([pscustomobject]@{ Status = '?'; Path = $p }) } }

$otherPlans = @(Get-ChildItem -LiteralPath (Join-Path $HisPath 'tasks') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $taskDir -and (Test-Path (Join-Path $_.FullName 'PLAN.md')) })

function Test-InPlan($path, $files) {
    $p = $path.Replace('\', '/').ToLowerInvariant()
    foreach ($f in $files) {
        if ($p -eq $f -or $p.EndsWith('/' + $f) -or (($f -notmatch '/') -and ($p.Split('/')[-1] -eq $f))) { return $true }
    }
    return $false
}

if ($changed.Count -eq 0) { Add-Result 'WARN' 'Pham vi' "Khong co thay doi nao so voi $diffBase." }
foreach ($c in $changed) {
    if ($c.Path -match '(?i)(^|/)(appsettings[^/]*\.json|web\.config|\.env[^/]*)$') {
        Add-Result 'FAIL' 'Bao mat' "Sua file cau hinh nhay cam: $($c.Path) (Luat 5)."
        continue
    }
    if (Test-InPlan $c.Path $planFiles) { continue }
    $owner = @()
    foreach ($op in $otherPlans) {
        $txt = [System.IO.File]::ReadAllText((Join-Path $op.FullName 'PLAN.md'), $Utf8NoBom)
        $ofiles = @([regex]::Matches($txt, $pathRegex) | ForEach-Object { $_.Groups[1].Value.Replace('\', '/').ToLowerInvariant() })
        if (Test-InPlan $c.Path $ofiles) { $owner += $op.Name }
    }
    $hint = if ($owner) { " -> co trong plan task khac: $($owner -join ', ') (commit rieng task do truoc)." } else { " -> khong thuoc plan nao: kiem tra Luat 1." }
    Add-Result 'WARN' 'Pham vi' "[$($c.Status)] $($c.Path) khong co trong PLAN.md$hint"
}

# ---------- 5. Dong bi xoa / them ----------
$deleted = New-Object System.Text.StringBuilder
$delCount = 0; $file = $null; $lineNo = 0
$diffText = @(Invoke-HisGit diff -U0 --no-color $diffBase)
foreach ($l in $diffText) {
    if ($l -match '^diff --git a/(.+) b/(.+)$') { $file = $Matches[2]; continue }
    if ($l -match '^@@ -(\d+)(?:,\d+)? \+(\d+)') { $lineNo = [int]$Matches[2]; [void]$deleted.AppendLine("  @@ $file (dong cu ~$($Matches[1]))"); continue }
    if ($l.StartsWith('---') -or $l.StartsWith('+++')) { continue }
    if ($l.StartsWith('-')) { $delCount++; [void]$deleted.AppendLine("    - " + $l.Substring(1)); continue }
    if ($l.StartsWith('+')) {
        $added = $l.Substring(1)
        if ($added -match '\?\?(?!=).*\?\?(?!=)') { Add-Result 'WARN' 'Fallback' "$file`:$lineNo co chuoi fallback ?? ... ?? (Luat 3): $($added.Trim())" }
        $lineNo++
    }
}
foreach ($c in $changed | Where-Object { $_.Status -eq '?' }) {
    $full = Join-Path $HisPath $c.Path
    if ((Get-Item -LiteralPath $full).Length -gt 1MB) { continue }
    $n = 0
    foreach ($added in [System.IO.File]::ReadAllLines($full, $Utf8NoBom)) {
        $n++
        if ($added -match '\?\?(?!=).*\?\?(?!=)') { Add-Result 'WARN' 'Fallback' "$($c.Path):$n co chuoi fallback ?? ... ?? (Luat 3): $($added.Trim())" }
    }
}
Add-Result 'OK' 'Dong bi xoa' "$delCount dong bi xoa -> xem CHECK_DELETED.md (Tester doi chieu 100% voi PLAN.md)."

# ---------- 6. Script SQL ----------
$sqlFiles = @(Get-ChildItem -LiteralPath $taskDir -Filter *.sql -File -ErrorAction SilentlyContinue)
foreach ($s in $sqlFiles) {
    $n = 0
    foreach ($sl in [System.IO.File]::ReadAllLines($s.FullName, $Utf8NoBom)) {
        $n++
        if ($sl.TrimStart().StartsWith('--')) { continue }
        if ($sl -match '(?i)\b(GREATEST|LEAST|GENERATE_SERIES)\s*\(') { Add-Result 'FAIL' 'SQL' "$($s.Name):$n dung ham $($Matches[1].ToUpper()) (khong co tren SQL Server 2017)." }
    }
}
if ($planVers.Count -eq 2) {
    $checklist = Join-Path $taskDir 'DEPLOY_CHECKLIST.md'
    $clText = if (Test-Path -LiteralPath $checklist) { [System.IO.File]::ReadAllText($checklist, $Utf8NoBom) } else { '' }
    $names = @($sqlFiles | ForEach-Object { $_.Name.ToLowerInvariant() })
    foreach ($nm in $names) {
        if ($nm -match '^(\d\d_.+)_v([23])\.sql$') {
            $other = "$($Matches[1])_v$(if ($Matches[2] -eq '2') { '3' } else { '2' }).sql"
            if ($names -contains $other) { continue }
            if ($clText -match [regex]::Escape($other)) { Add-Result 'OK' 'SQL' "Thieu $other nhung DEPLOY_CHECKLIST.md co ghi (kiem tra ly do)." }
            else { Add-Result 'FAIL' 'SQL' "Co $nm nhung thieu $other (task v2+v3) va DEPLOY_CHECKLIST.md khong ghi ly do." }
        }
    }
} elseif ($planVers.Count -eq 0) {
    Add-Result 'WARN' 'SQL' "Khong doc duoc 'Version ap dung' trong PLAN.md (chua danh dau [x]) -> bo qua kiem tra cap script v2/v3."
}

# ---------- 7. PROGRESS.md / PLAN.revN.md ----------
if (Test-Path -LiteralPath (Join-Path $taskDir 'PROGRESS.md')) { Add-Result 'OK' 'Tien do' 'Co PROGRESS.md.' }
else { Add-Result 'WARN' 'Tien do' 'Chua co PROGRESS.md (Coder phai ghi tien do tung buoc).' }
for ($k = 1; $k -lt $rev; $k++) {
    if (-not (Test-Path -LiteralPath (Join-Path $taskDir "PLAN.rev$k.md"))) { Add-Result 'WARN' 'Plan Rev' "PLAN.md dang Rev $rev nhung thieu ban sao PLAN.rev$k.md." }
}
if ($rev -gt 1) { Add-Result 'OK' 'Plan Rev' "Rev $rev -> so bang: git diff --no-index PLAN.rev$($rev - 1).md PLAN.md" }

# ---------- 8. Ghi bao cao ----------
$fails = @($results | Where-Object Level -eq 'FAIL').Count
$warns = @($results | Where-Object Level -eq 'WARN').Count
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# CHECK_REPORT - $(Split-Path -Leaf $taskDir)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- Thoi gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm') | Nhanh: ``$branch`` | So tu: ``$diffBase`` | Plan Rev: $rev")
[void]$sb.AppendLine("- **Ket qua: $fails FAIL, $warns WARN** (FAIL phai sua; WARN phai giai thich co bang chung trong TEST_REPORT.md)")
[void]$sb.AppendLine("")
foreach ($lvl in 'FAIL', 'WARN', 'OK') {
    $items = @($results | Where-Object Level -eq $lvl)
    if ($items.Count -eq 0) { continue }
    [void]$sb.AppendLine("## $lvl")
    foreach ($r in $items) { [void]$sb.AppendLine("- **[$($r.Group)]** $($r.Msg)") }
    [void]$sb.AppendLine("")
}
[System.IO.File]::WriteAllText((Join-Path $taskDir 'CHECK_REPORT.md'), $sb.ToString(), $Utf8NoBom)
$delHeader = "# CHECK_DELETED - $(Split-Path -Leaf $taskDir)`n`n> 100% dong bi xoa so voi ``$diffBase`` ($delCount dong). Moi dong phai thuoc 1 buoc trong PLAN.md (ke ca buoc HOAN TAC), neu khong -> FAIL Cong 1.`n`n"
[System.IO.File]::WriteAllText((Join-Path $taskDir 'CHECK_DELETED.md'), $delHeader + $deleted.ToString(), $Utf8NoBom)

Write-Host ""
foreach ($r in $results) {
    $color = switch ($r.Level) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Green' } }
    Write-Host ("  [{0}] [{1}] {2}" -f $r.Level, $r.Group, $r.Msg) -ForegroundColor $color
}
Write-Host ""
Write-Host "=> $fails FAIL, $warns WARN. Bao cao: $(Join-Path $taskDir 'CHECK_REPORT.md')" -ForegroundColor $(if ($fails) { 'Red' } elseif ($warns) { 'Yellow' } else { 'Green' })
if ($fails) { exit 1 } else { exit 0 }
