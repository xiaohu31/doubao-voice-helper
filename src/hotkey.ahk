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

    ; 按下时间戳（用于检测最小按住时长）
    static HoldStartTime := 0

    ; 回调函数
    static OnHoldStart := ""
    static OnHoldEnd := ""
    static OnFreeToggle := ""
    static OnHoldCancel := ""  ; 取消回调（快速按一下时）

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
        ; 直接使用传入的key，它已经是AHK格式（如 ^d, RAlt, XButton1 等）
        keyName := key

        try {
            ; 对于纯鼠标按键（无修饰键），使用 ~ 前缀
            prefix := this.IsPureMouseKey(key) ? "~" : ""

            ; 按下事件
            Hotkey(prefix . keyName, (*) => this.HandleHoldKeyDown())
            ; 松开事件
            Hotkey(prefix . keyName . " Up", (*) => this.HandleHoldKeyUp())

            this.RegisteredHotkeys["hold"] := keyName
            this.RegisteredHotkeys["hold_prefix"] := prefix
            return true
        } catch as e {
            ; 热键注册失败，输出错误信息
            return false
        }
    }

    ; 注册"自由说"热键
    static RegisterFreeHotkey(key) {
        keyName := key

        try {
            prefix := this.IsPureMouseKey(key) ? "~" : ""

            Hotkey(prefix . keyName, (*) => this.HandleFreeKeyPress())
            this.RegisteredHotkeys["free"] := keyName
            this.RegisteredHotkeys["free_prefix"] := prefix
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

            ; 注销按下事件
            try {
                Hotkey(prefix . key, "Off")
            } catch as e {
                ; 只忽略 "Nonexistent" 错误，其他错误需要处理
                if !InStr(e.Message, "Nonexistent")
                    throw e
            }

            ; 注销松开事件
            try {
                Hotkey(prefix . key . " Up", "Off")
            } catch as e {
                if !InStr(e.Message, "Nonexistent")
                    throw e
            }
        }

        ; 注销自由说热键
        if this.RegisteredHotkeys.Has("free") {
            key := this.RegisteredHotkeys["free"]
            prefix := this.RegisteredHotkeys.Has("free_prefix") ? this.RegisteredHotkeys["free_prefix"] : ""

            try {
                Hotkey(prefix . key, "Off")
            } catch as e {
                if !InStr(e.Message, "Nonexistent")
                    throw e
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

        this.IsHoldMode := true
        this.HoldStartTime := A_TickCount  ; 记录按下时间
        if this.OnHoldStart is Func
            this.OnHoldStart.Call()
    }

    ; 处理"按着说"松开
    static HandleHoldKeyUp() {
        if !this.IsHoldMode
            return

        this.IsHoldMode := false

        ; 计算按住时长
        holdDuration := A_TickCount - this.HoldStartTime
        minHoldDuration := Config.Get("MinHoldDuration")
        if minHoldDuration = ""
            minHoldDuration := 300  ; 默认300ms

        if holdDuration < minHoldDuration {
            ; 按住时间太短，取消操作
            if this.OnHoldCancel is Func
                this.OnHoldCancel.Call()
        } else {
            ; 正常松开，执行插入
            if this.OnHoldEnd is Func
                this.OnHoldEnd.Call()
        }
    }

    ; 处理"自由说"按键
    static HandleFreeKeyPress() {
        if this.IsHoldMode  ; 如果按着说模式正在进行，忽略
            return

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

    ; 设置回调函数
    static SetCallbacks(onHoldStart, onHoldEnd, onFreeToggle, onHoldCancel := "") {
        this.OnHoldStart := onHoldStart
        this.OnHoldEnd := onHoldEnd
        this.OnFreeToggle := onFreeToggle
        this.OnHoldCancel := onHoldCancel
    }
}
