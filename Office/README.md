# OFFICE

This directory includes all the office-suit installers.

Currently, support:
- **Microsoft Office 2024**
- **LibreOffice**

## MICROSOFT OFFICE 2024

The installer installs a fresh `unactivated Office 2024 LTSC suit` with `default configuration`. You need to activate it later using your own KMS/license *(or login with Microsoft 365)*.

Please refer to [README.md](Office2024/README.md) for more information.

** The `OLDER VERSION (OFFICE 2016, 2019, 2021,...)` can also be created for your own desire. Please read the manual below.**

### OLDER OFFICE VERSION

1. You might organize the `/Office` structure as below:

```txt
Office
├── LibreOffice
│   ├── install_libreoffice.au3
│   └── README.md
├── Office2024
│   ├── full_en.xml
│   ├── full_vi.xml
│   ├── install_office2024.au3
│   ├── README.md
│   ├── we_en.xml
│   ├── we_vi.xml
│   ├── wep_en.xml
│   ├── wep_vi.xml
│   ├── wepa_en.xml
│   └── wepa_vi.xml
├── Office2016
│   ├── full_en.xml
│   ├── full_vi.xml
│   ├── install_office2016.au3
│   ├── README.md
│   ├── we_en.xml
│   ├── we_vi.xml
│   ├── wep_en.xml
│   ├── wep_vi.xml
│   ├── wepa_en.xml
│   └── wepa_vi.xml
├── Office2019
│   ├── full_en.xml
│   ├── full_vi.xml
│   ├── install_office2019.au3
│   ├── README.md
│   ├── we_en.xml
│   ├── we_vi.xml
│   ├── wep_en.xml
│   ├── wep_vi.xml
│   ├── wepa_en.xml
│   └── wepa_vi.xml
├── Office2021
│   ├── full_en.xml
│   ├── full_vi.xml
│   ├── install_office2021.au3
│   ├── README.md
│   ├── we_en.xml
│   ├── we_vi.xml
│   ├── wep_en.xml
│   ├── wep_vi.xml
│   ├── wepa_en.xml
│   └── wepa_vi.xml
├── .gitignore
└── README.md
```

2. Copy the ODT tool `officedeploymenttool_*.exe` ([download here](https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_20228-20124.exe)) into each folder for each version. You may rename `setup.exe` in each version folder to `office2016.exe`, `office2019.exe`, `office2021.exe` or whatever you want.

3. The remaining instruction could be found at the original `README.md` of `/Office2024` folder. *Download Office, configure the XML files.*

## LIBREOFFICE

The installer installs `LibreOffice suit` with `default configuration`. Please make sure to configure them after installation has finished otherwise the exported file extensions will be in `.odp`, `.ods`, `.odt`, `.odb`, `.otp`, `.ots`, `.otg` format. 

Please refer to [README.md](LibreOffice/README.md) for more information.