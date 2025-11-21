@ECHO OFF
TITLE C# 파일 목록 생성 중...
rem UTF-8 인코딩으로 변경하여 한글 깨짐 방지
chcp 65001 > nul

setlocal

rem --- 파라미터 처리 ---
rem 첫 번째 파라미터: 결과물 저장 경로
set "destinationFolder=%~1"
rem 결과 파일 전체 경로 설정 (파일 이름 변경: script_list.txt)
set "outputFile=%destinationFolder%\script_list.txt"

rem 파라미터가 없으면 오류 메시지 후 종료
if "%destinationFolder%"=="" (
    echo [오류] 결과물 저장 경로가 전달되지 않았습니다.
    echo 사용법: list_cs_files.bat [결과폴더] [분석폴더1] [분석폴더2] ...
    pause
    exit /b 1
)

rem 파라미터 리스트에서 첫 번째(destinationFolder)를 제거
SHIFT

rem 분석할 폴더가 하나도 없으면 오류 메시지 후 종료
if "%1"=="" (
    echo [오류] 분석할 소스 폴더가 하나 이상 전달되어야 합니다.
    pause
    exit /b 1
)
rem --------------------

echo.
echo =======================================================
echo C# 스크립트 파일 목록 생성을 시작합니다 (하위 폴더 포함).
echo "/Deprecated" 폴더는 제외됩니다.
echo =======================================================
echo.
echo   결과 저장 위치: %destinationFolder%
echo.

rem 결과 폴더가 없으면 생성
if not exist "%destinationFolder%" (
    mkdir "%destinationFolder%"
    echo "[알림] %destinationFolder% 폴더를 생성했습니다."
)

rem 기존 출력 파일이 있으면 삭제
if exist "%outputFile%" (
    del "%outputFile%"
    echo "[알림] 기존 %outputFile% 파일을 삭제했습니다."
)

rem 파일 카운터 초기화
set fileCount=0

rem --- 전달받은 모든 소스 폴더에 대해 반복 처리 ---
:SOURCE_FOLDER_LOOP
rem 더 이상 처리할 소스 폴더가 없으면 루프 종료
if "%1"=="" goto :PROCESSING_DONE

echo.
echo "[처리중] '%~1' 폴더 및 하위 폴더에서 .cs 파일을 검색합니다..."
for /r "%~1" %%f in (*.cs) do (
    rem '%%f' 변수(파일의 전체 경로)에 "\Deprecated" 문자열이 포함되어 있는지 확인
    echo "%%f" | findstr /i /c:"\Deprecated" > nul
    
    rem findstr이 문자열을 찾지 못하면 errorlevel이 1이 됨 (즉, Deprecated가 아님)
    if errorlevel 1 (
        rem 정상 처리
        echo "[발견] %%~nxf 파일 처리 중..."
        rem 파일명과 경로를 출력 파일에 저장
        (
            echo 파일명: %%~nxf
            echo 경로: %%f
            echo.
        ) >> "%outputFile%"
        set /a fileCount+=1
    ) else (
        rem Deprecated 폴더이므로 무시
        echo "[무시] Deprecated 폴더의 파일입니다: %%~nxf"
    )
)

rem 다음 소스 폴더 파라미터로 이동
SHIFT
goto :SOURCE_FOLDER_LOOP
rem ----------------------------------------------------

:PROCESSING_DONE
echo.
echo =======================================================
if %fileCount% gtr 0 (
    echo [성공] 총 %fileCount%개의 .cs 파일 경로가 아래 파일로 저장되었습니다.
    echo "%outputFile%"
) else (
    echo [경고] 처리할 .cs 파일을 찾지 못했습니다.
    echo 소스 폴더 경로가 정확한지, 또는 모든 파일이 Deprecated 폴더에 있는 건 아닌지 확인해주세요.
)
echo =======================================================
echo.
echo 이 창은 10초 후 자동으로 닫힙니다.
timeout /t 10 > nul
exit