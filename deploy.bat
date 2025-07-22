@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ============================
REM === EDIT BELOW ONCE ========
REM ============================
set "GH_USER=nccu-dorm-j23"
set "GH_REPO=parcel-system"
set "GH_BRANCH=main"
REM ============================

echo.
echo ===========================================
echo   GitHub Pages 自動部署批次檔
echo   Repo: %GH_USER%/%GH_REPO%
echo   Branch: %GH_BRANCH%
echo ===========================================
echo.

REM --- 切換到本批次檔所在目錄 ---
cd /d "%~dp0" || (
    echo [錯誤] 找不到批次檔所在資料夾。中止。
    pause
    exit /b 1
)

REM --- 檢查 Git ---
where git >nul 2>&1
if errorlevel 1 (
    echo [錯誤] 找不到 Git。請先安裝 https://git-scm.com 。
    pause
    exit /b 1
)

REM --- 初始化 git（若尚未 init） ---
if not exist ".git" (
    echo [資訊] 尚未初始化 Git，正在執行 git init...
    git init
)

REM --- 確保在主分支 ---
git rev-parse --abbrev-ref HEAD >nul 2>&1
if errorlevel 1 (
    echo [資訊] 建立初始分支 %GH_BRANCH%...
    git checkout -b %GH_BRANCH%
) else (
    for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD') do set CUR_BRANCH=%%B
    if /i not "!CUR_BRANCH!"=="%GH_BRANCH%" (
        echo [資訊] 切換/建立分支 %GH_BRANCH%...
        git checkout -B %GH_BRANCH%
    )
)

REM --- 設定遠端 origin（若尚未設定） ---
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [資訊] 設定遠端 origin -> https://github.com/%GH_USER%/%GH_REPO%.git
    git remote add origin https://github.com/%GH_USER%/%GH_REPO%.git
) else (
    echo [資訊] 已存在遠端 origin。
)

REM --- 嘗試拉取遠端（避免 README 衝突） ---
echo [資訊] 嘗試從遠端拉取（若是新 repo 無需理會錯誤）...
git pull origin %GH_BRANCH% --allow-unrelated-histories --no-rebase --no-edit >nul 2>&1

REM --- 加入所有檔案 ---
echo [資訊] 加入所有變更...
git add -A

REM --- 建立 Commit（如無變更會失敗，允許） ---
for /f "tokens=* delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
git commit -m "Deploy %TS%" >nul 2>&1
if errorlevel 1 (
    echo [資訊] 沒有新變更需要提交。
) else (
    echo [資訊] 已建立 Commit。
)

REM --- 推送到 GitHub ---
echo [資訊] 推送到 GitHub (%GH_BRANCH%) ...
git push -u origin %GH_BRANCH%
if errorlevel 1 (
    echo.
    echo [⚠ 錯誤] 推送失敗。常見原因：
    echo   1. GitHub 尚未建立 repo %GH_REPO%
    echo   2. 沒有權限（需登入 GitHub 或使用 Token）
    echo   3. 網路問題
    echo.
    pause
    exit /b 1
)

echo.
echo ===========================================
echo   推送完成！
echo ===========================================
echo.

REM --- 顯示 GitHub Pages URL ---
echo 如果你已在 GitHub Settings > Pages 啟用 Pages，
echo 公開網址會是：
echo    https://%GH_USER%.github.io/%GH_REPO%/
echo.

REM --- 快速開啟 GitHub Pages 設定頁 ---
choice /m "要開啟 GitHub Pages 設定頁嗎？"
if errorlevel 1 (
    start "" "https://github.com/%GH_USER%/%GH_REPO%/settings/pages"
)

echo.
pause
endlocal
