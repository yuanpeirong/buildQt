# buildQt AI 维护指南

> 本文档面向后续参与本项目的 AI 助手（以及人类维护者），沉淀历次 Qt 版本升级中验证过的流程、约定与踩坑记录。
> **使用方式**：执行 Qt 版本升级 / 工具链升级 / 工作流改造前，先通读本文档，严格遵循其中的约定与流程，可避免重复踩坑。
> 最后验证：2026-11，Qt 6.11.3 与 Qt 6.12.0 已在 llvm-mingw 23.1.5 下全部编译成功。

---

## 1. 项目概述

- **用途**：用 GitHub Actions 从源码自动构建 Qt 的 Windows 静态库二进制版本（开源版），发布 Release 供下载。
- **构建矩阵**：多个编译器线 × 两种产物：
  - **完整版**（无 RP 后缀）：从 `qt-everywhere-src-<版本>.zip`（single 包）构建全部模块（除 qtwebengine）
  - **RP 版**（`_RP` 后缀，Releases Package 精简版）：只构建 qtbase / qttools / qttranslations / qtsvg 四个子模块，从各 submodule zip 分别下载解压
- **仓库结构**：
  - `.github/workflows/buildQt6_*.yml` —— Qt6 工作流（12 个 = 6 条编译器线 × 2）
  - `.github/workflows/buildQt5_*.yml` —— Qt5 工作流（24 个，Qt 5.15.19 为官方终版，通常不再升级）
  - `buildQt6/`、`buildQt5/` —— 本地/CI 共用的编译脚本（.cmd）
  - `README.md` —— 编译器清单与下载链接（**只记录已实际编译验证的版本**）
  - `HistoricalVersions.md` —— 历史版本记录（只增不改）

### 1.1 Qt6 编译器线一览（官方 vs 社区，以 main / 6.12.0 为准）

| 工作流（完整版与 RP 各一个 yml） | FILE_NAME 代号 | 编译器 | 来源 |
|---|---|---|---|
| `buildQt6_MSVC2022.yml` / `_RP.yml` | `msvc2022_64` | MSVC 2022（v17.14） | **Runner 自带**（windows-latest 镜像预装，无需下载编译器） |
| `buildQt6_MSVC2026.yml` / `_RP.yml` | `msvc2026_64` | MSVC 2026（v18.11） | **Runner 自带** |
| `buildQt6_MinGW1510_64.yml` / `_RP.yml` | `mingw1510_64` | MinGW-w64 15.1.0（UCRT） | **Qt 官方**（qtsdkrepository `tools_mingw1510`，Qt 6.12 官方默认编译器） |
| `buildQt6_LLVM-MinGW22.1.7.yml` / `_RP.yml` | `llvm-mingw22.1.7_64_UCRT` | LLVM-MinGW 22.1.7 | **Qt 官方**（qtsdkrepository `tools_llvm_mingw2217`，Qt 6.12 官方默认编译器） |
| `buildQt6_MinGW64.yml` / `_RP.yml` | `mingw1620_64_UCRT` | MinGW-w64 16.2.0-rt_v14-rev1（UCRT，GCC 16.2） | **社区** mingw-builds（niXman / GitHub Releases） |
| `buildQt6_LLVM-MinGW.yml` / `_RP.yml` | `llvm-mingw23.1.5_64_UCRT` | llvm-mingw 23.1.5（20261104，LLVM 23.1.5） | **社区最新** llvm-mingw（mstorsjo / GitHub Releases） |

