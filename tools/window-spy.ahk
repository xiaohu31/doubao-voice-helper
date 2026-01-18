#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; 豆包窗口调研脚本 v2
; 增加窗口尺寸和位置信息
; 按 F12 列出所有豆包相关窗口信息
; ============================================

Persistent()

TrayTip("按 F12 获取豆包窗口信息", "豆包窗口调研 v2", 1)

F12:: {
    result := ""
    count := 0

    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            class := WinGetClass(hwnd)
            exe := WinGetProcessName(hwnd)
            pid := WinGetPID(hwnd)

            ; 搜索豆包相关窗口
            if InStr(exe, "doubao") || InStr(exe, "Doubao") || InStr(exe, "DouBao")
                || InStr(title, "豆包") || InStr(title, "Doubao") {
                count++

                ; 获取窗口位置和尺寸
                WinGetPos(&x, &y, &w, &h, hwnd)

                ; 获取窗口样式
                style := WinGetStyle(hwnd)
                exStyle := WinGetExStyle(hwnd)

                ; 判断是否可见
                isVisible := (style & 0x10000000) ? "是" : "否"  ; WS_VISIBLE

                result .= "【窗口 " count "】`n"
                result .= "  标题: " (title = "" ? "(空)" : title) "`n"
                result .= "  类名: " class "`n"
                result .= "  进程: " exe "`n"
                result .= "  尺寸: " w " x " h "`n"
                result .= "  位置: (" x ", " y ")`n"
                result .= "  可见: " isVisible "`n"
                result .= "  HWND: " hwnd "`n"
                result .= "`n"
            }
        }
    }

    if result = "" {
        MsgBox("未找到豆包相关窗口", "调研结果", 48)
    } else {
        A_Clipboard := result
        MsgBox("找到 " count " 个豆包相关窗口：`n`n" result "`n(已复制到剪贴板)", "调研结果", 64)
    }
}

Escape:: ExitApp()
