#!/usr/bin/env python3
"""
=============================================================================
Theme Package Manager & Styling Toolkit for AutoInstaller
Location: tools/AutoInstaller/theme_manager.py
Author:   1172005thinh
=============================================================================
A developer utility to:
1. Scan and index all themeColor() and themeLoad() function calls across workspace.
2. Calculate total and per-key usage statistics.
3. Detect missing theme keys across all theme JSON databases (e.g. light.json, dark.json).
4. Verify and enforce equal line counts and canonical formatting across JSONs.
5. Validate color values (canonical 0xRRGGBB hex format) across all theme files.
6. Find unused/orphaned keys in theme files and suggest/prune them.
7. Sort all theme JSON keys alphabetically (A-Z) with clean 4-space indentation.
8. Hunt for hardcoded color hex values in GUI .au3 files and recommend theme keys.
9. Report theme coverage and parity matrix across all available themes.
"""

import sys
import os
import re
import json
import argparse
from pathlib import Path
from collections import Counter, defaultdict

# Ensure UTF-8 output encoding on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# ANSI Color codes for clean console output
class Colors:
    HEADER    = '\033[95m'
    BLUE      = '\033[94m'
    CYAN      = '\033[96m'
    GREEN     = '\033[92m'
    YELLOW    = '\033[93m'
    RED       = '\033[91m'
    BOLD      = '\033[1m'
    DIM       = '\033[2m'
    UNDERLINE = '\033[4m'
    ENDC      = '\033[0m'

# Disable colors if stdout is not a TTY or on legacy Windows without ANSI
if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    for attr in dir(Colors):
        if not attr.startswith("__"):
            setattr(Colors, attr, "")


def find_workspace_root(start_path: Path = None) -> Path:
    """Locate the workspace root by looking for AutoInstaller.au3 or navigating up."""
    if start_path is None:
        start_path = Path(__file__).resolve().parent
    current = start_path
    for _ in range(5):
        if (current / "AutoInstaller.au3").exists() and (current / "gui").is_dir():
            return current
        if current.parent == current:
            break
        current = current.parent
    # Fallback: two directories up from tools/AutoInstaller
    return Path(__file__).resolve().parent.parent.parent


def canonical_hex(val: str) -> str:
    """Normalize a hex color string to uppercase 0xRRGGBB format."""
    val = val.strip().strip('"\'')
    if val.startswith("#"):
        val = "0x" + val[1:]
    elif not val.lower().startswith("0x"):
        val = "0x" + val
    prefix = val[:2].lower()
    hex_digits = val[2:].upper()
    return f"0x{hex_digits.zfill(6)}"


def is_valid_hex_color(val: str) -> bool:
    """Check if string is a valid 6-digit hex color format (0xRRGGBB)."""
    return bool(re.match(r"^0x[0-9A-Fa-f]{6}$", val.strip()))


