# Applications Subsystem (`apps/`)

![Version](https://img.shields.io/badge/version-0.2.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows_11-lightgrey)

This directory hosts third-party software installers and execution scripts for **AutoInstaller**. Each application is decoupled into an autonomous subfolder containing an `install.au3` mini-installer.

---

## Mini-Installer Interface Standard (`install.au3`)

Every mini-installer adheres to a standardized parameter contract and exit code scheme:

### Parameters
| Position | Variable | Description | Default Fallback |
| :---: | :--- | :--- | :--- |
| `$CmdLine[1]` | `$g_sSetupFilename` | Vendor setup filename or absolute/relative path | Pre-defined per application (e.g. `7z.exe`) |
| `$CmdLine[2]` | `$g_bShortcut` | `"true"` to create Public Desktop shortcut, `"false"` to skip | `False` |
| `$CmdLine[3]` | `$g_bClean` | Cleanup flag (consumed by Font installer) | `False` |
| `$CmdLine[4]` | `$g_sLogPath` | Destination log file | `C:\Auto-installer\install-apps.log` |

### Path Resolution
Mini-installers support both local script-relative binaries and caller-supplied paths:
```autoit
Global $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
If FileExists($g_sSetupFilename) Then $g_sSetupPath = $g_sSetupFilename
```

### Exit Codes
| Exit Code | Meaning |
| :---: | :--- |
| `0` | Success (application installed and verified) |
| `10` | Already installed (pre-existing installation detected, shortcut refreshed) |
| `20` | Setup file missing (`$g_sSetupPath` not found on disk) |
| `21` | Execution error (`RunWait` failed with an AutoIt error) |
| `22` | Verification timeout (application installation not verified within timeout window) |
| Non-zero | Vendor installer exit code |

### Logging Format
Logs are appended to `$g_sLogPath` in UTF-8 without BOM:
```text
[YYYY-MM-DD HH:MM:SS] [AppName] <Message>
```

---

## Active Application Catalog (31 Applications)

| # | Application | Category | Default Binary | Status | Public Desktop Shortcut |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 0 | **7z** | Archiver | `7z.exe` | Imported | `7-Zip File Manager.lnk` |
| 1 | **Brave** | Browser | `brave.exe` | Skeleton Template | `Brave.lnk` |
| 2 | **Discord** | Social | `discord.exe` | Imported | `Discord.lnk` |
| 3 | **Docker** | Development | `DockerDesktopInstaller.exe`| Skeleton Template | `Docker Desktop.lnk` |
| 4 | **Fonts** | Utility | `Fonts/` | Imported | *None* |
| 5 | **Git** | Development | `git.exe` | Skeleton Template | `Git Bash.lnk` |
| 6 | **GoogleChrome** | Browser | `chrome-standalone.exe` | Imported | `Google Chrome.lnk` |
| 7 | **Java** | Environment | `java.exe` | Imported | `Java Web Start.lnk` |
| 8 | **Kaspersky** | Antivirus | `kaspersky.exe` | Imported | `Kaspersky.lnk` |
| 9 | **LibreOffice** | Office | `libreoffice.msi` | Imported | `LibreOffice.lnk` |
| 10 | **MicrosoftOffice**| Office | `office2024.exe` | Imported | Office Apps (Word, Excel, PPT...) |
| 11 | **MPC-HC** | Media | `mpc.exe` | Imported | `MPC-HC x64.lnk` |
| 12 | **MSYS2** | Development | `msys2.exe` | Skeleton Template | `MSYS2 UCRT64.lnk` |
| 13 | **Notepad++** | Editor | `notepadpp.exe` | Imported | `Notepad++.lnk` |
| 14 | **OBS** | Media | `obs.exe` | Imported | `OBS Studio.lnk` |
| 15 | **PotPlayer** | Media | `potplayer.exe` | Imported | `PotPlayer 64 bit.lnk` |
| 16 | **Python** | Environment | `python.exe` | Imported | `IDLE (Python x.y).lnk` |
| 17 | **qBittorrent** | Torrent | `qbittorrent.exe` | Imported | `qBittorrent.lnk` |
| 18 | **Shell** | File Explorer| `shell.msi` | Imported | *None* |
| 19 | **Tailscale** | Network | `tailscale.exe` | Skeleton Template | `Tailscale.lnk` |
| 20 | **TeamViewer** | Remote | `teamviewer.exe` | Imported | `TeamViewer.lnk` |
| 21 | **UltraViewer** | Remote | `ultraviewer.exe` | Imported | `UltraViewer.lnk` |
| 22 | **Unikey** | Utility | `unikey.exe` | Imported | `UniKey NT.lnk` |
| 23 | **VCRedist** | Environment | `vcredist-AIO.exe` | Imported | *None* |
| 24 | **VisualStudio** | IDE | `vs_community.exe` | Skeleton Template | `Visual Studio 2022.lnk` |
| 25 | **VLC** | Media | `vlc.exe` | Imported | `VLC media player.lnk` |
| 26 | **VSCode** | Editor | `vscode.exe` | Imported | `Visual Studio Code.lnk` |
| 27 | **WinRAR** | Archiver | `winrar.exe` | Imported | `WinRAR.lnk` |
| 28 | **WireGuard** | Network | `wireguard.exe` | Skeleton Template | `WireGuard.lnk` |
| 29 | **yt-dlp** | Utility | `yt-dlp.exe` | Skeleton Template | `yt-dlp.lnk` |
| 30 | **Zalo** | Social | `zalo.exe` | Imported | `Zalo.lnk` |

---

## Recommended Applications for Future Expansion

The following curated applications are recommended for future expansion to cover additional workstation, development, and multimedia requirements:

### Web Browsers
- **Mozilla Firefox** (`apps/Firefox`): Silent flag `/S`.
- **Microsoft Edge** (`apps/Edge`): Enterprise MSI silent flag `/qn /norestart`.
- **Tor Browser** (`apps/TorBrowser`): Silent flag `/S`.
- **Vivaldi** (`apps/Vivaldi`): Silent flag `--vivaldi-silent --do-not-launch-chrome`.

### System Utilities & Power Tools
- **Everything (Voidtools)** (`apps/Everything`): Silent flag `/S`.
- **Microsoft PowerToys** (`apps/PowerToys`): Silent flag `/passive /norestart`.
- **System Informer** (`apps/SystemInformer`): Silent flag `-silent`.
- **WizTree** (`apps/WizTree`): Silent flag `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`.
- **ShareX** (`apps/ShareX`): Silent flag `/VERYSILENT /NORESTART`.
- **Rufus** (`apps/Rufus`): Portable utility placed in `%ProgramFiles%\Rufus`.
- **Bulk Crap Uninstaller** (`apps/BCUninstaller`): Silent flag `/VERYSILENT /NORESTART`.

### Development Tools & Runtimes
- **Node.js (LTS)** (`apps/NodeJS`): MSI silent flag `/qn /norestart`.
- **Eclipse Temurin OpenJDK** (`apps/OpenJDK`): MSI silent flag `/qn ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome /norestart`.
- **DBeaver Community** (`apps/DBeaver`): Silent flag `/S`.
- **Sublime Text** (`apps/SublimeText`): Silent flag `/VERYSILENT /NORESTART`.
- **Rustup / Rust** (`apps/Rust`): Silent flag `-y --default-toolchain stable`.

### Media, Audio & Graphics
- **HandBrake** (`apps/HandBrake`): Silent flag `/S`.
- **Audacity** (`apps/Audacity`): Silent flag `/VERYSILENT /NORESTART`.
- **Paint.NET** (`apps/PaintDotNet`): Silent flag `/auto`.
- **GIMP** (`apps/GIMP`): Silent flag `/VERYSILENT /NORESTART /ALLUSERS`.

### Communication & Remote Collaboration
- **Telegram Desktop** (`apps/Telegram`): Silent flag `/VERYSILENT /NORESTART`.
- **AnyDesk** (`apps/AnyDesk`): Silent flag `--install "C:\Program Files (x86)\AnyDesk" --start-with-win --silent`.
- **Zoom** (`apps/Zoom`): MSI silent flag `/qn /norestart ZoomAutoUpdate=true`.

### Gaming, Graphics & Core Runtimes
- **Steam** (`apps/Steam`): Silent flag `/S`.
- **DirectX End-User Runtime** (`apps/DirectX`): Silent flag `/silent`.
- **.NET Desktop Runtime 8** (`apps/DotNet8`): Silent flag `/install /quiet /norestart`.
