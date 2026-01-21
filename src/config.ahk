; ============================================
; 配置管理模块
; ============================================
#Requires AutoHotkey v2.0

class Config {
    ; 默认配置
    static Default := Map(
        "HoldToTalkKey", "RCtrl",
        "FreeToTalkKey", "XButton1",
        "AutoSendKey", "LCtrl & LWin",
        "CancelKey", "z",
        "AutoSendDelay", 50,
        "DouBaoHotkey", "^d",
        "InsertDelay", 300,
        "ClipboardProtect", 1,
        "AutoStart", 1,
        "FocusRecovery", 1,
        "ShowTrayTip", 1,
        "ClipboardTimeout", 100
    )

    ; 当前配置
    static Current := Map()

    ; 配置文件路径（优先使用外部文件，不存在则使用用户目录）
    static FilePath := ""

    ; 获取配置文件路径
    static GetFilePath() {
        if this.FilePath != ""
            return this.FilePath

        ; 优先使用程序同目录的 config.ini
        localConfig := A_ScriptDir . "\..\config.ini"
        if FileExist(localConfig) {
            this.FilePath := localConfig
            return this.FilePath
        }

        ; 如果不存在，使用用户目录（支持单文件运行）
        userConfig := A_AppData . "\DouBaoVoiceHelper\config.ini"
        this.FilePath := userConfig

        ; 确保目录存在
        userDir := A_AppData . "\DouBaoVoiceHelper"
        if !FileExist(userDir)
            DirCreate(userDir)

        return this.FilePath
    }

    ; 初始化配置
    ; 返回值：true = 配置文件存在（非首次运行），false = 配置文件不存在（首次运行）
    static Init() {
        ; 先加载默认值
        for key, value in this.Default {
            this.Current[key] := value
        }

        ; 从文件加载（如果存在）
        return this.Load()
    }

    ; 从INI文件加载配置
    static Load() {
        filePath := this.GetFilePath()
        if !FileExist(filePath)
            return false

        try {
            filePath := this.GetFilePath()
            ; General 部分
            this.Current["HoldToTalkKey"] := IniRead(filePath, "General", "HoldToTalkKey", this.Default["HoldToTalkKey"])
            this.Current["FreeToTalkKey"] := IniRead(filePath, "General", "FreeToTalkKey", this.Default["FreeToTalkKey"])
            this.Current["AutoSendKey"] := IniRead(filePath, "General", "AutoSendKey", this.Default["AutoSendKey"])
            this.Current["CancelKey"] := IniRead(filePath, "General", "CancelKey", this.Default["CancelKey"])
            this.Current["AutoSendDelay"] := Integer(IniRead(filePath, "General", "AutoSendDelay", this.Default["AutoSendDelay"]))
            this.Current["DouBaoHotkey"] := IniRead(filePath, "General", "DouBaoHotkey", this.Default["DouBaoHotkey"])
            this.Current["InsertDelay"] := Integer(IniRead(filePath, "General", "InsertDelay", this.Default["InsertDelay"]))
            this.Current["ClipboardProtect"] := Integer(IniRead(filePath, "General", "ClipboardProtect", this.Default["ClipboardProtect"]))
            this.Current["AutoStart"] := Integer(IniRead(filePath, "General", "AutoStart", this.Default["AutoStart"]))

            ; Advanced 部分
            this.Current["FocusRecovery"] := Integer(IniRead(filePath, "Advanced", "FocusRecovery", this.Default["FocusRecovery"]))
            this.Current["ShowTrayTip"] := Integer(IniRead(filePath, "Advanced", "ShowTrayTip", this.Default["ShowTrayTip"]))
            this.Current["ClipboardTimeout"] := Integer(IniRead(filePath, "Advanced", "ClipboardTimeout", this.Default["ClipboardTimeout"]))

            return true
        } catch as e {
            return false
        }
    }

    ; 保存配置到INI文件
    static Save() {
        try {
            filePath := this.GetFilePath()
            ; General 部分
            IniWrite(this.Current["HoldToTalkKey"], filePath, "General", "HoldToTalkKey")
            IniWrite(this.Current["FreeToTalkKey"], filePath, "General", "FreeToTalkKey")
            IniWrite(this.Current["AutoSendKey"], filePath, "General", "AutoSendKey")
            IniWrite(this.Current["CancelKey"], filePath, "General", "CancelKey")
            IniWrite(this.Current["AutoSendDelay"], filePath, "General", "AutoSendDelay")
            IniWrite(this.Current["DouBaoHotkey"], filePath, "General", "DouBaoHotkey")
            IniWrite(this.Current["InsertDelay"], filePath, "General", "InsertDelay")
            IniWrite(this.Current["ClipboardProtect"], filePath, "General", "ClipboardProtect")
            IniWrite(this.Current["AutoStart"], filePath, "General", "AutoStart")

            ; Advanced 部分
            IniWrite(this.Current["FocusRecovery"], filePath, "Advanced", "FocusRecovery")
            IniWrite(this.Current["ShowTrayTip"], filePath, "Advanced", "ShowTrayTip")
            IniWrite(this.Current["ClipboardTimeout"], filePath, "Advanced", "ClipboardTimeout")

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
