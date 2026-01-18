; ============================================
; 豆包窗口管理模块
; 负责识别和操作豆包悬浮窗
; ============================================

class DoubaoWindow {
    ; 豆包进程名
    static ProcessName := "Doubao.exe"

    ; 语音悬浮窗最小高度（用于区分文字工具栏）
    static MinVoiceWindowHeight := 100

    ; 查找豆包语音悬浮窗
    ; 返回窗口句柄，未找到返回 0
    static FindVoiceWindow() {
        for hwnd in WinGetList("ahk_exe " this.ProcessName) {
            try {
                title := WinGetTitle(hwnd)
                WinGetPos(&x, &y, &w, &h, hwnd)

                ; 语音悬浮窗特征：
                ; 1. 标题为空（排除主窗口）
                ; 2. 高度 >= 100（排除文字工具栏，高度约64）
                ; 3. 窗口可见
                style := WinGetStyle(hwnd)
                isVisible := (style & 0x10000000)  ; WS_VISIBLE

                if (title = "" && h >= this.MinVoiceWindowHeight && isVisible) {
                    return hwnd
                }
            }
        }
        return 0
    }

    ; 激活豆包语音悬浮窗
    ; 返回是否成功激活
    static ActivateVoiceWindow() {
        hwnd := this.FindVoiceWindow()
        if hwnd {
            try {
                WinActivate(hwnd)
                Sleep(50)  ; 等待窗口激活
                return true
            }
        }
        return false
    }

    ; 向豆包悬浮窗发送按键
    ; 会先尝试激活悬浮窗，确保按键能被接收
    ; 返回是否成功发送（找到窗口并激活成功）
    static SendKey(key) {
        ; 尝试激活悬浮窗
        if !this.ActivateVoiceWindow() {
            ; 找不到悬浮窗，不发送按键（避免按键发送到其他窗口）
            return false
        }

        ; 发送按键
        SendInput(key)
        return true
    }

    ; 发送回车键（确认插入）
    ; 返回是否成功发送
    static SendEnter() {
        return this.SendKey("{Enter}")
    }

    ; 发送ESC键（取消/关闭悬浮窗）
    ; 返回是否成功发送
    static SendEscape() {
        return this.SendKey("{Escape}")
    }

    ; 检查豆包是否正在运行
    static IsRunning() {
        return ProcessExist(this.ProcessName) > 0
    }

    ; 检查语音悬浮窗是否存在
    static IsVoiceWindowExist() {
        return this.FindVoiceWindow() != 0
    }

    ; 检查悬浮窗是否有识别内容
    ; 返回 true 表示有内容（用户说话了）
    ; 返回 false 表示无内容（"请说话"状态）
    static HasVoiceContent() {
        hwnd := this.FindVoiceWindow()
        if !hwnd
            return false

        WinGetPos(&x, &y, &w, &h, hwnd)

        ; 高度判断：
        ; ~200px = "请说话"状态（无内容）
        ; ~243px+ = 有识别内容
        ; 阈值设为 220px
        return h > 220
    }
}
