@chcp 65001
@cd /d %~dp0

:: 设置Qt版本
SET QT_VERSION=5.15.16

:: 设置MinGW版本代号
SET MinGW_VERSION=mingw810_64_RP

:: 设置编译器和Perl
SET PATH=D:\a\buildQt\mingw64\bin;D:\a\buildQt\Strawberry\c\bin;D:\a\buildQt\Strawberry\perl\site\bin;D:\a\buildQt\Strawberry\perl\bin;%PATH%

:: 设置Qt文件夹路径
SET QT_PATH=D:\a\buildQt\Qt

:: 设置线程数
SET NUM_THRED=%NUMBER_OF_PROCESSORS%

::----------以下无需修改----------

:: 设置Qt源代码目录
SET SRC_qtbase="%QT_PATH%\%QT_VERSION%\qtbase-everywhere-src-%QT_VERSION%"
SET SRC_qttools="%QT_PATH%\%QT_VERSION%\qttools-everywhere-src-%QT_VERSION%"
SET SRC_qttranslations="%QT_PATH%\%QT_VERSION%\qttranslations-everywhere-src-%QT_VERSION%"
SET SRC_qtsvg="%QT_PATH%\%QT_VERSION%\qtsvg-everywhere-src-%QT_VERSION%"

:: 设置安装文件夹目录
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-static\%MinGW_VERSION%"
SET QMAKE_PATH=%INSTALL_DIR%\bin\qmake.exe

:: 设置build文件夹目录
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%MinGW_VERSION%"

:: 根据需要进行全新构建
rmdir /s /q "%BUILD_DIR%"
:: 定位到构建目录：
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%"

::编译qtbase
mkdir build-qtbase
cd build-qtbase
call %SRC_qtbase%\configure.bat -static -static-runtime -release -nomake examples -prefix %INSTALL_DIR% -opensource -confirm-license -qt-libpng -qt-libjpeg -qt-zlib -qt-pcre -qt-freetype -schannel -recheck-all -opengl desktop -platform win32-g++
mingw32-make -j%NUM_THRED%
mingw32-make install
cd ..

::编译qttools
mkdir build-qttools
cd build-qttools
%QMAKE_PATH% %SRC_qttools%\qttools.pro
mingw32-make -j%NUM_THRED%
mingw32-make install
cd ..

::编译qttranslations
mkdir build-qttranslations
cd build-qttranslations
%QMAKE_PATH% %SRC_qttranslations%\qttranslations.pro
mingw32-make -j%NUM_THRED%
mingw32-make install
cd ..

::编译qtsvg
mkdir build-qtsvg
cd build-qtsvg
%QMAKE_PATH% %SRC_qtsvg%\qtsvg.pro
mingw32-make -j%NUM_THRED%
mingw32-make install
cd ..

::复制qt.conf
copy %~dp0\qt.conf %INSTALL_DIR%\bin

::@pause
@cmd /k cd /d %INSTALL_DIR%
