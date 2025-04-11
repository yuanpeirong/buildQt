@chcp 65001
@cd /d %~dp0

:: 设置Qt版本
SET QT_VERSION=6.9.0

:: 设置MinGW版本代号
SET MinGW_VERSION=mingw1420_64_UCRT_RP

:: 设置编译器和Ninja
SET PATH=D:\a\buildQt\mingw64\bin;D:\a\buildQt\ninja;%PATH%

:: 设置Qt文件夹路径
SET QT_PATH=D:\a\buildQt\Qt

::----------以下无需修改----------

:: 设置Qt源代码目录
SET SRC_qtbase="%QT_PATH%\%QT_VERSION%\qtbase-everywhere-src-%QT_VERSION%"
SET SRC_qttools="%QT_PATH%\%QT_VERSION%\qttools-everywhere-src-%QT_VERSION%"
SET SRC_qttranslations="%QT_PATH%\%QT_VERSION%\qttranslations-everywhere-src-%QT_VERSION%"
SET SRC_qtsvg="%QT_PATH%\%QT_VERSION%\qtsvg-everywhere-src-%QT_VERSION%"

:: 设置安装文件夹目录
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-shared\%MinGW_VERSION%"

:: 设置build文件夹目录
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%MinGW_VERSION%"

:: 根据需要进行全新构建
rmdir /s /q "%BUILD_DIR%"
:: 定位到构建目录：
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%"

::编译qtbase
mkdir build-qtbase
cd build-qtbase
call %SRC_qtbase%\configure.bat -shared -debug-and-release -nomake examples -prefix %INSTALL_DIR% -opensource -confirm-license -qt-libpng -qt-libjpeg -qt-zlib -qt-pcre -qt-freetype -schannel -opengl desktop -platform win32-g++ -no-sql-psql
cmake --build . --parallel
ninja install
cd ..

::编译qttools
mkdir build-qttools
cd build-qttools
cmake %SRC_qttools%\CMakeLists.txt -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_PREFIX_PATH=%INSTALL_DIR%\lib\cmake"
cmake --build . --parallel
ninja install
cd ..

::编译qttranslations
mkdir build-qttranslations
cd build-qttranslations
cmake %SRC_qttranslations%\CMakeLists.txt -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_PREFIX_PATH=%INSTALL_DIR%\lib\cmake"
cmake --build . --parallel
ninja install
cd ..

::编译qtsvg
mkdir build-qtsvg
cd build-qtsvg
cmake %SRC_qtsvg%\CMakeLists.txt -G "Ninja" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DCMAKE_PREFIX_PATH=%INSTALL_DIR%\lib\cmake"
cmake --build . --parallel
ninja install
cd ..

::复制qt.conf
copy %~dp0\qt.conf %INSTALL_DIR%\bin

::@pause
@cmd /k cd /d %INSTALL_DIR%
