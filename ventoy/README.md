# VENTOY CONFIGURATION

## AUTO INSTALLATION

The script `extract.ps1` automatically copy `/ventoy` folder and other related files to the root of ISO partition. Please refer to [INSTRUCTION](/README.md/#step-by-step)

## MANUAL INSTALLATION

**Rename `ventoy.json.example` to `ventoy.json` before using**

Copy this ventoy folder to the root of Ventoy's ISO/data partition. The resulting configuration file must be located at `/ventoy/ventoy.json`.

The configuration applies to `/Windows/w11.iso`. Its unattend XML templates are stored at root `/`. Ventoy boots with the first selection after `10` seconds unless another option is chosen.

Please refer to [Unattend scripts](/Unattend/README.md) for more information.
