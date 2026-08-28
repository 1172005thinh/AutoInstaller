# REPO STRUCTURE

A complete structure of AutoInstaller repository:

``` txt
AutoInstaller/
├── .git
│   └── ...
├── Antivirus
│   ├── install_kaspersky.au3
│   └── README.md
├── Browsers
│   ├── install_chrome-standalone.au3
│   └── README.md
├── Drivers
│   ├── SDIO
│   └── README.md
├── Environment
│   ├── IDEs
│   │   ├── install_vs.au3
│   │   └── README.md
│   ├── Java
│   │   ├── install_java.au3
│   │   └── README.md
│   ├── Python
│   │   ├── install_python.au3
│   │   └── README.md
│   ├── VCRedist
│   │   ├── install_vcredist.au3
│   │   └── README.md
│   └── README.md
├── Office
│   ├── LibreOffice
│   │   ├── install_libreoffice.au3
│   │   └── README.md      
│   ├── Office2024
│   │   ├── full_en.xml
│   │   ├── full_vi.xml
│   │   ├── wepa_en.xml
│   │   ├── we_en.xml
│   │   ├── wep_en.xml
│   │   ├── install_office2024.au3
│   │   └── README.md
│   └── README.md
├── Socials
│   ├── install_discord.au3
│   ├── install_zalo.au3
│   └── README.md
├── Tools
│   ├── Archivers
│   │   ├── .gitignore
│   │   ├── install_7z.au3
│   │   ├── install_winrar.au3
│   │   └── README.md
│   ├── DesktopSupporters
│   │   ├── install_teamviewer.au3
│   │   ├── install_ultraviewer.au3
│   │   └── README.md
│   ├── Editors
│   │   ├── install_notepadpp.au3
│   │   ├── install_vscode.au3
│   │   └── README.md
│   └── ScreenRecorders
│       ├── install_obs.au3
│       └── README.md
├── Unattend
│   ├── .gitignore
│   ├── full_C.xml
│   ├── full_C_D.xml
│   ├── full_dyn_C_D.xml
│   ├── full_mandisk.xml
│   ├── noapps_C.xml
│   ├── noapps_C_D.xml
│   ├── noapps_dyn_C_D.xml
│   ├── noapps_mandisk.xml
│   ├── nodrivers_C.xml
│   ├── nodrivers_C_D.xml
│   ├── nodrivers_dyn_C_D.xml
│   ├── nodrivers_mandisk.xml
│   └── README.md
├── Utilities
│   ├── FileExplorer
│   │   ├── install_shell.au3
│   │   └── README.md
│   ├── Fonts
│   │   ├── .gitignore
│   │   ├── install_fonts.au3
│   │   ├── install_fonts.ps1
│   │   └── README.md
│   ├── MediaPlayers
│   │   ├── install_mpc.au3
│   │   └── README.md
│   └── VietnameseKeyboards
│       ├── install_unikey.au3
│       ├── unikey.reg
│       └── README.md
├── ventoy
│   ├── font
│   │   └── cascadia-code
│   │       ├── cascadia-code_12.pf2
│   │       ├── cascadia-code_14.pf2
│   │       ├── cascadia-code_16.pf2
│   │       ├── cascadia-code_18.pf2
│   │       ├── cascadia-code_20.pf2
│   │       ├── cascadia-code_22.pf2
│   │       ├── cascadia-code_24.pf2
│   │       ├── cascadia-code_26.pf2
│   │       ├── cascadia-code_28.pf2
│   │       ├── cascadia-code_30.pf2
│   │       └── cascadia-code_32.pf2
│   ├── theme
│   │   ├── 1172005thinh
│   │   │   ├── icons
│   │   │   │   ├── 4MLinux.png
│   │   │   │   ├── AlpineLinux.png
│   │   │   │   ├── android.png
│   │   │   │   ├── anonymous.png
│   │   │   │   ├── antergos.png
│   │   │   │   ├── arch.png
│   │   │   │   ├── archcraft.png
│   │   │   │   ├── archlinux.png
│   │   │   │   ├── arcolinux.png
│   │   │   │   ├── artix.png
│   │   │   │   ├── brunch-settings.png
│   │   │   │   ├── brunch.png
│   │   │   │   ├── cancel.png
│   │   │   │   ├── chakra.png
│   │   │   │   ├── chimera.png
│   │   │   │   ├── debian.png
│   │   │   │   ├── deepin.png
│   │   │   │   ├── default.png
│   │   │   │   ├── devuan.png
│   │   │   │   ├── driver.png
│   │   │   │   ├── edit.png
│   │   │   │   ├── efi.png
│   │   │   │   ├── elementary.png
│   │   │   │   ├── endeavouros.png
│   │   │   │   ├── fedora.png
│   │   │   │   ├── find.efi.png
│   │   │   │   ├── find.none.png
│   │   │   │   ├── freebsd.png
│   │   │   │   ├── gentoo.png
│   │   │   │   ├── gnu-linux.png
│   │   │   │   ├── gpart.png
│   │   │   │   ├── haiku.png
│   │   │   │   ├── help.png
│   │   │   │   ├── kali.png
│   │   │   │   ├── kaos.png
│   │   │   │   ├── kbd.png
│   │   │   │   ├── kernel.png
│   │   │   │   ├── korora.png
│   │   │   │   ├── kubuntu.png
│   │   │   │   ├── lang.png
│   │   │   │   ├── lfs.png
│   │   │   │   ├── linux.png
│   │   │   │   ├── linuxmint.png
│   │   │   │   ├── lubuntu.png
│   │   │   │   ├── macosx.png
│   │   │   │   ├── mageia.png
│   │   │   │   ├── Manjaro.i686.png
│   │   │   │   ├── manjaro.png
│   │   │   │   ├── Manjaro.x86_64.png
│   │   │   │   ├── manjarolinux.png
│   │   │   │   ├── memtest.png
│   │   │   │   ├── mx-linux.png
│   │   │   │   ├── neon.png
│   │   │   │   ├── nixos.png
│   │   │   │   ├── nobara.png
│   │   │   │   ├── opensuse.png
│   │   │   │   ├── parrot.png
│   │   │   │   ├── pop-os.png
│   │   │   │   ├── pop.png
│   │   │   │   ├── recovery.png
│   │   │   │   ├── regolith.png
│   │   │   │   ├── restart.png
│   │   │   │   ├── shutdown.png
│   │   │   │   ├── siduction.png
│   │   │   │   ├── solus.png
│   │   │   │   ├── steamos.png
│   │   │   │   ├── submenu.png
│   │   │   │   ├── SystemRescueCD.png
│   │   │   │   ├── type.png
│   │   │   │   ├── tz.png
│   │   │   │   ├── ubuntu.png
│   │   │   │   ├── ubuntuDDE.png
│   │   │   │   ├── unknown.png
│   │   │   │   ├── unset.png
│   │   │   │   ├── ventoy.png
│   │   │   │   ├── void.png
│   │   │   │   ├── windows.png
│   │   │   │   ├── xubuntu.png
│   │   │   │   └── zorin.png
│   │   │   ├── background_dark1610_fb.jpg
│   │   │   ├── background_dark1610_gh.jpg
│   │   │   ├── background_dark1610_htc.jpg
│   │   │   ├── background_dark169_fb.jpg
│   │   │   ├── background_dark169_gh.jpg
│   │   │   ├── background_dark169_htc.jpg
│   │   │   ├── background_dark43_fb.jpg
│   │   │   ├── background_dark43_gh.jpg
│   │   │   ├── background_dark43_htc.jpg
│   │   │   ├── background_light1610_fb.jpg
│   │   │   ├── background_light1610_gh.jpg
│   │   │   ├── background_light1610_htc.jpg
│   │   │   ├── background_light169_fb.jpg
│   │   │   ├── background_light169_gh.jpg
│   │   │   ├── background_light169_htc.jpg
│   │   │   ├── background_light43_fb.jpg
│   │   │   ├── background_light43_gh.jpg
│   │   │   ├── background_light43_htc.jpg
│   │   │   ├── cascadia-code_16.pf2
│   │   │   ├── cascadia-code_28.pf2
│   │   │   ├── select_c.png
│   │   │   ├── select_e.png
│   │   │   ├── select_w.png
│   │   │   ├── theme_dark1610_fb.txt
│   │   │   ├── theme_dark1610_gh.txt
│   │   │   ├── theme_dark1610_htc.txt
│   │   │   ├── theme_dark169_fb.txt
│   │   │   ├── theme_dark169_gh.txt
│   │   │   ├── theme_dark169_htc.txt
│   │   │   ├── theme_dark43_fb.txt
│   │   │   ├── theme_dark43_gh.txt
│   │   │   ├── theme_dark43_htc.txt
│   │   │   ├── theme_light1610_fb.txt
│   │   │   ├── theme_light1610_gh.txt
│   │   │   ├── theme_light1610_htc.txt
│   │   │   ├── theme_light169_fb.txt
│   │   │   ├── theme_light169_gh.txt
│   │   │   ├── theme_light169_htc.txt
│   │   │   ├── theme_light43_fb.txt
│   │   │   ├── theme_light43_gh.txt
│   │   │   └── theme_light43_htc.txt
│   │   ├── .gitignore
│   │   ├── preview_dark1610.png
│   │   ├── preview_dark169.png
│   │   ├── preview_dark43.png
│   │   ├── preview_light1610.png
│   │   ├── preview_light169.png
│   │   ├── preview_light43.png
│   │   └── README.md
│   ├── README.md
│   ├── ventoy.1610.json.example
│   ├── ventoy.169.json.example
│   ├── ventoy.43.json.example
│   └── ventoy.json.example
├── .gitignore
├── compile-au2exe.ps1
├── extract.ps1
├── configure-windows.au3
├── configure-windows.ini
├── configure-windows.ps1
├── icon.ico
├── icon.png
├── install-apps.au3
├── install-apps.ini
├── install-drivers.au3
├── install-drivers.ps1
├── LICENSE.md
├── README.md
├── report.au3
├── report.exe
├── report.ps1
├── REPO_STRUCTRE.md
├── USB_STRUCTRE.md
├── update_logs.ps1
└── wallpaper.png
```
