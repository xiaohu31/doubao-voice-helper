; ============================================
; 热键监听模块
; ============================================
#Requires AutoHotkey v2.0

class HotkeyManager {
    ; 当前注册的热键
    static RegisteredHotkeys := Map()

    ; 模式状态
    static IsHoldMode := false    ; 按着说模式激活中
    static IsFreeMode := false    ; 自由说模式激活中

    ; 防抖状态
    static LastFreeKeyPressTime := 0  ; 上次自由说按键触发时间
    static FreeKeyDebounceInterval := 500  ; 防抖间隔（毫秒）

    ; 回调函数
    static OnHoldStart := ""
    static OnHoldEnd := ""
    static OnFreeToggle := ""

    ; 初始化热键
    static Init(holdKey, freeKey) {
        ; 不需要调用 UnregisterAll()
        ; AutoHotkey v2 允许直接覆盖注册，新的回调会自动替换旧的

        holdSuccess := true
        freeSuccess := true

        ; 注册"按着说"热键（会自动覆盖旧的）
        if holdKey != "" {
            holdSuccess := this.RegisterHoldHotkey(holdKey)
        }

        ; 注册"自由说"热键（会自动覆盖旧的）
        if freeKey != "" {
            freeSuccess := this.RegisterFreeHotkey(freeKey)
        }

        ; 返回注册结果
        return {hold: holdSuccess, free: freeSuccess}
    }

    ; 注册"按着说"热键（需要按下和松开两个事件）
    static RegisterHoldHotkey(key) {
        ; 直接使用传入的key，它已经是AHK格式（如 ^d, RAlt, XButton1, LAlt & RWin 等）
        keyName := key

        try {
            ; 检测是否是 & 组合键格式
            if InStr(key, " & ") {
                ; & 组合键需要特殊处理
                return this.RegisterAmpersandHoldHotkey(key)
            }

            ; 检测是否是单独修饰键
            if this.IsSingleModifierKey(key) {
                return this.RegisterModifierHoldHotkey(key)
            }

            ; 对于纯鼠标按键（无修饰键），使用 ~ 前缀
            prefix := this.IsPureMouseKey(key) ? "~" : ""

            ; 按下事件
            Hotkey(prefix . keyName, (*) => this.HandleHoldKeyDown())
            ; 松开事件
            Hotkey(prefix . keyName . " Up", (*) => this.HandleHoldKeyUp())

            this.RegisteredHotkeys["hold"] := keyName
            this.RegisteredHotkeys["hold_prefix"] := prefix
            this.RegisteredHotkeys["hold_type"] := "normal"
            return true
        } catch as e {
            ; 热键注册失败，输出错误信息
            return false
        }
    }

    ; 注册单独修饰键作为"按着说"热键
    static RegisterModifierHoldHotkey(key) {
        try {
            ; 单独修饰键（如 RAlt, LWin）可以直接用键名注册
            ; 按下事件
            Hotkey(key, (*) => this.HandleHoldKeyDown())
            ; 松开事件
            Hotkey(key . " Up", (*) => this.HandleHoldKeyUp())

            this.RegisteredHotkeys["hold"] := key
            this.RegisteredHotkeys["hold_prefix"] := ""
            this.RegisteredHotkeys["hold_type"] := "modifier"
            return true
        } catch as e {
            return false
        }
    }

