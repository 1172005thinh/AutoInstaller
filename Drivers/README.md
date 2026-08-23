# DRIVERS

AutoInstaller requires SDIO to install drivers for the target machine. SDIO - Snappy Driver Installation Origin is free and open source software for installing and updating drivers on Microsoft Windows.

## DRIVERS INSTALLATION PROCESS

Once Windows installation and apps installer have finished, the driver installation process will start automatically (**`FULL` AUTOMATION SCRIPT ONLY**).

> Installing Windows without drivers? Please use the `nodrivers` unattend XML scripts.

The installation requires:

- **Stable Internet connection** - Recommended to plug a `wired LAN cable` if possible. As some later WiFi card drivers are not pre-installed in Windows 10/11.
- **Windows partition has some free GB**
- **SDIO execution files and unattend scripts present**

If the above conditions are not met, the driver installation process will log events to `log_path` set in `install-drivers.ini`, and exit gracefully. Then, Windows Update (with modified update policy - see [WINDOWS_UPDATE_POLICY](#windows-update-policy)) will be triggered as a fallback.

Finally, a summary will be conducted and report generated at `C:\Auto-installer\report.md`, including the overal result of the drivers installation process.

## SDIO INSTALLATION

This repository **`DOES NOT`** include the SDIO execution files in the source tree. A copy can be downloaded from the official website.

> Make sure you have cloned this repository before proceeding.

1. Access [official website](https://www.glenn.delahoy.com/snappy-driver-installer-origin/) or download the latest version [2.0.3](https://www.glenn.delahoy.com/downloads/sdio/SDIO_2.0.3.886.zip). **You may choose another version but version 2.0.3 is recommended**.
   - No installer is required, this software is distributed as a `portable` application.
   - **The tool is free. If you have been charged, please ask for a refund.**
2. Extract the downloaded ZIP file to the already created, empty `/Drivers/SDIO` directory in the cloned repository.
    - The `/Drivers/SDIO` directory should look like this:

        ```txt
        Drivers/
        ├── SDIO/
        │   ├── ...
        │   ├── SDIO_R886.exe
        │   └── SDIO_x64_R886.exe
        └── README.md              <--- We are here
        ```

    - `SDIO_R886.exe` is the 32-bit version, and `SDIO_x64_R886.exe` is the 64-bit version. Please make sure these filenames are not changed. **64-bit version is prioritized**.

## WINDOWS UPDATE POLICY

By default, the [install-drivers.ps1](install-drivers.ps1) will always modify the Windows Update policy to:

- **Feature Upgrades: blocked**
- **Drivers + Security patches: allowed**

The script will trigger the WU COM API search update and installation as a fallback if SDIO failed or missing (**`FULL` AUTOMATION SCRIPT ONLY**), WU skip if SDIO success fully installed drivers.

## TESTING LIMITATION

The author `1172005thinh` has limited real physical hardware to conduct a testing for this drivers installation automation script.

- **Virtual environment limitations**: Virtual machines often lack the diverse range of hardware components (like graphics cards, chipsets, and network adapters) present in physical machines, making it difficult to fully validate driver compatibility and functionality across different hardware configurations.

***All results from testing in virtual environment are NOT guaranteed to be working on physical machines.***
