@chcp 65001
@cd /d %~dp0

:: ==================== Parameterized Qt6 build script (templated path) ====================
:: Inputs via environment variables (set by build-qt6-line.yml):
::   QT_VERSION   Qt version, e.g. 6.12.0
::   MODE         full or rp
::   COMPILER_ID  compiler id, e.g. llvm-mingw23.1.5_64_UCRT (dir gets _RP suffix in rp mode)
::   LINE_ID      short line id, e.g. llvm-mingw (used for BUILD_DIR name)
::   QT_CONFIGURE_PRE/POST  configure args VERBATIM from the legacy per-line scripts
::                 (full: "call configure.bat <PRE> -prefix <INSTALL_DIR> <POST>",
::                  rp:   "call qtbase\configure.bat <PRE> -prefix <INSTALL_DIR> <POST>")
::   VCVARS       absolute path to vcvarsall.bat (MSVC lines only)
::   PATH_BIN     compiler bin dir relative to ROOT, backslashes (empty for MSVC lines)
:: Version bumps only need workflow inputs; no script edit required.
:: ==============================================================================

:: repo parent dir (runner root, e.g. D:\a\buildQt), derived - no hardcoding
SET ROOT=%~dp0..\..
for %%i in ("%ROOT%") do set "ROOT=%%~fi"
:: in CI prefer GITHUB_WORKSPACE parent (independent of script depth)
if defined GITHUB_WORKSPACE for %%i in ("%GITHUB_WORKSPACE%\..") do set "ROOT=%%~fi"
SET QT_PATH=%ROOT%\Qt

:: MSVC environment (vcvarsall must run before PATH is set, consistent with legacy MSVC script)
IF DEFINED VCVARS IF NOT "%VCVARS%"=="" CALL "%VCVARS%" amd64

:: PATH setting, same order and entries as legacy scripts:
::   MinGW/LLVM lines: <compiler bin>;<ninja>;<Strawberry x3>;%PATH%
::   MSVC lines:       <ninja>;%PATH%   (cl comes from vcvarsall above)
SET INHERIT=%PATH%
SET PATH=%ROOT%\%PATH_BIN%;%ROOT%\ninja;%ROOT%\Strawberry\c\bin;%ROOT%\Strawberry\perl\site\bin;%ROOT%\Strawberry\perl\bin;%INHERIT%
IF NOT DEFINED PATH_BIN SET PATH=%ROOT%\ninja;%INHERIT%

:: product dir id (rp mode appends _RP, same contract as legacy)
SET CID=%COMPILER_ID%
IF /I "%MODE%"=="rp" SET CID=%COMPILER_ID%_RP

:: install dir
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-static\%CID%"

:: build dir (short line id; long dirs exceed the 260-char MAX_PATH limit
:: in qtdeclarative fluentwinui3 dependency files, see 2026-11-08 logs)
SET BDIR=%LINE_ID%
IF /I "%MODE%"=="rp" SET BDIR=%LINE_ID%_RP
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%BDIR%"

:: always start from a clean build dir
rmdir /s /q "%BUILD_DIR%"

IF /I "%MODE%"=="full" goto full
IF /I "%MODE%"=="rp" goto rp
echo [ERROR] unknown MODE: %MODE%
exit /b 1

:full
:: Qt source dir
SET SRC_QT="%QT_PATH%\%QT_VERSION%\qt-everywhere-src-%QT_VERSION%"

:: enter build dir
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%" || exit /b 1

:: configure (args verbatim from legacy line, see QT_CONFIGURE_PRE/POST)
call %SRC_QT%\configure.bat %QT_CONFIGURE_PRE% -prefix %INSTALL_DIR% %QT_CONFIGURE_POST% || exit /b 1

:: build
cmake --build . --parallel || exit /b 1

:: install
ninja install || exit /b 1
goto tail

:rp
:: submodule source dirs
SET SRC_qtbase="%QT_PATH%\%QT_VERSION%\qtbase-everywhere-src-%QT_VERSION%"
SET SRC_qttools="%QT_PATH%\%QT_VERSION%\qttools-everywhere-src-%QT_VERSION%"
SET SRC_qttranslations="%QT_PATH%\%QT_VERSION%\qttranslations-everywhere-src-%QT_VERSION%"
SET SRC_qtsvg="%QT_PATH%\%QT_VERSION%\qtsvg-everywhere-src-%QT_VERSION%"

:: enter build dir
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%" || exit /b 1

::build qtbase
mkdir build-qtbase && cd build-qtbase || exit /b 1
call %SRC_qtbase%\configure.bat %QT_CONFIGURE_PRE% -prefix %INSTALL_DIR% %QT_CONFIGURE_POST% || exit /b 1
cmake --build . --parallel || exit /b 1
ninja install || exit /b 1
cd ..

::build qttools
mkdir build-qttools && cd build-qttools || exit /b 1
cmake %SRC_qttools% -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%INSTALL_DIR% || exit /b 1
cmake --build . --parallel || exit /b 1
ninja install || exit /b 1
cd ..

::build qttranslations
mkdir build-qttranslations && cd build-qttranslations || exit /b 1
cmake %SRC_qttranslations% -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%INSTALL_DIR% || exit /b 1
cmake --build . --parallel || exit /b 1
ninja install || exit /b 1
cd ..

::build qtsvg
mkdir build-qtsvg && cd build-qtsvg || exit /b 1
cmake %SRC_qtsvg% -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%INSTALL_DIR% || exit /b 1
cmake --build . --parallel || exit /b 1
ninja install || exit /b 1
cd ..

:tail
:: copy qt.conf (quote-stripped dest)
SET CHECK_QMAKE=%INSTALL_DIR:"=%
copy %~dp0qt.conf "%CHECK_QMAKE%\bin\qt.conf" /Y || exit /b 1

:: sanity check: fail loudly if qmake.exe missing
if not exist "%CHECK_QMAKE%\bin\qmake.exe" (
    echo [ERROR] qmake.exe not found in INSTALL_DIR\bin, build failed.
    exit /b 1
)
