; ============================================
; GUI 界面模块
; ============================================
#Requires AutoHotkey v2.0

class GuiManager {
    ; GUI窗口实例
    static MainGui := ""
    static IsRecording := false
    static RecordingFor := ""  ; "hold", "free", "doubao"

    ; 保存后的回调函数
    static OnSaveCallback := ""

    ; 控件引用
    static HoldKeyEdit := ""
    static FreeKeyEdit := ""
    static DouBaoHotkeyEdit := ""
    static InsertDelaySlider := ""
    static InsertDelayText := ""
    static ClipboardProtectCheck := ""
    static AutoStartCheck := ""
    static StatusText := ""

    ; 高级设置控件
    static ClipboardTimeoutEdit := ""
    static MinHoldDurationEdit := ""

    ; 录制按钮引用
    static HoldRecordBtn := ""
    static FreeRecordBtn := ""
    static DouBaoRecordBtn := ""

    ; 创建主窗口
    static CreateMainWindow() {
        this.MainGui := Gui("+Resize -MaximizeBox", "豆包语音助手 - 设置")
        this.MainGui.SetFont("s10", "Microsoft YaHei")
        this.MainGui.OnEvent("Close", (*) => this.OnClose())

        ; ===== 按着说模式 =====
        this.MainGui.AddGroupBox("x10 y10 w380 h80", "【按着说】模式")
        this.MainGui.AddText("x20 y35", "触发按键：")
        this.HoldKeyEdit := this.MainGui.AddEdit("x90 y32 w180 ReadOnly", "")
        this.HoldRecordBtn := this.MainGui.AddButton("x280 y30 w80 h25", "录制")
        this.HoldRecordBtn.OnEvent("Click", (*) => this.StartRecording("hold"))
        this.MainGui.AddText("x20 y60 cGray", "按住说话，松开自动插入")

        ; ===== 自由说模式 =====
        this.MainGui.AddGroupBox("x10 y100 w380 h80", "【自由说】模式")
        this.MainGui.AddText("x20 y125", "触发按键：")
        this.FreeKeyEdit := this.MainGui.AddEdit("x90 y122 w180 ReadOnly", "")
        this.FreeRecordBtn := this.MainGui.AddButton("x280 y120 w80 h25", "录制")
        this.FreeRecordBtn.OnEvent("Click", (*) => this.StartRecording("free"))
        this.MainGui.AddText("x20 y150 cGray", "点击开始，再次点击结束并插入")

        ; ===== 分隔线 =====
        this.MainGui.AddText("x10 y190 w380 h1 0x10")  ; 水平线

        ; ===== 豆包快捷键 =====
        this.MainGui.AddText("x20 y200", "豆包快捷键：")
        this.DouBaoHotkeyEdit := this.MainGui.AddEdit("x110 y197 w160 ReadOnly", "")
        this.DouBaoRecordBtn := this.MainGui.AddButton("x280 y195 w80 h25", "录制")
        this.DouBaoRecordBtn.OnEvent("Click", (*) => this.StartRecording("doubao"))

        ; ===== 插入延迟 =====
        this.MainGui.AddText("x20 y235", "插入延迟：")
        this.InsertDelaySlider := this.MainGui.AddSlider("x110 y232 w180 Range500-5000 TickInterval500", 1500)
        this.InsertDelaySlider.OnEvent("Change", (*) => this.OnDelaySliderChange())
        this.InsertDelayText := this.MainGui.AddText("x300 y235 w80", "1.5 秒")

        ; ===== 复选框选项 =====
        this.ClipboardProtectCheck := this.MainGui.AddCheckbox("x20 y270", "剪贴板保护（防止覆盖原有复制内容）")
        this.ClipboardProtectCheck.Value := 1

        this.AutoStartCheck := this.MainGui.AddCheckbox("x20 y295", "开机自启动")

        ; ===== 高级设置 =====
        this.MainGui.AddGroupBox("x10 y325 w380 h100", "高级设置")

        this.MainGui.AddText("x20 y350", "剪贴板超时：")
        this.ClipboardTimeoutEdit := this.MainGui.AddEdit("x110 y347 w80 Number", "500")
        this.MainGui.AddText("x195 y350", "ms")
        this.MainGui.AddText("x230 y350 cGray", "(推荐200-2000)")

        this.MainGui.AddText("x20 y380", "最小按住时长：")
        this.MinHoldDurationEdit := this.MainGui.AddEdit("x120 y377 w70 Number", "300")
        this.MainGui.AddText("x195 y380", "ms")
        this.MainGui.AddText("x230 y380 cGray", "(推荐200-500)")

        ; ===== 按钮 =====
        this.MainGui.AddButton("x100 y440 w80 h30", "保存").OnEvent("Click", (*) => this.OnSave())
        this.MainGui.AddButton("x200 y440 w80 h30", "取消").OnEvent("Click", (*) => this.OnCancel())

        ; ===== 状态栏 =====
        this.StatusText := this.MainGui.AddText("x20 y485 w360 cGreen", "状态: ● 已就绪")
    }

