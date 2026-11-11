
	:: INFO:
	:: RustDesk Github: https://github.com/rustdesk/rustdesk
	:: RustDesk ID Changer Github: https://github.com/abdullah-erturk/RustDesk-ID-Changer

::===============================================================================================================
@echo off
mode con:cols=90 lines=50
title RustDesk ID ^& 服务器修改工具 v4 中文版 by Abdullah ERTURK

:: 语言：本脚本已改为中文界面（控制台代码页 GBK / chcp 936）
for /f "delims=" %%a in ('powershell -NoProfile -Command "(Get-UICulture).TwoLetterISOLanguageName"') do set OS_LANG=%%a
set LANG_TR=0
if /i "%OS_LANG%"=="tr" set LANG_TR=1

net file 1>nul 2>nul && goto :Main || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c ""%~fnx0""""'"
goto :eof
::===============================================================================================================
:Main
cls
chcp 936 >nul 2>&1

:: Log file: prefer script directory, fall back to %TEMP% if not writable (e.g. read-only USB)
set "LOGFILE=%~dp0RustDesk_Changer.log"
2>nul (>>"%~dp0.rdwtest" echo.) && (del "%~dp0.rdwtest" >nul 2>&1) || set "LOGFILE=%TEMP%\RustDesk_Changer.log"

:: Work inside %TEMP% so generated helper scripts are always in a writable location
pushd "%temp%" >nul 2>&1

:: Feature: detect RustDesk install path dynamically from the Windows Registry
call :DetectPath

if not exist "%RUSTDESK_PATH%\rustdesk.exe" (
  echo.
  if %LANG_TR%==1 (
    echo 未安装 RustDesk，请先安装 RustDesk。
    echo.
    echo 按任意键退出。
  ) else (
    echo 未安装 RustDesk，请先安装 RustDesk。
    echo.
    echo 按任意键退出。
  )
  pause >nul
  exit
)

:: Current ID (full path, no cd needed)
for /f "usebackq delims=" %%i in (`"%RUSTDESK_PATH%\rustdesk.exe" --get-id ^| more`) do set "rustdesk_id=%%i"

:: Feature: status indicator (current server)
call :GetServerStatus

:: Minimum accepted custom-ID length varies by OS/RustDesk build:
::   Windows 10/11 client = 6, Windows 7/8.x = 7, Windows Server = 8
set "MIN_LEN=6"
ver | findstr /c:"Version 10." >nul || set "MIN_LEN=7"
set "INST_TYPE="
for /f "tokens=3" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v InstallationType 2^>nul') do set "INST_TYPE=%%i"
if /i "%INST_TYPE%"=="Server" set "MIN_LEN=8"

:Run
echo.
echo ==========================================================================================
echo.
if %LANG_TR%==1 goto Menu_TR
goto Menu_EN

:Menu_TR
echo			  RustDesk ID ^& 服务器修改工具 中文版
echo.
echo.		github.com/abdullah-erturk ^| erturk-dev.netlify.app
echo.
echo.	  当前 ID：%rustdesk_id%     服务器：%SERVER_STATUS%
echo.
echo.	-----------------------------------------------------------------
echo	 	  1 - 使用计算机名作为 RustDesk ID："%computername%"
echo	 	  2 - 使用 9 位随机数字作为 RustDesk ID
echo	 	  3 - 自定义设置为指定的 RustDesk ID
echo.	-----------------------------------------------------------------
echo	 	  4 - 切换到公共服务器 [清除私有服务器信息]
echo	 	  5 - 切换到私有服务器 [应用已备份的私有服务器信息]
echo	 	  6 - 新建私有服务器
echo	 	  7 - 导入完整配置 [Config String]
echo.	-----------------------------------------------------------------
echo	 	  8 - 设置永久密码
echo	 	  9 - 撤销上次 ID 修改 [Undo]
echo	 	  P - 重置设置锁定 PIN
echo	 	  0 - 删除私有服务器备份
echo	 	  X - 退出
echo.
echo ==========================================================================================
echo.
choice /c 1234567890PX /n /m "请选择 [1-2-3-4-5-6-7-8-9-0-P-X]： "
goto Menu_Choice

:Menu_EN
echo			  RustDesk ID ^& 服务器修改工具 中文版
echo.
echo.		github.com/abdullah-erturk ^| erturk-dev.netlify.app
echo.
echo.	  当前 ID：%rustdesk_id%     服务器：%SERVER_STATUS%
echo.
echo.	-----------------------------------------------------------------
echo	 	  1 - 使用计算机名作为 RustDesk ID："%computername%"
echo	 	  2 - 使用 9 位随机数字作为 RustDesk ID
echo	 	  3 - 自定义设置为指定的 RustDesk ID
echo.	-----------------------------------------------------------------
echo	 	  4 - 切换到公共服务器 [清除私有服务器信息]
echo	 	  5 - 切换到私有服务器 [应用已备份的私有服务器信息]
echo	 	  6 - 新建私有服务器
echo	 	  7 - 导入完整配置 [Config String]
echo.	-----------------------------------------------------------------
echo	 	  8 - 设置永久密码
echo	 	  9 - 撤销上次 ID 修改 [Undo]
echo	 	  P - 重置设置锁定 PIN
echo	 	  0 - 删除私有服务器备份
echo	 	  X - 退出
echo.
echo ==========================================================================================
echo.
choice /c 1234567890PX /n /m "请选择 [1-2-3-4-5-6-7-8-9-0-P-X]： "
goto Menu_Choice

:Menu_Choice
echo.
if errorlevel 12 Exit
if errorlevel 11 goto :Reset_PIN
if errorlevel 10 goto :Delete_Backups
if errorlevel 9 goto :Restore_ID
if errorlevel 8 goto :Set_Password
if errorlevel 7 goto :Config_Import
if errorlevel 6 goto :Server_Private_New
if errorlevel 5 goto :Server_Private
if errorlevel 4 goto :Server_Public
if errorlevel 3 goto :ID_UserDefined
if errorlevel 2 goto :ID_Random
if errorlevel 1 goto :ID_Host
echo.
::===============================================================================================================
:ID_Host
:: Computer name must meet the OS-required minimum length, otherwise RustDesk rejects it
set "NAME_OK=1"
if "%MIN_LEN%"=="8" if "%computername:~7,1%"=="" set "NAME_OK=0"
if "%MIN_LEN%"=="7" if "%computername:~6,1%"=="" set "NAME_OK=0"
if "%MIN_LEN%"=="6" if "%computername:~5,1%"=="" set "NAME_OK=0"
if "%NAME_OK%"=="0" (
    echo.
    if %LANG_TR%==1 (
        echo 警告：计算机名 "%computername%" 长度不足 %MIN_LEN% 个字符。
        echo 本系统要求 RustDesk ID 至少 %MIN_LEN% 个字符，未执行操作。
        echo 请改用第 2 或第 3 个选项。
    ) else (
        echo 警告：计算机名 "%computername%" 长度不足 %MIN_LEN% 个字符。
        echo 本系统要求 RustDesk ID 至少 %MIN_LEN% 个字符，未执行操作。
        echo 请改用第 2 或第 3 个选项。
    )
    call :Log "ID host SKIPPED: computer name too short (min=%MIN_LEN%)"
    goto :done
)
set "RD_ID_MODE=host"
set "RUSTDESK_NEW_ID="
goto :RunIDSet
::===============================================================================================================
:ID_Random
set "RD_ID_MODE=random"
set "RUSTDESK_NEW_ID="
goto :RunIDSet
::===============================================================================================================
:ID_UserDefined
echo.
:: MIN_LEN is computed in :Main (Win10/11=6, Win7/8=7, Server=8)
if %LANG_TR%==1 (
    echo 新的 RustDesk ID 值必须至少 %MIN_LEN% 个字符
    echo.
    goto Ask_ID_TR
) else (
    echo 新的 RustDesk ID 值必须至少 %MIN_LEN% 个字符
    echo.
    goto Ask_ID_EN
)

:Ask_ID_TR
set "RUSTDESK_NEW_ID="
set /p RUSTDESK_NEW_ID="请输入 RustDesk ID（至少 %MIN_LEN% 个字符）： "
if not defined RUSTDESK_NEW_ID (
    echo 错误：ID 不能为空！
    echo.
    goto Ask_ID_TR
)
set "LEN_OK=1"
if "%MIN_LEN%"=="8" if "%RUSTDESK_NEW_ID:~7,1%"=="" set "LEN_OK=0"
if "%MIN_LEN%"=="7" if "%RUSTDESK_NEW_ID:~6,1%"=="" set "LEN_OK=0"
if "%MIN_LEN%"=="6" if "%RUSTDESK_NEW_ID:~5,1%"=="" set "LEN_OK=0"
if "%LEN_OK%"=="0" (
    echo 错误：ID 必须至少 %MIN_LEN% 个字符！
    echo.
    goto Ask_ID_TR
)
set "RD_ID_MODE=custom"
goto :RunIDSet

:Ask_ID_EN
set "RUSTDESK_NEW_ID="
set /p RUSTDESK_NEW_ID="请输入 RustDesk ID（至少 %MIN_LEN% 个字符）： "
if not defined RUSTDESK_NEW_ID (
    echo 错误：ID 不能为空！
    echo.
    goto Ask_ID_EN
)
set "LEN_OK=1"
if "%MIN_LEN%"=="8" if "%RUSTDESK_NEW_ID:~7,1%"=="" set "LEN_OK=0"
if "%MIN_LEN%"=="7" if "%RUSTDESK_NEW_ID:~6,1%"=="" set "LEN_OK=0"
if "%MIN_LEN%"=="6" if "%RUSTDESK_NEW_ID:~5,1%"=="" set "LEN_OK=0"
if "%LEN_OK%"=="0" (
    echo 错误：ID 必须至少 %MIN_LEN% 个字符！
    echo.
    goto Ask_ID_EN
)
set "RD_ID_MODE=custom"
goto :RunIDSet
::===============================================================================================================
:RunIDSet
echo.
set "RUSTDESK_EXE=%RUSTDESK_PATH%\rustdesk.exe"
set "RD_OLD_ID=%rustdesk_id%"
echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_ID_Set.ps1
echo $mode = $env:RD_ID_MODE >> RustDesk_ID_Set.ps1
echo if ^($mode -eq "host"^) { $val = hostname } elseif ^($mode -eq "random"^) { $val = -join ^(^(48..57^) ^| Get-Random -Count 9 ^| ForEach-Object {[char]$_}^) } else { $val = $env:RUSTDESK_NEW_ID } >> RustDesk_ID_Set.ps1
echo $candidates = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml","$env:APPDATA\RustDesk\config\RustDesk.toml"^) >> RustDesk_ID_Set.ps1
echo $found = @^($candidates ^| Where-Object { Test-Path $_ }^) >> RustDesk_ID_Set.ps1
echo if ^($found.Count -eq 0^) { Write-Host "CONFIG_NOT_FOUND"; exit 2 } >> RustDesk_ID_Set.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_ID_Set.ps1
echo foreach ^($cfg in $found^) { Copy-Item -Path $cfg -Destination "$cfg.idbackup" -Force -ErrorAction SilentlyContinue; $c = Get-Content $cfg; $c = $c ^| Where-Object { $_ -notmatch "^^\s*enc_id\s*=" -and $_ -notmatch "^^\s*id\s*=" }; $c = @^("id = '" + $val + "'"^) + $c; $c ^| Set-Content $cfg } >> RustDesk_ID_Set.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_ID_Set.ps1
echo Start-Sleep -Seconds 2 >> RustDesk_ID_Set.ps1
echo $verify = "" >> RustDesk_ID_Set.ps1
echo try { $verify = ^(^& $env:RUSTDESK_EXE --get-id ^| Out-String^).Trim^(^) } catch {} >> RustDesk_ID_Set.ps1
if %LANG_TR%==1 (
    echo Write-Host ^("旧 ID： " + $env:RD_OLD_ID^) >> RustDesk_ID_Set.ps1
    echo Write-Host ^("新 ID： " + $verify^) >> RustDesk_ID_Set.ps1
) else (
    echo Write-Host ^("旧 ID： " + $env:RD_OLD_ID^) >> RustDesk_ID_Set.ps1
    echo Write-Host ^("新 ID： " + $verify^) >> RustDesk_ID_Set.ps1
)
echo if ^($verify -eq $val^) { exit 0 } else { exit 1 } >> RustDesk_ID_Set.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File RustDesk_ID_Set.ps1
set "RD_RESULT=%errorlevel%"
if "%RD_RESULT%"=="2" (
    if %LANG_TR%==1 (
        echo 错误：未找到 RustDesk 配置文件，无法更改 ID。
    ) else (
        echo 错误：未找到 RustDesk 配置文件，无法更改 ID。
    )
    call :Log "ID change FAILED (mode=%RD_ID_MODE%): config not found"
    goto :done
)
call :RestartGUI
call :GetServerStatus
echo.
if "%RD_RESULT%"=="0" (
    if %LANG_TR%==1 (
        echo 验证：ID 已成功修改。
    ) else (
        echo 验证：ID 已成功修改。
    )
) else (
    if %LANG_TR%==1 (
        echo 警告：已写入新 ID，但 RustDesk 分配了不同的 ID。
    ) else (
        echo 警告：已写入新 ID，但 RustDesk 分配了不同的 ID。
    )
)
echo %SERVER_STATUS%| findstr /b /c:"Public" >nul
if not errorlevel 1 if not "%RD_RESULT%"=="0" (
    if %LANG_TR%==1 (
        echo 注意：公共服务器可能不接受含字母/自定义字符的 ID，而分配一个纯数字 ID。
        echo      如需使用自定义 ID，请切换到私有服务器。
    ) else (
        echo 注意：公共服务器可能不接受含字母/自定义字符的 ID，而分配一个纯数字 ID。
        echo      如需使用自定义 ID，请切换到私有服务器。
    )
)
call :Log "ID set (mode=%RD_ID_MODE%) result=%RD_RESULT% server=%SERVER_STATUS%"
goto :done
::===============================================================================================================
:Restore_ID
echo.
set "RUSTDESK_EXE=%RUSTDESK_PATH%\rustdesk.exe"
echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_ID_Restore.ps1
echo $candidates = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml","$env:APPDATA\RustDesk\config\RustDesk.toml"^) >> RustDesk_ID_Restore.ps1
echo $found = @^($candidates ^| Where-Object { Test-Path $_ }^) >> RustDesk_ID_Restore.ps1
echo if ^($found.Count -eq 0^) { Write-Host "CONFIG_NOT_FOUND"; exit 2 } >> RustDesk_ID_Restore.ps1
echo $haveBk = @^($found ^| Where-Object { Test-Path ^($_ + ".idbackup"^) }^) >> RustDesk_ID_Restore.ps1
echo if ^($haveBk.Count -eq 0^) { Write-Host "NO_BACKUP"; exit 3 } >> RustDesk_ID_Restore.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_ID_Restore.ps1
echo foreach ^($cfg in $haveBk^) { Copy-Item -Path ^($cfg + ".idbackup"^) -Destination $cfg -Force } >> RustDesk_ID_Restore.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_ID_Restore.ps1
echo Start-Sleep -Seconds 2 >> RustDesk_ID_Restore.ps1
echo $verify = "" >> RustDesk_ID_Restore.ps1
echo try { $verify = ^(^& $env:RUSTDESK_EXE --get-id ^| Out-String^).Trim^(^) } catch {} >> RustDesk_ID_Restore.ps1
if %LANG_TR%==1 (
    echo Write-Host ^("已恢复 ID： " + $verify^) >> RustDesk_ID_Restore.ps1
) else (
    echo Write-Host ^("已恢复 ID： " + $verify^) >> RustDesk_ID_Restore.ps1
)
echo exit 0 >> RustDesk_ID_Restore.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File RustDesk_ID_Restore.ps1
set "RD_RESULT=%errorlevel%"
if "%RD_RESULT%"=="2" (
    if %LANG_TR%==1 (
        echo 错误：未找到 RustDesk 配置文件。
    ) else (
        echo 错误：未找到 RustDesk 配置文件。
    )
    call :Log "ID restore FAILED: config not found"
    goto :done
)
if "%RD_RESULT%"=="3" (
    if %LANG_TR%==1 (
        echo 未找到可恢复的 ID 备份，请先修改一次 ID。
    ) else (
        echo 未找到可恢复的 ID 备份，请先修改一次 ID。
    )
    call :Log "ID restore FAILED: no backup"
    goto :done
)
call :RestartGUI
echo.
if %LANG_TR%==1 (
    echo 验证：已成功恢复上一个 ID。
) else (
    echo 验证：已成功恢复上一个 ID。
)
call :Log "ID restored from backup"
goto :done
::===============================================================================================================
:Server_Public
echo.
echo $isPublic = $true > check_public.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> check_public.ps1
echo foreach ^($path in $paths^) { if ^(Test-Path $path^) { $content = Get-Content $path; if ^(^($content -match "^^custom-rendezvous-server"^) -or ^($content -match "^^api-server"^) -or ^($content -match "^^custom-rs-server"^)^) { $isPublic = $false } } } >> check_public.ps1
echo if ^($isPublic^) { exit 1 } else { exit 0 } >> check_public.ps1
powershell.exe -ExecutionPolicy Bypass -File check_public.ps1
if errorlevel 1 (
    del check_public.ps1 >nul 2>&1
    if %LANG_TR%==1 (
        echo 您已在使用公共服务器，未执行操作。
    ) else (
        echo 您已在使用公共服务器，未执行操作。
    )
    goto :done
)
del check_public.ps1 >nul 2>&1

echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_Server_Public.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_Server_Public.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> RustDesk_Server_Public.ps1
echo foreach ^($path in $paths^) { >> RustDesk_Server_Public.ps1
echo     if ^(Test-Path $path^) { >> RustDesk_Server_Public.ps1
echo         $content = Get-Content $path >> RustDesk_Server_Public.ps1
echo         $hasCustom = ^($content -match "^^custom-rendezvous-server" -or $content -match "^^api-server" -or $content -match "^^custom-rs-server"^) >> RustDesk_Server_Public.ps1
echo         if ^($hasCustom^) { Copy-Item -Path $path -Destination "$path.backup" -Force; if ^(-not ^(Test-Path "$path.backup"^)^) { exit 3 } } >> RustDesk_Server_Public.ps1
echo         $newContent = $content -replace "^^custom-rendezvous-server.*", "" >> RustDesk_Server_Public.ps1
echo         $newContent = $newContent -replace "^^custom-rs-server.*", "" >> RustDesk_Server_Public.ps1
echo         $newContent = $newContent -replace "^^api-server.*", "" >> RustDesk_Server_Public.ps1
echo         $newContent = $newContent -replace "^^custom-api-server.*", "" >> RustDesk_Server_Public.ps1
echo         $newContent = $newContent -replace "^^key.*", "" >> RustDesk_Server_Public.ps1
echo         $newContent = $newContent ^| Where-Object { $_.Trim^(^) -ne "" } >> RustDesk_Server_Public.ps1
echo         $newContent ^| Set-Content $path >> RustDesk_Server_Public.ps1
echo     } >> RustDesk_Server_Public.ps1
echo } >> RustDesk_Server_Public.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_Server_Public.ps1
powershell.exe -ExecutionPolicy Bypass -File RustDesk_Server_Public.ps1
if errorlevel 3 (
    if %LANG_TR%==1 (
        echo 备份时发生错误，请检查权限，操作已中止。
    ) else (
        echo 备份时发生错误，请检查权限，操作已中止。
    )
    call :Log "Switch to Public FAILED: backup error"
    goto :done
)
call :RestartGUI
echo.
if %LANG_TR%==1 (
    echo 已备份当前私有服务器设置并切换到公共服务器。
) else (
    echo 已备份当前私有服务器设置并切换到公共服务器。
)
call :GetServerStatus
if %LANG_TR%==1 (
    echo 验证 / 服务器状态：%SERVER_STATUS%
) else (
    echo 验证 / 服务器状态：%SERVER_STATUS%
)
echo %rustdesk_id%| findstr /r "[^0-9]" >nul
if not errorlevel 1 (
    echo.
    if %LANG_TR%==1 (
        echo 注意：当前 ID 含有字母/自定义字符，公共服务器不接受该 ID
        echo      连接后会自动分配一个纯数字 ID。
    ) else (
        echo 注意：当前 ID 含有字母/自定义字符，公共服务器不接受该 ID
        echo      连接后会自动分配一个纯数字 ID。
    )
)
call :Log "Switched to Public server"
goto :done
::===============================================================================================================
:Server_Private
echo.
echo $isPrivate = $false > check_private.ps1
echo $hasBackup = $false >> check_private.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> check_private.ps1
echo foreach ^($path in $paths^) { if ^(Test-Path $path^) { $content = Get-Content $path; if ^(^($content -match "^^custom-rendezvous-server"^) -or ^($content -match "^^api-server"^) -or ^($content -match "^^custom-rs-server"^)^) { $isPrivate = $true } } ; if ^(Test-Path "$path.backup"^) { $hasBackup = $true } } >> check_private.ps1
echo if ^($isPrivate^) { exit 1 } elseif ^(-not $hasBackup^) { exit 2 } else { exit 0 } >> check_private.ps1
powershell.exe -ExecutionPolicy Bypass -File check_private.ps1
if errorlevel 2 (
    del check_private.ps1 >nul 2>&1
    if %LANG_TR%==1 (
        echo 系统中未找到已保存的私有服务器备份。
        echo 请先在 RustDesk 中配置并连接私有服务器信息。
    ) else (
        echo 系统中未找到已保存的私有服务器备份。
        echo 请先在 RustDesk 中配置并连接私有服务器信息。
    )
    goto :done
)
if errorlevel 1 (
    del check_private.ps1 >nul 2>&1
    if %LANG_TR%==1 (
        echo 您已在使用私有服务器，未执行操作。
    ) else (
        echo 您已在使用私有服务器，未执行操作。
    )
    goto :done
)
del check_private.ps1 >nul 2>&1

echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_Server_Private.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_Server_Private.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> RustDesk_Server_Private.ps1
echo foreach ^($path in $paths^) { >> RustDesk_Server_Private.ps1
echo     $backupPath = "$path.backup" >> RustDesk_Server_Private.ps1
echo     if ^(Test-Path $backupPath^) { Copy-Item -Path $backupPath -Destination $path -Force } >> RustDesk_Server_Private.ps1
echo } >> RustDesk_Server_Private.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_Server_Private.ps1
powershell.exe -ExecutionPolicy Bypass -File RustDesk_Server_Private.ps1
call :RestartGUI
echo.
if %LANG_TR%==1 (
    echo 已恢复已备份的私有服务器设置。
) else (
    echo 已恢复已备份的私有服务器设置。
)
call :GetServerStatus
if %LANG_TR%==1 (
    echo 验证 / 服务器状态：%SERVER_STATUS%
) else (
    echo 验证 / 服务器状态：%SERVER_STATUS%
)
call :Log "Switched to Private server (restored backup)"
goto :done
::===============================================================================================================
:Server_Private_New
echo.
echo $isPrivate = $false > check_private_new.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> check_private_new.ps1
echo foreach ^($path in $paths^) { if ^(Test-Path $path^) { $content = Get-Content $path; if ^(^($content -match "^^custom-rendezvous-server"^) -or ^($content -match "^^api-server"^) -or ^($content -match "^^custom-rs-server"^)^) { $isPrivate = $true } } } >> check_private_new.ps1
echo if ^($isPrivate^) { exit 1 } else { exit 0 } >> check_private_new.ps1
powershell.exe -ExecutionPolicy Bypass -File check_private_new.ps1
if errorlevel 1 (
    del check_private_new.ps1 >nul 2>&1
    if %LANG_TR%==1 (
        echo 已配置过私有服务器。请先使用第 4 项切换到公共服务器并备份现有设置。
    ) else (
        echo 已配置过私有服务器。请先使用第 4 项切换到公共服务器并备份现有设置。
    )
    goto :done
)
del check_private_new.ps1 >nul 2>&1

if %LANG_TR%==1 goto Server_Private_New_TR
goto Server_Private_New_EN

:Server_Private_New_TR
echo 请输入新的私有服务器（Rendezvous 服务器）IP 或主机地址。
set /p RS_HOST="服务器地址（例：192.168.1.100 或 hb.example.com）： "
echo.
echo 请输入 Key（密钥）。如果没有 Key，留空并按 ENTER。
set /p RS_KEY="Key（可选）： "
goto Server_Private_New_Proceed

:Server_Private_New_EN
echo 请输入新的私有服务器（Rendezvous 服务器）IP 或主机地址。
set /p RS_HOST="服务器地址（例：192.168.1.100 或 hb.example.com）： "
echo.
echo 请输入 Key（密钥）。如果没有 Key，留空并按 ENTER。
set /p RS_KEY="Key（可选）： "
goto Server_Private_New_Proceed

:Server_Private_New_Proceed
echo.
echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_Server_Private_New.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_Server_Private_New.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml", "$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> RustDesk_Server_Private_New.ps1
echo foreach ^($path in $paths^) { >> RustDesk_Server_Private_New.ps1
echo     if ^(Test-Path $path^) { >> RustDesk_Server_Private_New.ps1
echo         $newContent = Get-Content $path >> RustDesk_Server_Private_New.ps1
echo         $newContent = $newContent ^| Where-Object { $_.Trim^(^) -ne "" } >> RustDesk_Server_Private_New.ps1
echo         $newContent += "custom-rendezvous-server = '" + $env:RS_HOST + "'" >> RustDesk_Server_Private_New.ps1
echo         $newContent += "key = '" + $env:RS_KEY + "'" >> RustDesk_Server_Private_New.ps1
echo         $newContent ^| Set-Content $path >> RustDesk_Server_Private_New.ps1
echo     } >> RustDesk_Server_Private_New.ps1
echo } >> RustDesk_Server_Private_New.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_Server_Private_New.ps1
powershell.exe -ExecutionPolicy Bypass -File RustDesk_Server_Private_New.ps1
call :RestartGUI
echo.
if %LANG_TR%==1 (
    echo 已成功配置新的私有服务器并重启 RustDesk。
) else (
    echo 已成功配置新的私有服务器并重启 RustDesk。
)
call :GetServerStatus
if %LANG_TR%==1 (
    echo 验证 / 服务器状态：%SERVER_STATUS%
) else (
    echo 验证 / 服务器状态：%SERVER_STATUS%
)
call :Log "New Private server defined"
goto :done
::===============================================================================================================
:Config_Import
echo.
if %LANG_TR%==1 (
    echo 粘贴您在 RustDesk 中导出的完整配置字符串。
    echo 该字符串包含 ID/中继/API 服务器及 Key 信息。
) else (
    echo 粘贴您在 RustDesk 中导出的完整配置字符串。
    echo 该字符串包含 ID/中继/API 服务器及 Key 信息。
)
echo.
set "RD_CFG="
set /p RD_CFG="配置字符串（Config String）： "
if not defined RD_CFG (
    if %LANG_TR%==1 (
        echo 错误：配置字符串不能为空！
    ) else (
        echo 错误：配置字符串不能为空！
    )
    goto :done
)
echo $q = [char]34 > RustDesk_Config_Import.ps1
echo $sq = [char]39 >> RustDesk_Config_Import.ps1
echo $shost = ''; $srelay = ''; $sapi = ''; $skey = ''; $dec = '' >> RustDesk_Config_Import.ps1
echo $cfg_str = $env:RD_CFG >> RustDesk_Config_Import.ps1
echo try { $arr = $cfg_str.ToCharArray^(^); [Array]::Reverse^($arr^); $rev = -join $arr; $dec = [System.Text.Encoding]::UTF8.GetString^([Convert]::FromBase64String^($rev^)^) } catch { $dec = '' } >> RustDesk_Config_Import.ps1
echo foreach ^($f in @^('host','relay','api','key'^)^) { $pat = $q + $f + $q + '\s*:\s*' + $q + '^([^^' + $q + ']*^)' + $q; if ^($dec -match $pat^) { Set-Variable -Name ^('s' + $f^) -Value $matches[1] } } >> RustDesk_Config_Import.ps1
echo if ^(-not $shost^) { Write-Host 'INVALID_CONFIG'; exit 4 } >> RustDesk_Config_Import.ps1
echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue >> RustDesk_Config_Import.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml","$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> RustDesk_Config_Import.ps1
echo $found = @^($paths ^| Where-Object { Test-Path $_ }^) >> RustDesk_Config_Import.ps1
echo if ^($found.Count -eq 0^) { Write-Host 'CONFIG_NOT_FOUND'; exit 2 } >> RustDesk_Config_Import.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_Config_Import.ps1
echo foreach ^($p in $found^) { $c = Get-Content $p; $c = $c ^| Where-Object { $_ -notmatch '^^\s*custom-rendezvous-server' -and $_ -notmatch '^^\s*custom-rs-server' -and $_ -notmatch '^^\s*relay-server' -and $_ -notmatch '^^\s*api-server' -and $_ -notmatch '^^\s*custom-api-server' -and $_ -notmatch '^^\s*key\s*=' }; $c = @^($c ^| Where-Object { $_.Trim^(^) -ne '' }^); $c += 'custom-rendezvous-server = ' + $sq + $shost + $sq; if ^($srelay^) { $c += 'relay-server = ' + $sq + $srelay + $sq }; if ^($sapi^) { $c += 'api-server = ' + $sq + $sapi + $sq }; $c += 'key = ' + $sq + $skey + $sq; $c ^| Set-Content $p } >> RustDesk_Config_Import.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_Config_Import.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File RustDesk_Config_Import.ps1
set "RD_RESULT=%errorlevel%"
if "%RD_RESULT%"=="4" (
    if %LANG_TR%==1 (
        echo 错误：无法解析配置字符串，请输入从 RustDesk 导出的有效字符串。
    ) else (
        echo 错误：无法解析配置字符串，请输入从 RustDesk 导出的有效字符串。
    )
    call :Log "Config import FAILED: invalid string"
    goto :done
)
if "%RD_RESULT%"=="2" (
    if %LANG_TR%==1 (
        echo 错误：未找到 RustDesk2.toml。
    ) else (
        echo 错误：未找到 RustDesk2.toml。
    )
    call :Log "Config import FAILED: config not found"
    goto :done
)
call :RestartGUI
call :GetServerStatus
echo.
if %LANG_TR%==1 (
    echo 配置已导入并应用到两个配置文件。
    echo 验证 / 服务器状态：%SERVER_STATUS%
) else (
    echo 配置已导入并应用到两个配置文件。
    echo 验证 / 服务器状态：%SERVER_STATUS%
)
call :Log "Config string imported, server=%SERVER_STATUS%"
goto :done
::===============================================================================================================
:Set_Password
echo.
setlocal enabledelayedexpansion
if %LANG_TR%==1 (
    echo 永久访问密码必须至少 6 个字符。
) else (
    echo 永久访问密码必须至少 6 个字符。
)
echo.
:Ask_PW
set "RD_PW="
if %LANG_TR%==1 (
    set /p RD_PW="新密码： "
) else (
    set /p RD_PW="新密码： "
)
if not defined RD_PW (
    if %LANG_TR%==1 ( echo 错误：密码不能为空！ ) else ( echo 错误：密码不能为空！ )
    echo.
    goto Ask_PW
)
if "!RD_PW:~5,1!"=="" (
    if %LANG_TR%==1 ( echo 错误：密码必须至少 6 个字符！ ) else ( echo 错误：密码必须至少 6 个字符！ )
    echo.
    goto Ask_PW
)
set "RUSTDESK_EXE=%RUSTDESK_PATH%\rustdesk.exe"
echo ^& $env:RUSTDESK_EXE --password $env:RD_PW > RustDesk_Password.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File RustDesk_Password.ps1
set "RD_RESULT=%errorlevel%"
endlocal & set "RD_RESULT=%RD_RESULT%"
call :RestartGUI
echo.
if "%RD_RESULT%"=="0" (
    if %LANG_TR%==1 (
        echo 验证：永久密码已成功设置。
    ) else (
        echo 验证：永久密码已成功设置。
    )
) else (
    if %LANG_TR%==1 (
        echo 警告：设置密码命令返回错误，请检查您的 RustDesk 版本。
    ) else (
        echo 警告：设置密码命令返回错误，请检查您的 RustDesk 版本。
    )
)
call :Log "Permanent password set, result=%RD_RESULT%"
goto :done
::===============================================================================================================
:Reset_PIN
echo.
echo $svc = Get-Service -Name RustDesk -ErrorAction SilentlyContinue > RustDesk_Reset_PIN.ps1
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml","$env:APPDATA\RustDesk\config\RustDesk2.toml"^) >> RustDesk_Reset_PIN.ps1
echo $found = @^($paths ^| Where-Object { Test-Path $_ }^) >> RustDesk_Reset_PIN.ps1
echo if ^($found.Count -eq 0^) { Write-Host 'CONFIG_NOT_FOUND'; exit 2 } >> RustDesk_Reset_PIN.ps1
echo $had = $false >> RustDesk_Reset_PIN.ps1
echo foreach ^($p in $found^) { if ^(Get-Content $p ^| Where-Object { $_ -match "^^\s*unlock_pin\s*=" }^) { $had = $true } } >> RustDesk_Reset_PIN.ps1
echo if ^(-not $had^) { Write-Host 'NO_PIN'; exit 3 } >> RustDesk_Reset_PIN.ps1
echo if ^($svc^) { Stop-Service -Name RustDesk -Force -ErrorAction SilentlyContinue }; Get-Process rustdesk -ErrorAction SilentlyContinue ^| Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 >> RustDesk_Reset_PIN.ps1
echo foreach ^($p in $found^) { $c = Get-Content $p ^| Where-Object { $_ -notmatch "^^\s*unlock_pin\s*=" }; $c ^| Set-Content $p } >> RustDesk_Reset_PIN.ps1
echo if ^($svc^) { Start-Service -Name RustDesk -ErrorAction SilentlyContinue } >> RustDesk_Reset_PIN.ps1
echo exit 0 >> RustDesk_Reset_PIN.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File RustDesk_Reset_PIN.ps1
set "RD_RESULT=%errorlevel%"
if "%RD_RESULT%"=="2" (
    if %LANG_TR%==1 (
        echo 错误：未找到 RustDesk2.toml。
    ) else (
        echo 错误：未找到 RustDesk2.toml。
    )
    call :Log "Reset unlock_pin FAILED: config not found"
    goto :done
)
if "%RD_RESULT%"=="3" (
    if %LANG_TR%==1 (
        echo 未发现已设置的锁定 PIN，未执行操作。
    ) else (
        echo 未发现已设置的锁定 PIN，未执行操作。
    )
    call :Log "Reset unlock_pin: no PIN set"
    goto :done
)
call :RestartGUI
echo.
if %LANG_TR%==1 (
    echo 已移除设置锁定 PIN，您可以在 RustDesk 界面重新设置 PIN。
) else (
    echo 已移除设置锁定 PIN，您可以在 RustDesk 界面重新设置 PIN。
)
call :Log "Settings-lock PIN reset"
goto :done
::===============================================================================================================
:Delete_Backups
echo.
del /f /q "%APPDATA%\RustDesk\config\RustDesk2.toml.backup" >nul 2>&1
del /f /q "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml.backup" >nul 2>&1
if %LANG_TR%==1 (
    echo 私有服务器备份已成功删除！
) else (
    echo 私有服务器备份已成功删除！
)
call :Log "Custom server backups deleted"
goto :done
::===============================================================================================================
:done
del RustDesk_ID_Set.ps1 >nul 2>&1
del RustDesk_ID_Restore.ps1 >nul 2>&1
del RustDesk_Server_Public.ps1 >nul 2>&1
del RustDesk_Server_Private.ps1 >nul 2>&1
del RustDesk_Server_Private_New.ps1 >nul 2>&1
del RustDesk_Config_Import.ps1 >nul 2>&1
del RustDesk_Password.ps1 >nul 2>&1
del RustDesk_Reset_PIN.ps1 >nul 2>&1
del detect_path.ps1 >nul 2>&1
del server_status.ps1 >nul 2>&1
echo.
if %LANG_TR%==1 (
    echo	 操作已完成
    echo.
    choice /C:MX /N /M "按 M 返回主菜单，按 X 退出： "
) else (
    echo	 操作已完成
    echo.
    choice /C:MX /N /M "按 M 返回主菜单，按 X 退出： "
)
if errorlevel 2 Exit
if errorlevel 1 goto :Main
::===============================================================================================================
:DetectPath
set "RUSTDESK_PATH=C:\Program Files\RustDesk"
echo $p = $null > detect_path.ps1
echo $keys = @^("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk"^) >> detect_path.ps1
echo foreach ^($k in $keys^) { if ^(Test-Path $k^) { $v = ^(Get-ItemProperty -Path $k -ErrorAction SilentlyContinue^).InstallLocation; if ^($v^) { $p = $v; break } } } >> detect_path.ps1
echo if ^(-not $p^) { $p = "C:\Program Files\RustDesk" } >> detect_path.ps1
echo Write-Output $p.TrimEnd^("\"^) >> detect_path.ps1
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -File detect_path.ps1`) do set "RUSTDESK_PATH=%%p"
del detect_path.ps1 >nul 2>&1
goto :eof
::===============================================================================================================
:GetServerStatus
set "SERVER_STATUS=Public"
echo $paths = @^("C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml","$env:APPDATA\RustDesk\config\RustDesk2.toml"^) > server_status.ps1
echo $srv = "Public" >> server_status.ps1
echo foreach ^($path in $paths^) { if ^(Test-Path $path^) { $line = ^(Get-Content $path ^| Where-Object { $_ -match "^^custom-rendezvous-server" } ^| Select-Object -First 1^); if ^($line^) { $addr = ^(^($line -replace "custom-rendezvous-server\s*=\s*",""^).Trim^(^).Trim^("'"^)^); $srv = "Private [" + $addr + "]"; break } } } >> server_status.ps1
echo Write-Output $srv >> server_status.ps1
for /f "usebackq delims=" %%s in (`powershell -NoProfile -ExecutionPolicy Bypass -File server_status.ps1`) do set "SERVER_STATUS=%%s"
del server_status.ps1 >nul 2>&1
goto :eof
::===============================================================================================================
:RestartGUI
:: Restart only the user-session RustDesk GUI (SessionId != 0) so the app window
:: instantly reflects the new ID/server. The service process (SessionId 0) is left intact.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process rustdesk -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -ne 0 } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
timeout /t 1 >nul 2>&1
start "" "%RUSTDESK_PATH%\rustdesk.exe" --tray
goto :eof
::===============================================================================================================
:Log
>>"%LOGFILE%" echo [%date% %time%] %~1
goto :eof
::===============================================================================================================
