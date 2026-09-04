; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#include <AutoItConstants.au3>

Local $sScriptPath = @ScriptDir & "\install-drivers.ps1"
Local $sPowerShell = @SystemDir & "\WindowsPowerShell\v1.0\powershell.exe"
If Not FileExists($sScriptPath) Or Not FileExists($sPowerShell) Then Exit 20

Local $sArguments = '-NoProfile -ExecutionPolicy Bypass -File "' & $sScriptPath & '"'
For $i = 1 To $CmdLine[0]
    $sArguments &= ' "' & StringReplace($CmdLine[$i], '"', '\"') & '"'
Next

Local $iExitCode = RunWait('"' & $sPowerShell & '" ' & $sArguments, @ScriptDir, @SW_HIDE)
If @error Then Exit 21
Exit $iExitCode
