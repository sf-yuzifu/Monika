# 莫妮卡

将《心跳文学部》的莫妮卡带到小米手环上陪伴你！

## watchface 多设备开发分支

本分支将旧设备分支整合为共用 Lua 运行逻辑和分设备布局、素材。已接入以下目标；当前完成工程生成与模拟回归，安装兼容性和实际显示仍需真机验证。

| 设备 | 构建目标 | 分辨率 | DeviceType |
| --- | --- | --- | --- |
| 小米手环 9 | `band9` | 192×490 | 366 |
| 小米手环 10 | `band10` | 212×520 | 466 |
| 小米手环 11 | `band11` | 212×520 | 共用 band10 包 |
| 小米手环 8 Pro | `band8pro` | 336×480 | 11 |
| 小米手环 9 Pro | `band9pro` | 336×480 | 367 |
| 小米手环 10 Pro | `band10pro` | 336×480 | 567 |
| Redmi Watch 6 | `redmiwatch6` | 432×514 | 565 |

手环 8 Pro 保留旧版的 21 条图片对话，不订阅心率和步数；其他目标保留 41 条文字对话及健康数据联动。RW6 使用专用 432×514 素材和 20px 字体，其余文字目标使用 16px 字体。

### 生成与编译

需要 Python 3.9+；生成工程使用 Python 标准库，安装包编译参考 EasyFace 4.23：

```powershell
python tools/build.py
python tools/build.py --device redmiwatch6
python tools/build.py --compiler "<EasyFace目录>\Compiler.exe"
python tools/build.py --device band9 --compiler "<EasyFace目录>\Compiler.exe" --id 979825266001 --version 2
```

生成工程位于 `build/<目标>/monika.fprj`，可用 EasyFace 打开；编译成功后输出 `dist/monika-<目标>.face`。`band11` 选择器会构建 `band10`，编译时同时复制一份 `monika-band11.face`。默认表盘 ID 为 `979825266001`，包头版本为 `2`。包头写入逻辑用于 Gen2 格式，编译后仍需设备安装验证。

### 源文件与素材

```text
src/common.lua          对话选择、字体及控件辅助函数
src/runtime.lua         状态渲染、定时器、数据过滤与亮熄屏处理
src/subscriptions.lua   时间、日期及健康数据订阅
devices.json            设备参数、配置继承与共包关系
devices/<目标>/layout.lua   设备布局与电量排列
devices/<目标>/*.bin        设备运行素材
devices/redmiwatch6/originals/  RW6 PNG 原素材
tools/build.py          生成工程与可选编译
tools/test.py           Lua 5.4 模拟回归
```

素材和布局来自原 `band9`、`band10`、`band8pro`、`band9pro` 分支，以及作者提供的 RW6 工程；已导入仓库，构建不依赖外部目录或旧分支。`band10pro` 继承 `band9pro` 的布局、字体和素材。`devices/*/preview.png` 是导入的旧版设计预览，不是运行截图。

数字、日期、星期和电量图标的 PNG 源素材位于 `assets/common/`；原始“容器”文件名的重命名对应表保存在 `assets/common/source-map.json`。RW6 的专用大尺寸 PNG 位于 `devices/redmiwatch6/originals/`，也包含背景、表情和对话框。构建按“设备专用 PNG → 共用 PNG → 旧 BIN”选择素材，自动映射 Lua 中动态生成的资源文件名，工程只打包实际选中的文件。PNG 由 EasyFace 在编译阶段转换。

已有 PNG 替代的 BIN 已清理；保留的 BIN 为其他设备的人物背景、表情、对话框及 8 Pro 图片文字。根目录旧版 band9 工程也已换用本地 PNG 数字素材。以后补充 PNG 后可运行 `python tools/clean_assets.py` 清理被替代的 BIN，再重新生成工程。

修改上述源文件后重新生成工程。根目录 `app/` 和 `monika.fprj` 保留为旧版 band9 工程，统一构建使用 `src/` 和 `devices/`。`build/`、`dist/` 为忽略的构建产物，不要直接编辑其中的 Lua。

### 回归验证

```powershell
python -m pip install -r requirements-dev.txt
python tools/test.py
```

回归在 Lua 5.4 中运行全部七款配置，检查资源、无效数据过滤、电量边界、点击对话、彩蛋恢复和亮熄屏定时器行为。真机重点验证字体、人物眼部贴图对齐、对话换行、触摸事件、长按切换表盘及熄屏恢复。