    ; 注册 & 组合键作为"按着说"热键
    static RegisterAmpersandHoldHotkey(key) {
        ; 解析 & 组合键（如 "LAlt & RWin"）
        parts := StrSplit(key, " & ")
        if parts.Length != 2
            return false

        prefixKey := parts[1]
        suffixKey := parts[2]

        try {
            ; 注册组合键（按下 suffix 时触发）
            Hotkey(key, (*) => this.HandleHoldKeyDown())

            ; 注册 suffix 的 Up 事件（当 prefix 按下时松开 suffix 触发）
            ; 对于 & 组合键，Up 事件格式是 "prefix & suffix Up"
            Hotkey(prefixKey . " & " . suffixKey . " Up", (*) => this.HandleHoldKeyUp())

            ; 为 prefix 键添加一个空热键，防止它触发原有功能
            ; 但只有单独按下 prefix 时才不触发，与 suffix 组合时正常工作
            try {
                Hotkey(prefixKey, (*) => {})  ; 空回调，阻止 prefix 键的默认行为
            } catch {
                ; 如果已注册，忽略错误
            }

            this.RegisteredHotkeys["hold"] := key
            this.RegisteredHotkeys["hold_prefix"] := ""
            this.RegisteredHotkeys["hold_type"] := "ampersand"
            this.RegisteredHotkeys["hold_prefixKey"] := prefixKey
            this.RegisteredHotkeys["hold_suffixKey"] := suffixKey
            return true
        } catch as e {
            return false
        }
    }

    ; 注册"自由说"热键
    static RegisterFreeHotkey(key) {
        keyName := key

        try {
            ; 检测是否是 & 组合键格式
            if InStr(key, " & ") {
                return this.RegisterAmpersandFreeHotkey(key)
            }

            ; 检测是否是单独修饰键
            if this.IsSingleModifierKey(key) {
                return this.RegisterModifierFreeHotkey(key)
            }

            prefix := this.IsPureMouseKey(key) ? "~" : ""

            Hotkey(prefix . keyName, (*) => this.HandleFreeKeyPress())
            this.RegisteredHotkeys["free"] := keyName
            this.RegisteredHotkeys["free_prefix"] := prefix
            this.RegisteredHotkeys["free_type"] := "normal"
            return true
        } catch as e {
            return false
        }
    }

    ; 注册单独修饰键作为"自由说"热键
    static RegisterModifierFreeHotkey(key) {
        try {
            ; 单独修饰键，使用 Up 事件来触发（松开时触发）
            ; 这样可以避免与其他组合键冲突
            Hotkey(key . " Up", (*) => this.HandleFreeKeyPress())

            this.RegisteredHotkeys["free"] := key
            this.RegisteredHotkeys["free_prefix"] := ""
            this.RegisteredHotkeys["free_type"] := "modifier"
            return true
        } catch as e {
            return false
        }
    }

    ; 注册 & 组合键作为"自由说"热键
    static RegisterAmpersandFreeHotkey(key) {
        ; 解析 & 组合键
        parts := StrSplit(key, " & ")
        if parts.Length != 2
            return false

        prefixKey := parts[1]
        suffixKey := parts[2]

        try {
            ; 注册组合键
            Hotkey(key, (*) => this.HandleFreeKeyPress())

            ; 为 prefix 键添加一个空热键
            try {
                Hotkey(prefixKey, (*) => {})
            } catch {
                ; 如果已注册，忽略错误
            }

            this.RegisteredHotkeys["free"] := key
            this.RegisteredHotkeys["free_prefix"] := ""
            this.RegisteredHotkeys["free_type"] := "ampersand"
            this.RegisteredHotkeys["free_prefixKey"] := prefixKey
            this.RegisteredHotkeys["free_suffixKey"] := suffixKey
            return true
        } catch as e {
            return false
        }
    }