要点：
- **Qt 官方线**（mingw1510、llvm-mingw22.1.7）随 Qt 版本演进更换：升级 Qt 版本时先查官方是否换了默认编译器（Qt 6.8~6.11 默认 LLVM-MinGW 17.0.6，6.12 起为 22.1.7），换了就按 §5.4 的 qtsdkrepository 模式找新地址、按 §5.3 验证新版 7z 包内部结构，并 `git mv` 工作流/cmd 文件名同步改名。
- **社区 llvm-mingw 线**（llvm-mingw 23.1.5）跟进 mstorsjo 的最新 release，是验证新 libc++ 行为的前哨（§7 的 libc++ 23 补丁经验全部来自这条线）。
- **社区 MinGW64 线**（mingw1620，GCC 16.2 + UCRT + libstdc++）与 Qt 官方 MinGW 线并行提供；libstdc++ 没有 libc++ 那类头文件精简问题。
- **6.11.3 分支的差异**：官方线保留旧名与旧版（`buildQt6_LLVM-MinGW17.0.6.yml` 用官方 17.0.6 包、`buildQt6_MinGW1310_64.yml` 用官方 13.1.0 包），且只需要 releasehelper.h 补丁（无 litehtml 补丁）；社区 llvm-mingw 线同为 23.1.5。
- Qt5 的 24 个工作流（12 线 × 2）为历史线：MSVC（runner 自带）+ Qt 官方 mingw810_64/32、mingw1310 + 社区 mingw-builds（cristianadam 的 11.2.0、niXman 的 12.2.0/13.2.0/14.2.0）。Qt 5.15.19 是官方终版，一般不再升级。

## 2. 分支模型

- `main` —— 稳定基线，保持与最近一次成功构建的版本一致
- **每个 Qt 版本一个分支**（如 `6.11.3`、`6.12.0`），从 `main` 创建后再做版本升级改动
- 工作流为手动触发（`workflow_dispatch`），推分支后在 GitHub 上手动跑
- 分支上的改动经验证（RP 先行）并更新 README 后，合并回 `main`

## 3. 标准升级流程（SOP）

1. **确认新版本可用**：Qt 官方源 `https://download.qt.io/official_releases/qt/<主.次>/<完整版>/` 下已有源码包（用网页抓取或 curl 验证，见 §9）。
2. **建分支**：`git switch -c <版本号> main`（注意：切换前确保当前分支工作区干净，否则未提交改动会跟着走）。
3. **批量替换版本号**（遵循 §6 操作规范）。
4. **核对 Qt 官方工具链**：Qt 每 1~2 个 minor 版本会升级官方默认编译器（见 §5），需下载新 7z 包验证内部结构后同步改工作流与 cmd。
5. **核对 GitHub Actions 组件**是否有新 major（见 §8）。
6. **先跑 RP 工作流**（快），确认能过再跑完整版。
7. **编译验证通过后**才更新 `README.md` 的编译器清单与下载链接（README 只记录已验证构建，勿提前）。
8. 合并回 `main`。

## 4. 版本变量与命名约定（升级时必须同步修改的全部位置）

### 4.1 工作流 yml（每个 Qt6 工作流都有）

| 位置 | 内容 | 示例（6.12.0） |
|------|------|----------------|
| `name:` | `build_Qt<完整版>_<编译器>[_RP]` | `build_Qt6.12.0_LLVM-MinGW_RP` |
| `env.QT_VERSION` | 完整版本号 | `6.12.0` |
| `env.QT_VERSION2` | **主.次两段**（下载 URL 的 minor 目录段） | `'6.12'` |
| `env.FILE_NAME` | 产物名 `static-Release_<编译器代号>[_RP]` | `static-Release_llvm-mingw23.1.5_64_UCRT_RP` |
| 源码下载 URL | `official_releases/qt/${{env.QT_VERSION2}}/${{env.QT_VERSION}}/...` | 变量拼接，一般无需手改 |
| cmd 调用行 | `cmd.exe /c "call "D:\a\buildQt\buildQt\buildQt6\build-Qt6<编译器>[_RP(ninja)].cmd""` | 编译器改名时必须同步 |

**跨 minor 升级（如 6.11.x → 6.12.0）必须同步改 `QT_VERSION2`**；同 minor 的 patch 升级（6.11.2 → 6.11.3）不用改它。