动画改为 100ms 定时器，仅状态或表情变化时重绘，熄屏暂停；眨眼、对话和彩蛋用 `lvgl.tick_get()` 计时。沿用旧版的对话选择概率：完整文字模式的彩蛋需要步数达到 500 且未选中健康对话后才抽取，因此整体概率低于 0.1%。

## 功能特性

- ✅ **自然眨眼效果** - 每7～10秒自动眨眼一次
- ✅ **暗色模式支持** - 自动切换日/夜间主题
- ✅ **交互功能** - 触摸头部触发互动反应
- ✅ **智能问候** - 根据不同时间段显示开屏问候（上午、下午、晚上）
- ✅ **丰富对话** - 内置41条AI生成的对话内容
- ✅ **隐藏彩蛋** - 0.1%概率触发魔术脸特效
- ✅ **健康数据集成** - 结合步数、心率等数据的情景对话

## 效果预览

<div style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;"> <img src="images/preview.png" alt="表盘预览" style="height: 200px; object-fit: contain;"> <img src="images/1.png" alt="功能展示1" style="height: 200px; object-fit: contain;"> <img src="images/2.png" alt="功能展示2" style="height: 200px; object-fit: contain;"> </div>

## 快速开始

### 环境要求

- 支持Lua表盘的小米手环
- EasyFace表盘打包工具

### 安装步骤

1. 下载并安装 [EasyFace工具](https://github.com/m0tral/EasyFace)
2. 克隆或下载本项目代码
3. 使用EasyFace打开 `monika.fprj` 项目文件
4. 连接手环并打包安装表盘

### 下载地址

- GitHub: [https://github.com/m0tral/EasyFace](https://github.com/m0tral/EasyFace)
- 米坛社区: [https://www.bandbbs.cn/resources/2357/](https://www.bandbbs.cn/resources/2357/)

## 项目结构

```
monika/
├── LICENSE
├── README.md
├── app/
│   └── _lua/
│       └── monika/          # 核心代码与资源
├── images/                  # 预览图片
│   ├── 1.png
│   ├── 2.png
│   └── preview.png
├── monika.fprj             # EasyFace项目文件
└── 附加条款.md             # 许可证补充说明
```

### 核心文件说明

`app/_lua/monika/` 目录包含以下重要文件：

- **图片资源** (`.bin`文件) - LVGL格式的二进制图像
- **monika.lua** - 主程序逻辑

#### 图片资源分类

**必需资源：**
- `0.bin` ~ `9.bin`, `num_gang.bin` - 大数字显示 (54×64px)
- `num0.bin` ~ `num9.bin`, `num_%.bin`, `num_mao.bin` - 小数字显示 (20×24px)
- `mon.bin` ~ `sun.bin` - 星期指示图标 (48×20px)
- `bg.bin` - 背景图片 (设备分辨率)
- `msg.bin` - 对话框素材 (设备分辨率)

**可选资源：**
- `smile.bin`, `eye_close.bin`, `scare.bin` - 特殊表情效果
- `*_n.bin` - 夜间模式专用素材
- `ap.bin` - 电量指示图标 (22×22px)

> 所有 `.bin` 图片文件均可使用PNG格式替代，EasyFace支持自动转换。
> 且图片尺寸大小并不需要严格限死，但仍需保证像正常表盘开发一样的图片尺寸一致的规范

## 开发指南

### 自定义修改

本项目基于Luavgl开发，代码结构清晰易于理解：

1. **修改对话内容** - 编辑 `totalText` 数组和 `return_text()` 函数中的对话选项
2. **调整界面布局** - 修改 `t.objImage` 到 `t.text` 部分的坐标和资源路径
3. **自定义电量显示** - 调整 `systemStatusBattery` 事件处理中的布局逻辑

### 最佳实践

1. **设计先行** - 使用Figma、即时设计或MasterGo等工具预先设计界面
2. **逐步实现** - 按照容器坐标逐个元素实现布局
3. **测试验证** - 在真机上频繁测试确保兼容性

## 许可证

本项目采用 **GPL v3 许可证**并附加中文补充条款，详细内容请参阅：
- [LICENSE](LICENSE) -  GNU通用公共许可证v3
- [附加条款.md](附加条款.md) - 中文补充说明

---

希望本项目能帮助您学习表盘开发，为小米手环生态增添更多精彩内容！
