# =======================================================
# C# Script Analyzer (.NET StreamWriter Final Version)
# 파일 이름: analyze_cs_final.ps1
# =======================================================

# --- IMPORTANT: Force the script execution environment encoding to UTF-8 ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- 파라미터 처리 (안정성 강화) ---
# $Args[0] = 결과 폴더, $Args[1]... = 소스 폴더들
if ($Args.Count -lt 2) {
    # 파라미터가 2개 미만이면(결과폴더+소스폴더 최소 1개), 경고 후 기본값 사용
    Write-Host "[경고] 전달된 파라미터가 부족하여 스크립트 내 기본 경로를 사용합니다." -ForegroundColor Yellow
    $destinationFolder = "C:\Workspace\result"
    $sourceFolderPaths = @(
        "C:\Workspace\The-Forgetting-Village\Assets\Editor",
        "C:\Workspace\The-Forgetting-Village\Assets\Scripts"
    )
} else {
    # 파라미터가 정상적으로 전달된 경우
    $destinationFolder = $Args[0]
    # Select-Object -Skip 1: 첫 번째($Args[0]) 요소를 제외한 나머지 모두를 가져옴
    $sourceFolderPaths = $Args | Select-Object -Skip 1
}
$outputFile = Join-Path -Path $destinationFolder -ChildPath "script_analysis_result.txt"
# --- 파라미터 처리 끝 ---

Clear-Host
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Starting C# script analysis. (Using .NET StreamWriter)"
Write-Host "Excluding files under any '/Deprecated' folder."
Write-Host "======================================================="
Write-Host ""
# --- 디버깅 정보: 실제 사용되는 경로 출력 ---
Write-Host "[INFO] 결과 저장 폴더: $destinationFolder" -ForegroundColor Cyan
Write-Host "[INFO] 분석 대상 폴더:" -ForegroundColor Cyan
$sourceFolderPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
Write-Host ""
# ----------------------------------------

# Create result folder and delete existing file
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    Write-Host "[INFO] Created folder: $destinationFolder" -ForegroundColor Yellow
}
if (Test-Path -Path $outputFile) {
    Remove-Item -Path $outputFile
    Write-Host "[INFO] Deleted existing file: $outputFile" -ForegroundColor Yellow
}

# --- Create .NET StreamWriter Object ---
try {
    $streamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList @($outputFile, $false, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "[ERROR] Could not create or write to the result file: $outputFile" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "오류 발생! Enter 키를 눌러 종료합니다..."
    exit 1
}


Write-Host ""
Write-Host "[PROCESSING] Starting C# file analysis..."
$totalFileCount = 0

try {
    foreach ($folder in $sourceFolderPaths) {
        if (-not (Test-Path $folder)) {
            Write-Host "[WARNING] Source folder not found: $folder" -ForegroundColor Yellow
            continue
        }

        Get-ChildItem -Path $folder -Filter "*.cs" -Recurse | Where-Object { $_.FullName -notlike '*\Deprecated\*' } | ForEach-Object {
            $file = $_
            
            Write-Host "  [Analyzing] $($file.FullName)"
            $totalFileCount++
            
            $streamWriter.WriteLine("============================================================")
            $streamWriter.WriteLine("File Name: $($file.Name)")
            $streamWriter.WriteLine("Path: $($file.FullName)")
            $streamWriter.WriteLine("============================================================")

            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            $contentWithoutComments = $content -replace '(?s)/\*.*?\*/' -replace '//.*'

            # Classes, Structs, Interfaces, Enums
            $classMatches = $contentWithoutComments | Select-String -Pattern '(class|interface|struct|enum)\s+([A-Za-z_][\w]*)' -AllMatches
            if ($classMatches) {
                foreach ($match in $classMatches.Matches) { $streamWriter.WriteLine("[TYPE] $($match.Groups[2].Value) ($($match.Groups[1].Value))") }
            } else { $streamWriter.WriteLine("[TYPE] Not found") }

            # Variables
            $streamWriter.WriteLine("--- Variables ---")
            $variableMatches = $contentWithoutComments.Split([System.Environment]::NewLine) | Select-String -Pattern '^\s*(public|private|protected|internal|static|readonly|const)\s+[\w\.<>\[\]\?]+\s+([A-Za-z_][\w]*)\s*.*?(;|{|=>)'
            if ($variableMatches) {
                foreach ($match in $variableMatches) { $streamWriter.WriteLine("$($match.Line.Trim())") }
            } else { $streamWriter.WriteLine("  (None)") }

            # Methods (and Constructors)
            $streamWriter.WriteLine("--- Methods ---")
            $methodMatches = $contentWithoutComments.Split([System.Environment]::NewLine) | Select-String -Pattern '^\s*(public|private|protected|internal|static|virtual|override|async|new|sealed)?\s*([\w\.<>\[\]\?]+\s+)?([A-Za-z_][\w]*)\s*\('
            $foundMethods = $false
            if ($methodMatches) {
                foreach ($match in $methodMatches) {
                    $methodName = $match.Matches[0].Groups[3].Value.Trim()
                    if ("if", "while", "for", "foreach", "switch", "catch" -notcontains $methodName) {
                        $streamWriter.WriteLine("$($match.Line.Trim())")
                        $foundMethods = $true
                    }
                }
            }
            if (-not $foundMethods) { $streamWriter.WriteLine("  (None)") }
            
            $streamWriter.WriteLine("")
        }
    }
}
finally {
    if ($streamWriter) {
        $streamWriter.Close()
        $streamWriter.Dispose()
    }
}

# --- Final Report ---
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
if ($totalFileCount -gt 0) {
    Write-Host "[SUCCESS] Analysis complete for a total of $totalFileCount C# scripts." -ForegroundColor Green
    Write-Host "Result file: $outputFile"
} else {
    Write-Host "[FAILURE] No .cs files were found to process." -ForegroundColor Red
    Write-Host "Please check if the source paths are correct, or if all files are in 'Deprecated' folders."
}
Write-Host "======================================================="
Write-Host ""
Read-Host "작업 완료. Enter 키를 눌러 창을 닫습니다..."