class ThemeManager:
    def __init__(self, workspace_root: Path):
        self.workspace_root = workspace_root
        self.themes_dir = self.workspace_root / "gui" / "assets" / "themes"
        self.ignore_dirs = {
            "tools/AutoIt",
            "tools/Ventoy",
            "BackUp",
            "scratch",
            ".git",
            ".vscode",
            "__pycache__"
        }
        self.theme_data = {}   # { 'light': dict, 'dark': dict, ... }
        self.theme_files = {}  # { 'light': Path, ... }
        self.calls = []        # list of (file_path, line_no, key)
        self.load_calls = []   # list of (file_path, line_no, theme_name)
        self.key_usage = Counter()
        self.key_locations = defaultdict(list)
        self.load_themes()
        self.scan_workspace_calls()

    def _should_ignore_dir(self, rel_path_str: str) -> bool:
        norm = rel_path_str.replace("\\", "/").strip("/")
        for ign in self.ignore_dirs:
            if norm == ign or norm.startswith(ign + "/"):
                return True
        return False

    def load_themes(self):
        """Load all *.json files in gui/assets/themes/."""
        self.theme_data.clear()
        self.theme_files.clear()
        if not self.themes_dir.exists():
            return
        for json_file in sorted(self.themes_dir.glob("*.json")):
            name = json_file.stem
            self.theme_files[name] = json_file
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    self.theme_data[name] = json.load(f)
            except Exception as e:
                print(f"{Colors.RED}Error reading {json_file.name}: {e}{Colors.ENDC}")
                self.theme_data[name] = {}

    def scan_workspace_calls(self):
        """Scan all .au3 files in workspace for themeColor() and themeLoad() calls."""
        self.calls.clear()
        self.load_calls.clear()
        self.key_usage.clear()
        self.key_locations.clear()

        # Regex patterns matching themeColor("key") and themeLoad("name")
        color_pattern = re.compile(r'themeColor\s*\(\s*["\']([^"\']+)["\']\s*\)')
        load_pattern = re.compile(r'themeLoad\s*\(\s*([^)]+)\s*\)')

        for root, dirs, files in os.walk(self.workspace_root):
            rel_root = Path(root).relative_to(self.workspace_root).as_posix()
            if self._should_ignore_dir(rel_root):
                continue

            for file in files:
                if not file.endswith(".au3"):
                    continue

                full_path = Path(root) / file
                rel_path = full_path.relative_to(self.workspace_root).as_posix()

                # Don't count theme.au3's own definition of themeColor($sKey)
                if rel_path == "gui/modules/theme.au3":
                    continue

                try:
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        for line_idx, line in enumerate(f, 1):
                            stripped = line.strip()
                            # Skip comments
                            if stripped.startswith(";") or stripped.startswith("#cs"):
                                continue

                            for m in color_pattern.finditer(line):
                                key = m.group(1)
                                self.calls.append((rel_path, line_idx, key))
                                self.key_usage[key] += 1
                                self.key_locations[key].append((rel_path, line_idx))

                            for lm in load_pattern.finditer(line):
                                arg = lm.group(1).strip().strip('"\'')
                                self.load_calls.append((rel_path, line_idx, arg))
                except Exception as e:
                    print(f"{Colors.YELLOW}Warning reading {rel_path}: {e}{Colors.ENDC}")

    # -------------------------------------------------------------------------
    # Analysis & Checks
    # -------------------------------------------------------------------------

    def get_missing_keys(self):
        """
        Identify:
        1. Keys used in code but missing in at least one theme file.
        2. Keys present in baseline ('light' or primary theme) but missing in others.
        """
        used_keys = set(self.key_usage.keys())
        code_missing = {} # { theme_name: set of keys }
        for name, data in self.theme_data.items():
            missing = used_keys - set(data.keys())
            if missing:
                code_missing[name] = missing

        inter_theme_missing = {}
        baseline_name = "light" if "light" in self.theme_data else (list(self.theme_data.keys())[0] if self.theme_data else None)
        if baseline_name:
            base_keys = set(self.theme_data.get(baseline_name, {}).keys())
            for name, data in self.theme_data.items():
                if name == baseline_name:
                    continue
                missing_vs_base = base_keys - set(data.keys())
                if missing_vs_base:
                    inter_theme_missing[name] = missing_vs_base

        return code_missing, inter_theme_missing

    def get_unused_keys(self):
        """Identify keys declared in JSON files that are not referenced in code."""
        used_keys = set(self.key_usage.keys())
        unused = {}
        for name, data in self.theme_data.items():
            diff = set(data.keys()) - used_keys
            if diff:
                unused[name] = diff
        return unused

    def get_line_count_status(self):
        """Check line counts across all theme JSON files."""
        counts = {}
        for name, fpath in self.theme_files.items():
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    counts[name] = len(f.readlines())
            except Exception:
                counts[name] = 0
        return counts

    def get_color_format_issues(self):
        """
        Verify that all color definitions in theme JSONs conform to canonical
        0xRRGGBB format (with uppercase hex digits).
        """
        issues = [] # list of (theme_name, key, value, issue_reason)
        for name, data in self.theme_data.items():
            for key, val in data.items():
                val_str = str(val).strip()
                if not is_valid_hex_color(val_str):
                    issues.append((name, key, val_str, "Invalid hex color format (expected 0xRRGGBB)"))
                elif val_str != canonical_hex(val_str):
                    issues.append((name, key, val_str, f"Non-canonical casing (expected {canonical_hex(val_str)})"))
        return issues

    def scan_hardcoded_colors(self):
        """
        Search for hardcoded hex colors (0xXXXXXX) in GUI .au3 files
        that should be moved to the theme system.
        """
        candidates = []
        # Target GUI color setting functions
        color_api_patterns = [
            re.compile(r'GUISetBkColor\s*\(\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'GUICtrlSetColor\s*\([^,]+,\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'GUICtrlSetBkColor\s*\([^,]+,\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'_GUICtrlListView_SetTextColor\s*\([^,]+,\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'_GUICtrlListView_SetTextBkColor\s*\([^,]+,\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'_GUICtrlListView_SetBkColor\s*\([^,]+,\s*(0x[0-9A-Fa-f]{6})\b'),
            re.compile(r'scrollSetViewportBkColor\s*\(\s*(0x[0-9A-Fa-f]{6})\b'),
        ]

        # Inverted index of existing theme colors for intelligent key suggestion
        known_colors = {}
        for theme_name, data in self.theme_data.items():
            for k, v in data.items():
                norm = canonical_hex(str(v))
                if norm not in known_colors:
                    known_colors[norm] = []
                known_colors[norm].append((theme_name, k))

        # Check all workspace .au3 files (excluding ignored dirs and theme.au3)
        for root, dirs, files in os.walk(self.workspace_root):
            rel_root = Path(root).relative_to(self.workspace_root).as_posix()
            if self._should_ignore_dir(rel_root):
                continue

            for file in files:
                if not file.endswith(".au3"):
                    continue

                full_path = Path(root) / file
                rel_path = full_path.relative_to(self.workspace_root).as_posix()

                if rel_path == "gui/modules/theme.au3":
                    continue

                try:
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        for line_idx, line in enumerate(f, 1):
                            stripped = line.strip()
                            if stripped.startswith(";") or stripped.startswith("#cs"):
                                continue

                            # Skip lines already using themeColor()
                            if "themeColor(" in line:
                                continue

                            for pat in color_api_patterns:
                                m = pat.search(line)
                                if m:
                                    color_val = canonical_hex(m.group(1))
                                    # Lookup suggestion
                                    suggestion = None
                                    if color_val in known_colors:
                                        match_list = known_colors[color_val]
                                        suggestion = match_list[0][1]
                                    candidates.append((rel_path, line_idx, color_val, line.strip(), suggestion))
                except Exception:
                    pass

        return candidates

    # -------------------------------------------------------------------------
    # Actions & Fixes
    # -------------------------------------------------------------------------

    def sort_all_databases(self):
        """Sort all JSON theme files A-Z and format with 4-space indents and canonical hex."""
        modified = []
        for name, fpath in self.theme_files.items():
            data = self.theme_data.get(name, {})
            # Sort A-Z by key
            sorted_items = sorted(data.items(), key=lambda item: item[0])

            content = "{\n"
            for i, (k, v) in enumerate(sorted_items):
                # Ensure canonical uppercase 0xRRGGBB format if it's a valid hex
                val_str = str(v).strip()
                if is_valid_hex_color(val_str) or val_str.startswith("#"):
                    val_str = canonical_hex(val_str)
                escaped_k = json.dumps(k, ensure_ascii=False)
                escaped_v = json.dumps(val_str, ensure_ascii=False)
                comma = "," if i < len(sorted_items) - 1 else ""
                content += f"    {escaped_k}: {escaped_v}{comma}\n"
            content += "}\n"

            with open(fpath, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            modified.append(name)

        self.load_themes()
        return modified

    def synchronize_keys(self):
        """
        Ensure all JSON databases share the exact same key set as the baseline (light.json).
        Missing keys in other themes are populated with the baseline value so line-counts match.
        """
        baseline_name = "light" if "light" in self.theme_data else (list(self.theme_data.keys())[0] if self.theme_data else None)
        if not baseline_name:
            print(f"{Colors.RED}No baseline theme found! Cannot sync.{Colors.ENDC}")
            return False

        base_dict = self.theme_data.get(baseline_name, {})
        base_keys = sorted(base_dict.keys())

        for name, fpath in self.theme_files.items():
            if name == baseline_name:
                continue
            curr_dict = self.theme_data.get(name, {})
            updated = {}
            for k in base_keys:
                if k in curr_dict:
                    updated[k] = curr_dict[k]
                else:
                    updated[k] = base_dict[k] # Fallback to baseline theme color
            self.theme_data[name] = updated

        self.sort_all_databases()
        return True

    def clean_unused_keys(self):
        """Remove unused keys from all theme JSON files."""
        unused = self.get_unused_keys()
        all_unused = set()
        for s in unused.values():
            all_unused.update(s)

        if not all_unused:
            return 0

        total_removed = 0
        for name, fpath in self.theme_files.items():
            curr_dict = self.theme_data.get(name, {})
            new_dict = {k: v for k, v in curr_dict.items() if k not in all_unused}
            total_removed += len(curr_dict) - len(new_dict)
            self.theme_data[name] = new_dict

        self.sort_all_databases()
        return total_removed

    # -------------------------------------------------------------------------
    # Reports
    # -------------------------------------------------------------------------

    def print_audit_report(self) -> bool:
        """Print full audit report. Returns True if all checks pass."""
        has_errors = False
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== AutoInstaller Theme Package Audit ==={Colors.ENDC}\n")

        # 1. Summary Statistics
        total_calls = len(self.calls)
        unique_keys = len(self.key_usage)
        total_loads = len(self.load_calls)
        print(f"{Colors.BOLD}1. Usage Overview:{Colors.ENDC}")
        print(f"   * Total themeColor() calls in code: {Colors.GREEN}{total_calls}{Colors.ENDC}")
        print(f"   * Unique keys referenced in code: {Colors.GREEN}{unique_keys}{Colors.ENDC}")
        print(f"   * themeLoad() invocations in code: {Colors.GREEN}{total_loads}{Colors.ENDC}")
        for name, data in sorted(self.theme_data.items()):
            print(f"   * Database [{name}.json]: {Colors.GREEN}{len(data)}{Colors.ENDC} keys")

        # 2. Line Count Parity
        line_counts = self.get_line_count_status()
        print(f"\n{Colors.BOLD}2. Line-Count Parity:{Colors.ENDC}")
        counts_set = set(line_counts.values())
        if len(counts_set) == 1:
            cnt = next(iter(counts_set))
            print(f"   {Colors.GREEN}[PASS] All theme databases have identical line counts ({cnt} lines).{Colors.ENDC}")
        else:
            has_errors = True
            print(f"   {Colors.RED}[FAIL] Line count mismatch detected across theme files!{Colors.ENDC}")
            for name, cnt in sorted(line_counts.items()):
                print(f"     - {name}.json: {cnt} lines")
            print(f"     {Colors.YELLOW}Tip: Run 'python tools/AutoInstaller/theme_manager.py sort' or 'sync' to align.{Colors.ENDC}")

        # 3. Missing Keys
        code_missing, inter_missing = self.get_missing_keys()
        print(f"\n{Colors.BOLD}3. Missing Keys in Databases:{Colors.ENDC}")
        if not code_missing and not inter_missing:
            print(f"   {Colors.GREEN}[PASS] All referenced keys exist across all theme databases.{Colors.ENDC}")
        else:
            has_errors = True
            if code_missing:
                for name, keys in sorted(code_missing.items()):
                    print(f"   {Colors.RED}[FAIL] [{name}.json] is missing {len(keys)} key(s) used in code:{Colors.ENDC}")
                    for k in sorted(keys)[:10]:
                        locs = self.key_locations.get(k, [("unknown", 0)])[0]
                        print(f"     - '{k}' (used in {locs[0]}:{locs[1]})")
                    if len(keys) > 10:
                        print(f"     ... and {len(keys) - 10} more.")

            if inter_missing:
                for name, keys in sorted(inter_missing.items()):
                    print(f"   {Colors.YELLOW}[WARN] [{name}.json] is missing {len(keys)} key(s) compared to baseline theme:{Colors.ENDC}")
                    for k in sorted(keys)[:5]:
                        print(f"     - '{k}'")
                    if len(keys) > 5:
                        print(f"     ... and {len(keys) - 5} more.")

        # 4. Color Value Format & Parity Integrity
        format_issues = self.get_color_format_issues()
        print(f"\n{Colors.BOLD}4. Color Value Format & Parity (Canonical 0xRRGGBB):{Colors.ENDC}")
        if not format_issues:
            print(f"   {Colors.GREEN}[PASS] All color entries have valid 0xRRGGBB hex formatting.{Colors.ENDC}")
        else:
            has_errors = True
            print(f"   {Colors.RED}[FAIL] Found {len(format_issues)} color format discrepancy/discrepancies:{Colors.ENDC}")
            for name, key, val, reason in format_issues[:8]:
                print(f"     * [{name}.json] '{key}': {Colors.RED}{val!r}{Colors.ENDC} ({reason})")
            if len(format_issues) > 8:
                print(f"     ... and {len(format_issues) - 8} more.")
            print(f"     {Colors.YELLOW}Tip: Run 'python tools/AutoInstaller/theme_manager.py sort' to canonicalize values.{Colors.ENDC}")

        # 5. Unused Keys
        unused = self.get_unused_keys()
        print(f"\n{Colors.BOLD}5. Unused Keys (in JSON but not called in code):{Colors.ENDC}")
        all_unused = set()
        for s in unused.values():
            all_unused.update(s)
        if not all_unused:
            print(f"   {Colors.GREEN}[PASS] No orphaned or unused keys detected.{Colors.ENDC}")
        else:
            print(f"   {Colors.YELLOW}[INFO] Found {len(all_unused)} key(s) declared in JSON but never called in code:{Colors.ENDC}")
            for k in sorted(all_unused)[:10]:
                print(f"     - '{k}'")
            if len(all_unused) > 10:
                print(f"     ... and {len(all_unused) - 10} more.")
            print(f"     {Colors.DIM}(Run 'python tools/AutoInstaller/theme_manager.py clean-unused' if you wish to prune them){Colors.ENDC}")

        # 6. Overall Status
        print(f"\n{Colors.BOLD}=== Summary ==={Colors.ENDC}")
        if not has_errors:
            print(f"{Colors.GREEN}{Colors.BOLD}[PASS] ALL theme CHECKS PASSED!{Colors.ENDC}\n")
        else:
            print(f"{Colors.RED}{Colors.BOLD}[FAIL] ISSUES DETECTED. Review suggestions above or run fix commands.{Colors.ENDC}\n")

        return not has_errors

    def print_coverage_matrix(self):
        """Display theme completeness and parity matrix."""
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== Theme Coverage & Parity Matrix ==={Colors.ENDC}\n")
        baseline_name = "light" if "light" in self.theme_data else (list(self.theme_data.keys())[0] if self.theme_data else None)
        base_dict = self.theme_data.get(baseline_name, {})
        total_master = len(base_dict)

        print(f"{'Theme':<14} {'Total Keys':<12} {'Coverage':<12} {'Status'}")
        print("-" * 52)
        for name, data in sorted(self.theme_data.items()):
            count = len(data)
            pct = (count / total_master * 100) if total_master else 0
            if pct >= 100:
                status = f"{Colors.GREEN}Complete{Colors.ENDC}"
            else:
                status = f"{Colors.YELLOW}Incomplete ({total_master - count} missing){Colors.ENDC}"
            print(f"{name:<14} {count:<12} {pct:>5.1f}%       {status}")
        print()

    def print_hardcoded_report(self):
        """Scan and display hardcoded GUI hex colors."""
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== Hardcoded Color Scanner ==={Colors.ENDC}\n")
        candidates = self.scan_hardcoded_colors()
        if not candidates:
            print(f"{Colors.GREEN}[OK] No hardcoded GUI colors detected! All styling uses themeColor().{Colors.ENDC}\n")
            return

        print(f"Found {Colors.YELLOW}{len(candidates)}{Colors.ENDC} potential hardcoded color(s):\n")
        for rel_path, line_no, color_val, line_snippet, suggestion in candidates:
            print(f" * {rel_path}:{line_no}")
            print(f"   Hex Value:  {Colors.BOLD}{color_val}{Colors.ENDC}")
            print(f"   Code:       {Colors.DIM}{line_snippet}{Colors.ENDC}")
            if suggestion:
                print(f"   Suggested:  themeColor(\"{Colors.GREEN}{suggestion}{Colors.ENDC}\")")
            else:
                print(f"   Suggested:  themeColor(\"custom.color\")")
            print()


def main():
    parser = argparse.ArgumentParser(
        description="AutoInstaller Theme Package Manager & Styling Toolkit",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tools/AutoInstaller/theme_manager.py audit
  python tools/AutoInstaller/theme_manager.py sort
  python tools/AutoInstaller/theme_manager.py sync
  python tools/AutoInstaller/theme_manager.py scan-hardcoded
  python tools/AutoInstaller/theme_manager.py clean-unused
  python tools/AutoInstaller/theme_manager.py coverage
        """
    )

    parser.add_argument(
        "action",
        nargs="?",
        default="audit",
        choices=["audit", "sort", "sync", "clean-unused", "scan-hardcoded", "coverage", "check"],
        help="Action to perform (default: audit)"
    )
    parser.add_argument(
        "--workspace",
        type=Path,
        default=None,
        help="Path to workspace root (defaults to auto-detected root)"
    )

    args = parser.parse_args()
    workspace = find_workspace_root(args.workspace)
    manager = ThemeManager(workspace)

    if args.action in ("audit", "check"):
        success = manager.print_audit_report()
        sys.exit(0 if success else 1)

    elif args.action == "sort":
        modified = manager.sort_all_databases()
        print(f"{Colors.GREEN}[OK] Successfully sorted and formatted: {', '.join(modified)}{Colors.ENDC}")

    elif args.action == "sync":
        if manager.synchronize_keys():
            print(f"{Colors.GREEN}[OK] All theme databases synchronized with baseline theme and sorted.{Colors.ENDC}")

    elif args.action == "clean-unused":
        removed = manager.clean_unused_keys()
        print(f"{Colors.GREEN}[OK] Removed {removed} unused key entries across all theme databases.{Colors.ENDC}")

    elif args.action == "scan-hardcoded":
        manager.print_hardcoded_report()

    elif args.action == "coverage":
        manager.print_coverage_matrix()


if __name__ == "__main__":
    main()