### 4.2 编译脚本 cmd（buildQt6/ 下与 yml 一一对应）

| 变量 | 说明 |
|------|------|
| `SET QT_VERSION=...` | 完整版本号 |
| `SET MinGW_VERSION=...` / `SET LLVM_MinGW_VERSION=...` | 编译器代号（影响 BUILD_DIR / INSTALL_DIR 路径），**RP 版带 `_RP` 后缀** |
| `SET PATH=D:\a\buildQt\<解压目录>\bin;...` | 编译器解压后的 bin 路径（与工具链包结构对应，见 §5） |

### 4.3 其他联动

- 源码包下载文件名 / 临时文件名（`curl -L -o xxx.zip` 与 `unzip -d` 行）
- 文件改名用 `git mv`（保留历史）；yml 内对 cmd 的调用路径与 cmd 文件名必须一致（**历史上漏改过 RP 版带 `_RP(ninja)` 后缀的调用路径**，改名时务必全文件 grep 旧名）

## 5. 源码包与工具链包结构（重点踩坑区）

### 5.1 两种源码包的目录结构不同（源码补丁路径必须与之一致）

| 包 | 顶层目录 | qttools 源码路径 |
|----|---------|------------------|
| single 包 `qt-everywhere-src-<版本>.zip`（完整版用） | `qt-everywhere-src-<版本>/` | `qt-everywhere-src-<版本>\qttools\src\...`（**子模块短名**） |
| submodule 包 `qttools-everywhere-src-<版本>.zip`（RP 版用） | `qttools-everywhere-src-<版本>/` | `qttools-everywhere-src-<版本>\src\...` |

> ⚠️ 给源码打补丁时路径写错一个字，构建会在 PowerShell 步骤直接挂（Get-Content 找不到文件）。历史上完整版补丁曾误写成 RP 版结构导致 CI 失败。

### 5.2 编译器统一解压到 `Tools\<编译器名>` 子目录

- 工作流中统一用 `7z x <包>.7z -oD:\a\buildQt\Tools\<编译器名>` 指定解压目标，cmd 的 PATH 指向 `Tools\<编译器名>\bin`（保持目录惯例统一、不污染 buildQt 根目录）。
- `7z x` 的 `-o` 会**自动创建不存在的多级目标目录**（已实测），无需 mkdir。

### 5.3 新旧工具链 7z 包内部结构不同（不能想当然）

| 包 | 内部结构 |
|----|---------|
| 旧版（llvm_mingw1706、mingw1310 等） | 自带 `Tools\<编译器名>_64\` 前缀目录 → 解压 `-oD:\a\buildQt` 即可 |
| **新版（llvm_mingw2217、mingw1510 起）** | **顶层直接是 `bin\`**（无前缀）→ 必须用 `-o` 指定到 `Tools\<编译器名>_64` |

- 判断方法：下载 7z 包后 `7z l <包>.7z` 列目录（qt.io 可直连下载，见 §9），或从 CI 日志确认。
- ⚠️ **不能从包内 `meta.7z` 的 `installscript.qs` 推断解压结构**——那是 Qt 在线安装器的目标目录层级，与 7z 包内部结构无关（llvm-mingw2217 的教训）。

### 5.4 Qt 官方工具链 URL 模式

```
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_<名>/qt.tools.win64_<名>/<版本>-<时间戳><名>.7z
```

实例（6.12.0 时代已验证）：
- LLVM-MinGW 22.1.7：`tools_llvm_mingw2217/qt.tools.win64_llvm_mingw2217/22.1.7-202608200704llvm_mingw2217.7z`
- MinGW 15.1.0：`tools_mingw1510/qt.tools.win64_mingw1510/15.1.0-202610271023mingw1510.7z`

Qt 官方默认编译器的演进：Qt 6.8~6.11 默认 LLVM-MinGW 17.0.6；**Qt 6.12 起默认 LLVM-MinGW 22.1.7**、MinGW 15.1.0；**CMake 最低要求 Qt 6.12 起提升到 3.25**（GitHub runner 自带 3.31.6，满足）。

### 5.5 社区 llvm-mingw（mstorsjo）

- 下载：`https://github.com/mstorsjo/llvm-mingw/releases/download/<日期>/llvm-mingw-<日期>-ucrt-x86_64.zip`，解压顶层目录同名（`llvm-mingw-<日期>-ucrt-x86_64\bin`）
- release notes 经常为空，升级前需查 LLVM 对应版本的 Clang Release Notes（Potentially Breaking Changes 章节）

