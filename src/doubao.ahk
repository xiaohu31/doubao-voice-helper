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
    static SendKey(key) {
        ; 尝试激活悬浮窗
        this.ActivateVoiceWindow()

        ; 发送按键
        SendInput(key)
    }

    ; 发送回车键（确认插入）
    static SendEnter() {
        this.SendKey("{Enter}")
    }

    ; 发送ESC键（取消/关闭悬浮窗）
    static SendEscape() {
        this.SendKey("{Escape}")
    }

    ; 检查豆包是否正在运行
    static IsRunning() {
        return ProcessExist(this.ProcessName) > 0
    }

    ; 检查语音悬浮窗是否存在
    static IsVoiceWindowExist() {
        return this.FindVoiceWindow() != 0
    }
}
