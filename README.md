# 豆包语音输入助手 | Doubao Voice Helper

> 🎙️ Windows 豆包语音输入增强工具 - 一键语音转文字，按住说话自动插入，让豆包桌面版语音输入更高效

[![GitHub release](https://img.shields.io/github/v/release/xiaohu31/doubao-voice-helper)](https://github.com/xiaohu31/doubao-voice-helper/releases)
[![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-blue)](https://www.autohotkey.com/)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078d4)](https://github.com/xiaohu31/doubao-voice-helper)
[![License](https://img.shields.io/github/license/xiaohu31/doubao-voice-helper)](LICENSE)

**关键词**: 豆包语音输入 / 语音转文字 / 按键说话 / Voice to Text / Speech Input / Windows 效率工具

## 🎬 演示

![演示](assets/demo.gif)

## ✨ 功能特性

### 两种输入模式

| 模式 | 操作方式 | 适用场景 | 默认按键 |
|------|----------|----------|----------|
| **按着说** | 按住 → 说话 → 松开自动插入 | 快速短句 | 鼠标侧键2 |
| **自由说** | 点一下开始 → 说话 → 再点结束 | 长段落 | 鼠标侧键1 |

### 核心能力

- **剪贴板保护** - 不覆盖用户原有复制内容
- **智能检测** - 无内容时快速关闭悬浮窗
- **防抖保护** - 防止长按重复触发
- **失焦修复** - 自动激活悬浮窗确保按键有效
- **灵活按键** - 支持键盘、鼠标、修饰键组合

## 📥 下载安装

### 方式一：下载 exe（推荐）

从 [Releases](https://github.com/xiaohu31/doubao-voice-helper/releases) 下载最新版 `DouBaoVoiceHelper-vX.X.exe`，双击即可运行，无需安装。

### 方式二：运行源码

需要先安装 [AutoHotkey v2](https://www.autohotkey.com/download/)，然后双击 `src/main.ahk`。

## 📋 使用前提

1. 已安装 **豆包桌面版**
2. 豆包语音输入功能正常
3. 豆包快捷键已配置（默认 `Ctrl+D`）

## ⚙️ 配置说明

**首次运行会自动弹出设置窗口**，之后可通过双击托盘图标或右键「设置」打开。

### 基本配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| 按着说触发键 | 按住说话的触发按键 | 鼠标侧键2 |
| 自由说触发键 | 点击切换的触发按键 | 鼠标侧键1 |
| 豆包快捷键 | 唤起豆包语音的快捷键 | Ctrl+D |
| 插入延迟 | 松开后等待识别完成的时间 | 500ms |
| 剪贴板保护 | 是否保护原有剪贴板内容 | 开启 |
| 开机自启动 | 是否随系统启动 | 关闭 |

### 支持的触发按键

| 类型 | 示例 |
|------|------|
| 鼠标按键 | 侧键1、侧键2、中键 |
| 功能键 | F1-F12 |
| 字母/数字 | A-Z、0-9 |
| 组合键 | Ctrl+D、Alt+Space、Win+V |
| 单独修饰键 | 右Alt、右Win、右Ctrl、右Shift |
| 修饰键组合 | 左Alt+右Win、左Ctrl+右Shift |

## 🔧 工作原理

```
按下触发键 → 发送豆包快捷键唤起悬浮窗
    ↓
用户说话（豆包实时转写）
    ↓
松开/再按触发键
    ↓
检测悬浮窗内容
├─ 无内容 → ESC 快速关闭
└─ 有内容 → 等待识别 → Enter 确认 → 自动粘贴到光标位置
```

## ❓ 常见问题

**Q: 识别结果没有插入？**
- 检查豆包是否正常运行
- 检查豆包快捷键设置（默认 Ctrl+D）
- 尝试增加「插入延迟」

**Q: 如何更改触发按键？**
- 打开设置，点击「录制」按钮，按下想要的按键即可

**Q: 热键注册失败？**
- 可能与其他软件冲突，尝试换一个按键

## 📁 项目结构

```
DouBaoVoiceHelper/
├── src/
│   ├── main.ahk        # 主程序入口
│   ├── config.ahk      # 配置管理
│   ├── hotkey.ahk      # 热键监听
│   ├── clipboard.ahk   # 剪贴板操作
│   ├── window.ahk      # 窗口管理
│   ├── gui.ahk         # 设置界面
│   └── doubao.ahk      # 豆包窗口控制
├── dist/               # 编译后的 exe
├── assets/             # 图标资源
└── config.ini          # 用户配置
```

## 📄 许可证

MIT License

## 🙏 致谢

感谢豆包团队提供优秀的语音识别功能。

---

*如有问题或建议，欢迎提交 [Issue](https://github.com/xiaohu31/doubao-voice-helper/issues)！*
