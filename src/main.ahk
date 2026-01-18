; ============================================
; 豆包语音助手 - 主程序入口
; ============================================
#Requires AutoHotkey v2.0
#SingleInstance Force

; 设置工作目录
SetWorkingDir(A_ScriptDir)

; 引入模块
#Include config.ahk
#Include clipboard.ahk
#Include window.ahk
#Include hotkey.ahk
#Include gui.ahk
#Include doubao.ahk

; ============================================
; 语音流程控制器
; ============================================
class VoiceController {
    ; 状态标志
    static IsProcessing := false
    static IsEnabled := true  ; 是否启用

    ; 防重复提示
    static LastTipTime := 0
    static TipDebounceInterval := 2000  ; 2秒内不重复相同提示

    ; 初始化
    static Init() {
        ; 加载配置并检查是否是首次运行（配置文件不存在）
        isFirstRun := !Config.Init()

        ; 设置热键回调
        HotkeyManager.SetCallbacks(
            (*) => this.OnVoiceStart(),
            (*) => this.OnHoldEnd(),
            (isStart) => this.OnFreeToggle(isStart)
        )

        ; 设置GUI保存回调
        GuiManager.OnSaveCallback := (*) => this.Reload()

        ; 初始化热键
        this.InitHotkeys()

        ; 设置托盘
        this.SetupTray()

        ; 如果是首次运行，弹出设置界面
        if isFirstRun
            GuiManager.Show()
    }

    ; 初始化热键
    static InitHotkeys() {
        holdKey := Config.Get("HoldToTalkKey")
        freeKey := Config.Get("FreeToTalkKey")

        result := HotkeyManager.Init(holdKey, freeKey)

        ; 检查注册结果并提供反馈
        if !result.hold && holdKey != "" {
            this.ShowTrayTip("热键注册失败", "按着说热键 '" holdKey "' 注册失败，可能与其他程序冲突")
        }

        if !result.free && freeKey != "" {
            this.ShowTrayTip("热键注册失败", "自由说热键 '" freeKey "' 注册失败，可能与其他程序冲突")
        }
    }

    ; 重新加载配置和热键
    static Reload() {
        Config.Load()
        this.InitHotkeys()
        ; 更新托盘菜单（刷新热键显示）
        this.UpdateTrayMenu()
    }

    ; 设置托盘图标（根据状态切换）
    ; state: "normal" | "disabled"
    static SetTrayIcon(state := "normal") {
        ; 优先使用自定义图标，不存在则使用系统图标
        switch state {
            case "normal":
                iconPath := A_ScriptDir . "\..\assets\icon.ico"
                if FileExist(iconPath)
                    TraySetIcon(iconPath)
                else if A_IsCompiled
                    TraySetIcon(A_ScriptFullPath)  ; 使用编译时嵌入的图标
                else
                    TraySetIcon("shell32.dll", 169)  ; 麦克风图标
            case "disabled":
                iconPath := A_ScriptDir . "\..\assets\icon-disabled.ico"
                if FileExist(iconPath)
                    TraySetIcon(iconPath)
                else
                    TraySetIcon("shell32.dll", 132)  ; 灰色图标
        }
    }

    ; 设置托盘图标和菜单
    static SetupTray() {
        ; 设置初始图标
        this.SetTrayIcon("normal")

        ; 设置托盘提示
        A_IconTip := "豆包语音助手"

        ; 创建托盘菜单
        this.UpdateTrayMenu()
    }