    ; 显示主窗口
    static Show() {
        if this.MainGui = ""
            this.CreateMainWindow()

        ; 加载当前配置到界面
        this.LoadConfigToGui()

        this.MainGui.Show("w400 h520")
    }

    ; 隐藏主窗口
    static Hide() {
        if this.MainGui != ""
            this.MainGui.Hide()
    }

    ; 加载配置到界面
    static LoadConfigToGui() {
        ; 按着说按键 - 显示友好名称
        holdKey := Config.Get("HoldToTalkKey")
        this.HoldKeyEdit.Value := this.KeyToDisplayName(holdKey)

        ; 自由说按键
        freeKey := Config.Get("FreeToTalkKey")
        this.FreeKeyEdit.Value := this.KeyToDisplayName(freeKey)

        ; 豆包快捷键
        doubaoKey := Config.Get("DouBaoHotkey")
        this.DouBaoHotkeyEdit.Value := this.KeyToDisplayName(doubaoKey)

        ; 插入延迟
        delay := Config.Get("InsertDelay")
        this.InsertDelaySlider.Value := delay
        this.InsertDelayText.Value := Format("{:.1f} 秒", delay / 1000)

        ; 剪贴板保护
        this.ClipboardProtectCheck.Value := Config.Get("ClipboardProtect")

        ; 开机自启动
        this.AutoStartCheck.Value := Config.IsAutoStartEnabled()

        ; 高级设置
        this.ClipboardTimeoutEdit.Value := Config.Get("ClipboardTimeout")
        this.MinHoldDurationEdit.Value := Config.Get("MinHoldDuration")
    }

    ; 从界面保存配置
    static SaveConfigFromGui() {
        ; 按着说按键 - 从显示名称转回AHK格式
        holdDisplay := this.HoldKeyEdit.Value
        Config.Set("HoldToTalkKey", this.DisplayNameToKey(holdDisplay))

        ; 自由说按键
        freeDisplay := this.FreeKeyEdit.Value
        Config.Set("FreeToTalkKey", this.DisplayNameToKey(freeDisplay))

        ; 豆包快捷键
        doubaoDisplay := this.DouBaoHotkeyEdit.Value
        Config.Set("DouBaoHotkey", this.DisplayNameToKey(doubaoDisplay))

        ; 插入延迟
        Config.Set("InsertDelay", this.InsertDelaySlider.Value)

        ; 剪贴板保护
        Config.Set("ClipboardProtect", this.ClipboardProtectCheck.Value)

        ; 开机自启动
        Config.Set("AutoStart", this.AutoStartCheck.Value)
        Config.SetAutoStart(this.AutoStartCheck.Value)

        ; 高级设置
        clipboardTimeout := this.ClipboardTimeoutEdit.Value
        if clipboardTimeout = "" || clipboardTimeout < 100
            clipboardTimeout := 500
        Config.Set("ClipboardTimeout", Integer(clipboardTimeout))

        minHoldDuration := this.MinHoldDurationEdit.Value
        if minHoldDuration = "" || minHoldDuration < 100
            minHoldDuration := 300
        Config.Set("MinHoldDuration", Integer(minHoldDuration))

        ; 保存到文件
        Config.Save()
    }

