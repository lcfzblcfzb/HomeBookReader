# HomePdfReader Windows 一键启动
# 用法：双击 run_windows.bat，或在终端执行 powershell -ExecutionPolicy Bypass -File run_windows.ps1
# 说明：Flutter 不在 PATH，脚本内固定候选路径；运行输出同时写入 logs\run-<时间戳>.log 与 logs\latest.log。

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

$flutterCandidates = @(
    'E:\flutter\bin\flutter.bat',
    'D:\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat',
    (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')
)
$flutter = $flutterCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $flutter) {
    Write-Host '[错误] 未找到 Flutter SDK，请修改 run_windows.ps1 里的 $flutterCandidates。' -ForegroundColor Red
    exit 1
}

# 国内镜像与包缓存（与开发环境一致；已存在则不覆盖用户设置）
if (-not $env:PUB_CACHE) { $env:PUB_CACHE = 'E:\pub-cache' }
if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn' }
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn' }

# 日志：本次运行 + 最近一次（应用内异常也追加到 latest.log）
$logsDir = Join-Path $projectRoot 'logs'
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runLog = Join-Path $logsDir "run-$stamp.log"
$latestLog = Join-Path $logsDir 'latest.log'

# 日志轮转：包含本次新建的在内，run-*.log 只保留最近 10 个（按文件名时间戳倒序）。
# 清理发生在创建本次日志之前，因此这里只保留 9 个历史文件；latest.log 是本次运行的镜像，不参与计数也不删除。
$keepRunLogs = 10
$removedCount = 0
$staleLogs = Get-ChildItem -LiteralPath $logsDir -Filter 'run-*.log' -File |
    Sort-Object Name -Descending |
    Select-Object -Skip ($keepRunLogs - 1)
foreach ($stale in $staleLogs) {
    if ($stale.FullName -eq $runLog) { continue }
    try {
        Remove-Item -LiteralPath $stale.FullName -Force -ErrorAction Stop
        $removedCount++
    } catch {
        # 可能仍被上一轮 flutter run 占用（Windows 文件锁），跳过，下次启动再清。
        Write-Host ("[launcher] 跳过删除占用中的日志: " + $stale.Name)
    }
}

$utf8 = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($runLog, '', $utf8)
[System.IO.File]::WriteAllText($latestLog, '', $utf8)
$env:HPR_LOG_FILE = $latestLog

function Add-LogLine {
    param([string]$Text)
    Write-Host $Text
    [System.IO.File]::AppendAllText($runLog, $Text + "`r`n", $utf8)
    [System.IO.File]::AppendAllText($latestLog, $Text + "`r`n", $utf8)
}

Add-LogLine ("[launcher] " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " 启动 flutter run -d windows")
Add-LogLine ("[launcher] Flutter: " + $flutter)
Add-LogLine ("[launcher] 项目目录: " + $projectRoot)
Add-LogLine ("[launcher] 本次日志: " + $runLog)
Add-LogLine ("[launcher] 日志轮转: 保留最近 " + $keepRunLogs + " 个 run-*.log，本次清理 " + $removedCount + " 个")

Set-Location -LiteralPath $projectRoot
# flutter 会往 stderr 写提示，Stop 模式下会被当成终止性错误，这里临时放行。
$ErrorActionPreference = 'Continue'
& $flutter run -d windows 2>&1 | ForEach-Object {
    Add-LogLine ("$_")
}
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Add-LogLine ("[launcher] " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " flutter run 退出，退出码=" + $code)
exit $code
