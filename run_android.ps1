# HomePdfReader Android 启动脚本（双击或终端执行）
# 用法：
#   .\run_android.ps1                 自动使用唯一已连接设备
#   .\run_android.ps1 emulator-5554   指定设备 id
param([string]$Device = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 不依赖 PATH：按顺序找可用的 Flutter
$flutter = @(
    'E:\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat',
    'D:\flutter\bin\flutter.bat'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $flutter) {
    Write-Host '[launcher] 未找到 Flutter，请修改脚本里的候选路径。'
    exit 1
}

# 本机 Android 环境（与 flutter doctor 验证过的一致）
$androidSdk = 'D:\AndroidSDK'
if (-not (Test-Path -LiteralPath $androidSdk)) {
    Write-Host "[launcher] 未找到 Android SDK：$androidSdk"
    exit 1
}
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
if (-not $env:JAVA_HOME -and (Test-Path -LiteralPath 'D:\JDK17\jdk-17.0.12')) {
    $env:JAVA_HOME = 'D:\JDK17\jdk-17.0.12'
}
$env:PUB_CACHE = 'E:\pub-cache'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:Path = "$androidSdk\platform-tools;$env:Path"

# 选择设备：优先命令行参数，否则要求恰好一个已连接设备
$adb = Join-Path $androidSdk 'platform-tools\adb.exe'
# adb 首次启动 daemon 时会往 stderr 打 "daemon not running; starting now"，
# 在 $ErrorActionPreference='Stop' 下会被当成终止性错误。这里临时放行外部程序报错。
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$devices = @(& $adb devices 2>$null | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
if (-not $Device) {
    if ($devices.Count -eq 1) {
        $Device = $devices[0]
    } elseif ($devices.Count -eq 0) {
        Write-Host '[launcher] 没有已连接的设备。'
        Write-Host '[launcher] 启动模拟器：'
        Write-Host "           & '$androidSdk\emulator\emulator.exe' -avd Pixel_5_API_30"
        Write-Host '[launcher] 或连接真机后重试；设备 id 用 flutter devices / adb devices 查询。'
        exit 1
    } else {
        Write-Host '[launcher] 检测到多个设备，请指定设备 id：'
        $devices | ForEach-Object { Write-Host "           $_" }
        Write-Host '[launcher] 例如：.\run_android.ps1 emulator-5554'
        exit 1
    }
}
$ErrorActionPreference = $prevEap

Write-Host "[launcher] Flutter: $flutter"
Write-Host "[launcher] Android SDK: $androidSdk"
Write-Host "[launcher] 设备: $Device"

Set-Location -LiteralPath $projectRoot
# flutter 会往 stderr 写提示，Stop 模式下会被当成终止性错误，这里临时放行。
$ErrorActionPreference = 'Continue'
& $flutter run -d $Device
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Write-Host "[launcher] flutter run 退出，退出码=$code"
exit $code
