# UNATTEND XML SCRIPTS

These scripts are used to automate the Windows installation process, please view the table below to know all of the scripts and their purpose:

> *Scroll horizontally to view all collumns*

| No. | Filename | Description |
|-----|----------|-------------|
| 1 | `full_C.xml` | Install Windows on C: drive, no other partitions will be created |
| 2 | `full_C_D.xml` | Install Windows on C: drive and create D: drive with remaining space |
| 3 | `full_dyn_C_D.xml` | Install Windows on C: drive and create D: drive with inputable size |
| 4 | `full_mandisk.xml` | Install Windows on C: drive and create D: drive with manual disk selection |
| 5 | `noapps_C.xml` | Install Windows on C: drive without any apps |
| 6 | `noapps_C_D.xml` | Install Windows on C: drive and create D: drive with remaining space without any apps |
| 7 | `noapps_dyn_C_D.xml` | Install Windows on C: drive and create D: drive with inputable size without any apps |
| 8 | `noapps_mandisk.xml` | Install Windows on C: drive and create D: drive with manual disk selection without any apps |
| 9 | `nodrivers_C.xml` | Install Windows on C: drive without any drivers |
| 10 | `nodrivers_C_D.xml` | Install Windows on C: drive and create D: drive with remaining space without any drivers |
| 11 | `nodrivers_dyn_C_D.xml` | Install Windows on C: drive and create D: drive with inputable size without any drivers |
| 12 | `nodrivers_mandisk.xml` | Install Windows on C: drive and create D: drive with manual disk selection without any drivers |

> **About `Dynamic Partition`**, it will automatically prompt you to enter the size of the partition you want to create, and then create the partition with the specified size.

> **About `Manual Disk Selection`**, it will automatically prompt you to select the disk and partition you want to create the partition on.

## COPY TO ISO PARTITION

**NOTE:** The `extract.ps1` script will automatically copy these unattend scripts to ISO partition of yourr Ventoy USB.

> *Or your prefer to do it yourself, then do the following steps:*

**1. COPY THESE UNATTEND SCRIPTS TO ISO PARTITION**

Copy these unattend scripts to ISO partition of your ISO partition of the USB *(Ventoy installed, please refer to [INSTRUCTION](/README.md/#step-by-step))*

``` txt
ISO/
├── Windows
│   └── w11.iso
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