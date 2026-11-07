@chcp 65001
@cd /d %~dp0

:: ==================== Parameterized Qt6 build script (templated path) ====================
:: Inputs via environment variables (set by build-qt6-line.yml):
::   QT_VERSION   full Qt version, e.g. 6.12.0
::   MODE         full or rp
::   COMPILER_ID  compiler id, e.g. llvm-mingw23.1.5_64_UCRT (dir gets _RP suffix in rp mode)
::   QT_CONFIGURE_PRE/POST  configure args VERBATIM from the legacy per-line scripts
::                 (full: "call configure.bat <PRE> -prefix <INSTALL_DIR> <POST>",
::                  rp:   "call qtbase\configure.bat <PRE> -prefix <INSTALL_DIR> <POST>")
::   VCVARS       absolute path to vcvarsall.bat (MSVC lines only)
:: Compiler bin dirs are injected via GITHUB_PATH by the workflow steps.
:: Version bumps only need workflow inputs; no script edit required.
:: ==============================================================================

:: repo parent dir (runner root, e.g. D:\a\buildQt), derived - no hardcoding
:: script sits at <root>/<repo>/buildQt6/, so two levels up from script dir
set ROOT=%~dp0..\..
for %%i in ("%ROOT%") do set ROOT=%%~fi
:: in CI prefer GITHUB_WORKSPACE parent (independent of script depth)
if defined GITHUB_WORKSPACE for %%i in ("%GITHUB_WORKSPACE%\..") do set ROOT=%%~fi
set QT_PATH=%ROOT%\Qt

:: Ninja and Perl dirs
set PATH=%ROOT%\ninja;%ROOT%\Strawberry\c\bin;%ROOT%\Strawberry\perl\site\bin;%ROOT%\Strawberry\perl\bin;%PATH%


:: MSVC environment
if defined VCVARS if not "%VCVARS%"=="" call "%VCVARS%" amd64

:: product dir id (rp mode appends _RP, same contract as legacy)
set CID=%COMPILER_ID%
if /i "%MODE%"=="rp" set CID=%COMPILER_ID%_RP

:: install dir
set INSTALL_DIR="%QT_PATH%\%QT_VERSION%-static\%CID%"

:: build dir
set BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%CID%"

:: always start from a clean build dir
rmdir /s /q "%BUILD_DIR%"

if /i "%MODE%"=="full" goto full
if /i "%MODE%"=="rp" goto rp
echo [ERROR] unknown MODE: %MODE%
exit /b 1

:full
:: Qt source dir
set SRC_QT="%QT_PATH%\%QT_VERSION%\qt-everywhere-src-%QT_VERSION%"

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
set SRC_qtbase="%QT_PATH%\%QT_VERSION%\qtbase-everywhere-src-%QT_VERSION%"
set SRC_qttools="%QT_PATH%\%QT_VERSION%\qttools-everywhere-src-%QT_VERSION%"
set SRC_qttranslations="%QT_PATH%\%QT_VERSION%\qttranslations-everywhere-src-%QT_VERSION%"
set SRC_qtsvg="%QT_PATH%\%QT_VERSION%\qtsvg-everywhere-src-%QT_VERSION%"

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
set CHECK_QMAKE=%INSTALL_DIR:"=%
copy %~dp0qt.conf "%CHECK_QMAKE%\bin\qt.conf" /Y || exit /b 1

:: sanity check: fail loudly if qmake.exe missing
if not exist "%CHECK_QMAKE%\bin\qmake.exe" (
    echo [ERROR] qmake.exe not found in INSTALL_DIR\bin, build failed.
    exit /b 1
)
