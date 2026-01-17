; ============================================
; 剪贴板操作模块
; ============================================
#Requires AutoHotkey v2.0

class ClipboardManager {
    ; 备份的剪贴板内容
    static BackupData := ""
    static BackupText := ""

    ; 监听状态
    static IsListening := false
    static LastContent := ""
    static ContentChanged := false

    ; 备份剪贴板
    static Backup() {
        try {
            this.BackupData := ClipboardAll()
            this.BackupText := A_Clipboard
            return true
        } catch {
            return false
        }
    }

    ; 恢复剪贴板
    static Restore() {
        try {
            A_Clipboard := this.BackupData
            return true
        } catch {
            return false
        }
    }

    ; 清空剪贴板（用于检测变化）
    static Clear() {
        try {
            A_Clipboard := ""
            return true
        } catch {
            return false
        }
    }

    ; 开始监听剪贴板变化
    static StartListening() {
        this.LastContent := A_Clipboard
        this.ContentChanged := false
        this.IsListening := true
    }

    ; 停止监听
    static StopListening() {
        this.IsListening := false
    }

    ; 检查剪贴板是否变化
    static CheckChange() {
        if !this.IsListening
            return false

        currentContent := A_Clipboard
        if currentContent != this.LastContent && currentContent != "" {
            this.ContentChanged := true
            return true
        }
        return false
    }

    ; 等待剪贴板变化（带超时）
    static WaitForChange(timeout := 5000) {
        this.StartListening()
        startTime := A_TickCount

        loop {
            if this.CheckChange() {
                this.StopListening()
                return true
            }

            if (A_TickCount - startTime) >= timeout {
                this.StopListening()
                return false
            }

            Sleep(50)  ; 每50ms检查一次
        }
    }

    ; 获取当前剪贴板文本
    static GetText() {
        return A_Clipboard
    }

    ; 设置剪贴板文本
    static SetText(text) {
        A_Clipboard := text
    }

    ; 检测剪贴板是否与备份时不同（用于判断豆包是否写入了内容）
    static HasChanged() {
        currentContent := A_Clipboard
        ; 如果当前内容与备份时不同，且当前内容不为空，说明有变化
        return currentContent != this.BackupText && currentContent != ""
    }
}
