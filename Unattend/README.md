# UNATTEND XML SCRIPTS

These scripts are used to automate the Windows installation process, please view the table below to know all of the scripts and their purpose:

## **⚠️⚠️⚠️ MOST OF THE UNATTEND XML SCRIPTS `DESTROY EVERYTHING` ON THE TARGET DISK! ⚠️⚠️⚠️**

> *Scroll horizontally to view all collumns*

| No. | Filename | Description | Edition | Activation | Language/Region | Disks & Partitions Management Style | Hardware Checks | BitLocker | Local Account | Host Name | OOBE | Bloatware Removal | Installs Apps | Install Drivers | Configure Windows |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `full_C.xml` | Best for `installation as batches` for **DEVELOPER** usage | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C drive *(full size)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | **`Yes`** | **`Yes`** | **`Yes`** |
| 2 | `full_C_D.xml` | Best for `installation as batches` for **INDIVIDUAL** usage | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(153600 MB)* and D drive *(remaining space)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | **`Yes`** | **`Yes`** | **`Yes`** |
| 3 | `full_dyn_C_D.xml` | Best for `Auto-pilot` experience with comfortable adjustment | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(`input`)* and D drive *(remaining space)* | Bypassed | Disabled | *(`input`)* *(Administrator Group)* | *(`input`)* | Bypassed | Removed | **`Yes`** | **`Yes`** | **`Yes`** |
| 4 | `full_mandisk.xml` | Best for a `safe installation with pre-existing data drives` | Pro | Unactivated | English/vi-vn | **`Manually`** configure disks & partitions | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | **`Yes`** | **`Yes`** | **`Yes`** |
| 5 | `noapps_C.xml` |  | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C drive *(full size)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | **`Yes`** | No |
| 6 | `noapps_C_D.xml` |  | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(153600 MB)* and D drive *(remaining space)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | **`Yes`** | No |
| 7 | `noapps_dyn_C_D.xml` |  | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(`input`)* and D drive *(remaining space)* | Bypassed | Disabled | *(`input`)* *(Administrator Group)* | *(`input`)* | Bypassed | Removed | No | **`Yes`** | No |
| 8 | `noapps_mandisk.xml` |  | Pro | Unactivated | English/vi-vn | **`Manually`** configure disks & partitions | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | **`Yes`** | No |
| 9 | `nodrivers_C.xml` | You want `just Windows`, nothing else | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C drive *(full size)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | No | No |
| 10 | `nodrivers_C_D.xml` |  | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(153600 MB)* and D drive *(remaining space)* | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | No | No |
| 11 | `nodrivers_dyn_C_D.xml` |  | Pro | Unactivated | English/vi-vn | Select a disk not the USB it self, format as C *(`input`)* and D drive *(remaining space)* | Bypassed | Disabled | *(`input`)* *(Administrator Group)* | *(`input`)* | Bypassed | Removed | No | No | No |
| 12 | `nodrivers_mandisk.xml` | The `minimalism guys` | Pro | Unactivated | English/vi-vn | **`Manually`** configure disks & partitions | Bypassed | Disabled | OEM *(Administrator Group)* | PC | Bypassed | Removed | No | No | No |

> *You may create your own Unattend XML scripts.*

## COPY TO ISO PARTITION

**NOTE:** The `extract.ps1` script will automatically copy these unattend scripts to ISO partition of yourr Ventoy USB.

> *Or your prefer to do it yourself, then do the following steps:*

**1. COPY THESE UNATTEND SCRIPTS TO ISO PARTITION**

Copy these unattend scripts to ISO partition of your ISO partition of the USB *(Ventoy installed, please refer to [INSTRUCTION](/README.md/#step-by-step))*

``` txt
ISO/
├── Windows
│   └── Windows11
│       └── w11.iso
├── full_C.xml
├── full_C_D.xml
├── full_mandisk.xml
├── full_dyn_C_D.xml
├── noapps_C.xml
├── noapps_C_D.xml
├── noapps_mandisk.xml
├── noapps_dyn_C_D.xml
├── nodrivers_C.xml
├── nodrivers_C_D.xml
├── nodrivers_mandisk.xml
├── nodrivers_dyn_C_D.xml
└── 5b512ee8a59deb284ad0a6a035ba10b1.md5
```

**2. MODIFY `ventoy.json` FILE**

Modify `"auto_install"` block in `ventoy.json` file to use these scripts.

``` json
{
    "auto_install":[
        {
            "image": "/Windows/Windows11/w11.iso",
            "template":[
                "/full_dyn_C_D.xml",
                "/full_C_D.xml",
                "/full_C.xml",
                "/full_mandisk.xml",
                "/noapps_dyn_C_D.xml",
                "/noapps_C_D.xml",
                "/noapps_C.xml",
                "/noapps_mandisk",
                "/nodrivers_dyn_C_D.xml",
                "/nodrivers_C_D.xml",
                "/nodrivers_C.xml",
                "/nodrivers_mandisk.xml"
            ],
            "timeout": 10,
            "autosel": 1
        }
    ]
}
```

There is an example [ventoy.json.example](/ventoy/ventoy.json.example).