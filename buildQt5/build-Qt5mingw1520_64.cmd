@chcp 65001
@cd /d %~dp0

:: 设置Qt版本
SET QT_VERSION=5.15.19

:: 设置MinGW版本代号
SET MinGW_VERSION=mingw1520_64_UCRT

:: 设置编译器和Perl
SET PATH=D:\a\buildQt\mingw64\bin;D:\a\buildQt\Strawberry\c\bin;D:\a\buildQt\Strawberry\perl\site\bin;D:\a\buildQt\Strawberry\perl\bin;%PATH%

:: 设置Qt文件夹路径
SET QT_PATH=D:\a\buildQt\Qt

:: 设置线程数
SET NUM_THRED=%NUMBER_OF_PROCESSORS%

::----------以下无需修改----------

:: 设置Qt源代码目录
SET SRC_QT="%QT_PATH%\%QT_VERSION%\qt-everywhere-src-%QT_VERSION%"

::替换qfilesystemengine_win.cpp、main.c(使其可以被高于MinGW GCC8.1.0版本编译)
copy %~dp0\qfilesystemengine_win.cpp %SRC_QT%\qtbase\src\corelib\io\qfilesystemengine_win.cpp /Y || exit /b 1
copy %~dp0\main.c %SRC_QT%\qttools\src\assistant\qcollectiongenerator\main.c /Y || exit /b 1

:: 补充设置qtbase\bin和gnuwin32\bin
SET PATH=%SRC_QT%\qtbase\bin;%SRC_QT%\gnuwin32\bin;%PATH%

:: 设置安装文件夹目录
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-static\%MinGW_VERSION%"

:: 设置build文件夹目录
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%MinGW_VERSION%"

:: 根据需要进行全新构建
rmdir /s /q "%BUILD_DIR%"
:: 定位到构建目录：
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%" || exit /b 1

:: configure
call %SRC_QT%\configure.bat -static -static-runtime -release -prefix %INSTALL_DIR% -nomake examples -nomake tests -skip qtwebengine -opensource -confirm-license -qt-libpng -qt-libjpeg -qt-zlib -qt-pcre -qt-freetype -schannel -opengl desktop -platform win32-g++ -no-feature-d3d12 -skip qtmultimedia -skip qtlocation || exit /b 1

:: 编译、安装
mingw32-make -j%NUM_THRED%          || exit /b 1
mingw32-make install || exit /b 1

::复制qt.conf
copy %~dp0\qt.conf %INSTALL_DIR%\bin || exit /b 1

::@pause
:: 校验构建产物完整性(防止构建失败后发布残缺包)
set CHECK_QMAKE=%INSTALL_DIR:"=%
if not exist "%CHECK_QMAKE%\bin\qmake.exe" (
    echo [ERROR] qmake.exe not found in INSTALL_DIR\bin, build failed.
    exit /b 1
)
