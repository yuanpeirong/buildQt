# PROJECT_MAP.md — buildQt 项目地图

> 生成于 2026-11-13（main-new @ c6086d4），是后续所有会话的唯一入口，**不要重扫仓库**。
> 详细背景看 `AI_MAINTENANCE_GUIDE.md`（下称 Guide）；本文与其冲突时以仓库/Guide 为准并更新本文。
> 配套仓库：`D:\Code\GitHub\buildRedPanda-CPP`（下游，消费本仓库 Release）。

## ① 一句话概览

纯 GitHub Actions 仓库（无本地可构建程序）：从 Qt 官方源码静态构建 **Qt 5.15.19 / Qt 6.12.0** 的 Windows 静态库（6 条编译器线 × 完整版/RP 精简版），发 Release 供下游 buildRedPanda-CPP 使用；main-new 分支在原 36 个逐线工作流之外新增了**模板化构建路径**（JSON 数据源 + 矩阵调度 + 参数化脚本），双轨并存。

## ② 常用命令

无本地构建/测试/自检命令——一切构建在 CI 上手动触发（全部 `workflow_dispatch`，无 push/PR 联动）。

| 操作 | 方式 |
|---|---|
| 触发 Qt6 构建（新路径） | Actions 页 → **build Qt6 (matrix)** → 输入 `qt_version`/`qt_version2`/`mode`(full/rp/both)/`lines`(如 `msvc2022,llvm-mingw_RP`，无后缀=完整版，`_RP`=RP 版，`_both`=两者，留空=全部)。升级版本**不改文件** |
| 触发旧路径构建 | Actions 页 → `build_Qt<版本>_<编译器>[_RP]`（36 个逐线工作流） |
| 归集正式发布 | Actions 页 → **promote temp releases to formal release** → 输入 `qt_version`/`rev`(默认 rev0)/`delete_temp`(默认 false)；把 `temp_Qt_<版本>-*` 资产归集为 `Qt<版本>_<rev>` |
| 本地验证 URL / 包结构 | qt.io 可直连：`curl.exe -sIL -w "%{http_code}" <url>`、`7z l <包>.7z`；GitHub 域名本机受限，改用网页抓取 |
| 版本号批量替换（旧路径升级） | PowerShell `ReadAllBytes`/`WriteAllBytes` 字节级替换（保留中文注释），替换后三重验证：旧串零残留、新串精确计数、`git diff --stat` 增删行数完全对称（Guide §6） |
| 对拍新旧脚本 | 展开比对产物在 `.tmp/expand/`（未跟踪，临时）；改 `config/compilers-qt6.json` 前必须与旧 cmd 逐字节对拍 |
| git | 改名一律 `git mv`；分支模型：`main` 稳定基线，每个 Qt 版本一个分支（`6.12.0` 等），验证后合回 |

## ③ 目录与文件职责

### `.github/workflows/`（39 个 yml）

| 文件 | 职责 | 约行 |
|---|---|---|
| `build-qt6.yml` | **新路径调度器**：输入版本/模式/线过滤，从 JSON 生成矩阵，逐线调用 reusable 工作流 | 133 |
| `build-qt6-line.yml` | **可复用单线构建**（workflow_call）：装 Perl/编译器/Ninja → 下载解压源码（actions/cache 缓存 zip）→ libc++ 补丁 → 调参数化 cmd → 打包 `7z a -mx=9` → artifact + temp release | 268 |
| `promote-release.yml` | 把某版本所有 temp release 资产归集为正式 release `Qt<版本>_<rev>`；`delete_temp` 默认 false，人工清理 | 79 |
| `buildQt6_*.yml` ×12 | **旧 Qt6 逐线工作流**（6 线 × 完整/RP）：env 定 QT_VERSION/QT_VERSION2/FILE_NAME，内联下载/补丁，`cmd.exe` 调 buildQt6 下对应 cmd | 102–142 |
| `buildQt5_*.yml` ×24 | **Qt5 逐线工作流**（12 线 × 2，5.15.19 冻结线）：结构与 Qt6 旧版同构 | 98–111 |

