; ============================================
; 窗口焦点管理模块
; ============================================
#Requires AutoHotkey v2.0

class WindowManager {
    ; 保存的窗口ID
    static SavedWindowId := 0
    static SavedControlHwnd := 0

    ; 记录当前活动窗口
    static SaveCurrentWindow() {
        try {
            this.SavedWindowId := WinGetID("A")
            ; 尝试获取当前焦点控件
            try {
                this.SavedControlHwnd := ControlGetFocus("A")
            } catch {
                this.SavedControlHwnd := 0
            }
            return true
        } catch {
            return false
        }
    }

    ; 恢复到保存的窗口
    static RestoreWindow() {
        if this.SavedWindowId = 0
            return false

        try {
            ; 先激活窗口
            WinActivate("ahk_id " . this.SavedWindowId)

            ; 等待窗口激活
            if !WinWaitActive("ahk_id " . this.SavedWindowId, , 2)
                return false

            ; 如果有保存的控件焦点，尝试恢复
            if this.SavedControlHwnd != 0 {
                try {
                    ControlFocus(this.SavedControlHwnd, "ahk_id " . this.SavedWindowId)
                }
            }

            return true
        } catch {
            return false
        }
    }

    ; 检查窗口是否仍然存在
    static WindowExists() {
        if this.SavedWindowId = 0
            return false
        return WinExist("ahk_id " . this.SavedWindowId) ? true : false
    }

    ; 清除保存的窗口信息
    static Clear() {
        this.SavedWindowId := 0
        this.SavedControlHwnd := 0
    }

    ; 获取当前活动窗口ID
    static GetActiveWindowId() {
        try {
            return WinGetID("A")
        } catch {
            return 0
        }
    }

    ; 检查是否成功恢复到原窗口
    static IsRestoredSuccessfully() {
        if this.SavedWindowId = 0
            return false
        try {
            currentId := WinGetID("A")
            return currentId = this.SavedWindowId
        } catch {
            return false
        }
    }
}
