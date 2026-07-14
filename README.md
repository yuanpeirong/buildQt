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

## Qt6.11.1 完整版本(rev1)
1. Qt6.11.1 msvc2022_64
2. Qt6.11.1 msvc2026_64
3. Qt6.11.1 MinGW1310_64              (使用Qt6.8+官方默认编译器版本)
4. Qt6.11.1 MinGW1610_64(UCRT)   
5. Qt6.11.1 LLVM-MinGW17.0.6(UCRT)     (使用Qt6.8+官方默认编译器版本)
6. Qt6.11.1 LLVM-MinGW22.1.8(UCRT)

## Qt6.11.1 RP版本(rev1)
1. Qt6.11.1 msvc2022_64_RP
2. Qt6.11.1 msvc2026_64_RP
3. Qt6.11.1 MinGW1310_64_RP            (使用Qt6.8+官方默认编译器版本)
4. Qt6.11.1 MinGW1610_64_RP(UCRT)
5. Qt6.11.1 LLVM-MinGW17.0.6_RP(UCRT)  (使用Qt6.8+官方默认编译器版本)
6. Qt6.11.1 LLVM-MinGW22.1.8_RP(UCRT)

## Qt5.15.19 完整版本(64位)
1. Qt5.15.19 msvc2022_64
2. Qt5.15.19 msvc2026_64
3. Qt5.15.19 MinGW810_64              (使用Qt5.15官方默认编译器版本)
4. Qt5.15.19 MinGW1120_64             (使用Qt6.3官方默认编译器版本)
5. Qt5.15.19 MinGW1220_64
6. Qt5.15.19 MinGW1310_64             (使用Qt6.8+官方默认编译器版本)
7. Qt5.15.19 MinGW1320_64(UCRT)
8. Qt5.15.19 MinGW1420_64(UCRT)
9. Qt5.15.19 MinGW1520_64(UCRT)
10. Qt5.15.19 MinGW1610_64(UCRT)

## Qt5.15.19 完整版本(32位)
1. Qt5.15.19 msvc2022_32
2. Qt5.15.19 msvc2026_32
3. Qt5.15.19 MinGW810_32              (使用Qt5.15官方默认编译器版本)

## Qt5.15.19 RP版本
1. Qt5.15.19 msvc2022_64_RP
2. Qt5.15.19 msvc2026_64_RP
3. Qt5.15.19 MinGW810_64_RP              (使用Qt5.15官方默认编译器版本)
4. Qt5.15.19 MinGW1120_64_RP             (使用Qt6.3官方默认编译器版本)
5. Qt5.15.19 MinGW1220_64_RP
6. Qt5.15.19 MinGW1310_64_RP             (使用Qt6.8+官方默认编译器版本)
7. Qt5.15.19 MinGW1320_64_RP(UCRT)
8. Qt5.15.19 MinGW1420_64_RP(UCRT)
9. Qt5.15.19 MinGW1520_64_RP(UCRT)
10. Qt5.15.19 MinGW1610_64_RP(UCRT)

## Qt6.11.1 编译器(rev1)
1. **msvc2022_64**：Visual Studio 2022 Developer Command Prompt v17.14.35
2. **msvc2026_64**：Visual Studio 2026 Developer Command Prompt v18.7.2
3. **mingw1310_64**：[13.1.0-202407240918mingw1310.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw1310/qt.tools.win64_mingw1310/13.1.0-202407240918mingw1310.7z) (Qt6.8+官方默认编译器版本)
4. **mingw1610_64_UCRT**：[x86_64-16.1.0-release-posix-seh-ucrt-rt_v14-rev1.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/16.1.0-rt_v14-rev1/x86_64-16.1.0-release-posix-seh-ucrt-rt_v14-rev1.7z)
5. **llvm-mingw17.0.6_64_UCRT**：[17.0.6-202409091150llvm_mingw1706.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_llvm_mingw1706/qt.tools.win64_llvm_mingw1706/17.0.6-202409091150llvm_mingw1706.7z)  (Qt6.8+官方默认编译器版本)
6. **llvm-mingw22.1.8_64_UCRT**：[llvm-mingw-20260616-ucrt-x86_64.zip](https://github.com/mstorsjo/llvm-mingw/releases/download/20260616/llvm-mingw-20260616-ucrt-x86_64.zip)

## Qt5.15.19 编译器
1. **msvc2022_64**：Visual Studio 2022 Developer Command Prompt v17.14.33
2. **msvc2026_64**：Visual Studio 2026 Developer Command Prompt v18.6.2
3. **mingw810_64**：[8.1.0-1-202411201005x86_64-8.1.0-gdb-11.2.0-release-posix-seh-rt_v6-rev0.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw81/qt.tools.win64_mingw810/8.1.0-1-202411201005x86_64-8.1.0-gdb-11.2.0-release-posix-seh-rt_v6-rev0.7z) (Qt5.15官方默认编译器版本)
4. **mingw810_32**：[8.1.0-1-202411201005i686-8.1.0-gdb-11.2.0-release-posix-dwarf-rt_v6-rev0.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw81/qt.tools.win32_mingw810/8.1.0-1-202411201005i686-8.1.0-gdb-11.2.0-release-posix-dwarf-rt_v6-rev0.7z) (Qt5.15官方默认编译器版本)
5. **mingw1120_64**：[x86_64-11.2.0-release-posix-seh-rt_v9-rev3.7z](https://github.com/cristianadam/mingw-builds/releases/download/v11.2.0-rev3/x86_64-11.2.0-release-posix-seh-rt_v9-rev3.7z) (Qt6.3官方默认编译器版本)
6. **mingw1220_64**：[x86_64-12.2.0-release-posix-seh-msvcrt-rt_v10-rev2.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/12.2.0-rt_v10-rev2/x86_64-12.2.0-release-posix-seh-msvcrt-rt_v10-rev2.7z)
7. **mingw1310_64**：[13.1.0-202407240918mingw1310.7z](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw1310/qt.tools.win64_mingw1310/13.1.0-202407240918mingw1310.7z) (Qt6.8+官方默认编译器版本)
8. **mingw1320_64_UCRT**：[x86_64-13.2.0-release-posix-seh-ucrt-rt_v11-rev1.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/13.2.0-rt_v11-rev1/x86_64-13.2.0-release-posix-seh-ucrt-rt_v11-rev1.7z)
9. **mingw1420_64_UCRT**：[x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev2.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev2/x86_64-14.2.0-release-posix-seh-ucrt-rt_v12-rev2.7z)
10. **mingw1520_64_UCRT**：[x86_64-15.2.0-release-posix-seh-ucrt-rt_v13-rev1.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev1/x86_64-15.2.0-release-posix-seh-ucrt-rt_v13-rev1.7z)
11. **mingw1610_64_UCRT**：[x86_64-16.1.0-release-posix-seh-ucrt-rt_v14-rev1.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/16.1.0-rt_v14-rev1/x86_64-16.1.0-release-posix-seh-ucrt-rt_v14-rev1.7z)
