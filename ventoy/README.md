# Ventoy configuration

## ***Rename `ventoy.json.example` to `ventoy.json` before using***

Copy this ventoy folder to the root of Ventoy's ISO/data partition. The resulting configuration file must be located at /ventoy/ventoy.json.

The configuration applies to /Windows/w11_24h2_fa_c.iso. Its templates are stored under /Windows/Windows11/. Ventoy selects Auto-pilot after five seconds unless another option is chosen:

1. Boot normally without an unattended template.
2. Use auto-pilot_autounattend.xml.
3. Use windows-only_autounattend.xml.
4. Use windows-only-no-driver_autounattend.xml.

The three XML files are stored under /Windows/Windows11/, as defined in ventoy.json. They use Ventoy's `$$VT_WINDOWS_DISK_1ST_NONVTOY$$` variable so Windows Setup targets the first non-Ventoy disk rather than assuming disk 0.

If the final ISO filename changes, update the image value in ventoy.json to its exact partition-relative path.
