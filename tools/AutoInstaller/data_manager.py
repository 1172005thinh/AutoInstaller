#!/usr/bin/env python3
"""
=============================================================================
Data Subsystem Manager & CSV Toolkit for AutoInstaller
Location: tools/AutoInstaller/data_manager.py
Author:   1172005thinh
=============================================================================
A developer utility to:
1. Sort all CSV files in gui/assets/data/ alphabetically (A-Z) by first column.
2. Audit and lint CSV datasets for correct ordering, duplicates, and RFC-4180 format.
3. Report dataset statistics, column layouts, and row counts.
"""

import sys
import os
import csv
import argparse
from pathlib import Path
from typing import List, Tuple, Dict, Optional

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


def find_workspace_root(start_path: Optional[Path] = None) -> Path:
    """Locate the workspace root by looking for AutoInstaller.au3 or navigating up."""
    if start_path is None:
        start_path = Path(__file__).resolve().parent
    current = start_path
    for _ in range(5):
        if (current / "AutoInstaller.au3").exists() or (current / "gui").is_dir():
            return current
        if current.parent == current:
            break
        current = current.parent
    return start_path


class DataManager:
    """Manages CSV datasets in gui/assets/data/."""

    def __init__(self, workspace_root: Path):
        self.workspace = workspace_root
        self.data_dir = self.workspace / "gui" / "assets" / "data"

    def get_csv_files(self, target_file: Optional[str] = None) -> List[Path]:
        """Return list of CSV files to process."""
        if not self.data_dir.is_dir():
            return []
        if target_file:
            specific = self.data_dir / target_file
            if specific.exists():
                return [specific]
            specific_csv = self.data_dir / f"{target_file}.csv"
            if specific_csv.exists():
                return [specific_csv]
            return []
        return sorted(self.data_dir.glob("*.csv"))

    def read_csv(self, file_path: Path) -> Tuple[List[str], List[List[str]]]:
        """Read CSV file, returning (header, rows)."""
        with open(file_path, "r", encoding="utf-8", newline="") as f:
            reader = list(csv.reader(f))
        if not reader:
            return [], []
        return reader[0], reader[1:]

    def write_csv(self, file_path: Path, header: List[str], rows: List[List[str]]) -> None:
        """Write CSV file in UTF-8 without BOM, with LF newlines."""
        with open(file_path, "w", encoding="utf-8", newline="\n") as f:
            writer = csv.writer(f)
            if header:
                writer.writerow(header)
            writer.writerows(rows)

    def sort_rows(self, rows: List[List[str]]) -> List[List[str]]:
        """Sort data rows by first column (A-Z), case-insensitive with tie-breaker."""
        return sorted(rows, key=lambda row: (row[0].strip().lower(), row[0].strip()) if row else ("", ""))

    def sort_all(self, target_file: Optional[str] = None) -> List[Tuple[str, int, bool]]:
        """Sort CSV file(s) according to their first column by A-Z."""
        files = self.get_csv_files(target_file)
        results = []
        for file_path in files:
            header, rows = self.read_csv(file_path)
            sorted_rows = self.sort_rows(rows)
            changed = rows != sorted_rows
            if changed:
                self.write_csv(file_path, header, sorted_rows)
            results.append((file_path.name, len(sorted_rows), changed))
        return results

    def audit(self, target_file: Optional[str] = None) -> bool:
        """Audit CSV files for sorting order, duplicates, and integrity."""
        files = self.get_csv_files(target_file)
        if not files:
            print(f"{Colors.RED}[ERROR] No CSV files found in {self.data_dir}{Colors.ENDC}")
            return False

        print(f"\n{Colors.BOLD}{Colors.HEADER}=== AutoInstaller CSV Data Audit ==={Colors.ENDC}\n")

        all_passed = True
        total_rows = 0

        for file_path in files:
            filename = file_path.name
            header, rows = self.read_csv(file_path)
            total_rows += len(rows)

            issues = []

            # 1. Check header
            if not header or not header[0].strip():
                issues.append("Missing or empty header row")

            # 2. Check sort order
            sorted_rows = self.sort_rows(rows)
            if rows != sorted_rows:
                # Find first out-of-order element
                for i in range(len(rows)):
                    if rows[i] != sorted_rows[i]:
                        issues.append(f"Not sorted A-Z at row {i + 2} (Found: '{rows[i][0]}', Expected: '{sorted_rows[i][0]}')")
                        break

            # 3. Check duplicate keys in column 0
            seen_keys: Dict[str, int] = {}
            duplicates = []
            for idx, r in enumerate(rows):
                if not r:
                    continue
                k = r[0].strip().lower()
                if k in seen_keys:
                    duplicates.append((r[0].strip(), seen_keys[k] + 2, idx + 2))
                else:
                    seen_keys[k] = idx

            if duplicates:
                dup_str = ", ".join(f"'{k}' (rows {r1}, {r2})" for k, r1, r2 in duplicates[:3])
                if len(duplicates) > 3:
                    dup_str += f" (+{len(duplicates) - 3} more)"
                issues.append(f"Duplicate first-column values: {dup_str}")

            # 4. Check column count consistency
            if header:
                expected_cols = len(header)
                mismatched = [idx + 2 for idx, r in enumerate(rows) if len(r) != expected_cols]
                if mismatched:
                    issues.append(f"Column count mismatch at rows: {mismatched[:5]}")

            if not issues:
                first_col = header[0] if header else "Col 0"
                print(f"  {Colors.GREEN}[PASS]{Colors.ENDC} {filename:<18} ({len(rows):>2} rows) - Sorted A-Z by '{first_col}'")
            else:
                all_passed = False
                print(f"  {Colors.RED}[FAIL]{Colors.ENDC} {filename:<18} ({len(rows):>2} rows)")
                for issue in issues:
                    print(f"         * {Colors.YELLOW}{issue}{Colors.ENDC}")

        print(f"\n{Colors.BOLD}Audit Summary:{Colors.ENDC}")
        print(f"  * Datasets inspected: {len(files)}")
        print(f"  * Total records:      {total_rows}")

        if all_passed:
            print(f"\n{Colors.GREEN}{Colors.BOLD}[PASS] ALL CSV AUDIT CHECKS PASSED!{Colors.ENDC}\n")
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}[FAIL] ISSUES DETECTED. Run 'data_manager.py sort' to fix ordering.{Colors.ENDC}\n")

        return all_passed

    def print_stats(self, target_file: Optional[str] = None) -> None:
        """Display summary table of all CSV datasets."""
        files = self.get_csv_files(target_file)
        if not files:
            print(f"{Colors.RED}[ERROR] No CSV files found in {self.data_dir}{Colors.ENDC}")
            return

        print(f"\n{Colors.BOLD}{Colors.HEADER}=== AutoInstaller CSV Datasets Overview ==={Colors.ENDC}\n")
        print(f"  {'Filename':<18} {'Rows':<6} {'Columns':<26} {'Primary Key / Col 0':<28}")
        print("  " + "-" * 78)

        total_rows = 0
        for file_path in files:
            header, rows = self.read_csv(file_path)
            total_rows += len(rows)
            cols_str = ", ".join(header) if header else "(empty)"
            first_col = header[0] if header else "(none)"
            print(f"  {file_path.name:<18} {len(rows):<6} {cols_str:<26} {first_col:<28}")

        print("  " + "-" * 78)
        print(f"  Total: {len(files)} datasets, {total_rows} total rows.\n")