## 6. 批量替换操作规范

1. **用字节级替换**（PowerShell `ReadAllBytes`/`WriteAllBytes` + ASCII 模式串），可完整保留文件编码与中文注释（yml/cmd 都含中文注释）。仓库中已有可复用的 `Replace-Bytes` / `Bytes-Equal` 函数写法。
2. 替换模式要**带上下文前缀**（如 `build_Qt6.11.2_`、`SET QT_VERSION=6.11.2`、完整 URL），避免误伤（如 `llvm-mingw17.0.6` 与 LLVM-MinGW 的临时文件名 `llvm_mingw1706.7z` 的包含关系——先替换长模式再替换短模式）。
3. **替换后必做三重验证**：
   - 旧版本字符串全仓库（工作流+cmd 范围）**零残留**（`Select-String -SimpleMatch` 逐模式计数）
   - 新版本**精确计数**（等于预期文件数/出现数）
   - `git diff --stat` 的 insertions 与 deletions **完全对称**（1:1 替换不应改变行数）
4. README 与 HistoricalVersions.md 的处理：README 等**编译验证通过后再更新**；HistoricalVersions 只增不改。

## 7. LLVM 23（libc++）兼容性补丁记录（重要经验）

**背景**：LLVM 23 的 libc++ 做了头文件传递依赖精简（include what you use），会暴露 Qt 源码与捆绑第三方库「使用标准库符号却缺显式 include」的疏漏。报错特征：`use of undeclared identifier 'xxx'`（如 `atoi`、`std::vector`）。

### 7.1 已打补丁清单（位于 llvm-mingw 工作流的 Build Qt 步骤，源码解压后执行）

| 文件 | 缺失 | 补丁 |
|------|------|------|
| `qttools/.../linguist/shared/releasehelper.h` | `<vector>` | 在 `#include <QtCore/qstringlist.h>` 后插入（6.11.3 与 6.12.0 均需要） |
| `qttools/.../qlitehtml/src/3rdparty/litehtml/src/` 下 **9 个文件**：`css_selector.cpp`、`el_before_after.cpp`、`el_font.cpp`、`element.cpp`、`html_microsyntaxes.cpp`、`html_tag.cpp`、`render_block.cpp`、`table.cpp`、`url.cpp` | `<cstdlib>` | 在文件开头插入（仅 6.12.0 需要，6.11.3 的 litehtml 无此问题） |

**补丁实现要求**：PowerShell 幂等写法——`Test-Path` 存在守卫 + `notmatch` 幂等检查 + `Write-Host` patched/skip 日志。文件不存在时跳过并提示，**绝不能让补丁步骤本身挂掉构建**。

### 7.2 ⚠️ 禁用全局强制包含（实证失败）

`SET CXXFLAGS=-include cstdlib`（Qt configure 会读取该环境变量）**不可用**：forced include 会把 stdlib.h 抢到文件最前面，破坏 `qtbase/src/corelib/global/qrandom.cpp` 的 `_CRT_RAND_S` → `#include <stdlib.h>` 顺序依赖，导致 `rand_s` 未声明，qtbase 早期即失败。**只能精准补丁，不要全局注入**。

### 7.3 升级到新 Qt / 新 LLVM 版本时的处理流程