    ; 注销所有热键
    static UnregisterAll() {
        ; 注销按着说热键
        if this.RegisteredHotkeys.Has("hold") {
            key := this.RegisteredHotkeys["hold"]
            prefix := this.RegisteredHotkeys.Has("hold_prefix") ? this.RegisteredHotkeys["hold_prefix"] : ""
            keyType := this.RegisteredHotkeys.Has("hold_type") ? this.RegisteredHotkeys["hold_type"] : "normal"

            if keyType = "ampersand" {
                ; & 组合键的注销
                prefixKey := this.RegisteredHotkeys.Has("hold_prefixKey") ? this.RegisteredHotkeys["hold_prefixKey"] : ""
                suffixKey := this.RegisteredHotkeys.Has("hold_suffixKey") ? this.RegisteredHotkeys["hold_suffixKey"] : ""

                try {
                    Hotkey(key, "Off")
                } catch {
                }
                try {
                    Hotkey(prefixKey . " & " . suffixKey . " Up", "Off")
                } catch {
                }
            } else {
                ; 普通热键或修饰键热键的注销
                try {
                    Hotkey(prefix . key, "Off")
                } catch as e {
                    if !InStr(e.Message, "Nonexistent")
                        throw e
                }

                try {
                    Hotkey(prefix . key . " Up", "Off")
                } catch as e {
                    if !InStr(e.Message, "Nonexistent")
                        throw e
                }
            }
        }

        ; 注销自由说热键
        if this.RegisteredHotkeys.Has("free") {
            key := this.RegisteredHotkeys["free"]
            prefix := this.RegisteredHotkeys.Has("free_prefix") ? this.RegisteredHotkeys["free_prefix"] : ""
            keyType := this.RegisteredHotkeys.Has("free_type") ? this.RegisteredHotkeys["free_type"] : "normal"

            if keyType = "ampersand" {
                try {
                    Hotkey(key, "Off")
                } catch {
                }
            } else if keyType = "modifier" {
                try {
                    Hotkey(key . " Up", "Off")
                } catch {
                }
            } else {
                try {
                    Hotkey(prefix . key, "Off")
                } catch as e {
                    if !InStr(e.Message, "Nonexistent")
                        throw e
                }
            }
        }

        this.RegisteredHotkeys.Clear()
        this.ResetState()
    }

    ; 处理"按着说"按下
    static HandleHoldKeyDown() {
        if this.IsFreeMode  ; 如果自由说模式正在进行，忽略
            return

        if this.IsHoldMode  ; 防止重复触发
            return

        ; 检查是否正在处理中（防止在等待期间重复触发）
        ; 需要通过全局访问 VoiceController，但为了避免循环依赖，
        ; 我们通过回调函数来检查
        ; 暂时先允许触发，由 OnHoldStart 内部检查

        this.IsHoldMode := true
        if this.OnHoldStart is Func
            this.OnHoldStart.Call()
    }

    ; 处理"按着说"松开
    static HandleHoldKeyUp() {
        if !this.IsHoldMode
            return

        this.IsHoldMode := false

        ; 直接执行插入流程（提前检测会处理无内容的情况）
        if this.OnHoldEnd is Func
            this.OnHoldEnd.Call()
    }

    ; 处理"自由说"按键
    static HandleFreeKeyPress() {
        if this.IsHoldMode  ; 如果按着说模式正在进行，忽略
            return

        ; 防抖检查：距离上次触发时间必须 >= 500ms
        currentTime := A_TickCount
        if (currentTime - this.LastFreeKeyPressTime) < this.FreeKeyDebounceInterval
            return

        this.LastFreeKeyPressTime := currentTime

        this.IsFreeMode := !this.IsFreeMode
        if this.OnFreeToggle is Func
            this.OnFreeToggle.Call(this.IsFreeMode)
    }

    ; 重置状态
    static ResetState() {
        this.IsHoldMode := false
        this.IsFreeMode := false
    }

    ; 检查是否是纯鼠标按键（不带修饰键）
    static IsPureMouseKey(key) {
        ; 纯鼠标按键列表
        static mouseKeys := ["XButton1", "XButton2", "MButton", "LButton", "RButton"]

        ; 如果包含修饰符前缀，不是纯鼠标键
        if InStr(key, "^") || InStr(key, "!") || InStr(key, "+") || InStr(key, "#")
            return false

        for mk in mouseKeys {
            if key = mk
                return true
        }
        return false
    }

    ; 检查是否是单独修饰键
    static IsSingleModifierKey(key) {
        static modifierKeys := ["RAlt", "LAlt", "RCtrl", "LCtrl", "RShift", "LShift", "RWin", "LWin"]

        for mk in modifierKeys {
            if key = mk
                return true
        }
        return false
    }

    ; 设置回调函数
    static SetCallbacks(onHoldStart, onHoldEnd, onFreeToggle) {
        this.OnHoldStart := onHoldStart
        this.OnHoldEnd := onHoldEnd
        this.OnFreeToggle := onFreeToggle
    }
}
