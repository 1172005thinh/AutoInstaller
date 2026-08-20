# AUTOINSTALLER PROJECT

Automating Windows Installation, drivers and third-party apps.

## WORKSPACE

- The workspace we are at currently is not at the targeted USB. This is a development environment, focusing on Software partition of the USB. This workspace is a replica of the Software partition of the USB drive (drive `S:`).

- However, for developement convenience, the workspace includes:
    1. `/windows`: Extracted content of Windows ISO **Will not be in the USB, only the ISO is**
    2. `*.xml`: autounattend scripts for various automation levels **Will be in the USB at ISO partition**
    3. `PLANS.md`: The plan of the project **Will not be in the USB**

## INSTALLATION MEDIA

A USB with Ventoy installed and 3 partitions:

1. ISO partition *(Currently registeres as `I:`)* storing ISO image files. E.g. `I:/Windows/w11_24h2_fa_c.iso` is a custom ISO (build with DISM) installing Windows 11 24H2 by desctructive method (clean install) as a single C: drive with no user interaction. The ISO has been extraced as /windows at the root of this workspace.
2. Software partition *(Currently registers as `S:`)* storing custom setup files for third-party apps. E.g. `S:/Browsers/chrome-standalone.exe` is a standalone installer for Google Chrome, `S:/Tools/Editors/notepadpp-8.4.4.exe` is a standalone installer for Notepad++. Each setup file has an auto-installer executable file, e.g. `S:/Browsers/install_chrome-standalone.exe`. The script is original written in AutoIt v3 (or PowerShell for a silent-installation supported/CLI-installation apps *optional*), then is compiled as a .exe file. There is a master installation executable file `S:/Auto-installer.exe`. See the [Software installation process](#software-installation) for better understanding.
3. EFI partition *(Currently not registered)* for bootable Ventoy environment setup.

**NOTE:** The drive letters assigned to the partitions may vary depending on the system and the number of drives connected. Solution: Put a file named as a hash (MD5) from the drive label at the root directory:
    - ISO partition: `5b512ee8a59deb284ad0a6a035ba10b1.md5`
    - Software partition: `aea541d7f9574587656dc5125116e548.md5`
    - EFI partition: `6e2807816e9d2621b7e5dffff6c33711.md5`

## VENTOY CONFIGURATION

Flow:

1. Boot into Ventoy media
2. Select Windows ISO file (clean install)
3. Select what automation to start the installation:
    - Normal boot: lean installation, users manually go through the installation setup.
    - `Auto-pilot`: full automated installation, using [auto-pilot_autounattend.xml](auto-pilot_autounattend.xml).
    - `Windows-only`: install Windows and drivers, using [windows-only_autounattend.xml](windows-only_autounattend.xml).
    - `Windows-only-no-driver`: install Windows (no driver installation), using [windows-only-no-driver_autounattend.xml](windows-only-no-driver_autounattend.xml).

## WINDOWS INSTALLATION

**NOTE:** The Windows installation has been automated sucessfully. See [Autounattend.xml](windows-only-no-driver_autounattend.xml) for more details.

```text
auto-pilot_autounattend.xml <-- at ISO partition
windows-only_autounattend.xml <-- at ISO partition
windows-only-no-driver_autounattend.xml <-- at ISO partition
```

Requirements:

1. The USB is booted into Ventoy and select Windows ISO file to start the installation. **OPTIONAL**
2. The installation resource (ISO, scripts) are accessible and clean (not corrupted). **OPTIONAL**
3. The disk 0 must not be the USB itself. **CRITICAL!!! Abort the installation immediately if it is.**

In summary, the script does:

1. Destroys and erases the disk 0.
2. Format the disk as three partitions (EFI; Windows; WinRE).
3. Install Windows 11 Pro edition to Windows partition (C drive).
4. Disable Dynamic Update, skip hardware verification and skipp OOBE steps.
5. Set localization, region, timezone to specified cofiguration.
6. Name the computer as `PC`.
7. Create a new user `OEM` as Admin without password.
8. Remove unwanted and bloat software (e.g OneDrive,...).
9. Login to the account `OEM` and run FirstLogin script.
10. Installation finished.

## DRIVERS INSTALLATION

This installation process runs **after** [Software Installation](#software-installation) and [Windows Configuration](#windows-configuration), as the final automated step before report generation. Running drivers last allows the reboot loop to complete without interrupting app installation.

```text
# Written in PowerShell and compiled as an exe file
install-drivers.ps1 <-- source file in the USB
install-drivers.exe <-- compiled file in the USB
install-drivers.log <-- log file in the USB at C:/Auto-installer/install-drivers.log
```

Requirements:

1. The Windows installation, software installation, and Windows configuration processes have terminated successfully. **IMPORTANT! Does not start the drivers installation if any preceding process has not terminated successfully.**
2. Windows login to the created user has been completed. **IMPORTANT! Does not start the drivers installation if the Windows login to the created user is not completed.**
3. The computer has access to the Internet. **OPTIONAL -- if no connection is available, the installation is skipped and logged as `skipped-no-internet`.**

In summary, the script acts:

1. Check if the `install-drivers.exe` run as Administrator, `max_iteration >= 1`? Init `iteration = 1`, go to step 2 : Terminate and log into the configure log-file (by default: `C:/Auto-installer/install-drivers.log`).
2. Configure Windows Update policy via registry to: include driver updates, include security patches, and block feature/version upgrades. Restart `wuauserv` and `UsoSvc` to apply the new policy.
3. Check if the Internet connection is available? Go to step 4 : Log `skipped-no-internet` and terminate (go to step 9).
4. Search Windows Update for all available drivers (`Type='Driver'`) and security/software updates (`Type='Software'`), excluding hidden items. Retry up to 3 times with 60-second waits if the WU agent is not yet ready.
5. Are there updates found? Go to step 6 : If `iteration > 1`, log `completed-clean` (all updates applied in prior iterations); else log `no-updates`. Go to step 9.
6. List all queued updates to the terminal and log, then install all of them.
7. Installation finished -- does it require a restart? Go to step 8 : Go to step 9.
8. Is `iteration < max_iteration`? Register a scheduled task to resume at startup, increment `iteration`, restart the computer, and go to step 2 on next boot : Log `reboot-required` (manual reboot needed), go to step 9.
9. Installation finished. If `-ReportAfterCompletion` was set, hand off to `report.exe`.

## SOFTWARE INSTALLATION

This installation process runs after the [Windows installation process](#windows-installation). It now runs **before** the [drivers installation process](#drivers-installation) so that the driver reboot loop does not interrupt app or configuration phases.

```text
# Written in AutoIt v3 and compiled as an exe file
install-apps.au3 <-- source file in the USB
install-apps.exe <-- master executable file in the USB
install-apps.ini <-- configuration file in the USB
install-apps.log <-- log file in the USB at C:/Auto-installer/install-apps.log
```

Requirements:

1. The Windows installation and driver installation processes have been terminated successfully. **IMPORTANT! Does not start the software installation if the Windows installation and driver installation processes have not been terminated successfully.**
2. Windows login to the created user has been completed. **IMPORTANT! Does not start the software installation if the Windows login to the created user is not completed.**
3. The computer has access to the Internet. **OPTIONAL as some apps need internet connection to install, else the installation skips to the next apps.**

In summary, the scripts does:

1. Check if the `install-apps.exe` runs as Administrator, `install-apps.ini` exists and correctly formated? Initialize `idx = 0`, `iteration = 0`, read `max_iteration` and `max_idx`, go to step 2 : Terminated and log into the configure log-file (by default: `C:/Auto-installer/install-apps.log`), go to step 11.
2. Is `idx <= max_idx`? Go to step 3 : Reset `idx` to 0, and go to step 11.
3. Check if the target `idx` app is not installed? Go to step 4 : Update `install_status = 1`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
4. Check if the target `idx` app has `install_file` and `setup_file` path existed? Go to step 5 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
5. Check if the target `idx` app `install_file` runs and calls the `setup_file` successfully? Go to step 6 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
6. Check if the target `idx` app `install_file` navigate/control the configuration of `setup_file` successfully according to the expected behaviour? Go to step 7 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
7. Check if the target `idx` app `install_file` and `setup_file` do not crash in process? Go to step 8 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
8. Check if the target `idx` app `install_file` and `setup_file` do not terminate with error code? Go to step 9 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
9. Check if the target `idx` app `install_file` and `setup_file` do not terminate in a reasonable time? Go to step 10 : Update `install_status = 0`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
10. Check if the target `idx` app does not fail to launch after installation? Close the app, update `install_status = 1`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2 : Update `install_status = 2`, log the result into `C:/Auto-installer/install-apps.log` file, increment `idx` and go to step 2.
11. Is `iteration >= max_iteration`? Go to step 12 : Log the start of a new iteration into `C:/Auto-installer/install-apps.log` file, increment `iteration` and go to step 2.
12. Installation finished.

Install_file and setup_file:

- `install_file` is a **generic** wrapper script written in AutoIt v3, compiled as `.exe`. Its name format: `install_<appname>.exe` (e.g. `install_python.exe`, `install_notepadpp.exe`). The script is version-agnostic — it receives the setup filename and shortcut flag from the master at runtime via CLI arguments.
- `setup_file` is the original setup file from the software vendor (e.g. `python-3.14.2.exe`, `notepadpp-8.4.4.exe`, `shell.msi`). Its relative path is the version-specific entry in `install-apps.ini`.

The master (`install-apps.exe`) passes **three** arguments to each `install_file`:
1. **`$CmdLine[1]`** — the setup filename/dirname (basename only, e.g. `"python-3.14.2.exe"` or `"Fonts"`). The installer resolves the full path using `@ScriptDir`.
2. **`$CmdLine[2]`** — the desktop shortcut flag (`"true"` or `"false"`) from the `desktop_shortcut_flag` column of `install-apps.ini`.
3. **`$CmdLine[3]`** — the `clean_after_installing` flag (`"true"` or `"false"`) from `install-apps.ini`; currently only consumed by the font installer.

To upgrade a dependency (e.g. Python 3.14.2 → 3.14.7): copy the new setup file to the same folder, update `setup_file` in `install-apps.ini`, and delete the old setup file. No script recompilation is required.

### Font Installer (special case)

`Utilities/Fonts/install_fonts.exe` is a special installer that does not target a single setup file. Its `setup_file` INI entry is a **directory** (`Utilities/Fonts`). The master handles this by using `DirExists` in addition to `FileExists` for the setup-path check.

Internally it spawns a helper PowerShell script that:
1. Validates each `.ttf`, `.otf`, and `.ttc` file with the GDI+ `PrivateFontCollection` API.
2. Copies valid fonts to `C:\Windows\Fonts` and registers them in `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` for all users.
3. Skips fonts that are already installed (same file size) without a popup.
4. Records invalid/uninstallable/skipped fonts in the log.
5. Optionally deletes invalid/broken font files from the source directory if `clean_after_installing=true`.
6. Broadcasts `WM_FONTCHANGE` so running applications immediately see the new fonts.

## REPORT GENERATION

Generate a report file at the end of the installation process to summarize the installation process and any issues encountered.

```text
report.ps1 <-- source file in the USB
report.exe <-- compiled file in the USB
report.md <-- report file in the USB at C:/Auto-installer/report.md
```

Requirements:

1. `install-drivers.log` and `install-apps.log` exist.
2. `configure-windows.log` exists.

In summary, the script acts:
1. Parses log files for status codes and application names.
2. Evaluates the validation block inside `configure-windows.log` to determine the success state of post-installation customizations.
3. Generates a Markdown table summarizing Drivers, Apps, and Windows Configuration.

## WINDOWS CONFIGURATION

This process runs immediately after Software Installation.

```text
configure-windows.ps1 <-- source file in the USB
configure-windows.au3 <-- compiled as configure-windows.exe wrapper
configure-windows.log <-- log file in the USB at C:/Auto-installer/configure-windows.log
```

The script manages post-installation customizations:
- **Taskbar**: Uses Group Policy to disable Widgets (`AllowNewsAndInterests`), and uses the Shell COM `taskbarunpin`/`taskbarpin` verbs to explicitly set the taskbar app layout without disrupting other elements.
- **Start Menu**: Injects custom JSON objects to pin the Settings app layout into `LayoutModification.json`.
- **Desktop**: Reorders desktop icons via UI Automation (Win+D, ControlClick focus, Context Menu sorting).
- **Power**: Configures monitor AC/DC timeout via `powercfg`.
- **Validation**: At the conclusion of the script, validates that all GPOs, Registry values, and power settings actually applied, appending a `[VALIDATION]` block to the log.


## VENTOY GRUB TERMINAL & DYNAMIC SCRIPTS (`*dyn*.xml`)

For dynamic disk partitioning and on-the-fly customization, the installation media uses Ventoy's integrated GRUB terminal script (`ventoy/ventoy_grub.cfg`) alongside dynamic unattended templates (`ventoy/script/*dyn_C_D.xml`).

### Interactive GRUB Flow (`ventoy_grub.cfg`)

When booting from the Ventoy USB:

1. **Safety Warning (30-second countdown)**:
   - Prints a prominent multi-line warning alerting that target disk data will be erased.
   - 30-second countdown before auto-booting. Pressing any key pauses the countdown.
   - Once paused, pressing `ESC` halts/exits the installation.

2. **C:D Partition Ratio Prompt**:
   - `y` / `yes`: Defaults to **50:50** C and D drive split.
   - `n` / `no` / `empty`: Prompts for custom ratio in `CC:DD` format (e.g. `60:40`, where $CC + DD = 100$).
   - Calculates C drive size in MB: `DYN_C_SIZE_MB = (UsableDiskMB * CC) / 100` (deducting 100MB EFI + 16MB MSR).
   - `esc`: Exits terminal (`halt`).

3. **Account & PC Name Prompt**:
   - `y` / `yes`: Uses default `OEM` account/display name and `PC` computer name.
   - `n` / `no`: Prompts user for custom Account Name and Computer Name (alphanumeric, no spaces, max 128 chars).
   - `esc`: Exits terminal (`halt`).

### Variable Injection into `*dyn*.xml`

GRUB exports the following environment variables:
- `DYN_C_SIZE_MB` -> Injected into Windows Setup `<DiskConfiguration>` Partition 3 `<Size>$$DYN_C_SIZE_MB$$</Size>`.
- `DYN_PC_NAME` -> Injected into `<ComputerName>$$DYN_PC_NAME$$</ComputerName>`.
- `DYN_ACCOUNT_NAME` & `DYN_DISPLAY_NAME` -> Injected into `<LocalAccount>`.

Windows Setup natively allocates `DYN_C_SIZE_MB` to C: drive and sets D: drive with `<Extend>true</Extend>` to take all remaining disk space without using fragile `diskpart` scripts in WinPE, eliminating error `0x80070001 - 0x40030`.

### Unattended Script Extraction & Time Synchronization

- **Script Extraction**: During the `specialize` pass, `<RunSynchronousCommand>` Order 1 executes the canonical Schneegans `ExtractScript` to deserialize all embedded scripts into `C:\Windows\Setup\Scripts\`, and Order 2 runs `Specialize.ps1`.
- **BOM-Free UTF-8 Encoding**: All XML templates are stored as UTF-8 without BOM to prevent Ventoy's variable replacement engine from corrupting the initial bytes into `?`.
- **Time & Region**: `configure-windows.ps1` explicitly starts `w32time` and triggers NTP time synchronization (`w32tm /resync /nowait`) so that the system clock is immediately accurate upon reaching the desktop.