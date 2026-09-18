# KOReader 手机式拼音输入法

给越狱 Kindle 上的 KOReader 一个**手机输入法式的拼音键盘**：26 键拼音、词组输入、独立候选栏、数字选字、翻页、模糊音容错。

告别 KOReader 自带笔画输入法的别扭，像用搜狗/百度那样打中文。

## 功能特性

- ✅ **26 键拼音**：QWERTY 键位，打拼音字母
- ✅ **词组输入**：打全拼直接出词（`yuanze` → 原则、`jingji` → 经济）
- ✅ **独立候选栏**：键盘上方一行，左对齐、显示拼音 + 候选、超宽自动截断
- ✅ **数字选字**：按数字键 1-9 直接选候选，0 键翻页
- ✅ **模糊音容错**：z/zh、c/ch、s/sh 自动互容（打 `zi` 也能出「知/之/只」）
- ✅ **删除透明**：候选栏显示当前拼音，按删除键一目了然

## 已知局限

- **词语级输入，不支持整句**：码表是「拼音 → 固定词」的词典，只能打单词/短语（如 `yuanze` → 原则）；连续打一串拼音一次性出整句（如 `woyaochifan` → 我要吃饭）需要分词算法 + 语言模型，当前不支持。
- **数字选字，非点选**：当前用数字键 1-9 选字（0 键翻页），不是手机那种「点候选字直接上屏」。
- **绑定 KOReader 版本**：`virtualkeyboard.lua` 基于 KOReader v2026.07.1 修改，其它版本可能需要重新适配。

## 安装

> ⚠️ 本输入法修改了 KOReader 的核心键盘文件，**请先备份原文件**。当前版本基于 **KOReader v2026.07.1**。

### 方式一：手动安装

1. 将 Kindle 连接电脑（U 盘模式），进入 KOReader 目录（通常是 `Kindle/koreader/`）。

2. **备份**这三个文件（如果存在）：
   ```
   frontend/ui/data/keyboardlayouts/zh_CN_keyboard.lua
   frontend/ui/widget/virtualkeyboard.lua
   ```

3. 把本项目的 `frontend/` 目录内容复制到 KOReader 目录下，覆盖同名文件：
   ```
   frontend/ui/data/keyboardlayouts/phone_ime.lua      → 新增
   frontend/ui/data/keyboardlayouts/zh_CN_keyboard.lua  → 覆盖
   frontend/ui/widget/virtualkeyboard.lua               → 覆盖
   ```

4. 重启 KOReader（或重启 Kindle）。

### 方式二：安装脚本（Linux/macOS/WSL）

```bash
./install.sh /path/to/koreader
```

脚本会自动备份原文件并复制新文件。

## 使用说明

1. 打开 KOReader，进入任意输入框
2. **点屏幕顶部 → 设置 → 设备 → 键盘 → 键盘布局 → 中文(zh)**（启用中文键盘）
3. 用「地球键」切到中文键盘
4. **打拼音字母**（26 键）→ 候选栏显示拼音和候选字
5. **按数字键 1-9 选字**，**按 0 键翻页**
6. **空格键**提交第一个候选
7. 打完整拼音（如 `yuanze`）可出**词组**

## 兼容性

- KOReader **v2026.07.1**（`virtualkeyboard.lua` 基于此版本修改，其它版本可能需要重新适配）
- 越狱 Kindle（PW4 等，任何能跑 KOReader 的设备理论上都行）
- 依赖 KOReader 自带的 `zh_pinyin_data.lua` 码表（约 2.4 万词组 + 单字，无需额外下载）

## 未来规划

| 版本 | 内容 |
|---|---|
| **v2.0** | **点击候选区上屏**：候选栏改成一排可点击的候选，点字直接上屏；加「展开」查看全部候选；取消数字标注和 9 个上限 |
| **v2.x** | 更多模糊音对（l/n、h/f、r/l、前后鼻音 an/ang、en/eng、in/ing） |
| **v3.x** | 整句输入（引入分词 + 语言模型） |
| 持续 | 候选排序优化、用户词库 / 词频学习 |

> 欢迎提 issue 和 PR。

## 项目结构

```
frontend/
├── ui/data/keyboardlayouts/
│   ├── phone_ime.lua      # 输入法引擎（纯逻辑，从零重写）
│   └── zh_CN_keyboard.lua # 键盘布局（QWERTY + 接 phone_ime）
└── ui/widget/
    └── virtualkeyboard.lua # 键盘组件（加了候选栏，改自 KOReader 原版）
```

## 许可证

基于 KOReader（AGPL-3.0）二次开发，本项目同样采用 **AGPL-3.0**。详见 [LICENSE](LICENSE)。

## 致谢

- [KOReader](https://github.com/koreader/koreader) —— 阅读器和键盘框架
- [rime-pinyin-simp](https://github.com/rime/rime-pinyin-simp) —— 拼音码表（KOReader 内置）
