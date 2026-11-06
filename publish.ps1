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
$readingUrl = "https://github.com/Yiz777/StockDaily/blob/main/$Date.md"
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
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 15 -UseBasicParsing
            if ($response.StatusCode -eq 200 -and $response.Content.Contains($ReportDate) -and $response.Content.Contains('Zoe')) {
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
    $reportContent = Get-Content -LiteralPath $required -Raw -Encoding utf8
    $datePrefix = if ($required -eq $htmlPath) { ($reportContent -split '</header>|<!-- 2 ', 2)[0] } else { $reportContent.Substring(0, [Math]::Min(500, $reportContent.Length)) }
    $chineseDate = [datetime]::ParseExact($Date, 'yyyy-MM-dd', $null).ToString('yyyy年M月d日')
    if (-not ($datePrefix.Contains($Date) -or $datePrefix.Contains($chineseDate))) {
        throw "正文日期与发布日期不一致，停止发布：$required"
    }
}

$publishFiles = @(
    "$Date.html",
    "$Date.md",
    'index.html',
    'watchlist.md',
    'rotation-review.md',
    'prompt-v5.md',
    'template.html',
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

$publicationProblem = $null
try {
    Invoke-Git -Arguments @('push', 'origin', 'HEAD:main')
    Write-Host '  GitHub 推送完成。'
}
catch {
    $publicationProblem = 'GitHub 推送失败；本期网页尚未确认更新。'
    $readingUrl = 'inline'
    Write-Warning "$publicationProblem 继续发送已核验的本期摘要及故障说明，避免手机漏报。"
}

if (-not $SkipPageCheck -and -not $publicationProblem) {
    Write-Host '=== 页面可用性检查 ==='
    if (-not (Test-PublishedPage -Url $pageUrl -ReportDate $Date)) {
        Write-Host '  GitHub Pages 未通过实际访问检查，改为验证文字版全文入口。'
        if (-not (Test-PublishedPage -Url $readingUrl -ReportDate $Date)) {
            $publicationProblem = '文件已上传，但两个阅读入口均未验证通过。'
            $readingUrl = 'inline'
            Write-Warning "$publicationProblem 手机通知将包含本期摘要和故障说明。"
        }
        else {
            Write-Host "  已验证文字版入口：$readingUrl；GitHub Pages 访问问题仍未解决。"
        }
    }
    else {
        Write-Host "  网页版已通过本机访问检查：$pageUrl（不等于手机网络已验证）。"
    }
}

if ($SkipMobile) {
    Write-Host '=== 手机通知已按参数跳过 ==='
    if ($publicationProblem) { throw $publicationProblem }
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
    if ($publicationProblem) { throw $publicationProblem }
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

$deliveryAlert = if ($publicationProblem) { "$Alert`n发布状态：$publicationProblem 本次仅发送摘要。" } else { $Alert }
& $python.Source (Join-Path $repo 'send_wechat.py') $Date $Summary $Sp500Value $Sp500Change $NasdaqValue $NasdaqChange $VixValue $deliveryAlert $readingUrl
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub 已发布，但手机通知发送失败。'
}

$updatedDates = @($sentDates + $Date | Sort-Object -Unique)
[ordered]@{
    mobile_sent_dates = $updatedDates
    updated_at = (Get-Date).ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8

Write-Host '  手机通知发送完成。'
Write-Host "阅读入口：$readingUrl；手机通知发送的是摘要和链接。"
if ($publicationProblem) {
    throw "$publicationProblem 手机摘要通知已被服务端接受，网页发布仍需修复。"
}
