#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#include <AutoItConstants.au3>

Local $sScriptPath = @ScriptDir & "\report.ps1"
Local $sPowerShell = @SystemDir & "\WindowsPowerShell\v1.0\powershell.exe"
If Not FileExists($sScriptPath) Or Not FileExists($sPowerShell) Then Exit 20

Local $iExitCode = RunWait('"' & $sPowerShell & '" -NoProfile -ExecutionPolicy Bypass -File "' & $sScriptPath & '"', @ScriptDir, @SW_HIDE)
If @error Then Exit 21
Exit $iExitCode