    ; 更新托盘菜单（支持动态刷新热键显示）
    static UpdateTrayMenu() {
        tray := A_TrayMenu
        tray.Delete()  ; 清除菜单

        ; 启用/禁用状态
        if this.IsEnabled
            tray.Add("✓ 已启用", (*) => this.ToggleEnabled())
        else
            tray.Add("○ 已禁用", (*) => this.ToggleEnabled())

        tray.Add()  ; 分隔线
        tray.Add("设置...", (*) => GuiManager.Show())
        tray.Add("帮助", (*) => this.ShowHelp())
        tray.Add()  ; 分隔线

        ; 显示当前热键（只读）
        holdKey := Config.Get("HoldToTalkKey")
        freeKey := Config.Get("FreeToTalkKey")
        holdDisplay := GuiManager.KeyToDisplayName(holdKey)
        freeDisplay := GuiManager.KeyToDisplayName(freeKey)

        holdMenuItem := "🎤 按着说: " . holdDisplay
        freeMenuItem := "🗣️ 自由说: " . freeDisplay

        tray.Add(holdMenuItem, (*) => {})
        tray.Add(freeMenuItem, (*) => {})
        tray.Disable(holdMenuItem)
        tray.Disable(freeMenuItem)

        tray.Add()  ; 分隔线
        tray.Add("关于", (*) => this.ShowAbout())
        tray.Add()  ; 分隔线
        tray.Add("退出", (*) => this.Exit())

        ; 设置默认动作（双击托盘图标）
        tray.Default := "设置..."
    }

    ; 显示关于对话框
    static ShowAbout() {
        aboutText := "
        (
豆包语音助手 v1.1

增强豆包桌面版的语音输入体验

功能特点：
• 按着说 - 按住说话，松开自动插入
• 自由说 - 点击开始，再点击结束
• 剪贴板保护 - 不覆盖原有内容

项目地址：https://github.com/xxx/DouBaoVoiceHelper
开源协议：MIT License
        )"
        MsgBox(aboutText, "关于 - 豆包语音助手", 64)
    }

    ; 语音开始（按着说模式按下 或 自由说模式开始）
    static OnVoiceStart() {
        ; 如果已经在处理中或已禁用，忽略本次触发
        if this.IsProcessing || !this.IsEnabled
            return

        this.IsProcessing := true

        ; 1. 记录当前焦点窗口
        WindowManager.SaveCurrentWindow()

        ; 2. 发送豆包快捷键
        doubaoHotkey := Config.Get("DouBaoHotkey")
        SendInput(doubaoHotkey)
    }

    ; 按着说模式松开
    static OnHoldEnd() {
        if !this.IsProcessing
            return

        ; 执行插入流程
        this.DoInsertProcess()
    }

    ; 自由说模式切换
    static OnFreeToggle(isStart) {
        if isStart {
            ; 开始说话
            this.OnVoiceStart()

            ; 延迟检测悬浮窗是否弹出（1秒后）
            SetTimer(() => this.CheckVoiceWindowAfterStart(), -1000)
        } else {
            ; 结束说话前，先检查悬浮窗是否还存在
            if !DoubaoWindow.IsVoiceWindowExist() {
                ; 悬浮窗不存在，说明用户手动关闭了
                ; 重置状态，不执行插入
                this.IsProcessing := false
                HotkeyManager.ResetState()

                ; 防重复提示：2秒内不重复显示相同提示
                currentTime := A_TickCount
                if (currentTime - this.LastTipTime) >= this.TipDebounceInterval {
                    this.ShowTrayTip("提示", "豆包悬浮窗已关闭")
                    this.LastTipTime := currentTime
                }
                return
            }

            ; 悬浮窗存在，正常执行插入
            if this.IsProcessing
                this.DoInsertProcess()
        }
    }

