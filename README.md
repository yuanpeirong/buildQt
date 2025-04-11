# buildQt 从源代码自动构建Qt

## 说明
1. 本项目的主要目的是从源代码构建Qt的二进制版本(使用GithubActions自动构建)
2. 主要针对开源版本的Qt5、Qt6版本
3. 主要构建`Windows版本`(使用`MSVC`、`MinGW64`、`LLVM-MinGW`三大编译器)

## 各分支说明
| 分支 | static/shared | debug/release | 备注
| :----- | :----- | :----- | :-----
| main | static | release | 主要构建64位版本
| shared-release | shared | release | 主要构建64位版本
| shared-debug | shared | debug | 主要构建64位版本
| shared-debug-and-release | shared | debug-and-release | 主要构建64位版本

## 版本
1. 无"RP"版本：从Qt完整源代码构建，构建绝大部分组件
2. 有"RP"版本：从Qt组件源代码构建，目前只构建qtbase、qttools、qttranslations、qtsvg共4个组件

## 仓库地址
1. Github: https://github.com/yuanpeirong/buildQt

## Qt6.9.0 完整版本
1. Qt6.9.0 msvc2022_64
2. Qt6.9.0 MinGW1310_64               (使用Qt官方默认编译器版本)
3. Qt6.9.0 MinGW1420_64(UCRT)    
4. Qt6.9.0 LLVM-MinGW17.0.6(UCRT)     (使用Qt官方默认编译器版本)
5. Qt6.9.0 LLVM-MinGW20.1.2(UCRT)

## Qt6.9.0 RP版本
1. Qt6.9.0 msvc2022_64_RP
2. Qt6.9.0 MinGW1310_64_RP            (使用Qt官方默认编译器版本)
3. Qt6.9.0 MinGW1420_64_RP(UCRT)
4. Qt6.9.0 LLVM-MinGW17.0.6_RP(UCRT)  (使用Qt官方默认编译器版本)
5. Qt6.9.0 LLVM-MinGW20.1.2_RP(UCRT)

## 目前已支持Qt5 完整版本
1. Qt5.15.16 msvc2022_64     
2. Qt5.15.16 MinGW810_64              (使用Qt官方默认编译器版本)
3. ~~Qt5.15.16 MinGW1420_64(UCRT)~~

## Qt5.15.16 完整版本(32位)
1. Qt5.15.16 msvc2022_32     
2. Qt5.15.16 MinGW810_32              (使用Qt官方默认编译器版本)

## Qt5.15.16 RP版本
1. Qt5.15.16 msvc2022_64_RP
2. Qt5.15.16 MinGW810_64_RP           (使用Qt官方默认编译器版本)
3. Qt5.15.16 MinGW1420_64_RP(UCRT)

## Qt6.9.0编译器
1. **msvc2022_64**：Visual Studio 2022 Developer Command Prompt v17.13.2
2. **mingw1310_64**：[13.1.0-202407240918mingw1310.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw1310/qt.tools.win64_mingw1310/13.1.0-202407240918mingw1310.7z) (Qt官方默认编译器版本)
3. **mingw1420_64_UCRT**：[x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev2.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev2/x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev2.7z)
4. **llvm-mingw17.0.6_64_UCRT**：[17.0.6-202409091150llvm_mingw1706.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_llvm_mingw1706/qt.tools.win64_llvm_mingw1706/17.0.6-202409091150llvm_mingw1706.7z)  (Qt官方默认编译器版本)
5. **llvm-mingw20.1.2_64_UCRT**：[llvm-mingw-20250402-ucrt-x86_64.zip](https://github.com/mstorsjo/llvm-mingw/releases/download/20250402/llvm-mingw-20250402-ucrt-x86_64.zip)

## Qt5.15.16编译器
1. **msvc2022_64**：Visual Studio 2022 Developer Command Prompt v17.12.4
2. **mingw1420_64_UCRT**：[x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev1.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev1/x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev1.7z)
3. **mingw810_64**：[8.1.0-1-202411201005x86_64-8.1.0-gdb-11.2.0-release-posix-seh-rt_v6-rev0.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw81/qt.tools.win64_mingw810/8.1.0-1-202411201005x86_64-8.1.0-gdb-11.2.0-release-posix-seh-rt_v6-rev0.7z) (Qt官方默认编译器版本)
4. **mingw810_32**：[8.1.0-1-202411201005i686-8.1.0-gdb-11.2.0-release-posix-dwarf-rt_v6-rev0.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw81/qt.tools.win32_mingw810/8.1.0-1-202411201005i686-8.1.0-gdb-11.2.0-release-posix-dwarf-rt_v6-rev0.7z) (Qt官方默认编译器版本)