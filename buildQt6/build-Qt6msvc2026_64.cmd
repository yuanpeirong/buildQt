@chcp 65001
@cd /d %~dp0

:: 设置Qt版本
SET QT_VERSION=6.12.0

:: 设置MSVC版本代号
SET MSVC_VERSION=msvc2026_64

:: 设置MSVC2026环境
CALL "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64

:: 设置Ninja
SET PATH=D:\a\buildQt\ninja;%PATH%

:: 设置Qt文件夹路径
SET QT_PATH=D:\a\buildQt\Qt

::----------以下无需修改----------

:: 设置Qt源代码目录
SET SRC_QT="%QT_PATH%\%QT_VERSION%\qt-everywhere-src-%QT_VERSION%"

:: 设置安装文件夹目录
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-static\%MSVC_VERSION%"

:: 设置build文件夹目录
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%MSVC_VERSION%"

:: 根据需要进行全新构建
rmdir /s /q "%BUILD_DIR%"
:: 定位到构建目录：
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%" || exit /b 1

:: configure
call %SRC_QT%\configure.bat -static -static-runtime -release -prefix %INSTALL_DIR% -nomake examples -nomake tests -skip qtwebengine -opensource -confirm-license -qt-libpng -qt-libjpeg -qt-zlib -qt-pcre -qt-freetype -qt-harfbuzz -qt-webp -qt-tiff -schannel -opengl desktop -platform win32-msvc -skip qtconnectivity -skip qtspeech || exit /b 1

:: 编译(不要忘记点)
cmake --build . --parallel || exit /b 1

:: 安装(取代cmake --install .)
ninja install || exit /b 1

::复制qt.conf
copy %~dp0\qt.conf %INSTALL_DIR%\bin || exit /b 1

::@pause
:: 校验构建产物完整性(防止构建失败后发布残缺包)
set CHECK_QMAKE=%INSTALL_DIR:"=%
if not exist "%CHECK_QMAKE%\bin\qmake.exe" (
    echo [ERROR] qmake.exe not found in INSTALL_DIR\bin, build failed.
    exit /b 1
)