    ; 执行插入流程
    static DoInsertProcess() {
        ; 0. 检查豆包是否在运行
        if !DoubaoWindow.IsRunning() {
            this.IsProcessing := false
            HotkeyManager.ResetState()
            this.ShowTrayTip("错误", "豆包未运行，无法完成语音输入")
            return
        }

        ; 1. 等待识别延迟（给豆包时间完成语音识别）
        delay := Config.Get("InsertDelay")
        Sleep(delay)

        ; 2. 备份剪贴板（用于检测变化，以及保护用户原内容）
        ClipboardManager.Backup()

        ; 3. 激活悬浮窗后发送回车键（解决失焦问题）
        DoubaoWindow.SendEnter()

        ; 4. 轮询等待剪贴板变化（带超时）
        timeout := Config.Get("ClipboardTimeout")
        if timeout = "" || timeout < 100
            timeout := 150  ; 默认150ms
        else if timeout > 200
            timeout := 200  ; 最大200ms

        startTime := A_TickCount
        clipboardChanged := false

        loop {
            if ClipboardManager.HasChanged() {
                clipboardChanged := true
                break
            }

            if (A_TickCount - startTime) >= timeout
                break

            Sleep(50)  ; 每50ms检测一次
        }

        ; 5. 根据检测结果处理
        if clipboardChanged {
            ; 剪贴板变化了，说明豆包识别成功
            ; 等待豆包完成粘贴操作（豆包写入剪贴板后还需要时间执行粘贴）
            Sleep(150)

            ; 如果开启剪贴板保护，恢复用户原来的剪贴板内容
            if Config.Get("ClipboardProtect")
                ClipboardManager.Restore()
        } else {
            ; 剪贴板没变化，说明豆包没识别到内容（用户没说话或识别失败）
            ; 激活悬浮窗后发送ESC退出（解决失焦问题）
            DoubaoWindow.SendEscape()
            ; 不需要恢复剪贴板（本来就是用户的内容）
            ; 静默处理，不显示托盘提示
        }

        ; 重置状态
        this.IsProcessing := false
        HotkeyManager.ResetState()
    }

    ; 检查悬浮窗是否弹出（自由说模式启动后1秒检测）
    static CheckVoiceWindowAfterStart() {
        ; 只在自由说模式且正在处理时检查
        if !HotkeyManager.IsFreeMode || !this.IsProcessing
            return

        ; 检查悬浮窗是否存在
        if !DoubaoWindow.IsVoiceWindowExist() {
            ; 悬浮窗不存在，重置状态
            this.IsProcessing := false
            HotkeyManager.ResetState()
            this.ShowTrayTip("错误", "豆包悬浮窗未弹出，请检查豆包是否正常运行")
        }
    }

    ; 显示托盘提示
    static ShowTrayTip(title, message) {
        if Config.Get("ShowTrayTip")
            TrayTip(message, title, 1)
    }

    ; 切换启用状态
    static ToggleEnabled() {
        this.IsEnabled := !this.IsEnabled

        ; 更新托盘图标和菜单
        if this.IsEnabled {
            this.SetTrayIcon("normal")
            A_IconTip := "豆包语音助手"
        } else {
            this.SetTrayIcon("disabled")
            A_IconTip := "豆包语音助手 (已禁用)"
        }

        ; 重新构建菜单（更新启用/禁用显示）
        this.UpdateTrayMenu()
    }

    ; 显示帮助
    static ShowHelp() {
        helpText := "
        (
豆包语音助手 使用说明

【按着说模式】
按住触发键说话，松开后自动插入识别结果到光标位置。
如果按住时间太短（小于最小按住时长），会自动取消。

【自由说模式】
点击触发键开始说话，再次点击结束并插入识别结果。
适合长时间语音输入，不限时长。

【默认触发键】
- 按着说：鼠标侧键1 (XButton1) 或 F1
- 自由说：鼠标侧键2 (XButton2) 或 F2
- 可在设置中自定义任意按键或组合键

【配置说明】
- 识别延迟：松开后等待豆包识别完成的时间
- 剪贴板保护：开启后会恢复用户原来的剪贴板内容
- 最小按住时长：按着说模式的最短按住时间
- 剪贴板超时：等待识别结果的超时时间

【注意事项】
1. 需要先安装并运行豆包桌面版
2. 确保豆包快捷键设置为 Ctrl+D
3. 识别结果会插入到当前焦点窗口的光标位置
4. 说话过程中可以切换窗口，内容会插入到新窗口

【常见问题】
Q: 为什么没有插入识别结果？
A: 请检查豆包是否正在运行，快捷键是否正确。

Q: 为什么插入了错误的内容？
A: 可能是识别延迟设置过短，请适当增加延迟时间。
        )"
        MsgBox(helpText, "豆包语音助手 - 帮助", 64)
    }

    ; 退出程序
    static Exit() {
        ExitApp()
    }
}

; ============================================
; 程序启动
; ============================================
VoiceController.Init()

; 保持脚本运行
Persistent()