    ; AHK格式转显示名称
    ; AHK格式: ^d (Ctrl+D), !d (Alt+D), +d (Shift+D), ^!d (Ctrl+Alt+D)
    ; 显示格式: Ctrl+D, Alt+D, Shift+D, Ctrl+Alt+D
    static KeyToDisplayName(ahkKey) {
        if ahkKey = ""
            return ""

        result := ahkKey

        ; 鼠标按键
        result := StrReplace(result, "XButton1", "鼠标侧键1")
        result := StrReplace(result, "XButton2", "鼠标侧键2")
        result := StrReplace(result, "MButton", "鼠标中键")

        ; 特殊键名（先处理，避免被修饰键替换干扰）
        result := StrReplace(result, "RAlt", "右Alt")
        result := StrReplace(result, "LAlt", "左Alt")
        result := StrReplace(result, "RCtrl", "右Ctrl")
        result := StrReplace(result, "LCtrl", "左Ctrl")
        result := StrReplace(result, "RShift", "右Shift")
        result := StrReplace(result, "LShift", "左Shift")

        ; 修饰键（AHK格式 -> 显示格式）
        ; 注意顺序：先处理 + 因为它在AHK里表示Shift，但在显示格式里 + 是连接符
        ; 所以需要用特殊标记避免冲突
        result := StrReplace(result, "^", "《CTRL》")
        result := StrReplace(result, "!", "《ALT》")
        result := StrReplace(result, "+", "《SHIFT》")
        result := StrReplace(result, "#", "《WIN》")

        ; 替换回正常显示
        result := StrReplace(result, "《CTRL》", "Ctrl+")
        result := StrReplace(result, "《ALT》", "Alt+")
        result := StrReplace(result, "《SHIFT》", "Shift+")
        result := StrReplace(result, "《WIN》", "Win+")

        return result
    }

    ; 显示名称转AHK格式
    ; 显示格式: Ctrl+D, Alt+D, Shift+D, Ctrl+Alt+D
    ; AHK格式: ^d (Ctrl+D), !d (Alt+D), +d (Shift+D), ^!d (Ctrl+Alt+D)
    static DisplayNameToKey(displayName) {
        if displayName = ""
            return ""

        result := displayName

        ; 鼠标按键
        result := StrReplace(result, "鼠标侧键1", "XButton1")
        result := StrReplace(result, "鼠标侧键2", "XButton2")
        result := StrReplace(result, "鼠标中键", "MButton")

        ; 特殊键名（先处理，避免被修饰键替换干扰）
        result := StrReplace(result, "右Alt", "RAlt")
        result := StrReplace(result, "左Alt", "LAlt")
        result := StrReplace(result, "右Ctrl", "RCtrl")
        result := StrReplace(result, "左Ctrl", "LCtrl")
        result := StrReplace(result, "右Shift", "RShift")
        result := StrReplace(result, "左Shift", "LShift")

        ; 修饰键（显示格式 -> AHK格式）
        ; Ctrl+, Alt+, Shift+, Win+ 转换为 ^, !, +, #
        result := StrReplace(result, "Ctrl+", "^")
        result := StrReplace(result, "Alt+", "!")
        result := StrReplace(result, "Shift+", "+")
        result := StrReplace(result, "Win+", "#")

        return result
    }

    ; 延迟滑块变化
    static OnDelaySliderChange() {
        delay := this.InsertDelaySlider.Value
        this.InsertDelayText.Value := Format("{:.1f} 秒", delay / 1000)
    }

    ; 保存按钮
    static OnSave() {
        this.SaveConfigFromGui()
        this.UpdateStatus("配置已保存")

        ; 调用保存回调（重新初始化热键）
        if this.OnSaveCallback is Func
            this.OnSaveCallback.Call()

        ; 延迟后隐藏窗口
        SetTimer(() => this.Hide(), -500)
    }

    ; 取消按钮
    static OnCancel() {
        this.Hide()
    }

    ; 关闭窗口
    static OnClose() {
        this.Hide()
    }

    ; 开始录制按键（支持组合键）
    static StartRecording(mode) {
        this.IsRecording := true
        this.RecordingFor := mode

        ; 更新按钮文字
        if mode = "hold"
            this.HoldRecordBtn.Text := "按下..."
        else if mode = "free"
            this.FreeRecordBtn.Text := "按下..."
        else if mode = "doubao"
            this.DouBaoRecordBtn.Text := "按下..."

        this.UpdateStatus("请按下要设置的按键（支持组合键如 Ctrl+D）...")

        ; 使用定时器检测按键
        SetTimer(() => this.CheckKeyPress(), 50)
    }

