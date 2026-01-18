; ============================================
; GUI 界面模块
; ============================================
#Requires AutoHotkey v2.0

class GuiManager {
    ; GUI窗口实例
    static MainGui := ""
    static IsRecording := false
    static RecordingFor := ""  ; "hold", "free", "doubao"
    static RecordedKey := ""   ; 已录制的按键（实时更新）
    static PeakRecordedKey := ""  ; 按键峰值状态（按下最多按键时的状态）
    static PeakKeyCount := 0      ; 峰值按键数量

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
        this.MainGui.AddGroupBox("x10 y325 w380 h70", "高级设置")

        this.MainGui.AddText("x20 y350", "剪贴板超时：")
        this.ClipboardTimeoutEdit := this.MainGui.AddEdit("x110 y347 w80 Number", "150")
        this.MainGui.AddText("x195 y350", "ms")
        this.MainGui.AddText("x230 y350 cGray", "(范围 100-200)")

        ; ===== 按钮 =====
        this.MainGui.AddButton("x100 y410 w80 h30", "保存").OnEvent("Click", (*) => this.OnSave())
        this.MainGui.AddButton("x200 y410 w80 h30", "取消").OnEvent("Click", (*) => this.OnCancel())

        ; ===== 状态栏 =====
        this.StatusText := this.MainGui.AddText("x20 y455 w360 cGreen", "状态: ● 已就绪")
    }

    ; 显示主窗口
    static Show() {
        if this.MainGui = ""
            this.CreateMainWindow()

        ; 加载当前配置到界面
        this.LoadConfigToGui()

        this.MainGui.Show("w400 h490")
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
            clipboardTimeout := 150
        else if clipboardTimeout > 200
            clipboardTimeout := 200
        Config.Set("ClipboardTimeout", Integer(clipboardTimeout))

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
        result := StrReplace(result, "RWin", "右Win")
        result := StrReplace(result, "LWin", "左Win")

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

        ; 将字母转为大写显示（更美观）
        result := StrUpper(result)
        ; 恢复修饰键的正确大小写
        result := StrReplace(result, "CTRL+", "Ctrl+")
        result := StrReplace(result, "ALT+", "Alt+")
        result := StrReplace(result, "SHIFT+", "Shift+")
        result := StrReplace(result, "WIN+", "Win+")

        ; 处理纯修饰键组合：移除末尾多余的 +
        if SubStr(result, -1) = "+"
            result := SubStr(result, 1, -1)

        return result
    }

    ; 显示名称转AHK格式
    ; 显示格式: Ctrl+D, Alt+D, Shift+D, Ctrl+Alt+D
    ; AHK格式: ^d (Ctrl+D), !d (Alt+D), +d (Shift+D), ^!d (Ctrl+Alt+D)
    static DisplayNameToKey(displayName) {
        if displayName = ""
            return ""

        result := displayName

        ; 鼠标按键（先用占位符保护，避免被后面的小写转换影响）
        result := StrReplace(result, "鼠标侧键1", "《XBUTTON1》")
        result := StrReplace(result, "鼠标侧键2", "《XBUTTON2》")
        result := StrReplace(result, "鼠标中键", "《MBUTTON》")

        ; 特殊键名（先处理，用占位符保护）
        result := StrReplace(result, "右Alt", "《RALT》")
        result := StrReplace(result, "左Alt", "《LALT》")
        result := StrReplace(result, "右Ctrl", "《RCTRL》")
        result := StrReplace(result, "左Ctrl", "《LCTRL》")
        result := StrReplace(result, "右Shift", "《RSHIFT》")
        result := StrReplace(result, "左Shift", "《LSHIFT》")
        result := StrReplace(result, "右Win", "《RWIN》")
        result := StrReplace(result, "左Win", "《LWIN》")

        ; 保护功能键 F1-F12
        Loop 12 {
            result := StrReplace(result, "F" . A_Index, "《F" . A_Index . "》")
        }

        ; 保护其他特殊键名
        specialKeys := ["Space", "Tab", "Enter", "Escape", "Backspace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "CapsLock", "NumLock", "ScrollLock", "PrintScreen", "Pause"]
        for key in specialKeys {
            result := StrReplace(result, key, "《" . key . "》")
        }

        ; 修饰键（显示格式 -> AHK格式）
        ; Ctrl+, Alt+, Shift+, Win+ 转换为 ^, !, +, #
        result := StrReplace(result, "Ctrl+", "^")
        result := StrReplace(result, "Alt+", "!")
        result := StrReplace(result, "Shift+", "+")
        result := StrReplace(result, "Win+", "#")

        ; 处理纯修饰键组合末尾的修饰键（如 Ctrl+Alt 中的 Alt 没有 + 后缀）
        ; 这些需要单独处理
        result := StrReplace(result, "Ctrl", "^")
        result := StrReplace(result, "Alt", "!")
        result := StrReplace(result, "Shift", "+")
        result := StrReplace(result, "Win", "#")

        ; 将剩余部分转为小写（主要是字母键，如 D -> d）
        result := StrLower(result)

        ; 恢复特殊键名（从占位符恢复为正确的 AHK 键名）
        result := StrReplace(result, "《xbutton1》", "XButton1")
        result := StrReplace(result, "《xbutton2》", "XButton2")
        result := StrReplace(result, "《mbutton》", "MButton")
        result := StrReplace(result, "《ralt》", "RAlt")
        result := StrReplace(result, "《lalt》", "LAlt")
        result := StrReplace(result, "《rctrl》", "RCtrl")
        result := StrReplace(result, "《lctrl》", "LCtrl")
        result := StrReplace(result, "《rshift》", "RShift")
        result := StrReplace(result, "《lshift》", "LShift")
        result := StrReplace(result, "《rwin》", "RWin")
        result := StrReplace(result, "《lwin》", "LWin")

        ; 恢复功能键
        Loop 12 {
            result := StrReplace(result, "《f" . A_Index . "》", "F" . A_Index)
        }

        ; 恢复其他特殊键名
        for key in specialKeys {
            result := StrReplace(result, "《" . StrLower(key) . "》", key)
        }

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
        ; 如果已经在录制，先停止
        if this.IsRecording {
            SetTimer(() => this.CheckKeyPress(), 0)
        }

        this.IsRecording := true
        this.RecordingFor := mode
        this.RecordedKey := ""
        this.PeakRecordedKey := ""
        this.PeakKeyCount := 0

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

    ; 检测按键按下（改用"按下检测 + 松开确认"模式，使用峰值状态记录）
    static CheckKeyPress() {
        if !this.IsRecording
            return

        ; 检测左右修饰键的独立状态
        lCtrl := GetKeyState("LCtrl", "P")
        rCtrl := GetKeyState("RCtrl", "P")
        lAlt := GetKeyState("LAlt", "P")
        rAlt := GetKeyState("RAlt", "P")
        lShift := GetKeyState("LShift", "P")
        rShift := GetKeyState("RShift", "P")
        lWin := GetKeyState("LWin", "P")
        rWin := GetKeyState("RWin", "P")

        ; 检测主键（非修饰键）
        mainKey := this.DetectMainKey()

        ; 计算当前按下的按键数量
        currentKeyCount := (lCtrl ? 1 : 0) + (rCtrl ? 1 : 0) + (lAlt ? 1 : 0) + (rAlt ? 1 : 0)
                         + (lShift ? 1 : 0) + (rShift ? 1 : 0) + (lWin ? 1 : 0) + (rWin ? 1 : 0)
                         + (mainKey != "" ? 1 : 0)

        ; 任何键被按下时，构建当前热键
        if currentKeyCount > 0 {
            currentKey := this.BuildHotkey(lCtrl, rCtrl, lAlt, rAlt, lShift, rShift, lWin, rWin, mainKey)
            this.RecordedKey := currentKey

            ; 如果当前按键数量 >= 峰值，更新峰值状态和显示（用户还在添加按键）
            if currentKeyCount >= this.PeakKeyCount {
                this.PeakKeyCount := currentKeyCount
                this.PeakRecordedKey := currentKey
                this.UpdateRecordingDisplay()  ; 只在按键增加或不变时更新显示
            }
            ; 当按键数量减少时，不更新显示，保持峰值状态的显示
        }

        ; 所有键都松开时，使用峰值状态完成录制
        if currentKeyCount = 0 && this.PeakRecordedKey != "" {
            ; 最终更新显示为峰值状态
            this.RecordedKey := this.PeakRecordedKey
            this.UpdateRecordingDisplay()
            this.FinishRecordingWithKey(this.PeakRecordedKey)
        }
    }

    ; 检测主键（非修饰键）
    static DetectMainKey() {
        ; 检测鼠标按键
        if GetKeyState("XButton1", "P")
            return "XButton1"
        if GetKeyState("XButton2", "P")
            return "XButton2"
        if GetKeyState("MButton", "P")
            return "MButton"

        ; 检测功能键 F1-F12
        Loop 12 {
            if GetKeyState("F" . A_Index, "P")
                return "F" . A_Index
        }

        ; 检测字母键
        Loop 26 {
            letter := Chr(64 + A_Index)  ; A-Z
            if GetKeyState(letter, "P")
                return StrLower(letter)  ; 转为小写
        }

        ; 检测数字键
        Loop 10 {
            num := A_Index - 1
            if GetKeyState(String(num), "P")
                return String(num)
        }

        ; 检测特殊键
        specialKeys := ["Space", "Tab", "Enter", "Escape", "Backspace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right", "CapsLock", "NumLock", "ScrollLock", "PrintScreen", "Pause"]
        for key in specialKeys {
            if GetKeyState(key, "P")
                return key
        }

        return ""
    }

    ; 根据按下的修饰键和主键构建 AHK 热键字符串
    static BuildHotkey(lCtrl, rCtrl, lAlt, rAlt, lShift, rShift, lWin, rWin, mainKey) {
        ; 如果有主键，使用标准修饰符格式
        if mainKey != "" {
            ahkKey := ""
            if lCtrl || rCtrl
                ahkKey .= "^"
            if lAlt || rAlt
                ahkKey .= "!"
            if lShift || rShift
                ahkKey .= "+"
            if lWin || rWin
                ahkKey .= "#"
            ahkKey .= mainKey
            return ahkKey
        }

        ; 没有主键时，处理纯修饰键情况
        ; 优先检测单独的右侧修饰键
        if rAlt && !lAlt && !lCtrl && !rCtrl && !lShift && !rShift && !lWin && !rWin
            return "RAlt"
        if rCtrl && !lCtrl && !lAlt && !rAlt && !lShift && !rShift && !lWin && !rWin
            return "RCtrl"
        if rShift && !lShift && !lCtrl && !rCtrl && !lAlt && !rAlt && !lWin && !rWin
            return "RShift"
        if rWin && !lWin && !lCtrl && !rCtrl && !lAlt && !rAlt && !lShift && !rShift
            return "RWin"

        ; 检测单独的左侧修饰键
        if lAlt && !rAlt && !lCtrl && !rCtrl && !lShift && !rShift && !lWin && !rWin
            return "LAlt"
        if lCtrl && !rCtrl && !lAlt && !rAlt && !lShift && !rShift && !lWin && !rWin
            return "LCtrl"
        if lShift && !rShift && !lCtrl && !rCtrl && !lAlt && !rAlt && !lWin && !rWin
            return "LShift"
        if lWin && !rWin && !lCtrl && !rCtrl && !lAlt && !rAlt && !lShift && !rShift
            return "LWin"

        ; 纯修饰键组合（如 Ctrl+Alt, Win+Alt）
        ahkKey := ""
        if lCtrl || rCtrl
            ahkKey .= "^"
        if lAlt || rAlt
            ahkKey .= "!"
        if lShift || rShift
            ahkKey .= "+"
        if lWin || rWin
            ahkKey .= "#"

        return ahkKey
    }

    ; 实时更新录制显示
    static UpdateRecordingDisplay() {
        displayName := this.KeyToDisplayName(this.RecordedKey)

        if this.RecordingFor = "hold"
            this.HoldKeyEdit.Value := displayName
        else if this.RecordingFor = "free"
            this.FreeKeyEdit.Value := displayName
        else if this.RecordingFor = "doubao"
            this.DouBaoHotkeyEdit.Value := displayName
    }

    ; 完成录制（新版本，接收已构建的热键字符串）
    static FinishRecordingWithKey(ahkKey) {
        SetTimer(() => this.CheckKeyPress(), 0)  ; 停止检测
        this.IsRecording := false

        ; 恢复按钮文字
        if this.RecordingFor = "hold"
            this.HoldRecordBtn.Text := "录制"
        else if this.RecordingFor = "free"
            this.FreeRecordBtn.Text := "录制"
        else if this.RecordingFor = "doubao"
            this.DouBaoRecordBtn.Text := "录制"

        ; 检测是否是纯修饰键组合（无法注册为热键）
        if this.IsPureModifierCombo(ahkKey) {
            ; 恢复原来的值
            this.RestorePreviousKey()
            ; 重置状态
            this.RecordedKey := ""
            this.PeakRecordedKey := ""
            this.PeakKeyCount := 0
            this.RecordingFor := ""
            ; 显示醒目的错误提示
            this.UpdateStatusError("纯修饰键组合无法作为触发键，请添加一个非修饰键（如字母、数字、功能键）")
            return
        }

        ; 检查热键冲突
        this.CheckHotkeyConflict(ahkKey)

        displayName := this.KeyToDisplayName(ahkKey)
        this.UpdateStatus("按键已设置: " . displayName)

        ; 重置状态
        this.RecordedKey := ""
        this.PeakRecordedKey := ""
        this.PeakKeyCount := 0
        this.RecordingFor := ""
    }

    ; 检测是否是纯修饰键组合
    static IsPureModifierCombo(ahkKey) {
        ; 纯修饰键组合的特征：只有修饰符前缀，没有主键
        ; 例如 "^!" (Ctrl+Alt), "#!" (Win+Alt)
        ; 但 "RAlt", "RCtrl" 等单独右侧修饰键是有效的

        ; 移除修饰符前缀后检查剩余部分
        temp := ahkKey
        temp := StrReplace(temp, "^", "")
        temp := StrReplace(temp, "!", "")
        temp := StrReplace(temp, "+", "")
        temp := StrReplace(temp, "#", "")

        ; 如果剩余为空，说明是纯修饰键组合
        return temp = ""
    }

    ; 恢复录制前的按键值
    static RestorePreviousKey() {
        if this.RecordingFor = "hold"
            this.HoldKeyEdit.Value := this.KeyToDisplayName(Config.Get("HoldToTalkKey"))
        else if this.RecordingFor = "free"
            this.FreeKeyEdit.Value := this.KeyToDisplayName(Config.Get("FreeToTalkKey"))
        else if this.RecordingFor = "doubao"
            this.DouBaoHotkeyEdit.Value := this.KeyToDisplayName(Config.Get("DouBaoHotkey"))
    }

    ; 完成录制（保留旧版本以兼容，但不再使用）
    static FinishRecording(ctrlDown, altDown, shiftDown, winDown, mainKey) {
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

        this.FinishRecordingWithKey(ahkKey)
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
            this.UpdateStatusWarning("与 " . conflictStr . " 冲突!")
        }
    }

    ; 更新状态文本（支持不同类型的消息）
    static UpdateStatus(text, type := "info") {
        if this.StatusText != "" {
            this.StatusText.Value := "状态: " . text

            ; 根据类型设置颜色
            if type = "error" {
                this.StatusText.SetFont("cRed Bold")
            } else if type = "warning" {
                this.StatusText.SetFont("cFF6600")  ; 橙色
            } else {
                this.StatusText.SetFont("cGreen")   ; 正常绿色
            }
        }
    }

    ; 显示错误状态（醒目提示）
    static UpdateStatusError(text) {
        this.UpdateStatus(text, "error")
        ; 弹出消息框确保用户看到
        MsgBox(text, "豆包语音助手 - 错误", "Icon!")
    }

    ; 显示警告状态
    static UpdateStatusWarning(text) {
        this.UpdateStatus(text, "warning")
    }
}