1. 先跑 RP 快速验证；遇 `undeclared identifier` 报错 → 99% 是缺 include 类问题
2. 读日志确认报错文件与符号，从本地源码（用户本地有 zip，见 §9）确认该文件缺哪个头
3. 若同类问题可能批量存在（第三方库），**下载源码包解压后用正则扫描**「使用了 stdlib 函数但缺 include」的文件，一次补全（正则示例：`\b(atoi|atol|strtol|strtod|getenv|qsort|bsearch|srand|rand|malloc|calloc|realloc|exit)\s*\(` 且不含 `include <cstdlib|stdlib.h>`）
4. 上游（qt.io tarball 打包时点）通常晚于 dev 分支修复，新 patch 版本发布后补丁块可移除（但残留无害，补丁均有幂等保护）

## 8. GitHub Actions 组件版本（2026-11 验证）

| 组件 | 当前版本 | 说明 |
|------|---------|------|
| `actions/checkout` | v7 | v7 默认拒绝 fork PR 检出；本仓库全 workflow_dispatch 不受影响 |
| `actions/setup-python` | v7（python-version '3.13'） | v7 无行为变化 |
| `actions/upload-artifact` | v7 | |
| `softprops/action-gh-release` | v3 | v2 跑在 Node 20（已弃用），必须 ≥v3 |
| `microsoft/setup-msbuild` | v3 | |
| `seanmiddleditch/gha-setup-vsdevenv` | @master | 跟随滚动 |

Runner：Qt6 系列用 `windows-latest`（= windows-2025，预装 VS2022 17.14、CMake 3.31.6、Ninja 1.13.2、7-Zip、Perl）；Qt5 系列固定 `windows-2022`。升级 Action 大版本前先查其 release notes 的 breaking changes（输入参数是否变化、Node 运行时要求）。

其他工具：Strawberry Perl 5.42.3.1 portable（`SP_54231_64bit`）；Ninja 1.13.2（已是最新稳定版）；jom 用官方滚动链接 `jom.zip` 无需改。

## 9. 环境与验证技巧

- **本机直连 GitHub 受限**（curl/HEAD 请求 GitHub 域名会失败）：获取 GitHub 资源改用网页抓取工具（webfetch）；**qt.io 可直连**（curl 下载、7z l 验证包结构都可行）。
- **本地源码缓存**：用户本地有已下载的源码 zip（如 `I:\Qt\6.12.0\*.zip`），扫描/分析前先问是否有本地包，避免重复下载（I: 盘在工作区外，工具调用会触发权限确认）。
- URL 有效性验证：qt.io 用 `curl.exe -sIL -w "%{http_code}"` 或下载后看文件大小；GitHub release 资产列表用网页抓取 `releases/expanded_assets/<tag>` 页。
- 扫描第三方库源码：从 zip 提取到工作区临时目录（如 `.tmp-*`，用完即删），7z x 会保留完整嵌套路径。

## 10. 模板化构建路径（2026-11 新增，待 CI 实测验证）

Qt6 的 12 个独立工作流已收敛为「1 份配置 + 2 个工作流 + 1 个参数化脚本」，与旧工作流**并存**；旧 `buildQt6_*.yml` 在新路径验证稳定前仍是默认方式。

### 10.1 新增文件

| 文件 | 作用 |
|------|------|
| `config/compilers-qt6.json` | **单一数据源**：6 条编译器线的全部参数（URL、解压目录、configure 参数原文（逐字取自旧脚本，pre/post 以 `-prefix %INSTALL_DIR%` 为界）、是否装 Perl、是否打 libc++ 补丁、vcvars 路径）。**修改参数前必须先跑 verify 脚本逐字节对拍旧脚本** |
| `.github/workflows/build-qt6.yml` | 调度器：`workflow_dispatch` 输入 qt_version / qt_version2 / mode(full/rp/both)，从 JSON 生成矩阵（12 个任务） |
| `.github/workflows/build-qt6-line.yml` | 可复用单线构建（`workflow_call`）：装 Perl/编译器 → 下载解压源码（带缓存）→ libc++ 补丁 → 调参数化脚本 → 打包 → temp release |
| `buildQt6/build-qt6.cmd` | 参数化编译脚本：ROOT 由 `GITHUB_WORKSPACE` 父目录推导（本地回退按脚本位置上溯两级，不再硬编码 `D:\a\buildQt`）；全部关键步骤带 `\|\| exit /b 1` 门禁 + qmake.exe 产物校验 |