命名注意：工作流文件名 `buildQt6_MinGW64.yml` / `buildQt6_LLVM-MinGW.yml` 是**缩写**，实际编译器代号分别为 `mingw1620_64_UCRT`、`llvm-mingw23.1.5_64_UCRT`（以 `FILE_NAME` 为准）。

### `config/`

| 文件 | 职责 | 约行 |
|---|---|---|
| `compilers-qt6.json` | **Qt6 单一数据源**：6 条编译器线全部参数（COMPILER_URL、解压目录、PATH_BIN、VCVARS、NEEDS_PERL、LIBCPP_PATCH、CONFIGURE full/rp 的 PRE/POST 原文）。configure 参数逐字取自旧脚本，**改前必对拍** | 161 |

### `buildQt6/`（12 个旧 cmd + 1 个新脚本 + qt.conf）

| 文件 | 职责 | 约行 |
|---|---|---|
| `build-qt6.cmd` | **参数化编译脚本（新路径）**：ROOT 由 GITHUB_WORKSPACE 推导（本地按脚本位置上溯）；vcvars→PATH→BUILD_DIR(短 line id)→full=configure.bat+cmake --build+ninja install / rp=qtbase configure 后 qttools/qttranslations/qtsvg 各 cmake+Ninja；qt.conf 拷贝 + qmake.exe 校验。每步 `\|\| exit /b 1` 门禁 | 120 |
| `build-Qt6<编译器>.cmd` ×6 | 旧完整版逐线脚本：硬编码 `D:\a\buildQt` 路径、configure 原文、cmake --build + ninja install | ~50 |
| `build-Qt6<编译器>_RP(ninja).cmd` ×6 | 旧 RP 逐线脚本（**文件名带 `(ninja)`**，Qt5 的 RP 不带——命名沿用 main 原文勿"修"）；qtbase 用 configure.bat，其余 3 模块用 cmake+Ninja | ~55 |
| `qt.conf` | 产物内 `bin\qt.conf`，`Prefix=..`（保持便携相对布局） | 2 |

### `buildQt5/`（24 个 cmd + 2 个补丁源文件 + qt.conf）

| 文件 | 职责 | 约行 |
|---|---|---|
| `build-Qt5<编译器>.cmd` ×13 | Qt5 完整版逐线脚本：MinGW 线 configure.bat+`mingw32-make`；MSVC 线 jom（jom 走 qt.io `jom.zip`，https）；构建前按线替换下方两个补丁文件 | 50–84 |
| `build-Qt5<编译器>_RP.cmd` ×11 | Qt5 RP 逐线脚本（qtbase 先 configure+make install，qttools/qttranslations/qtsvg 用 **qmake .pro**）；无 `(ninja)` 后缀 | 50–84 |
| `qfilesystemengine_win.cpp` | Qt5 qtbase io 源码修复版，构建时 `copy /Y` 进源码（使其能被高于 GCC 8.1.0 的 MinGW 编译） | 1694 |
| `main.c` | qttools `qcollectiongenerator` 垫片（转发 qhelpgenerator），构建时同上替换 | 113 |
| `qt.conf` | 同 buildQt6 | 2 |

### 根目录

| 文件 | 职责 | 约行 |
|---|---|---|
| `AI_MAINTENANCE_GUIDE.md` | **最重要文档**：升级 SOP、版本变量清单（§4）、包结构坑（§5）、libc++ 补丁经验（§7）、模板化路径说明（§10） | 229 |
| `README.md` | 已验证版本清单 + 编译器下载链接（**只记已验证构建，勿提前写**） | 93 |
| `HistoricalVersions.md` | 历史版本记录，**只增不改** | 400 |
| `LICENSE` | GPL-3.0 文本 | 674 |
| `.tmp/expand/` | 模板化改造的展开对拍产物（diff + 展开 yml/cmd），未跟踪，临时 | — |

## ④ 关键数据流 / 链路

