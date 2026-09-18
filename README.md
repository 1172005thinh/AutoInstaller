# <img src="gui/assets/icons/AutoInstaller.ico" width="32" height="32" valign="bottom"  /> AUTOINSTALLER

![Version](https://img.shields.io/badge/version-0.2.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/status-in_development-orange)

`AutoInstaller` is a comprehensive automation solution for a **fresh Windows 11 installation** with third-party apps, drivers, and configurations.

---
## **🚨IMPORTANT:** This `main` branch is under a large refactor. It is *not completed* and definitely *not working*, please visit the `dev` branch temporarily for the last stable version. Thank you.

## 📖 TABLE OF CONTENTS

| No. | Section |
|---|---|
| 0 | [Why AutoInstaller](#why-autoinstaller) |
| 1 | [Main Features](#main-features) |
| 2 | [Project Structure](#project-structure) |
| 3 | [Getting Start](#getting-start) |
| 4 | [Incoming Features](#incoming-features) |
| 5 | [Changelog](#changelog) |
| 6 | [Known Issues](#known-issues) |
| 7 | [References](#references) |
| 8 | [License](#license) |
| 9 | [Contribution](#contribution) |

<br clear="left"/>

---

## <a id="why-autoinstaller"></a>💡 WHY AUTOINSTALLER?

> **Ever heard of `GHOST`?**

It is an "old school" solution to `clone` a machine to another one. A clone image might have Windows pre-installed, all the applications, drivers, and configurations you need. Easy to deploy, fast to restore, just a USB and you are good to go. However, if you are installing a fresh Windows from an shared image, think about it:

1. How about the `hardware configuration` is not the same? The drivers might *not be compatible* with the new machine. Good luck with `BSOD`!
2. Or, you don't like the idea of *sharing a cloned OS* with someone else? How about the `personalization`? How about the `privacy`? How about the `bloatware`? You may not want to share your custom configuration with others.
3. Or, the `corrupted` image that includes a `funny virus/malware`? You might not know *what has been added* in the image.

    ***Do you really trust the distributor?***

> **Here comes `AutoInstaller`**

Your machine, *your own personalized Windows*, softwares and configuration in your hand, fully installed with automation scripts.

## <a id="main-features"></a>✨ MAIN FEATURES

[AutoInstaller](https://github.com/1172005thinh/AutoInstaller) is a complete automation of fresh Windows installation, this tool provides:

1. **A custom bootable USB drive** with [Ventoy](https://www.ventoy.net/en/index.html) supporting:
    - A custom boot menu theme [1172005thinh](tools/Ventoy/AutoInstaller/theme/1172005thinh):

        | Dark Theme Preview | Light Theme Preview |
        | :---: | :---: |
        | ![Dark Theme Preview](docs/preview/preview_dark43.png) | ![Light Theme Preview](docs/preview/preview_light43.png) |

    - A custom Ventoy configuration [ventoy.json](tools/Ventoy/AutoInstaller/ventoy.json) with pre-defined `Menu Alias`, `Menu Tips`, `Themes`, `Menu Class`, and `Auto-select` with [unattend scripts](Unattend):
        + **Menu Alias**: Replace the default image name with a custom name.
        + **Menu Tips**: Display a short description of the image.
        + **Themes**: Apply a custom theme to the boot menu with integrated [fonts](tools/Ventoy/AutoInstaller/font/cascadia-code).
        + **Menu Class**: To add [icons](tools/Ventoy/AutoInstaller/theme/1172005thinh/icons) to existing images.
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
2. **🏗️ Underconstruction...**

## <a id="project-structure"></a>📁 PROJECT STRUCTURE

**🏗️ Underconstruction...**

<br clear="left"/>

---

## <a id="getting-start"></a>🚀 GETTING START

**🏗️ Underconstruction...**

### <a id="requirements"></a>📋 REQUIREMENTS

**🏗️ Underconstruction...**

### <a id="step-by-step"></a>🛠️ STEP-BY-STEP

**🏗️ Underconstruction...**

### <a id="verification"></a>✅ VERIFICATION

**🏗️ Underconstruction...**

<br clear="left"/>

---

## <a id="incoming-features"></a>🔮 INCOMING FEATURES

These below are my `ideas`, `not promises`:

|No.|Features|
|---|---|
|0|GUI for customization|
|1|Auto-download setup files/dependencies/third-party tools|
|2|Re-organize project structure|
|3|Add more .au3 mini-installers|

## <a id="changelog"></a>⏳ CHANGELOG


**🏗️ Underconstruction...**

## <a id="known-issues"></a>⚠️ KNOWN ISSUES

**🏗️ Underconstruction...**

## <a id="references"></a>📚 REFERENCES

|No.|Ref.|
|---|---|
|0|[Unattend Generator Schneegans.de](https://schneegans.de/windows/unattend-generator/)|
|1|[Microsoft Autounattend](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)|
|2|[GRUB2 Theme Icons](https://www.gnome-look.org/p/2206122)|
|3|[Cascadia-Code Fonts](https://fonts.google.com/specimen/Cascadia+Code)|
|4|[AutoIt Scripts](https://www.autoitscript.com/wiki/)|
|5|[Snappy Driver Installer Origin](https://www.snappy-driver-installer.org/)|

## <a id="license"></a>⚖️ LICENSE

Please refer to [LICENSE.md](LICENSE.md) for more information.

## <a id="contribution"></a>🤝 CONTRIBUTION

This is a `hobby project`, I am the only developer and I am still in school so I can not promise to update the tools regularly. It is my own decision to maintain or discontinue this project at any time.

**Author: `1172005thinh`** <img src="https://avatars.githubusercontent.com/u/190686462?v=4" width="32" height="32" align="center" style="margin-left: 10px;" />

- `Hung Thinh Nguyen` [GitHub](https://github.com/1172005thinh)
- `Nguyễn Hưng Thịnh` [Facebook](https://www.facebook.com/quickcomp.hungthinhnguyen)
- `HungThinhCloud` [Public Profile](https://hungthinhcloud.freeddns.org/about/)

**Contributors: `AI Agents`**

- `Claude - Anthropic` - Master reasoning
- `Codex - OpenAI` - Coder
- `Gemini - Google` - Researching and validation testing
