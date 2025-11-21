@echo off
rem UTF-8 인코딩으로 변경하여 한글 깨짐 방지
chcp 65001 > nul
TITLE 분석 스크립트 런처

:: ==================================================================
:: 1단계: 경로 설정 (스크립트 시작 시 한 번만 실행)
:: ==================================================================
:MAIN_MENU
CLS
ECHO.
ECHO ======================================================
ECHO         분석 스크립트 실행기
ECHO ======================================================
ECHO.

:: 출력 경로 입력받기
SET "OUTPUT_PATH="
ECHO [1단계] 결과물을 저장할 출력 경로를 입력하세요.
SET /P OUTPUT_PATH="(입력하지 않으면 현재 폴더): "
IF "%OUTPUT_PATH%"=="" SET "OUTPUT_PATH=."
ECHO.

:: 분석할 경로 입력받기
SET "INPUT_PATHS_ALL="
ECHO [2단계] 분석할 경로를 하나씩 입력하고 Enter를 누르세요.
ECHO         입력을 마치려면 'q'를 입력하고 Enter를 누르세요.
ECHO.
:INPUT_LOOP
SET "INPUT_PATH_CURRENT="
SET /P INPUT_PATH_CURRENT="분석 경로 입력 (완료: q): "
IF /I "%INPUT_PATH_CURRENT%"=="q" GOTO SCRIPT_SELECTION_LOOP
IF NOT "%INPUT_PATH_CURRENT%"=="" SET "INPUT_PATHS_ALL=%INPUT_PATHS_ALL% "%INPUT_PATH_CURRENT%""
GOTO INPUT_LOOP


:: ==================================================================
:: 2단계: 스크립트 선택 루프 (여기서 계속 반복됨)
:: ==================================================================
:SCRIPT_SELECTION_LOOP
CLS
ECHO.
ECHO ------------------------------------------------------
ECHO [현재 설정된 경로]
ECHO   - 출력 경로: %OUTPUT_PATH%
ECHO   - 분석 대상: %INPUT_PATHS_ALL%
ECHO ------------------------------------------------------
ECHO.
ECHO [3단계] 실행할 분석 스크립트를 선택하세요.
ECHO.
ECHO   A. 소스 코드 병합 (모든 .cs 파일 내용을 하나로 합치기)
ECHO   B. 파일 목록 생성 (.cs 파일의 전체 경로 리스트)
ECHO   C. 코드 구조 분석 (클래스, 메서드, 변수 요약)
ECHO   D. 모든 작업 실행 (A, B, C 모두 실행)
ECHO.
ECHO   X. 처음으로 돌아가기 (경로 재설정)
ECHO.

CHOICE /C ABCDX /N /M "선택 (A, B, C, D, X): "

IF ERRORLEVEL 5 GOTO MAIN_MENU   REM X를 누르면 맨 처음으로
IF ERRORLEVEL 4 GOTO RUN_ALL
IF ERRORLEVEL 3 GOTO RUN_C
IF ERRORLEVEL 2 GOTO RUN_B
IF ERRORLEVEL 1 GOTO RUN_A

GOTO SCRIPT_SELECTION_LOOP


:: ==================================================================
:: 3단계: 스크립트 실행 부분
:: ==================================================================
:RUN_A
ECHO.
ECHO combine_cs.bat를 비동기로 실행합니다...
START "분석 스크립트 A" scripts\combine_cs.bat "%OUTPUT_PATH%" %INPUT_PATHS_ALL%
GOTO AFTER_RUN

:RUN_B
ECHO.
ECHO list_cs_files.bat를 비동기로 실행합니다...
START "분석 스크립트 B" scripts\list_cs_files.bat "%OUTPUT_PATH%" %INPUT_PATHS_ALL%
GOTO AFTER_RUN

:RUN_C
ECHO.
ECHO analyze_cs.ps1를 비동기로 실행합니다...
START "분석 스크립트 C" powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { & '.\scripts\analyze_cs.ps1' \"%OUTPUT_PATH%\" %INPUT_PATHS_ALL% } catch { Write-Host '스크립트 실행 중 심각한 오류 발생!' -ForegroundColor Red; Write-Host $_.Exception.ToString(); Read-Host '오류를 확인했습니다. Enter 키를 눌러 창을 닫으세요...' } }"
GOTO AFTER_RUN

:RUN_ALL
ECHO.
ECHO 모든 분석 스크립트(A, B, C)를 비동기로 실행합니다...
START "분석 스크립트 A" scripts\combine_cs.bat "%OUTPUT_PATH%" %INPUT_PATHS_ALL%
START "분석 스크립트 B" scripts\list_cs_files.bat "%OUTPUT_PATH%" %INPUT_PATHS_ALL%
START "분석 스크립트 C" powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { & '.\scripts\analyze_cs.ps1' \"%OUTPUT_PATH%\" %INPUT_PATHS_ALL% } catch { Write-Host '스크립트 실행 중 심각한 오류 발생!' -ForegroundColor Red; Write-Host $_.Exception.ToString(); Read-Host '오류를 확인했습니다. Enter 키를 눌러 창을 닫으세요...' } }"
GOTO AFTER_RUN

:AFTER_RUN
ECHO 스크립트가 새 창에서 시작되었습니다.
ECHO 2초 후 선택 화면으로 돌아갑니다.
TIMEOUT /T 2 /NOBREAK > NUL
GOTO SCRIPT_SELECTION_LOOP