**旧路径（36 个逐线 yml，当前默认方式）**
```
workflow_dispatch → yml(env: QT_VERSION/QT_VERSION2/FILE_NAME)
  → 装编译器(qt.io 7z / GitHub zip / runner 自带 MSVC) + Perl + Ninja(+Qt5 MSVC: jom)
  → 下载解压 Qt 源码到 D:\a\buildQt\Qt\<版本>\（actions/cache 按版本+模式缓存 zip）
  → llvm-mingw 线: 打 libc++ 23 补丁（PowerShell 幂等）  |  Qt5 MinGW>8.1 线: 替换 qfilesystemengine_win.cpp + main.c
  → cmd.exe 调 buildQt6|buildQt5 逐线 cmd → configure(-static -static-runtime -release …) → cmake+ninja(Qt6)/mingw32-make|jom(Qt5) → install 到 Qt\<版本>-static\<编译器代号[_RP]>
  → copy qt.conf → qmake.exe 存在校验 → 7z a Qt_<版本>-<FILE_NAME>.7z ../Qt/<版本>-static -mx=9
  → upload-artifact + temp release（tag=temp_Qt_<版本>-<FILE_NAME>，一线一 tag）
```

**新路径（模板化，与旧并存）**
```
build-qt6.yml（输入 qt_version/qt_version2/mode/lines）
  → ubuntu job 读 config/compilers-qt6.json 生成矩阵（lines 后缀解析：无后缀=full、_RP=rp、_both）
  → build-qt6-line.yml（reusable，20+ 输入逐字段透传）
  → build-qt6.cmd（QT_CONFIGURE_PRE/POST 环境变量传 configure 原文；BUILD_DIR 用短 line_id 防 260 路径）
  → 同样的打包/temp release 输出
```

**发布与下游**
```
promote-release.yml: temp_Qt_<版本>-* 资产 → 正式 release Qt<版本>_revN（不删 temp 除非显式输入）
  → 下游 buildRedPanda-CPP 在其 Actions 页手动触发对应工作流（两仓库间无自动事件联动）
```

**命名契约（下游依赖，不可变）**：产物 `Qt_<版本>-static-Release_<编译器代号>[_RP].7z`；`FILE_NAME=static-Release_<编译器代号>[_RP]`；temp tag `temp_Qt_<版本>-<FILE_NAME>`。

## ⑤ 项目约定与红线

1. **命名/大小写/顺序沿用 main 原文**（维护者强所有权）：`_RP`、`_RP(ninja)`、`MinGW64`缩写、temp tag 格式等一律不"规范化"。
2. **configure 参数一字不改**：JSON 的 PRE/POST 逐字取自旧脚本；任何修改先逐字节对拍。
3. **打包 `-mx=9` 体积优先**，不得为速度降压缩等级。
4. **README 只记已验证构建**；HistoricalVersions 只增不改；文件改名用 `git mv` 保历史。
5. **全部工作流仅手动触发**（workflow_dispatch），不加 push/PR 联动。
6. 补丁必须幂等（`Test-Path` 守卫 + `notmatch` 检查），**补丁步骤绝不挂构建**；文件缺失只 skip+日志。
7. 新脚本注释一律 ASCII（cmd 在 UTF-8 注释下解析错位，实测踩过）；旧脚本中文注释保持不动。
8. 与维护者协作：提交前先征得认同；改造类提交拆条有序（上次加固改造恰好 4 条提交）。
9. 跨 minor 升级必须同步 `QT_VERSION2`（主.次两段）；`lines` 过滤输入的 id 拼写以 JSON `id` 字段为准。

## ⑥ 坑与注意事项

