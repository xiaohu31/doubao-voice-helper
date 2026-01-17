; ============================================
; 配置管理模块
; ============================================
#Requires AutoHotkey v2.0

class Config {
    ; 默认配置
    static Default := Map(
        "HoldToTalkKey", "XButton1",
        "FreeToTalkKey", "XButton2",
        "DouBaoHotkey", "^d",
        "InsertDelay", 1500,
        "ClipboardProtect", 1,
        "AutoStart", 0,
        "FocusRecovery", 1,
        "ShowTrayTip", 1,
        "ClipboardTimeout", 500,
        "MinHoldDuration", 300
    )

    ; 当前配置
    static Current := Map()

    ; 配置文件路径
    static FilePath := A_ScriptDir . "\..\config.ini"

    ; 初始化配置
    static Init() {
        ; 先加载默认值
        for key, value in this.Default {
            this.Current[key] := value
        }

        ; 从文件加载（如果存在）
        this.Load()
    }

    ; 从INI文件加载配置
    static Load() {
        if !FileExist(this.FilePath)
            return false

        try {
            ; General 部分
            this.Current["HoldToTalkKey"] := IniRead(this.FilePath, "General", "HoldToTalkKey", this.Default["HoldToTalkKey"])
            this.Current["FreeToTalkKey"] := IniRead(this.FilePath, "General", "FreeToTalkKey", this.Default["FreeToTalkKey"])
            this.Current["DouBaoHotkey"] := IniRead(this.FilePath, "General", "DouBaoHotkey", this.Default["DouBaoHotkey"])
            this.Current["InsertDelay"] := Integer(IniRead(this.FilePath, "General", "InsertDelay", this.Default["InsertDelay"]))
            this.Current["ClipboardProtect"] := Integer(IniRead(this.FilePath, "General", "ClipboardProtect", this.Default["ClipboardProtect"]))
            this.Current["AutoStart"] := Integer(IniRead(this.FilePath, "General", "AutoStart", this.Default["AutoStart"]))

            ; Advanced 部分
            this.Current["FocusRecovery"] := Integer(IniRead(this.FilePath, "Advanced", "FocusRecovery", this.Default["FocusRecovery"]))
            this.Current["ShowTrayTip"] := Integer(IniRead(this.FilePath, "Advanced", "ShowTrayTip", this.Default["ShowTrayTip"]))
            this.Current["ClipboardTimeout"] := Integer(IniRead(this.FilePath, "Advanced", "ClipboardTimeout", this.Default["ClipboardTimeout"]))
            this.Current["MinHoldDuration"] := Integer(IniRead(this.FilePath, "Advanced", "MinHoldDuration", this.Default["MinHoldDuration"]))

            return true
        } catch as e {
            return false
        }
    }

    ; 保存配置到INI文件
    static Save() {
        try {
            ; General 部分
            IniWrite(this.Current["HoldToTalkKey"], this.FilePath, "General", "HoldToTalkKey")
            IniWrite(this.Current["FreeToTalkKey"], this.FilePath, "General", "FreeToTalkKey")
            IniWrite(this.Current["DouBaoHotkey"], this.FilePath, "General", "DouBaoHotkey")
            IniWrite(this.Current["InsertDelay"], this.FilePath, "General", "InsertDelay")
            IniWrite(this.Current["ClipboardProtect"], this.FilePath, "General", "ClipboardProtect")
            IniWrite(this.Current["AutoStart"], this.FilePath, "General", "AutoStart")

            ; Advanced 部分
            IniWrite(this.Current["FocusRecovery"], this.FilePath, "Advanced", "FocusRecovery")
            IniWrite(this.Current["ShowTrayTip"], this.FilePath, "Advanced", "ShowTrayTip")
            IniWrite(this.Current["ClipboardTimeout"], this.FilePath, "Advanced", "ClipboardTimeout")
            IniWrite(this.Current["MinHoldDuration"], this.FilePath, "Advanced", "MinHoldDuration")

            return true
        } catch as e {
            return false
        }
    }

    ; 获取配置值
    static Get(key) {
        return this.Current.Has(key) ? this.Current[key] : ""
    }

    ; 设置配置值
    static Set(key, value) {
        this.Current[key] := value
    }

    ; 设置开机自启动
    static SetAutoStart(enable) {
        startupPath := A_Startup . "\豆包语音助手.lnk"

        if enable {
            try {
                FileCreateShortcut(A_ScriptFullPath, startupPath)
                return true
            } catch {
                return false
            }
        } else {
            try {
                if FileExist(startupPath)
                    FileDelete(startupPath)
                return true
            } catch {
                return false
            }
        }
    }

    ; 检查是否已设置开机自启动
    static IsAutoStartEnabled() {
        return FileExist(A_Startup . "\豆包语音助手.lnk") ? true : false
    }
}
