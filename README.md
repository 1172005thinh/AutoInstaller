# AUTOINSTALLER

`AutoInstaller` is a comprehensive automation solution for a fresh Windows installation with third-party apps, drivers and configurations.

## WHY AUTOINSTALLER?

> **Ever heard of `GHOST`?**

It is an "old school" solution to `clone` a machine to another one. A clone image might have Windows pre-installed, all the applications, drivers, and configurations you need. Easy to deploy, fast to restore, just a USB and you are good to go. However, if you are installing a fresh Windows from an shared image, think about it:

- How about the `hardware configuration` is not the same? The drivers might not be compatible with the new machine. Good luck with `BSOD`!
- Or, you don't like the idea of sharing a cloned OS with someone else? How about the `personalization`? How about the `privacy`? How about the `bloatware`? You may not want to share your custom configuration with others.
- Or, the `corrupted` image that includes a `funny virus/malware`? You might not know what has been added in the image. **Do you really trust the distributor?**

> **Here comes `AutoInstaller`**

Your machine, your own personalized Windows, softwares and configuration in your hand, fully installed with automation scripts.

## MAIN FEATURE

[AutoInstaller](https://github.com/1172005thinh/AutoInstaller) is a complete automation of fresh Windows installation, this tool provides:

1. **A custom bootable USB drive** with [Ventoy](https://www.ventoy.net/en/index.html) supporting:
    - A custom boot menu theme [ventoy/theme/1172005thinh](https://github.com/1172005thinh/AutoInstaller/tree/main/ventoy/theme/1172005thinh):
        + [Dark Theme Preview](https://github.com/1172005thinh/AutoInstaller/blob/main/ventoy/theme/preview_dark43.png)
        + [Light Theme Preview](https://github.com/1172005thinh/AutoInstaller/blob/main/ventoy/theme/preview_light43.png)
    - A custom Ventoy configuration [ventoy/ventoy.json.example](https://github.com/1172005thinh/AutoInstaller/tree/main/ventoy/ventoy.json.example) with pre-defined `Menu Alias`, `Menu Tips`, `Themes`, `Menu Class`, and `Auto-select` with [unattend scripts](https://github.com/1172005thinh/AutoInstaller/tree/main/Unattend):
        + **Menu Alias**: Replace the default image name with a custom name.
        + **Menu Tips**: Display a short description of the image.
        + **Themes**: Apply a custom theme to the boot menu with integrated [fonts](https://github.com/1172005thinh/AutoInstaller/tree/main/ventoy/font/cascadia-code).
        + **Menu Class**: To add [icons](https://github.com/1172005thinh/AutoInstaller/tree/main/ventoy/theme/1172005thinh/icons) to existing images.
        + **Unattend scripts**: Overall, these unattend scripts provides:
            + Installing Windows hands-off
            + Bypassing Windows 11 Hardware checks (TPM 2.0, Secure Boot, RAM, CPU, etc.)
            + Automatic/Manual disks, partitions selection/creation
            + Setting up Windows with your preferences (language, timezone, keyboard layout, etc.)
            + Creating a local user account
            + Disabling BitLocker
            + Remove bloatwares
            + And a lot more
        + About Ventoy Plugin, please refer to [Ventoy Plugin Docs](https://www.ventoy.net/en/plugin_entry.html) for more information.
2. **AutoInstaller scripts** for automatic apps/drivers installation and configuration after Windows installation:
    - `Auto-installer.exe`: Main entry point, provides the overall workflow of AutoInstaller.
    - `install-apps.exe`: Installing apps listed in `install-apps.ini`, a configuration file to define the apps to be installed.
        + `*/install_*.exe` is the mini-installer written for each app. **This tool does not work as a "magic" where it can install whatever you told it to.**
    - `install-drivers.exe`: Installing drivers using [SDIO](https://github.com/1172005thinh/AutoInstaller/tree/main/Drivers/README.md) and Windows Update as fallback. **Requires Internet connection**
    - `configure-windows.exe`: Configuring Windows settings defined under `configure-windows.ini`, a configuration file to tell what options should be enabled or disabled.
3. **Overall report and detailed logs** after installation:
    - The tool monitors the installation process and logs under `log_path` described in `install-apps.ini`.
    - A comprehensive `report.md` will also be generated at `log_path` for you to review the installation process.
    - However, some **Unattend scripts' logs** are stored in `C:\Windows\Setup\Scripts\*.log`, due to time limitations, I have not copied them to `log_path`. **Maybe in the future, I will.**

## PROJECT STRUCTURE

This repository is a `collection`, the source tree is not a representation of the folder structure of the bootable USB drive. **You need to manually copy the files to the bootable USB drive later**.

Overall, the tree looks like this:

> Note that some `*.md`, `.gitignore`, `mini-installer directories`, `.git` have been skipped for a better reading volume.

``` txt
AutoInstaller/
├── <mini-installers>                           <-- Mini-installer directories for each app
│   ├── *.ps1                                   <-- PowerShell helper script
│   └── install_*.au3                           <-- AutoIt script to install a specific app
├── Unattend
│   └── *.xml                                   <-- Unattend scripts for Windows installation
├── ventoy
│   ├── font
│   │   └── cascadia-code
│   │       └── *.pf2                           <-- Font files for Ventoy menu
│   ├── theme
│   │   ├── 1172005thinh
│   │   │   └── ...                             <-- Theme files for Ventoy menu
│   │   └── preview_*.png                       <-- Preview images for Ventoy menu
│   └── ventoy.*.json.example                   <-- Ventoy configuration example
├── .gitignore
├── compile-au2exe.ps1                          <-- PowerShell script to compile AutoIt scripts to executables
├── configure-windows.au3                       <-- AutoIt script to configure Windows
├── configure-windows.ini                       <-- Configuration file for configure-windows.au3
├── configure-windows.ps1                       <-- PowerShell script to configure Windows
├── icon.ico                                    <-- Icon file for the tool
├── icon.png
├── install-apps.au3                            <-- AutoIt script to install applications
├── install-apps.ini                            <-- Configuration file for install-apps.au3
├── install-drivers.au3                         <-- AutoIt script to install drivers
├── install-drivers.ps1                         <-- PowerShell script to install drivers
├── report.au3                                  <-- AutoIt script to generate report
├── report.ps1                                  <-- PowerShell script to generate report
├── update_logs.ps1                             <-- PowerShell script to update logs
└── wallpaper.png                               <-- Example wallpaper image
```

For a detailed folder structure, please refer to [Repo Structure](https://github.com/1172005thinh/AutoInstaller/tree/main/REPO_STRUCTRE.md).

## HOW TO BUILD YOUR OWN BOOTABLE USB DRIVE?

**NOTE THAT THIS IS THE INSTRUCTION FOR `WINDOWS` FOLKS ONLY**

### REQUIREMENTS

This repo depends on the following tools:

**MUST HAVE**

1. `AutoIt V3` compiler, please visit [official website](https://www.autoitscript.com/site/autoit/downloads/) or download the [latest version](https://www.autoitscript.com/files/autoit3/autoit-v3-setup.zip).
2. `PowerShell v5.0` scripting, please visit [official website](https://github.com/powershell/powershell) or download the [Microsoft Store installer](https://apps.microsoft.com/detail/9mz1snwt0n5d). Apparently, PowerShell is pre-installed in Windows 10/11. **NOTE**: You may need to install `.NET Runtime` accordingly as well.
3. `Ventoy` for a bootable USB, please visit [official website](https://www.ventoy.net/en/download.html) or download the version [1.1.17](https://sourceforge.net/projects/ventoy/files/v1.1.17). **NOTE**: Please check the SHA as this website is not underprovisioned.
4. A `16GB+` USB Flash Drive *(>= 16GB is recommended for storing Windows images, installer files and data)*. **NOTE**: Please ensure you have backed up all the data as this USB will be wiped completely.

**OPTIONAL**

1. `ffmpeg` for converting images into icons, please visit [official website](https://www.ffmpeg.org/download.html) or download the [latest version](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip).
2. `VMware Workstation Pro` for testing USB without the need of real hardware, please visit [official website](https://www.vmware.com/products/workstation-pro.html). **NOTE*: You have to signup a Broadcom account to get the installer.
3. `git` if you are interested in contributing to this project, please visit [official website](https://git-scm.com/downloads) or download the version [2.55.0.5](https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe).
4. `vs-code` if you want to edit the source code more efficiently, please visit [official website](https://code.visualstudio.com/download).
5. `AI Agents` if you don't understand what the hecks I am writing. **However, the AI Agents are not guaranteed to provide a correct answer, so please double-check the answer.**

### STEP-BY-STEP

**PREPARING USB DRIVE WITH VENTOY**

Ensure you have Ventoy installed on you host machine, your USB drive is plugged in and add data is backed up:

1. Run `Ventoy2Disk.exe` from the extracted Ventoy folder with ` Administrator` privileges.
2. Click the dropdown menu `Device` to select your USB drive.
3. At the top left of the window, click `Option` menu > `Partition Configuration`, check `Preserve some space at the end of the disk` option, enter your desired `amount of free Gigabyte/Megabyte` *(recommended to be at least 10GB)*, click `OK` button at the bottom of the window to save.
4. Once Partition Configuration saved and closed, click `Install` button at the bottom to install Ventoy. You will be prompted to confirm the installation, click `Yes` to continue.
5. Once the installation has done, you will see the `three new partitions created` in File Explorer by Ventoy *(might be two as the other bootloader partition is hidden)*:
    
    ``` txt
    This PC/
    ├── ...                                     <-- Other disks and partitions
    ├── ISO/                                    <-- Typical ISO partition name created by Ventoy
    ├── USB/                                    <-- Remaining partition of the USB created by Ventoy
    └── VTOYEFI/                                <-- Hidden bootloader partition, no need to modify
    ```
    > *You may change the partitions' names according to your preference. This instruction assumes you are using the original partition names that came with Ventoy.*

6. Accessing the ISO partition and create files and folders to be as follow:

    ``` txt
    ISO/
    ├── Windows                                 <-- Windows ISO files stored here
    └── 5b512ee8a59deb284ad0a6a035ba10b1.md5    <-- Important flag, do not delete
    ```
    > *The MD5 flag file is a hash for identification. Removing it will cause issues.*

**COPYING THE ISO FILES**

Please copy your desired original Windows ISO file to the ISO partition of the USB drive:

1. Download the official Windows 11 ISO from [Microsoft's website](https://www.microsoft.com/software-download/windows11).
2. Moving that ISO file to `ISO/Windows` folder created in the previous step:

    ``` txt
    ISO/
    ├── Windows
    │   └── w11.iso                             <-- Copied Windows ISO file
    └── 5b512ee8a59deb284ad0a6a035ba10b1.md5
    ```
    *Optional: You may add other ISO images, e.g. `ArchLinux`, `Ubuntu`, to the `ISO/` partition as needed. E.g.:*
    ``` txt
    ISO/
    ├── Windows
    │   └── w11.iso                             <-- Copied Windows ISO file
    ├── ArchLinux
    │   └── archlinux.iso                       <-- Copied ArchLinux ISO file
    └── 5b512ee8a59deb284ad0a6a035ba10b1.md5
    ```    
    > *The ISO filename can be renamed however you like, but it might require to update the `ventoy.json` file. I recommend to rename it as above.*

**CLONING THIS REPOSITORY**

You have to download or clone this repository from GitHub by either:

1. Download [this ZIP file](https://github.com/1172005thinh/AutoInstaller/archive/refs/heads/dev.zip), then extract it to a directory (not on your USB partition) on your computer.
2. Manually download the ZIP file by navigating to [this repository](https://github.com/1172005thinh/AutoInstaller), click `Code` button, and then click `Download ZIP`, then extract it to a directory (not on your USB partition) on your computer.
3. For command-line folks, you can clone this repo by:

    ``` powershell
    git clone https://github.com/1172005thinh/AutoInstaller.git
    cd AutoInstaller
    ```

**PREPARING EXECUTALBES**

By cloning this repo, you will have the source files of the executables. **You must compile them or else the scripts won't run**:

1. Open the repo directory with a terminal (`PowerShell` recommended), run this:

    *Check if the script can be executed by running:*
    ``` powershell
    ./compile-au2exe.ps1
    ```
    *If it returns an `ExecutionPolicy` error, you need to enable the execution policy by running:*
    ``` powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
    *To compile all the scripts, run:*
    ``` powershell
    ./compile-au2exe.ps1 -a
    ```
    *Make sure the scripts are compiled successfully by checking the output.*

    ``` txt
    AutoInstaller/
    ├── <mini-installers>                       <-- Mini-installer directories for each app
    │   ├── *.ps1
    │   ├── install_*.exe                       <-- Compiled executables
    │   └── install_*.au3
    ├── compile-au2exe.ps1                      <-- PowerShell script to compile AutoIt scripts to executables
    ├── Auto-installer.exe                      <-- Compiled master executable
    ├── configure-windows.au3
    ├── configure-windows.exe                   <-- Compiled executable to configure Windows
    ├── configure-windows.ini
    ├── configure-windows.ps1
    ├── install-apps.au3
    ├── install-apps.exe                        <-- Compiled executable to install applications
    ├── install-apps.ini
    ├── install-drivers.au3
    ├── install-drivers.exe                     <-- Compiled executable to install drivers
    ├── install-drivers.ps1
    ├── report.au3
    ├── report.exe                              <-- Compiled executable to generate report
    ├── report.ps1
    ├── update_logs.ps1
    └── ...                                     <-- Others files
    ```

2. Now, please download the third-party installers from the Internet and place them in each `<mini-installer>` directory accordingly:

    ``` txt
    
**COPYING FILES TO THE USB DRIVE**

There are two USB partitions, the ISO and USB.

*ISO PARTITION*

1. Copy the `ventoy` folder from the extracted repo directory to the ISO partition:

    ``` txt
    AutoInstaller/
    ├── ventoy                                  <-- Copy this folder
    │   └── ...
    └── ...                                     <-- Other directories in the repo

    # Parse ventoy folder to the ISO partition:

    ISO/
    ├── ventoy                                  <-- Copied Ventoy files
    │   └── ...  
    ├── Windows
    │   └── w11.iso
    └── 5b512ee8a59deb284ad0a6a035ba10b1.md5
    ```

2. Copy the XML files from `Unattend` folder from the extracted repo directory to the ISO partition:

    ``` txt
    AutoInstaller/
    ├── Unattend
    │   └── *.xml                               <-- Copy all XML files
    └── ...

    # Parse these XML files to the ISO partition:

    ISO/
    ├── ventoy
    │   └── ...  
    ├── Windows
    │   └── w11.iso
    ├── *.xml                                   <-- Copied XML files
    └── 5b512ee8a59deb284ad0a6a035ba10b1.md5
    ```

*USB PARTITION*

1. Copy all files and folders (except `ventoy`, `Unattend` and hidden `.git` folders) from the extracted repo directory to the USB partition:

    ``` txt
    AutoInstaller/
    ├── <mini-installers>
    │   ├── *.ps1
    │   ├── install_*.exe
    │   └── install_*.au3
    ├── compile-au2exe.ps1
    ├── Auto-installer.exe
    ├── configure-windows.au3
    ├── configure-windows.exe
    ├── configure-windows.ini
    ├── configure-windows.ps1
    ├── install-apps.au3
    ├── install-apps.exe
    ├── install-apps.ini
    ├── install-drivers.au3
    ├── install-drivers.exe
    ├── install-drivers.ps1
    ├── report.au3
    ├── report.exe
    ├── report.ps1
    ├── update_logs.ps1

**FINALLY**

Please have a look at [USB Structure](https://github.com/1172005thinh/AutoInstaller/blob/main/USB_STRUCTURE.md) to verify if your USB has been set up properly.

## INCOMING FEATURES

## KNOWN ISSUES

## REFERENCES

- [Unattend Generator Schneegans.de](https://schneegans.de/windows/unattend-generator/)
- [Microsoft Autounattend](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [GRUB2 Theme Icons](https://www.gnome-look.org/p/2206122)
- [Cascadia-Code Fonts](https://fonts.google.com/specimen/Cascadia+Code)
- [AutoIt Scripts](https://www.autoitscript.com/wiki/)

## LICENSE

Please refer to [LICENSE.md](https://github.com/1172005thinh/AutoInstaller/tree/main/LICENSE.md) for more information.

## CONTRIBUTION

This is a `hobby project`, and I am the only developer. It is my own decision to maintain or discontinue this project at any time.

**Author: `1172005thinh`**

- `Hung Thinh Nguyen` [GitHub](https://github.com/1172005thinh)
- `Nguyễn Hưng Thịnh` [Facebook](https://www.facebook.com/quickcomp.hungthinhnguyen)
- `HungThinhCloud` [Public Profile](https://hungthinhcloud.freeddns.org/about/)

**Contributors: `AI Agents`**

- `Claude - Anthropic` - Master reasoning
- `Codex - OpenAI` - Coder
- `Gemini - Google` - Researching and validation testing

---

*Updated: 08:00 24/08/2026*