### 10.2 升级流程变化（对照 §3）

- **patch 版本升级**（如 6.12.0 → 6.12.1）：手动触发 `build Qt6 (matrix)`，输入新版本号即可，**不改任何文件**；验证后把 JSON 里的默认值更新为新版本。
- **编译器升级**：只改 `config/compilers-qt6.json` 对应条目（URL、extract_to、path_bin、id）。
- §5（包结构）、§7（libc++ 补丁）的经验已内化为 JSON 字段与 `build-qt6-line.yml` 的模式感知补丁步骤（full/submodule 路径自动区分）。

### 10.3 正式发布与下游联动（promote-release.yml）

- **temp release 保留**：一线一 temp tag，正式整理前资产即可下载（单文件体积大，直接下载方便）；是否清理由人工决定（`delete_temp` 输入默认 `false`）。与下游 buildRedPanda-CPP 不同——下游频率高、tag 固定会冲突，故不发 Release。
- `.github/workflows/promote-release.yml`（手动触发，输入 qt_version/rev/delete_temp）：把该版本所有 `temp_Qt_<版本>-*` release 的资产归集为正式 release `Qt<版本>_<rev>`（默认 `Qt<版本>_rev0`），**取代原人工整理步骤**。
- 建议流程：矩阵跑完 → 手动触发 promote（先不删 temp）→ 核对正式 release 资产齐全 → 下游 buildRedPanda-CPP 在其 Actions 页**手动触发**对应工作流（全部工作流均为手动触发，无事件联动）。

### 10.4 注意事项

- **命名契约不变**：产物 `Qt_<版本>-static-Release_<编译器>[_RP].7z`、temp tag `temp_Qt_<版本>-<FILE_NAME>`，下游 buildRedPanda-CPP 无感知。
- 首次验证建议 mode=rp 先行（沿用 §3 的 RP 先行原则），通过后再跑 both。
- 新脚本的注释一律 ASCII（规避 cmd 在 UTF-8 注释下的解析错位风险，本地实测踩过）；旧脚本中文注释保持不动。
- 编译器 bin 路径由工作流步骤经 `GITHUB_PATH` 注入，脚本内不再做分号拆分（cmd 的 `%VAR:;= %` 在变量未定义时会解析崩溃，实测踩过）。

## 11. 历史升级记录（快照）

| 时间 | 内容 |
|------|------|
| 2026-11 | Action 三件套升级（checkout v7 / setup-python v7 / action-gh-release v3）；Perl 5.42.2.1→5.42.3.1；llvm-mingw 20260616→20261104（LLVM 23.1.5）；Qt 官方线 LLVM-MinGW 17.0.6→22.1.7、MinGW 13.1.0→15.1.0（6.12.0 分支）；Qt 6.11.3、6.12.0 分支建立并全线编译成功，合并 main |
| 2026-11 | 加固改造（main-new 分支）：36 个工作流 curl 加固/timeout/concurrency/Qt源码zip缓存（打包保持 -mx=9 体积优先）；36 个 cmd 加 errorlevel 门禁与 qmake.exe 产物校验（移除 cmd /k）；jom 改 https；新增 §10 模板化构建路径与 promote-release.yml 正式发布自动化 |
| 经验教训 | 见 §5（包结构）、§7（libc++ 23 补丁与 CXXFLAGS 禁用）——**这两节是本项目独有的、网上查不到的实战知识** |

---

*本文档由升级实战沉淀，如流程与实际仓库状态不符，以仓库为准并更新本文档。*
