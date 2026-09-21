[CmdletBinding()]
param(
    [string]$DevEcoHome = $env:DEVECO_STUDIO_HOME,
    [string]$ArkUIXSdkHome = $env:ARKUIX_SDK_HOME,
    [string]$AndroidSdkHome = $env:ANDROID_HOME,
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$ProxyUrl = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
foreach ($setting in @('DevEcoHome','ArkUIXSdkHome','AndroidSdkHome','JavaHome')) {
    $value = Get-Variable $setting -ValueOnly
    if (!$value -or !(Test-Path -LiteralPath $value -PathType Container)) { throw "Supply a valid -$setting directory" }
}
$node = Join-Path $DevEcoHome 'tools/node/node.exe'
$hvigor = Join-Path $DevEcoHome 'tools/hvigor/bin/hvigorw.js'
$ohpm = Join-Path $DevEcoHome 'tools/ohpm/bin/ohpm.bat'
$sdk = Join-Path $ArkUIXSdkHome '24/arkui-x'
foreach ($file in @($node,$hvigor,$ohpm,(Join-Path $sdk 'arkui-x.json'),(Join-Path $JavaHome 'bin/java.exe'),(Join-Path $AndroidSdkHome 'platforms/android-35/android.jar'))) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required tool or SDK missing: $file" }
}
$changes = @{
    DEVECO_SDK_HOME = (Join-Path $DevEcoHome 'sdk')
    ARKUIX_SDK_HOME = $ArkUIXSdkHome
    ANDROID_HOME = $AndroidSdkHome
    JAVA_HOME = $JavaHome
    MOMOTALK_ARKUIX_SDK = $sdk
    MOMOTALK_NODE = $node
    NPM_CONFIG_REGISTRY = 'https://repo.harmonyos.com/npm/'
    NPM_CONFIG_USERCONFIG = (Join-Path $projectRoot 'scripts/build.npmrc')
    Path = ((Split-Path $node -Parent) + ';' + $env:Path)
}
if ($ProxyUrl) {
    $proxy = [Uri]$ProxyUrl
    if ($proxy.Scheme -ne 'http' -or $proxy.UserInfo -or !$proxy.Host -or $proxy.Port -lt 1) { throw 'ProxyUrl must be an HTTP proxy URL without credentials' }
    $changes.JAVA_TOOL_OPTIONS = "$env:JAVA_TOOL_OPTIONS -Dhttp.proxyHost=$($proxy.DnsSafeHost) -Dhttp.proxyPort=$($proxy.Port) -Dhttps.proxyHost=$($proxy.DnsSafeHost) -Dhttps.proxyPort=$($proxy.Port)"
}
$original = @{}
try {
    foreach ($name in $changes.Keys) {
        $original[$name] = [Environment]::GetEnvironmentVariable($name,'Process')
        [Environment]::SetEnvironmentVariable($name,$changes[$name],'Process')
    }
    Push-Location $projectRoot
    try {
        & (Join-Path (Split-Path $node -Parent) 'npm.cmd') ci --ignore-scripts
        if ($LASTEXITCODE) { throw 'Build tool dependency installation failed' }
        & $node (Join-Path $PSScriptRoot 'prepare-android.cjs')
        if ($LASTEXITCODE) { throw 'Android preparation failed' }
        Push-Location (Join-Path $projectRoot 'build/arkuix')
        try {
            & $ohpm install --all
            if ($LASTEXITCODE) { throw 'OHPM dependency installation failed' }
            & $node $hvigor --mode project -p product=default -p buildMode=debug assembleApp --no-daemon
            if ($LASTEXITCODE) { throw 'Android build failed; inspect the preceding build errors' }
        } finally { Pop-Location }
    } finally { Pop-Location }
    $apk = Join-Path $projectRoot 'build/arkuix/.arkui-x/android/app/build/outputs/apk/debug/app-debug.apk'
    if (!(Test-Path -LiteralPath $apk)) { throw 'Build returned without producing the Android APK' }
    Write-Output "Android debug APK: $apk"
} finally {
    foreach ($name in $original.Keys) { [Environment]::SetEnvironmentVariable($name,$original[$name],'Process') }
}
