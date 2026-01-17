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

; ============================================
; 语音流程控制器
; ============================================
class VoiceController {
    ; 状态标志
    static IsProcessing := false
    static IsEnabled := true  ; 是否启用

    ; 初始化
    static Init() {
        ; 加载配置
        Config.Init()

        ; 设置热键回调
        HotkeyManager.SetCallbacks(
            (*) => this.OnVoiceStart(),
            (*) => this.OnHoldEnd(),
            (isStart) => this.OnFreeToggle(isStart),
            (*) => this.OnHoldCancel()  ; 取消回调
        )

        ; 设置GUI保存回调
        GuiManager.OnSaveCallback := (*) => this.Reload()

        ; 初始化热键
        this.InitHotkeys()

        ; 设置托盘
        this.SetupTray()
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
    }

    ; 设置托盘图标和菜单
    static SetupTray() {
        ; 设置托盘图标（使用默认图标，如果有自定义图标可以更换）
        iconPath := A_ScriptDir . "\..\assets\icon.ico"
        if FileExist(iconPath)
            TraySetIcon(iconPath)

        ; 设置托盘提示
        A_IconTip := "豆包语音助手"

        ; 创建托盘菜单
        tray := A_TrayMenu
        tray.Delete()  ; 清除默认菜单

        tray.Add("✓ 已启用", (*) => this.ToggleEnabled())
        tray.Add()  ; 分隔线
        tray.Add("设置...", (*) => GuiManager.Show())
        tray.Add("帮助", (*) => this.ShowHelp())
        tray.Add()  ; 分隔线
        tray.Add("退出", (*) => this.Exit())

        ; 设置默认动作（双击托盘图标）
        tray.Default := "设置..."
    }

    ; 语音开始（按着说模式按下 或 自由说模式开始）
    static OnVoiceStart() {
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

    ; 按着说模式取消（按住时间太短）
    static OnHoldCancel() {
        if !this.IsProcessing
            return

        ; 等待豆包悬浮窗完全显示（避免ESC发送过快导致无效）
        Sleep(200)

        ; 发送ESC退出豆包悬浮窗
        SendInput("{Escape}")

        ; 重置状态（不需要恢复剪贴板，因为还没备份）
        this.IsProcessing := false
        HotkeyManager.ResetState()
    }

    ; 自由说模式切换
    static OnFreeToggle(isStart) {
        if isStart {
            ; 开始说话
            this.OnVoiceStart()
        } else {
            ; 结束说话，执行插入
            if this.IsProcessing
                this.DoInsertProcess()
        }
    }

    ; 执行插入流程
    static DoInsertProcess() {
        ; 1. 等待识别延迟
        delay := Config.Get("InsertDelay")
        Sleep(delay)

        ; 2. 备份剪贴板（用于检测变化，以及保护用户原内容）
        ClipboardManager.Backup()

        ; 3. 发送回车键（豆包会自动插入到光标位置）
        SendInput("{Enter}")

        ; 4. 轮询等待剪贴板变化（带超时）
        timeout := Config.Get("ClipboardTimeout")
        if timeout = "" || timeout < 100
            timeout := 500  ; 默认500ms

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
            ; 发送ESC退出豆包悬浮窗
            SendInput("{Escape}")
            ; 不需要恢复剪贴板（本来就是用户的内容）
            this.ShowTrayTip("未检测到识别结果", "豆包悬浮窗已退出")
        }

        ; 重置状态
        this.IsProcessing := false
        HotkeyManager.ResetState()
    }

    ; 显示托盘提示
    static ShowTrayTip(title, message) {
        if Config.Get("ShowTrayTip")
            TrayTip(message, title, 1)
    }

    ; 切换启用状态
    static ToggleEnabled() {
        this.IsEnabled := !this.IsEnabled

        ; 更新托盘菜单
        tray := A_TrayMenu
        if this.IsEnabled {
            tray.Rename("○ 已禁用", "✓ 已启用")
            A_IconTip := "豆包语音助手"
        } else {
            tray.Rename("✓ 已启用", "○ 已禁用")
            A_IconTip := "豆包语音助手 (已禁用)"
        }
    }

    ; 显示帮助
    static ShowHelp() {
        helpText := "
        (
豆包语音助手 使用说明

【按着说模式】
按住触发键说话，松开自动插入识别结果

【自由说模式】
点击触发键开始说话，再次点击结束并插入

【默认按键】
- 按着说：鼠标侧键1 (XButton1)
- 自由说：鼠标侧键2 (XButton2)

【注意事项】
1. 需要先安装并运行豆包桌面版
2. 确保豆包快捷键设置正确（默认 Ctrl+D）
3. 如遇焦点丢失，可手动 Ctrl+V 粘贴
        )"
        MsgBox(helpText, "帮助", 64)
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
