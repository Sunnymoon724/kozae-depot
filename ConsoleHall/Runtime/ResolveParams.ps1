param(
    [string]$ToolName,
    [string]$EnvTag = "",
    [string]$ScriptRoot
)

if ([string]::IsNullOrWhiteSpace($ToolName) -or [string]::IsNullOrWhiteSpace($ScriptRoot)) {
    Write-Host ""
    Write-Host "This script is not meant to be run directly." -ForegroundColor Red
    Write-Host "Use GenerateProto.bat, GenerateLua.bat, or GenerateCipher.bat instead."
    Write-Host ""
    Write-Host "Internal usage:"
    Write-Host "  -ToolName ProtoGenerator -EnvTag DEV -ScriptRoot <tool folder>"
    Write-Host ""
    if ($Host.Name -eq "ConsoleHost") {
        Read-Host "Press Enter to close"
    }
    exit 1
}

function Read-KeyValueMap {
    param([string]$Path)

    $map = @{}

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "File not found: $Path"
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()

        if ($line -eq "" -or $line.StartsWith("#")) {
            return
        }

        $parts = $line.Split("=", 2)

        if ($parts.Count -eq 2) {
            $map[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    return $map
}

function Resolve-PathsFile {
    param([string]$Root)

    $localFile = Join-Path $Root "Paths.env"

    if (Test-Path -LiteralPath $localFile) {
        return $localFile
    }

    $parentFile = Join-Path (Split-Path -Parent $Root) "Paths.env"

    if (Test-Path -LiteralPath $parentFile) {
        return $parentFile
    }

    throw "Paths.env not found near script root: $Root"
}

function Resolve-ParamFile {
    param(
        [string]$Root,
        [string]$Name
    )

    $candidates = @(
        (Join-Path $Root ("ParameterPath\{0}.list" -f $Name)),
        (Join-Path (Split-Path -Parent $Root) ("ParameterPath\{0}.list" -f $Name))
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "Parameter path file is not exist for $Name (looked under tool folder ParameterPath)"
}

$pathsFile = Resolve-PathsFile -Root $ScriptRoot
$paths = Read-KeyValueMap -Path $pathsFile

# Optional overrides from project wrappers (do not require Depot)
if (-not [string]::IsNullOrWhiteSpace($env:WRAP_WORK_PROJECT_PATH)) {
    $paths["WORK_PROJECT_PATH"] = $env:WRAP_WORK_PROJECT_PATH.Trim()
}

if (-not [string]::IsNullOrWhiteSpace($env:WRAP_DATA_ROOT_PATH)) {
    $paths["DATA_ROOT_PATH"] = $env:WRAP_DATA_ROOT_PATH.Trim()
}
elseif (-not [string]::IsNullOrWhiteSpace($env:WRAP_WORK_PROJECT_PATH)) {
    $paths["DATA_ROOT_PATH"] = $env:WRAP_WORK_PROJECT_PATH.Trim()
}

if (-not [string]::IsNullOrWhiteSpace($env:WRAP_PROTO_SOURCE_PATH)) {
    $paths["PROTO_SOURCE_PATH"] = $env:WRAP_PROTO_SOURCE_PATH.Trim()
}

foreach ($required in @("PROJECTS_ROOT", "WORK_PROJECT_PATH", "DATA_ROOT_PATH")) {
    if (-not $paths.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($paths[$required])) {
        throw "$required is not set. Use a project Tool wrapper, or set Paths.env / KZ_$required."
    }
}

if ($ToolName -eq "ProtoGenerator") {
    if (-not $paths.ContainsKey("PROTO_SOURCE_PATH") -or [string]::IsNullOrWhiteSpace($paths["PROTO_SOURCE_PATH"])) {
        throw "PROTO_SOURCE_PATH is not set. Set it in Paths.env or KZ_PROTO_SOURCE_PATH."
    }
}

$tokens = @{
    PROJECTS_ROOT     = $paths.PROJECTS_ROOT
    WORK_PROJECT_PATH = $paths.WORK_PROJECT_PATH
    DATA_ROOT_PATH    = $paths.DATA_ROOT_PATH
    PROTO_SOURCE_PATH = $paths.PROTO_SOURCE_PATH
    ENV_TAG           = $EnvTag
    TOOL_ROOT         = $ScriptRoot
}

$paramFile = Resolve-ParamFile -Root $ScriptRoot -Name $ToolName

Write-Output ("WORK_PROJECT_PATH={0}" -f $tokens.WORK_PROJECT_PATH)

if ($ToolName -eq "ProtoGenerator") {
    Write-Output ("PROTO_SOURCE_PATH={0}" -f $tokens.PROTO_SOURCE_PATH)
}

$index = 1

Get-Content -LiteralPath $paramFile | ForEach-Object {
    $line = $_.Trim()

    if ($line -eq "" -or $line.StartsWith("#")) {
        return
    }

    $text = $line

    foreach ($key in $tokens.Keys) {
        $text = $text.Replace("{${key}}", $tokens[$key])
    }

    Write-Output ("param{0}={1}" -f $index, $text)
    $index++
}