def main():
    parser = argparse.ArgumentParser(
        description="AutoInstaller Data Subsystem & CSV Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tools/AutoInstaller/data_manager.py sort
  python tools/AutoInstaller/data_manager.py audit
  python tools/AutoInstaller/data_manager.py stats
  python tools/AutoInstaller/data_manager.py sort --file locales
        """
    )

    parser.add_argument(
        "action",
        nargs="?",
        default="audit",
        choices=["audit", "sort", "check", "stats", "info"],
        help="Action to perform (default: audit)"
    )
    parser.add_argument(
        "--file",
        type=str,
        default=None,
        help="Specific CSV file name to process (e.g. locales, editions)"
    )
    parser.add_argument(
        "--workspace",
        type=Path,
        default=None,
        help="Path to workspace root (defaults to auto-detected root)"
    )

    args = parser.parse_args()
    workspace = find_workspace_root(args.workspace)
    manager = DataManager(workspace)

    if args.action in ("audit", "check"):
        success = manager.audit(args.file)
        sys.exit(0 if success else 1)

    elif args.action == "sort":
        results = manager.sort_all(args.file)
        modified = [name for name, _, changed in results if changed]
        print(f"\n{Colors.BOLD}{Colors.HEADER}=== AutoInstaller CSV Sorting ==={Colors.ENDC}\n")
        for name, count, changed in results:
            status = f"{Colors.GREEN}[SORTED]{Colors.ENDC}" if changed else f"{Colors.DIM}[ALREADY SORTED]{Colors.ENDC}"
            print(f"  {status} {name:<18} ({count} rows)")
        print(f"\n{Colors.GREEN}[OK] Processed {len(results)} CSV dataset(s). Modified: {len(modified)}{Colors.ENDC}\n")

    elif args.action in ("stats", "info"):
        manager.print_stats(args.file)


if __name__ == "__main__":
    main()
