@chcp 65001
@cd /d %~dp0

:: 设置Qt版本
SET QT_VERSION=6.8.3

:: 设置MinGW版本代号
SET MinGW_VERSION=mingw1310_64

:: 设置编译器和Ninja
SET PATH=D:\a\buildQt\Tools\mingw1310_64\bin;D:\a\buildQt\ninja;%PATH%

:: 设置Qt文件夹路径
SET QT_PATH=D:\a\buildQt\Qt

::----------以下无需修改----------

:: 设置Qt源代码目录
SET SRC_QT="%QT_PATH%\%QT_VERSION%\qt-everywhere-src-%QT_VERSION%"

:: 设置安装文件夹目录
SET INSTALL_DIR="%QT_PATH%\%QT_VERSION%-shared\%MinGW_VERSION%"

:: 设置build文件夹目录
SET BUILD_DIR="%QT_PATH%\%QT_VERSION%\build-%MinGW_VERSION%"

:: 根据需要进行全新构建
rmdir /s /q "%BUILD_DIR%"
:: 定位到构建目录：
mkdir "%BUILD_DIR%" && cd /d "%BUILD_DIR%"

:: configure
call %SRC_QT%\configure.bat -shared -debug-and-release -prefix %INSTALL_DIR% -nomake examples -nomake tests -skip qtwebengine -opensource -confirm-license -qt-libpng -qt-libjpeg -qt-zlib -qt-pcre -qt-freetype -schannel -platform win32-g++ -no-sql-psql

:: 编译(不要忘记点)
cmake --build . --parallel

:: 安装(注：cmake --install .会导致安装不完整)
ninja install

::复制qt.conf
copy %~dp0\qt.conf %INSTALL_DIR%\bin

::@pause
@cmd /k cd /d %INSTALL_DIR%
