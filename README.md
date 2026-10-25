# 【可互动】心跳文学部 莫妮卡表盘

![预览](images/preview.png)

将《心跳文学部》的文学部部长莫妮卡（Monika）带到小米手环/手表上陪伴你！


## ✨ 功能特性

- 💚 **自然眨眼与灵动神态**：平时每隔 7～10 秒自然眨眼一次；日夜自动切换对应的日间/夜间背景与表情。
- 💬 **打破第四面墙的真诚互动**：
  - **摸头交互**：轻触上半屏莫妮卡的头部，她会报以微笑并与你开启一段对话，点击对话框可提前收起。
  - **分时段开屏问候**：早晨、午后、夜晚抬腕亮屏时，送上契合时间段的贴心问候。
  - **70+ 条精心润色的专属台词**：彻底摒弃空洞抽象的语句，还原原版莫妮卡的知性、温柔、专属爱意与部长哲思。
  - **动态阅读时长**：对话框展示时间根据句子长短自适应调整（3～8 秒），不再一闪而过。
- 💓 **身体体征与生活联动**：
  - **心率感知**：运动、兴奋或平稳时，莫妮卡能感知到你的心率变化并做出回应。
  - **步数成就**：500、1000、6000、10000 步触发不同的鼓励散步台词。
  - **低电量关怀**：手环电量偏低（≤20% / ≤10%）时，适度触发体贴的充电提醒，绝不刷屏复读。
- 🎁 **隐藏彩蛋与专属纪念日**：
  - **特定节日祝福**：涵盖 9.22 莫妮卡生日、情人节、520、元旦、万圣、圣诞及跨年等，节日当天开屏即获专属祝福。
  - **惊吓魔术脸彩蛋**：极小概率（0.1%）触发经典的吓人鬼脸彩蛋。
  - **彩蛋安全开关**：怕被吓到？**轻触屏幕最底部的电量区域**即可随时禁用/重新启用惊吓彩蛋，并伴有莫妮卡的可爱调侃回应。
- 🌙 **省电原生息屏显示（AOD）**：
  - 进入息屏后自动隐藏背景人物与繁杂交互，仅以经典白边空心线条呈现时间、日期与星期。
  - 纯黑底色深度适配 AMOLED 屏幕，原生控件驱动，超低功耗，安静陪伴。

---

## 📱 支持设备

本项目已全量适配小米及 Redmi 旗下主流 VelaOS 穿戴设备：

| 设备类型 | 支持型号 | 分辨率 | 编译构建目标 |
| :--- | :--- | :---: | :---: |
| **手环系列** | 小米手环 9 | 192×490 | `band9` |
| | 小米手环 10 / NFC | 212×520 | `band10` |
| | 小米手环 11 / NFC | 212×520 | `band11`（共用手环 10 包） |
| **手环Pro系列** | 小米手环 8 Pro | 336×480 | `band8pro` |
| | 小米手环 9 Pro | 336×480 | `band9pro` |
| | 小米手环 10 Pro | 336×480 | `band10pro` |
| **红米手表** | Redmi Watch 6 | 432×514 | `redmiwatch6` |
| **小米手表** | Xiaomi Watch S4 | 466×466 | `s4` |
| | Xiaomi Watch S5 (41mm) | 466×466 | `s5_41` |
| | Xiaomi Watch S5 (46mm) | 480×480 | `s5_46` |

> **注**：手环 8 Pro 由于早期固件没有开放中文字体给表盘，本项目为其开发了自动化切图管线，内置 70+ 张高清抗锯齿文字切图，实现与其他机型完全一致的台词、数据联动与体积优化。

---

## 🎮 玩法与暗号指南

1. **摸摸头**：轻按莫妮卡的发饰或前额区域，触发互动台词。
2. **快速关闭对话框**：直接轻触粉色对话框，即可立刻收起。
3. **关闭/开启突脸彩蛋**：轻触屏幕最底部的电量图标或百分比区域：
   - 听到 *“秘密开关被发现了呢！恶作剧代码已禁用～”* 时，突脸彩蛋将被永久屏蔽；
   - 再次点击即可恢复启用。
4. **特殊日子记得看看手环**：9 月 22 日是莫妮卡生日，情人节、圣诞节等节日也别忘了抬腕打个招呼哦。

---

## 🛠️ 开发者指南

如果你想要修改文案、调整排版或自行编译安装包，可以参考以下步骤。

### 环境准备

1. **Python 3.9+**
2. 安装项目依赖：
   ```powershell
   python -m pip install -r requirements.txt
   ```