    ; 检测按键按下
    static CheckKeyPress() {
        if !this.IsRecording
            return

        ; 检测修饰键状态
        ctrlDown := GetKeyState("Ctrl", "P")
        altDown := GetKeyState("Alt", "P")
        shiftDown := GetKeyState("Shift", "P")
        winDown := GetKeyState("LWin", "P") || GetKeyState("RWin", "P")

        ; 检测普通键（排除修饰键本身）
        mainKey := ""

        ; 检测鼠标按键
        if GetKeyState("XButton1", "P")
            mainKey := "XButton1"
        else if GetKeyState("XButton2", "P")
            mainKey := "XButton2"
        else if GetKeyState("MButton", "P")
            mainKey := "MButton"

        ; 检测功能键
        if mainKey = "" {
            Loop 12 {
                if GetKeyState("F" . A_Index, "P") {
                    mainKey := "F" . A_Index
                    break
                }
            }
        }

        ; 检测字母键
        if mainKey = "" {
            Loop 26 {
                letter := Chr(64 + A_Index)  ; A-Z
                if GetKeyState(letter, "P") {
                    mainKey := letter
                    break
                }
            }
        }

        ; 检测数字键
        if mainKey = "" {
            Loop 10 {
                num := A_Index - 1
                if GetKeyState(String(num), "P") {
                    mainKey := String(num)
                    break
                }
            }
        }

        ; 检测特殊键
        if mainKey = "" {
            specialKeys := ["Space", "Tab", "Enter", "Escape", "Backspace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "CapsLock", "NumLock", "ScrollLock", "PrintScreen", "Pause"]
            for key in specialKeys {
                if GetKeyState(key, "P") {
                    mainKey := key
                    break
                }
            }
        }

        ; 检测右侧修饰键作为主键（当没有其他组合时）
        if mainKey = "" && !ctrlDown && !altDown && !shiftDown && !winDown {
            if GetKeyState("RAlt", "P")
                mainKey := "RAlt"
            else if GetKeyState("RCtrl", "P")
                mainKey := "RCtrl"
            else if GetKeyState("RShift", "P")
                mainKey := "RShift"
        }

        ; 如果检测到主键，构建组合键
        if mainKey != "" {
            this.FinishRecording(ctrlDown, altDown, shiftDown, winDown, mainKey)
        }
    }

    ; 完成录制
    static FinishRecording(ctrlDown, altDown, shiftDown, winDown, mainKey) {
        SetTimer(() => this.CheckKeyPress(), 0)  ; 停止检测
        this.IsRecording := false

        ; 构建AHK格式的热键
        ahkKey := ""
        if ctrlDown
            ahkKey .= "^"
        if altDown
            ahkKey .= "!"
        if shiftDown
            ahkKey .= "+"
        if winDown
            ahkKey .= "#"
        ahkKey .= mainKey

        ; 转换为显示名称
        displayName := this.KeyToDisplayName(ahkKey)

        ; 更新对应的输入框
        if this.RecordingFor = "hold" {
            this.HoldKeyEdit.Value := displayName
            this.HoldRecordBtn.Text := "录制"
        } else if this.RecordingFor = "free" {
            this.FreeKeyEdit.Value := displayName
            this.FreeRecordBtn.Text := "录制"
        } else if this.RecordingFor = "doubao" {
            this.DouBaoHotkeyEdit.Value := displayName
            this.DouBaoRecordBtn.Text := "录制"
        }

        ; 检查热键冲突
        this.CheckHotkeyConflict(ahkKey)

        this.UpdateStatus("按键已设置: " . displayName)
        this.RecordingFor := ""
    }

    ; 检查热键冲突
    static CheckHotkeyConflict(newKey) {
        conflicts := []

        ; 检查与已配置的其他热键冲突
        holdKey := this.DisplayNameToKey(this.HoldKeyEdit.Value)
        freeKey := this.DisplayNameToKey(this.FreeKeyEdit.Value)
        doubaoKey := this.DisplayNameToKey(this.DouBaoHotkeyEdit.Value)

        if this.RecordingFor != "hold" && newKey = holdKey
            conflicts.Push("按着说触发键")
        if this.RecordingFor != "free" && newKey = freeKey
            conflicts.Push("自由说触发键")
        if this.RecordingFor != "doubao" && newKey = doubaoKey
            conflicts.Push("豆包快捷键")

        if conflicts.Length > 0 {
            conflictStr := ""
            for c in conflicts
                conflictStr .= c . ", "
            conflictStr := SubStr(conflictStr, 1, -2)
            this.UpdateStatus("警告: 与 " . conflictStr . " 冲突!")
        }
    }

    ; 更新状态文本
    static UpdateStatus(text) {
        if this.StatusText != ""
            this.StatusText.Value := "状态: " . text
    }
}
