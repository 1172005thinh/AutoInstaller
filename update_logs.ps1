$files = Get-ChildItem -Path s:\ -Include install_*.au3 -Recurse | Where-Object { $_.Name -notmatch '(vcredist|vscode|mpc|discord)' }

foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    
    # Skip if already has _Log function
    if ($content -match 'Func _Log') { continue }
    
    # 1. Replace "If Not FileExists..."
    $content = $content -replace '(?m)^If Not FileExists\(\$g_sSetupPath\) Then Exit 20\s*$', 
        "If Not FileExists(`$g_sSetupPath) Then`r`n    _Log(`"ERROR: Setup file not found: `" & `$g_sSetupPath)`r`n    Exit 20`r`nEndIf`r`n"
    
    # 2. Replace "If _Is...Installed() Then Exit 10" (Single line)
    $content = $content -replace '(?m)^If (_Is[a-zA-Z0-9_]+Installed\(\)) Then Exit 10\s*$', 
        "If `$1 Then`r`n    _Log(`"INFO: App is already installed. Exiting with code 10.`")`r`n    Exit 10`r`nEndIf`r`n"
        
    # 3. Add log before checking if installed
    $content = $content -replace '(?m)^(If _Is[a-zA-Z0-9_]+Installed\(\) Then\r?\n)', 
        "_Log(`"INFO: Checking if app is already installed...`")`r`n`$1"
        
    # 4. Add log before RunWait
    $content = $content -replace '(?m)^(Local \$iExitCode = RunWait)', 
        "_Log(`"INFO: Starting installation...`")`r`n`$1"
        
    # 5. Add log after RunWait and handle @error
    $content = $content -replace '(?m)^If @error Then Exit 21\s*$', 
        "_Log(`"INFO: Installer finished with exit code: `" & `$iExitCode)`r`nIf @error Then`r`n    _Log(`"ERROR: RunWait failed with AutoIt error: `" & @error)`r`n    Exit 21`r`nEndIf`r`n"
        
    # 6. Handle If $iExitCode <> 0 Then Exit $iExitCode
    $content = $content -replace '(?m)^If \$iExitCode <> 0 Then Exit \$iExitCode\s*$', 
        "If `$iExitCode <> 0 Then`r`n    _Log(`"ERROR: Installer returned non-zero exit code: `" & `$iExitCode)`r`n    Exit `$iExitCode`r`nEndIf`r`n"
        
    # 7. Add log before _WaitFor...
    $content = $content -replace '(?m)^(If _WaitFor[a-zA-Z0-9_]+\(\d+\) Then\r?\n)', 
        "_Log(`"INFO: Waiting for app to be fully registered...`")`r`n`$1"
        
    # 8. Add log before Exit 22
    $content = $content -replace '(?m)^Exit 22\s*$', 
        "_Log(`"ERROR: Installation validation timed out.`")`r`nExit 22`r`n"
        
    # 9. Inject _Log inside the If _Is...Installed block (multiline)
    $content = $content -replace '(?m)(_Log\("INFO: Checking if app is already installed\.\.\."\)\r?\nIf _Is[a-zA-Z0-9_]+Installed\(\) Then\r?\n)', 
        "`$1    _Log(`"INFO: App is already installed. Exiting with code 10.`")`r`n"
        
    # 10. Inject _Log inside the If _WaitFor... block
    $content = $content -replace '(?m)(_Log\("INFO: Waiting for app to be fully registered\.\.\."\)\r?\nIf _WaitFor[a-zA-Z0-9_]+\(\d+\) Then\r?\n)', 
        "`$1    _Log(`"INFO: Installation confirmed. Exiting with code 0.`")`r`n"

    # Append _Log function
    $logFunc = @"

Func _Log(`$sMsg)
    Local `$sLogPath = `"C:\Auto-installer\install-apps.log`"
    Local `$hLog = FileOpen(`$sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If `$hLog <> -1 Then
        FileWriteLine(`$hLog, `"[`" & @YEAR & `"-`" & StringFormat(`"%02d`", @MON) & `"-`" & StringFormat(`"%02d`", @MDAY) & `" `" & @HOUR & `":`" & @MIN & `":`" & @SEC & `"] [`" & StringReplace(`$g_sSetupFilename, `".exe`", `"`") & `"] `" & `$sMsg)
        FileClose(`$hLog)
    EndIf
EndFunc
"@
    $content = $content + $logFunc
    
    Set-Content -Path $f.FullName -Value $content -Encoding UTF8
    Write-Host "Updated $($f.Name)"
}