- **源码包结构二象性**（Guide §5.1）：single 包顶层 `qt-everywhere-src-<版本>\qttools\src\...`；submodule 包顶层 `qttools-everywhere-src-<版本>\src\...`。补丁路径写错一个字即挂。
- **工具链 7z 包结构不一**（§5.3）：旧包自带 `Tools\<名>_64\` 前缀，新包（llvm_mingw2217、mingw1510 起）顶层直接 `bin\`，`-o` 目标必须不同；**不能**从包内 `meta.7z` 的 installscript.qs 推断结构。
- **260 MAX_PATH**：BUILD_DIR 必须用短 line id（`build-llvm-mingw`），用完整编译器代号会让 qtdeclarative fluentwinui3 依赖文件路径超限（2026-11-08 llvm 两条 full 全败于此）。
- **`PLATFORM` 是雷区变量名**：vcvarsall 会把它改写为 x64，导致 `-platform` 全部变形——绝不用它传自定义变量（实测事故）。
- **cmd 延迟展开**：`%VAR:;= %` 在变量未定义时解析崩溃，用 `call set` 做转换。
- **LLVM 23 libc++**（§7）：头文件精简暴露 Qt 源码缺 include（`undeclared identifier` 特征），只能精准补丁（releasehelper.h + litehtml 9 文件），`CXXFLAGS=-include cstdlib` 全局强制包含**已实证失败**（破坏 qrandom.cpp 的 `_CRT_RAND_S` 顺序）。
- **yml 内 cmd 调用路径与文件名必须一致**：历史上漏改过 `_RP(ninja)` 后缀导致失败，改名时全文件 grep 旧名。
- **本机网络**：GitHub 域名 curl/HEAD 受限（改网页抓取），qt.io 可直连；llvm-mingw release notes 常为空，需查 LLVM Clang Release Notes 的 Breaking Changes。
- **文档缺口**：Guide 未记录 Qt5 的"替换 qfilesystemengine_win.cpp + main.c"补丁机制（只在本文件与 cmd 内可见）；`build-qt6.yml` 头注写"用法见 Guide §11"实为 §10。README 列出的 Qt5 mingw1610 线在本仓库任何分支都无对应工作流（历史遗留描述）。
- Qt5 线冻结在 5.15.19（官方终版），一般不动；Qt6 官方默认编译器随版本演进（6.8~6.11 用 LLVM-MinGW 17.0.6，6.12 起 22.1.7 + MinGW 15.1.0），升级 Qt 前先查官方是否换线。

## ⑦ 任务 → 该读哪些文件

| 任务 | 必读 | 参考 |
|---|---|---|
| Qt 版本升级（新路径，首选） | `build-qt6.yml`（输入说明）、Guide §10 | `config/compilers-qt6.json`（验证后改默认值） |
| Qt 版本升级（旧路径） | Guide §3/§4/§6、目标 `buildQt6_*.yml` + 对应 cmd | `README.md`（验证后再更新） |
| 编译器升级/更换 | `config/compilers-qt6.json` 对应条目（新路径）或 Guide §5 + yml/cmd 同步 `git mv`（旧路径） | `README.md` 编译器清单、Guide §5.4 URL 模式 |
| 新增编译器线 | `config/compilers-qt6.json` + `build-qt6-line.yml` 输入字段 | 旧路径则复制一对 yml+cmd 并全文件 grep 改名 |
| llvm 线构建失败（undeclared identifier） | Guide §7、`build-qt6-line.yml` 补丁步 / 旧 yml 的补丁步 | Guide §9（本地源码包扫描正则） |
| 其他线构建失败 | 对应逐线 cmd（configure 原文、PATH 顺序） | Guide §5/§10.4、⑥ 各坑 |
| MSVC 线改动 | `build-qt6.cmd`（vcvars 顺序）+ JSON VCVARS 字段 | 旧 `build-Qt6msvc*.cmd` |
| 正式发布 / 下游联动 | `promote-release.yml`、Guide §10.3 | `build-qt6-line.yml` TempRelease 步 |
| 改 configure 参数 | `config/compilers-qt6.json` + `.tmp/expand/` 对拍 | Guide §10.1、红线 2 |
| 加固类改动（超时/缓存/下载） | `build-qt6-line.yml`、`promote-release.yml` | 旧 36 个 yml 同步改 |
| Qt5 线改动 | 对应 `buildQt5/*.cmd` + `buildQt5_*.yml` + 两个补丁源文件 | Guide §5.1（single/submodule 结构） |
| 产物/tag 命名契约 | `build-qt6-line.yml`（env.FILE_NAME、TempRelease 步） | Guide §10.4 |
| 批量替换操作规范 | Guide §6 | ⑥ 三重验证 |

## ⑧ 优化建议（分析后提出，均未实施）

1. **完成 Qt6 双轨收敛**：llvm 两条 full 线经 CI 重验通过后，将 12 个旧 `buildQt6_*.yml` + 12 个旧 cmd 移入 `legacy/`（或删除），README 标注新入口。消除"改一处必须同步两处"的最大维护成本；需要回滚时 git 历史仍在。
2. **Qt5 线轻量模板化**：24 个 Qt5 yml/cmd 与 Qt6 旧版同构但冻结不动，是双轨问题的翻版。不必复用 Qt6 的 JSON（构建系统不同：qmake/mingw32-make/jom vs cmake/ninja），可为 Qt5 单独出一份 `compilers-qt5.json` + 复用/复制 reusable line（加 `build_system` 字段），24 个 yml 收敛为 2；收益是未来 5.15.x 微升级或换 runner 镜像时只改一处。
3. **把对拍/替换工具沉淀进仓库**：Guide §6 说"仓库中已有可复用的 Replace-Bytes / Bytes-Equal 函数写法"，但仓库实际**没有**任何 .ps1/.py 脚本（只在历史会话中存在）。建议新增 `scripts/verify-config-parity.ps1`（JSON 展开 vs 旧 cmd 逐字节对拍）与 `scripts/replace-version.ps1`（含三重验证），让 Guide 的说法落地，避免每次会话重写、结果不可复现。
4. **README 与 JSON 去重**：编译器清单目前 README、`compilers-qt6.json`、Guide §1.1 三处重复，版本演进易漂移。长期方向：README 的"编译器"段由 JSON 生成（或至少互相注明"以 JSON 为准"）；同时清理 README 中无对应工作流的 mingw1610 描述。
5. **补齐 Guide 缺口**：把 Qt5 补丁机制（qfilesystemengine_win.cpp / main.c 的来源、适用线、替换方式）写进 Guide §5 或新增小节；修正 `build-qt6.yml` 头注的 §11→§10 引用。这两处是文档与仓库状态的真实偏差。
6. **小项**：① 加 `.gitignore`（`.tmp*/`），对拍产物不再依赖"未跟踪"状态；② `promote-release.yml` 的 `timeout-minutes: 30` 对 12 个 2–3GB 资产的下载+上传偏紧，建议放宽到 60；③ Guide 提到的"新 patch 版发布后 libc++ 补丁块可移除"可做成验证任务（每次升级 Qt patch 后先跑一次无补丁 RP 线确认上游是否已修复）。

**建议的落地顺序**（由依赖关系决定；每一步提交前均先征得维护者认同，不与 main-new 现有 4 条提交混淆，新工作单独成提交）：

1. **⑤ 文档缺口 + ⑥ 小项**：零 CI 风险、随时可做，一个批次完成（Guide 补 Qt5 补丁机制、yml 引用改正、.gitignore、promote 超时 60）。
2. **③ scripts/ 对拍工具落地**：是 ①② 的前置证据——任何"退役旧脚本 / Qt5 模板化"都必须先有逐字节对拍能力兜底，否则"与 legacy 一致"只是口头承诺。且 Guide §6 已声称仓库有此函数，落地后文档与仓库状态才对齐。
3. **① Qt6 双轨收敛**：有闸门，**不可抢跑**——需同时满足「llvm 两条 full 线 CI 重验通过」+「用户重度使用后评估裁决」（用户已明确并存保留，此步只做条件就绪，决定权在维护者）。触发后动作小：`git mv` 12 旧 yml + 12 旧 cmd 入 legacy/，README 标注新入口。
4. **② Qt5 轻量模板化**：排在 ① 之后——复用已在新路径生产验证过的 reusable line 模式，避免在未验证的框架上叠 24 条线的迁移。
5. **④ README-JSON 去重**：最后做——等 ①② 定稿谁是数据源后再生成分工，避免对"将要变动的源"做整理；同时清理 mingw1610 幽灵条目。
