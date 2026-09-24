#!/usr/bin/env python3
"""
=============================================================================
Language Package Manager & i18n Toolkit for AutoInstaller
Location: tools/AutoInstaller/i18n_manager.py
Author:   1172005thinh
=============================================================================
A developer utility to:
1. Scan and index all i18nGet() function calls across the workspace.
2. Calculate total and per-key usage statistics.
3. Detect missing translation keys across all language JSON databases.
4. Verify and enforce equal line counts and canonical formatting across JSONs.
5. Verify that i18nGet() fallback strings match en-us.json exactly (with auto-fix).
6. Find unused/orphaned keys in language files and suggest/prune them.
7. Sort all language JSON keys alphabetically (A-Z) with clean 4-space indentation.
8. Hunt for hardcoded UI strings longer than 3 characters in GUI .au3 files.
9. Report translation coverage matrix and untranslated string warnings.
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


class I18nManager:
    def __init__(self, workspace_root: Path):
        self.workspace_root = workspace_root
        self.langs_dir = self.workspace_root / "gui" / "assets" / "langs"
        self.ignore_dirs = {
            "tools/AutoIt",
            "tools/Ventoy",
            "BackUp",
            "scratch",
            ".git",
            ".vscode",
            "__pycache__"
        }
        self.lang_data = {}  # { 'en-us': dict, 'vi-vn': dict, ... }
        self.lang_files = {} # { 'en-us': Path, ... }
        self.calls = []      # list of (file_path, line_no, key, fallback_str)
        self.key_usage = Counter()
        self.key_locations = defaultdict(list)
        self.load_languages()
        self.scan_workspace_calls()

    def _should_ignore_dir(self, rel_path_str: str) -> bool:
        norm = rel_path_str.replace("\\", "/").strip("/")
        for ign in self.ignore_dirs:
            if norm == ign or norm.startswith(ign + "/"):
                return True
        return False

    def load_languages(self):
        """Load all *.json files in gui/assets/langs/."""
        if not self.langs_dir.exists():
            return
        for json_file in sorted(self.langs_dir.glob("*.json")):
            code = json_file.stem
            self.lang_files[code] = json_file
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    self.lang_data[code] = json.load(f)
            except Exception as e:
                print(f"{Colors.RED}Error reading {json_file.name}: {e}{Colors.ENDC}")
                self.lang_data[code] = {}

    def scan_workspace_calls(self):
        """Scan all .au3 files in workspace for i18nGet() calls."""
        self.calls.clear()
        self.key_usage.clear()
        self.key_locations.clear()

        # Regex pattern matching i18nGet("key", "fallback") or i18nGet("key")
        # Supports single or double quotes for arguments
        pattern = re.compile(
            r'i18nGet\s*\(\s*["\']([^"\']+)["\'](?:\s*,\s*["\'](.*?)["\'])?\s*\)'
        )

        for root, dirs, files in os.walk(self.workspace_root):
            rel_root = Path(root).relative_to(self.workspace_root).as_posix()
            if self._should_ignore_dir(rel_root):
                continue

            for file in files:
                if not file.endswith(".au3"):
                    continue

                full_path = Path(root) / file
                rel_path = full_path.relative_to(self.workspace_root).as_posix()

                try:
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        for line_idx, line in enumerate(f, 1):
                            # Skip full-line comments
                            stripped = line.strip()
                            if stripped.startswith(";") or stripped.startswith("#cs"):
                                continue

                            for m in pattern.finditer(line):
                                key = m.group(1)
                                fallback = m.group(2) # None if single argument
                                self.calls.append((rel_path, line_idx, key, fallback))
                                self.key_usage[key] += 1
                                self.key_locations[key].append((rel_path, line_idx))
                except Exception as e:
                    print(f"{Colors.YELLOW}Warning reading {rel_path}: {e}{Colors.ENDC}")

    # -------------------------------------------------------------------------
    # Analysis & Checks
    # -------------------------------------------------------------------------

    def get_missing_keys(self):
        """
        Identify:
        1. Keys used in code but missing in at least one lang file.
        2. Keys present in en-us but missing in other lang files.
        """
        used_keys = set(self.key_usage.keys())
        code_missing = {} # { lang_code: set of keys }
        for code, data in self.lang_data.items():
            missing = used_keys - set(data.keys())
            if missing:
                code_missing[code] = missing

        inter_lang_missing = {} # { lang_code: set of keys missing compared to en-us }
        en_keys = set(self.lang_data.get("en-us", {}).keys())
        for code, data in self.lang_data.items():
            if code == "en-us":
                continue
            missing_vs_en = en_keys - set(data.keys())
            if missing_vs_en:
                inter_lang_missing[code] = missing_vs_en

        return code_missing, inter_lang_missing

    def get_unused_keys(self):
        """Identify keys declared in JSON files that are not referenced in code."""
        used_keys = set(self.key_usage.keys())
        unused = {}
        for code, data in self.lang_data.items():
            diff = set(data.keys()) - used_keys
            if diff:
                unused[code] = diff
        return unused

    def get_line_count_status(self):
        """Check line counts across all lang JSON files."""
        counts = {}
        for code, fpath in self.lang_files.items():
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    counts[code] = len(f.readlines())
            except Exception:
                counts[code] = 0
        return counts

    def get_fallback_mismatches(self):
        """
        Check that every i18nGet() includes a fallback string that matches
        the English value in en-us.json exactly.
        """
        en_dict = self.lang_data.get("en-us", {})
        mismatches = [] # list of (rel_path, line_no, key, actual_fallback, expected_fallback)
        for rel_path, line_no, key, fallback in self.calls:
            expected = en_dict.get(key)
            if expected is None:
                continue # Key doesn't exist in en-us (handled by missing keys check)

            if fallback is None:
                mismatches.append((rel_path, line_no, key, None, expected))
            elif fallback != expected:
                mismatches.append((rel_path, line_no, key, fallback, expected))

        return mismatches

    def scan_hardcoded_strings(self, min_len=4):
        """
        Search for hardcoded strings in GUI .au3 files (longer than 3 chars)
        that could be candidates for localization.
        """
        candidates = []
        # Target GUI definition files
        target_patterns = [
            re.compile(r'GUICtrlCreate(?:Label|Button|Checkbox|Radio|Group)\s*\(\s*["\']([^"\']+)["\']'),
            re.compile(r'GUICtrlSet(?:Data|Tip)\s*\(\s*[^,]+,\s*["\']([^"\']+)["\']'),
            re.compile(r'appSetStatus\s*\(\s*["\']([^"\']+)["\']'),
            re.compile(r'MsgBox\s*\([^,]+,\s*["\']([^"\']+)["\'],\s*["\']([^"\']+)["\']'),
            re.compile(r'_GUICtrlEdit_SetCueBanner\s*\([^,]+,\s*["\']([^"\']+)["\']')
        ]

        # Ignore tokens that are layout/technical rather than user text
        technical_tokens = {
            "x64", "arm", "ntfs", "fat32", "pc", "auto", "manual", "hybrid",
            "gpt", "mbr", "express", "recommended", "administrator", "user",
            "windows", "light", "dark", "ready", "error", "saved", "loading"
        }

        for root, dirs, files in os.walk(self.workspace_root / "gui"):
            for file in files:
                if not file.endswith(".au3"):
                    continue
                full_path = Path(root) / file
                rel_path = full_path.relative_to(self.workspace_root).as_posix()

                try:
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        for line_idx, line in enumerate(f, 1):
                            line_s = line.strip()
                            if line_s.startswith(";") or line_s.startswith("#cs"):
                                continue

                            # Skip lines already using i18nGet
                            if "i18nGet(" in line:
                                continue

                            for pat in target_patterns:
                                for m in pat.finditer(line):
                                    for group_idx in range(1, len(m.groups()) + 1):
                                        val = m.group(group_idx)
                                        if not val:
                                            continue
                                        val_clean = val.strip()
                                        if len(val_clean) < min_len:
                                            continue
                                        # Skip pipe lists (e.g. "Windows 11 Pro|Windows 11 Home")
                                        if "|" in val_clean:
                                            continue
                                        # Skip technical markers
                                        if val_clean.startswith("$$VT_") or val_clean.startswith("0x"):
                                            continue
                                        if val_clean.lower() in technical_tokens:
                                            continue
                                        candidates.append((rel_path, line_idx, val_clean))
                except Exception:
                    pass

        return candidates

    # -------------------------------------------------------------------------
    # Actions & Fixes
    # -------------------------------------------------------------------------

    def sort_all_databases(self):
        """Sort all JSON language files A-Z and format with 4-space indents."""
        modified = []
        for code, fpath in self.lang_files.items():
            data = self.lang_data.get(code, {})
            sorted_data = dict(sorted(data.items(), key=lambda item: item[0]))
            
            # Format cleanly as UTF-8 without BOM
            content = "{\n"
            items = list(sorted_data.items())
            for i, (k, v) in enumerate(items):
                escaped_v = json.dumps(v, ensure_ascii=False)
                escaped_k = json.dumps(k, ensure_ascii=False)
                comma = "," if i < len(items) - 1 else ""
                content += f"    {escaped_k}: {escaped_v}{comma}\n"
            content += "}\n"

            with open(fpath, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            modified.append(code)

        self.load_languages()
        return modified

    def synchronize_keys(self):
        """
        Ensure all JSON databases share the exact same key set as en-us.
        Missing keys in other locales are populated with the English baseline.
        """
        en_dict = self.lang_data.get("en-us", {})
        if not en_dict:
            print(f"{Colors.RED}en-us.json not found or empty! Cannot sync.{Colors.ENDC}")
            return False

        en_keys = sorted(en_dict.keys())
        for code, fpath in self.lang_files.items():
            if code == "en-us":
                continue
            curr_dict = self.lang_data.get(code, {})
            updated = {}
            for k in en_keys:
                if k in curr_dict:
                    updated[k] = curr_dict[k]
                else:
                    updated[k] = en_dict[k] # Fallback to English value
            self.lang_data[code] = updated

        self.sort_all_databases()
        return True

    def fix_fallback_strings(self):
        """
        Automatically update all i18nGet() calls in .au3 files so their fallback
        matches the canonical value in en-us.json.
        """
        mismatches = self.get_fallback_mismatches()
        if not mismatches:
            return 0

        # Group by file
        by_file = defaultdict(list)
        for rel_path, line_no, key, actual, expected in mismatches:
            by_file[rel_path].append((line_no, key, actual, expected))

        patched_count = 0
        for rel_path, items in by_file.items():
            full_path = self.workspace_root / rel_path
            with open(full_path, "r", encoding="utf-8") as f:
                lines = f.readlines()

            for line_no, key, actual, expected in items:
                idx = line_no - 1
                if idx >= len(lines):
                    continue
                orig_line = lines[idx]
                escaped_expected = expected.replace('"', '""') # AutoIt quote escape

                if actual is not None:
                    # Replace second argument
                    # Matches i18nGet("key", "old")
                    old_pattern = re.compile(
                        r'(i18nGet\s*\(\s*["\']' + re.escape(key) + r'["\']\s*,\s*["\']).*?(["\']\s*\))'
                    )
                    new_line, count = old_pattern.subn(r'\g<1>' + expected + r'\g<2>', orig_line)
                    if count > 0:
                        lines[idx] = new_line
                        patched_count += 1
                else:
                    # Single argument i18nGet("key") -> i18nGet("key", "expected")
                    old_pattern = re.compile(
                        r'(i18nGet\s*\(\s*["\']' + re.escape(key) + r'["\']\s*)(\))'
                    )
                    new_line, count = old_pattern.subn(r'\g<1>, "' + expected + r'"\g<2>', orig_line)
                    if count > 0:
                        lines[idx] = new_line
                        patched_count += 1

            with open(full_path, "w", encoding="utf-8", newline="\n") as f:
                f.writelines(lines)

        self.scan_workspace_calls()
        return patched_count

    def clean_unused_keys(self):
        """Remove unused keys from all language JSON files."""
        unused = self.get_unused_keys()
        total_removed = 0
        all_unused = set()
        for s in unused.values():
            all_unused.update(s)

        if not all_unused:
            return 0

        for code, fpath in self.lang_files.items():
            curr_dict = self.lang_data.get(code, {})
            new_dict = {k: v for k, v in curr_dict.items() if k not in all_unused}
            self.lang_data[code] = new_dict
            total_removed += len(curr_dict) - len(new_dict)

        self.sort_all_databases()
        return total_removed

    # -------------------------------------------------------------------------
    # Reports
    # -------------------------------------------------------------------------

    def print_audit_report(self) -> bool:
        """Print full audit report. Returns True if all checks pass."""
        has_errors = False
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== AutoInstaller Language Package Audit ==={Colors.ENDC}\n")

        # 1. Summary Statistics
        total_calls = len(self.calls)
        unique_keys = len(self.key_usage)
        print(f"{Colors.BOLD}1. Usage Overview:{Colors.ENDC}")
        print(f"   * Total i18nGet() calls in code: {Colors.GREEN}{total_calls}{Colors.ENDC}")
        print(f"   * Unique keys referenced in code: {Colors.GREEN}{unique_keys}{Colors.ENDC}")
        for code, data in sorted(self.lang_data.items()):
            print(f"   * Database [{code}.json]: {Colors.GREEN}{len(data)}{Colors.ENDC} keys")

        # 2. Line Count Parity
        line_counts = self.get_line_count_status()
        print(f"\n{Colors.BOLD}2. Line-Count Parity:{Colors.ENDC}")
        counts_set = set(line_counts.values())
        if len(counts_set) == 1:
            cnt = next(iter(counts_set))
            print(f"   {Colors.GREEN}[PASS] All language databases have identical line counts ({cnt} lines).{Colors.ENDC}")
        else:
            has_errors = True
            print(f"   {Colors.RED}[FAIL] Line count mismatch detected across language files!{Colors.ENDC}")
            for code, cnt in sorted(line_counts.items()):
                print(f"     - {code}.json: {cnt} lines")
            print(f"     {Colors.YELLOW}Tip: Run 'python tools/AutoInstaller/i18n_manager.py sort' or 'sync' to align.{Colors.ENDC}")

        # 3. Missing Keys
        code_missing, inter_missing = self.get_missing_keys()
        print(f"\n{Colors.BOLD}3. Missing Keys in Databases:{Colors.ENDC}")
        if not code_missing and not inter_missing:
            print(f"   {Colors.GREEN}[PASS] All referenced keys exist across all language databases.{Colors.ENDC}")
        else:
            has_errors = True
            if code_missing:
                for code, keys in sorted(code_missing.items()):
                    print(f"   {Colors.RED}[FAIL] [{code}.json] is missing {len(keys)} key(s) used in code:{Colors.ENDC}")
                    for k in sorted(keys)[:10]:
                        locs = self.key_locations.get(k, [("unknown", 0)])[0]
                        print(f"     - '{k}' (used in {locs[0]}:{locs[1]})")
                    if len(keys) > 10:
                        print(f"     ... and {len(keys) - 10} more.")

            if inter_missing:
                for code, keys in sorted(inter_missing.items()):
                    print(f"   {Colors.YELLOW}[WARN] [{code}.json] is missing {len(keys)} key(s) compared to [en-us.json]:{Colors.ENDC}")
                    for k in sorted(keys)[:5]:
                        print(f"     - '{k}'")
                    if len(keys) > 5:
                        print(f"     ... and {len(keys) - 5} more.")

        # 4. Fallback Strings Integrity
        fallback_mismatches = self.get_fallback_mismatches()
        print(f"\n{Colors.BOLD}4. Fallback String Integrity (Must match en-us.json exactly):{Colors.ENDC}")
        if not fallback_mismatches:
            print(f"   {Colors.GREEN}[PASS] All i18nGet() fallback strings match en-us.json.{Colors.ENDC}")
        else:
            has_errors = True
            print(f"   {Colors.RED}[FAIL] Found {len(fallback_mismatches)} fallback string discrepancy/discrepancies:{Colors.ENDC}")
            for rel_path, line_no, key, actual, expected in fallback_mismatches[:8]:
                print(f"     * {rel_path}:{line_no} [{key}]")
                print(f"       Code fallback:     {Colors.RED}{actual!r}{Colors.ENDC}")
                print(f"       Expected (en-us):  {Colors.GREEN}{expected!r}{Colors.ENDC}")
            if len(fallback_mismatches) > 8:
                print(f"     ... and {len(fallback_mismatches) - 8} more.")
            print(f"     {Colors.YELLOW}Tip: Run 'python tools/AutoInstaller/i18n_manager.py fix-fallbacks' to repair automatically.{Colors.ENDC}")

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
            print(f"     {Colors.DIM}(Run 'python tools/AutoInstaller/i18n_manager.py clean-unused' if you wish to prune them){Colors.ENDC}")

        # 6. Overall Status
        print(f"\n{Colors.BOLD}=== Summary ==={Colors.ENDC}")
        if not has_errors:
            print(f"{Colors.GREEN}{Colors.BOLD}[PASS] ALL i18n CHECKS PASSED!{Colors.ENDC}\n")
        else:
            print(f"{Colors.RED}{Colors.BOLD}[FAIL] ISSUES DETECTED. Review suggestions above or run fix commands.{Colors.ENDC}\n")

        return not has_errors

    def print_coverage_matrix(self):
        """Display translation completeness matrix."""
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== Translation Coverage Matrix ==={Colors.ENDC}\n")
        en_dict = self.lang_data.get("en-us", {})
        total_master = len(en_dict)
        print(f"{'Locale':<12} {'Total Keys':<12} {'Coverage':<12} {'Status'}")
        print("-" * 50)
        for code, data in sorted(self.lang_data.items()):
            count = len(data)
            pct = (count / total_master * 100) if total_master else 0
            status = f"{Colors.GREEN}Complete{Colors.ENDC}" if pct >= 100 else f"{Colors.YELLOW}Incomplete ({total_master - count} missing){Colors.ENDC}"
            print(f"{code:<12} {count:<12} {pct:>5.1f}%       {status}")
        print()

    def print_hardcoded_report(self):
        """Scan and display hardcoded UI strings."""
        print(f"\n{Colors.BOLD}{Colors.CYAN}=== Hardcoded String Scanner ==={Colors.ENDC}\n")
        candidates = self.scan_hardcoded_strings()
        if not candidates:
            print(f"{Colors.GREEN}[OK] No obvious hardcoded UI strings detected!{Colors.ENDC}\n")
            return

        print(f"Found {Colors.YELLOW}{len(candidates)}{Colors.ENDC} potential hardcoded UI string(s):\n")
        for rel_path, line_no, text in candidates:
            # Suggest a key
            slug = re.sub(r'[^a-zA-Z0-9]+', '.', text.lower()).strip('.')
            if len(slug) > 25:
                slug = slug[:25].rstrip('.')
            print(f" * {rel_path}:{line_no}")
            print(f"   String:    \"{Colors.BOLD}{text}{Colors.ENDC}\"")
            print(f"   Suggested: \"ui.{slug}\"")
        print()


def main():
    parser = argparse.ArgumentParser(
        description="AutoInstaller Language Package Manager & i18n Toolkit",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tools/AutoInstaller/i18n_manager.py audit
  python tools/AutoInstaller/i18n_manager.py sort
  python tools/AutoInstaller/i18n_manager.py sync
  python tools/AutoInstaller/i18n_manager.py fix-fallbacks
  python tools/AutoInstaller/i18n_manager.py scan-hardcoded
  python tools/AutoInstaller/i18n_manager.py clean-unused
        """
    )

    parser.add_argument(
        "action",
        nargs="?",
        default="audit",
        choices=["audit", "sort", "sync", "fix-fallbacks", "clean-unused", "scan-hardcoded", "coverage", "check"],
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
    manager = I18nManager(workspace)

    if args.action == "audit":
        success = manager.print_audit_report()
        sys.exit(0 if success else 1)

    elif args.action == "check":
        success = manager.print_audit_report()
        sys.exit(0 if success else 1)

    elif args.action == "sort":
        modified = manager.sort_all_databases()
        print(f"{Colors.GREEN}[OK] Successfully sorted and formatted: {', '.join(modified)}{Colors.ENDC}")

    elif args.action == "sync":
        if manager.synchronize_keys():
            print(f"{Colors.GREEN}[OK] All language databases synchronized with en-us.json and sorted.{Colors.ENDC}")

    elif args.action == "fix-fallbacks":
        fixed = manager.fix_fallback_strings()
        print(f"{Colors.GREEN}[OK] Fixed {fixed} fallback string(s) in source code.{Colors.ENDC}")

    elif args.action == "clean-unused":
        removed = manager.clean_unused_keys()
        print(f"{Colors.GREEN}[OK] Removed {removed} unused key entries across all language databases.{Colors.ENDC}")

    elif args.action == "scan-hardcoded":
        manager.print_hardcoded_report()

    elif args.action == "coverage":
        manager.print_coverage_matrix()


if __name__ == "__main__":
    main()
