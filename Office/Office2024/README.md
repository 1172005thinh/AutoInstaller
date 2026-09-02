# OFFICE DEPLOYMENT TOOL COMMAND

The Office Deployment Tool (ODT) is a command-line tool that lets you download and deploy Click-to-Run versions of Office. You can use it to install, uninstall, or update Office 2024 on user computers. Please refer to [Microsoft ODT Docs](https://learn.microsoft.com/en-us/office/ltsc/2024/deploy) for more information.

1. Download the ODT tool from [official website](https://www.microsoft.com/en-us/download/details.aspx?id=49117)
2. Run the self-extracting executable file, which contains the Office Deployment Tool executable (`setup.exe`) and sample configuration XML files.
3. You may rename the `setup.exe` file to whatever you want *(recommended `office2024.exe`)*, a quick lock over [install-apps.ini](/install-apps.ini) is recommended.

## AUTO INSTALLATION

By letting the `Auto-installer.exe` handle the installation of Office2024 *(if indexed and enabled in `install-apps.ini`)*, the installer will automatically install Office2024 based on the configuration set in [install_office2024.au3](install_office2024.au3).

Basically it runs:

``` powershell
.\office2024.exe /configure full_en.xml
```

> *To understand the `full_en.xml` file, please refer to the table below. You may modify the AU3 file to use your own XML script, then remember to re-compile the executalble.*

## MANUAL INSTALLATION

There are two ways to manually install Office, by either:

**MAKE SURE OFFICE DATA IS DOWNLOADED BEFORE RUNNING THE INSTALLER**

1. Run the following `command-line` to manually install Office 2024:

    ``` powershell
    # Make sure you are at the Office2024 directory /Office/Office2024

    # If sudo is enabled
    # Download Office (the script.xml should be a full version)
    sudo .\office2024.exe /download script.xml

    # Install Office
    sudo .\office2024.exe /configure script.xml

    # Else runs PowerShell as Administrator
    .\office2024.exe /download script.xml

    .\office2024.exe /configure script.xml
    ```
    > *`script.xml` is an example filename, you may use your own XML script. Please view the table below to know which pre-configured scripts you might use:*

    | Script name | Description | Language | Removed |
    | --- | --- | --- | --- |
    | full_en.xml | All apps* | en-us | `Lync`, `OneDrive` |
    | full_vi.xml | All apps* | vi-vn | `Lync`, `OneDrive` |
    | wepa_en.xml | Word, Excel, PowerPoint, Access | en-us | `Lync`, `OneDrive`,   `OneNote`, `Outlook`, `Publisher`, `Teams` |
    | wepa_vi.xml | Word, Excel, PowerPoint, Access | vi-vn | `Lync`, `OneDrive`,   `OneNote`, `Outlook`, `Publisher`, `Teams` |
    | wep_en.xml | Word, Excel, PowerPoint | en-us | `Access`, `Lync`, `OneDrive`,  `OneNote`, `Outlook`, `Publisher`, `Teams` |
    | wep_vi.xml | Word, Excel, PowerPoint | vi-vn | `Access`, `Lync`, `OneDrive`,  `OneNote`, `Outlook`, `Publisher`, `Teams` |
    | we_en.xml | Word, Excel | en-us | `Access`, `Lync`, `OneDrive`, `OneNote`,    `Outlook`, `Publisher`, `PowerPoint`, `Teams` |
    | we_vi.xml | Word, Excel | vi-vn | `Access`, `Lync`, `OneDrive`, `OneNote`,    `Outlook`, `Publisher`, `PowerPoint`, `Teams` |

2. Just double-click the `install_office2024.exe` *(run as Administrator)* to launch the installer. It will install Office with the default configuration in `install_office2024.au3` (which is `full_en.xml` currently). 

> *You may need to re-compile the `install_office2024.exe` file after modifying the default configuration.*
