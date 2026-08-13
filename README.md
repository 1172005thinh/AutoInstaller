# ⚙️ AutoInstaller

AutoInstaller is a comprehensive, Ventoy-based deployment solution designed to fully automate the installation and configuration of Windows 11. It provides a zero-touch "Auto-pilot" workflow that takes a machine from a blank disk to a fully configured, production-ready state without requiring manual user interaction.

The deployment suite handles four major phases:
1. **Windows Setup**: Destructively formats the target drive, performs a clean installation of Windows 11 (24H2), skips OOBE (Out-Of-Box Experience), creates a default OEM administrative user, and applies localization settings.
2. **Driver Injection**: Automatically connects to Windows Update to fetch, install, and configure system-specific hardware drivers, handling necessary reboots automatically.
3. **Software Provisioning**: Executes a sequenced, version-agnostic deployment of third-party applications (browsers, office suites, development environments, utilities) defined in a central configuration file.
4. **Environment Configuration**: Customizes the Windows 11 shell by configuring the Start Menu layout, pinning taskbar items, disabling widgets, setting power profiles, cleaning up startup items, and dynamically sorting desktop shortcuts.

The entire process is heavily logged and concludes by generating a final Markdown report summarizing the status of the drivers, installed applications, and system configurations.

For detailed technical architecture and usage instructions, refer to `AUTOINSTALLER.md` and `AGENTS.md`.