3. 表盘打包工具推荐使用 **[EasyFace](https://github.com/m0tral/EasyFace)**。

### GitHub 自动发版

将工作流提交到仓库后，推送 `v主版本.次版本.修订号` 标签即可触发自动构建，例如：

```powershell
git tag v1.2.0
git push origin v1.2.0
```

GitHub Actions 会使用 Windows、Python 3.12 和校验过 SHA-256 的 EasyFace 4.23 编译全部互动版（含原生 AOD），通过回归及包头检查后创建 GitHub Release，上传 10 个 `.face` 和 `SHA256SUMS.txt`。静态版不会发布，也不会自动提交、修改 AstroBox 清单或回写 main。

包头版本直接读取**标签对应提交中的 `manifest_v2.json` → `downloads` → `versionCode`**，不再从标签换算。所有设备条目的 `versionCode` 必须是相同的正整数，否则停止构建。例如标签为 `v1.2.0`、清单的 `versionCode` 为 `7`，生成的包头版本就是 `7`。标签只用于 GitHub Release 名称，目前接受正式版 `vX.Y.Z`，不接受 `-beta` 等后缀。

每次发版先将全部设备的 `versionCode` 从 `6` 递增为 `7`、`8`……，并按需更新展示用 `version` 与更新日志；提交后再打标签。工作流只读取版本，不会自动加一或修改清单，也不校验它是否大于历史发布版本，请保持递增。

首次使用需确认仓库 Actions 已启用、组织策略允许工作流创建 Release；无需额外配置 PAT，发布任务使用 GitHub 自动提供的令牌。构建失败时不会创建 Release，可查看 Actions 日志排查；同名 Release 已存在时创建会失败，不会覆盖已发布文件。

### 常用命令

不需要互动时，可加 `--static` 构建静态版：强制使用日间背景，不显示对话、不眨眼、不切换日夜，也没有点击开关；时间、日期、星期、电量仍实时更新，原生 AOD 保留。

```powershell
python tools/build.py --static
python tools/build.py --static --device s4 --compiler "D:\EasyFace\Compiler.exe"
python tools/test_static.py
```

静态版工程位于 `build/<目标>-static/monika.fprj`，安装包为 `dist/monika-<目标>-static.face`，不会覆盖互动版文件。两版默认使用同一个表盘 ID，设备安装时可能相互替换；需要共存时通过 `--id` 指定不同 ID。

- **一键生成所有设备的 EasyFace 工程**：
  ```powershell
  python tools/build.py
  ```
- **生成指定设备的工程**（如 Redmi Watch 6）：
  ```powershell
  python tools/build.py --device redmiwatch6
  ```
- **调用 EasyFace 编译器直接编译出 `.face` 安装包**：
  ```powershell
  python tools/build.py --compiler "D:\EasyFace\Compiler.exe"
  ```
  编译完成后的安装包位于 `dist/monika-<设备>.face`。
- **运行自动化模拟回归测试**：
  ```powershell
  python tools/test.py
  ```
- **更新白天静态预览图**：
  ```powershell
  python tools/previews.py
  ```
- **为手环 8 Pro 重新批量生成文字切图**：
  ```powershell
  python tools/generate_text_images.py
  ```

---

## 📂 代码目录说明

### AstroBox 发布文件

根目录的 `manifest.json`、`manifest_v2.json` 和 `icon.png` 用于 AstroBox 展示与下载。正式发布只提供互动版（含 AOD）；静态版仅保留自行构建能力。

编译并测试后，运行以下命令整理发布文件：

```powershell
python tools/release.py
python tools/release.py --check
```

安装包放在 `release/`，版本自动读取包头；预览使用 `images/` 中的五张海报。脚本不提交或推送 Git。型号映射、验证范围及 main 分支整合注意事项见 [AstroBox 发布说明](docs/astrobox-release.md)。

```text
Monika/
├── assets/
│   ├── common/              # 各机型通用的数字、日期、星期 PNG 图标
│   └── aod/                 # AOD 息屏显示专用的白边轮廓素材库
├── devices/                 # 分设备的背景、表情贴图及设计预览图
├── devices.json             # 核心设备配置库（分辨率、坐标、字体、继承关系等）
├── dist/                    # 编译输出的最终 .face 安装包
├── src/
│   ├── monika.lua           # 基础运行环境、状态常量、全局字体与资源管理
│   ├── dialogue.lua         # 核心对话库、分类逻辑、去重算法与阅读时长计算
│   ├── ui.lua               # 统一的 UI 组件创建、触摸交互与电量层级管理
│   ├── runtime.lua          # 画面渲染引擎、事件动态定时调度器与亮熄屏生命周期
│   └── subscriptions.lua    # 时间、日期、步数与心率传感器数据订阅绑定
├── tools/                   # 构建、回归测试、切图生成与预览合成工具链
└── requirements.txt         # Python 依赖清单
```

---

## 🤝 致谢与开源协议

- 本项目基于 **GPL v3 许可证** 开源，并附带 [中文补充条款](附加条款.md)。
- 感谢 **Team Salvato** 创造的优秀作品《Doki Doki Literature Club!》。
- 感谢小米 Vela 穿戴生态与 [EasyFace](https://github.com/m0tral/EasyFace) 提供的开发支持。
