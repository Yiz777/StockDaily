[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$Date,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [Parameter(Mandatory = $true)]
    [string]$Sp500Value,

    [Parameter(Mandatory = $true)]
    [string]$Sp500Change,

    [Parameter(Mandatory = $true)]
    [string]$NasdaqValue,

    [Parameter(Mandatory = $true)]
    [string]$NasdaqChange,

    [Parameter(Mandatory = $true)]
    [string]$VixValue,

    [Parameter(Mandatory = $true)]
    [string]$Alert,

    [switch]$DryRun,
    [switch]$SkipMobile,
    [switch]$SkipPageCheck,
    [switch]$ForceMobile
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$htmlPath = Join-Path $repo "$Date.html"
$mdPath = Join-Path $repo "$Date.md"
$pageUrl = "https://Yiz777.github.io/StockDaily/$Date.html"
$statePath = Join-Path $repo '.publish-state.json'

function Invoke-Git {
    param([string[]]$Arguments)
    & git -C $repo @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git 命令失败：git $($Arguments -join ' ')"
    }
}

function Test-PublishedPage {
    param(
        [string]$Url,
        [string]$ReportDate
    )

    foreach ($attempt in 1..3) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 15 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                return $true
            }
        }
        catch {
            Write-Host "  公开页面暂不可核验（第 $attempt/3 次）"
        }
        if ($attempt -lt 3) {
            Start-Sleep -Seconds 5
        }
    }

    # 学校网络可能使用自己的 HTTPS 证书链，导致 github.io 在本机校验失败。
    # 此时用 GitHub API 确认当日文件已经进入远端 main，避免误判为发布失败。
    try {
        $encodedName = [uri]::EscapeDataString("$ReportDate.html")
        $apiUrl = "https://api.github.com/repos/Yiz777/StockDaily/contents/$encodedName`?ref=main"
        $response = Invoke-WebRequest -Uri $apiUrl -Method Get -TimeoutSec 20 -UseBasicParsing -Headers @{
            'User-Agent' = 'StockDaily-Publisher'
        }
        if ($response.StatusCode -eq 200) {
            Write-Host '  GitHub API 已确认当日文件位于远端 main；公开页面由 GitHub Pages 异步刷新。'
            return $true
        }
    }
    catch {
        Write-Host '  GitHub API 也无法确认当日文件。'
    }

    return $false
}

Write-Host "=========================================="
Write-Host "  美股日报发布流程 · $Date"
Write-Host "=========================================="

foreach ($required in @($htmlPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "缺少发布文件：$required"
    }
    if ((Get-Item -LiteralPath $required).Length -eq 0) {
        throw "发布文件为空：$required"
    }
}

$publishFiles = @(
    "$Date.html",
    "$Date.md",
    'index.html',
    'watchlist.md',
    'rotation-review.md',
    'publish.ps1',
    'publish.sh',
    'send_wechat.py',
    '.gitignore'
) | Where-Object { Test-Path -LiteralPath (Join-Path $repo $_) }

Write-Host "发布范围：$($publishFiles -join '、')"
if ($DryRun) {
    Write-Host '安全演练完成：未提交、未推送、未发送手机通知。'
    exit 0
}

Write-Host '=== GitHub 发布 ==='
Invoke-Git -Arguments (@('add', '--') + $publishFiles)

& git -C $repo diff --cached --quiet
$hasStagedChanges = $LASTEXITCODE -ne 0
if ($hasStagedChanges) {
    Invoke-Git -Arguments @('commit', '-m', "每日更新：$Date")
}
else {
    Write-Host '  没有新的本地改动，继续检查远端同步。'
}

Invoke-Git -Arguments @('push', 'origin', 'HEAD:main')
Write-Host '  GitHub 推送完成。'

if (-not $SkipPageCheck) {
    Write-Host '=== 页面可用性检查 ==='
    if (-not (Test-PublishedPage -Url $pageUrl -ReportDate $Date)) {
        throw "GitHub 已推送，但公开页面尚未就绪；为避免发送失效链接，本次不发手机通知：$pageUrl"
    }
    Write-Host "  页面可访问：$pageUrl"
}

if ($SkipMobile) {
    Write-Host '=== 手机通知已按参数跳过 ==='
    exit 0
}

$sentDates = @()
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    try {
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $sentDates = @($state.mobile_sent_dates)
    }
    catch {
        throw "发布状态文件无法读取，请先检查后再决定是否发送手机通知：$statePath"
    }
}

if (-not $ForceMobile -and $sentDates -contains $Date) {
    Write-Host "=== $Date 的手机通知已经发送，本次自动跳过 ==="
    exit 0
}

Write-Host '=== 手机通知 ==='
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw 'GitHub 已发布，但找不到 Python，手机通知未发送。'
}

& $python.Source (Join-Path $repo 'send_wechat.py') $Date $Summary $Sp500Value $Sp500Change $NasdaqValue $NasdaqChange $VixValue $Alert
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub 已发布，但手机通知发送失败。'
}

$updatedDates = @($sentDates + $Date | Sort-Object -Unique)
[ordered]@{
    mobile_sent_dates = $updatedDates
    updated_at = (Get-Date).ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8

Write-Host '  手机通知发送完成。'
Write-Host "日报地址：$pageUrl"
