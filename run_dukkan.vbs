' One-click Dukkan launcher: opens the app in Chrome, hidden (no console),
' and auto-kills the leftover flutter/dart + chrome processes once you close
' that browser window.

Dim shell, wmi, flutterExe, projectPath, chromePid, tries
Set shell = CreateObject("WScript.Shell")
Set wmi = GetObject("winmgmts:\\.\root\cimv2")

projectPath = "C:\AhmedGaid\Dukkan"
flutterExe = "C:\src\flutter\bin\flutter.bat"

shell.CurrentDirectory = projectPath
shell.Run Chr(34) & flutterExe & Chr(34) & " run -d chrome", 0, False

' Wait (up to 5 min) for the flutter-launched Chrome window to appear — it
' always runs from a distinct temp profile dir containing "flutter_tools.".
chromePid = 0
tries = 0
Do While chromePid = 0 And tries < 300
    WScript.Sleep 1000
    tries = tries + 1
    For Each p In wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='chrome.exe'")
        If Not IsNull(p.CommandLine) Then
            If InStr(p.CommandLine, "flutter_tools.") > 0 Then
                chromePid = p.ProcessId
                Exit For
            End If
        End If
    Next
Loop
If chromePid = 0 Then WScript.Quit

' Poll until that Chrome process ends (i.e. you closed the window).
Dim stillAlive
Do
    WScript.Sleep 2000
    stillAlive = False
    For Each p In wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE ProcessId=" & chromePid)
        stillAlive = True
    Next
Loop While stillAlive

' Browser closed — kill the leftover flutter/dart run and its Chrome profile.
For Each p In wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='dart.exe'")
    If Not IsNull(p.CommandLine) Then
        If InStr(p.CommandLine, "AhmedGaid\Dukkan") > 0 Or InStr(p.CommandLine, "flutter_tools") > 0 Then
            shell.Run "taskkill /PID " & p.ProcessId & " /F /T", 0, True
        End If
    End If
Next
For Each p In wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='chrome.exe'")
    If Not IsNull(p.CommandLine) Then
        If InStr(p.CommandLine, "flutter_tools.") > 0 Then
            shell.Run "taskkill /PID " & p.ProcessId & " /F /T", 0, True
        End If
    End If
Next
