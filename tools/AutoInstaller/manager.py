#!/usr/bin/env python3
"""
=============================================================================
Unified Audit Suite & Tooling Orchestrator for AutoInstaller
Location: tools/AutoInstaller/manager.py
Author:   1172005thinh
=============================================================================
A developer utility to:
1. Discover and orchestrate all sub-manager tools (*_manager.py) in tools/AutoInstaller/.
2. Run audit and lint checks across data, i18n, and theme packages in a single run.
3. Dispatch maintenance tasks (e.g., sort, sync, coverage) across supporting sub-managers.
4. Provide a consolidated status dashboard and aggregated return code.
"""

import sys
import os
import time
import argparse
import subprocess
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


MANAGER_SUPPORTED_ACTIONS: Dict[str, set] = {
    "data_manager.py": {"audit", "check", "sort", "stats", "info"},
    "i18n_manager.py": {"audit", "check", "sort", "sync", "coverage", "clean-unused", "scan-hardcoded", "fix-fallbacks"},
    "theme_manager.py": {"audit", "check", "sort", "sync", "coverage", "clean-unused", "scan-hardcoded"},
}


class Orchestrator:
    """Discovers and executes sub-managers in tools/AutoInstaller/."""

    def __init__(self, workspace_root: Path):
        self.workspace_root = workspace_root
        self.tools_dir = self.workspace_root / "tools" / "AutoInstaller"

    def discover_managers(self) -> List[Path]:
        """Find all *_manager.py scripts in tools/AutoInstaller excluding self."""
        if not self.tools_dir.is_dir():
            return []

        managers = []
        for file in sorted(self.tools_dir.glob("*_manager.py")):
            if file.name != "manager.py" and not file.name.startswith("test_"):
                managers.append(file)
        return managers

    def run_submanager(self, script_path: Path, action: str) -> Tuple[int, float]:
        """Execute a sub-manager script with the specified action and stream its output."""
        cmd = [sys.executable, str(script_path), action]

        env = os.environ.copy()
        env["PYTHONUNBUFFERED"] = "1"

        sys.stdout.flush()
        sys.stderr.flush()

        start_time = time.perf_counter()

        proc = subprocess.Popen(
            cmd,
            cwd=str(self.workspace_root),
            stdout=sys.stdout,
            stderr=sys.stderr,
            env=env
        )
        proc.communicate()
        sys.stdout.flush()
        sys.stderr.flush()
        elapsed = time.perf_counter() - start_time

        return proc.returncode, elapsed

    def execute_all(self, action: str) -> bool:
        """Run all discovered sub-managers with the given action and print summary."""
        managers = self.discover_managers()
        if not managers:
            print(f"{Colors.RED}[ERROR] No sub-managers found in {self.tools_dir}{Colors.ENDC}")
            return False

        print(f"\n{Colors.BOLD}{Colors.HEADER}==============================================================================={Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.HEADER}   AutoInstaller Unified Orchestrator: Dispatching '{action}'{Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.HEADER}==============================================================================={Colors.ENDC}\n")
        print(f"Target sub-managers ({len(managers)}): {', '.join(m.name for m in managers)}\n")
        sys.stdout.flush()

        results: List[Tuple[str, str, int, float, bool]] = []
        overall_start = time.perf_counter()

        for idx, mgr in enumerate(managers, 1):
            print(f"{Colors.BOLD}{Colors.CYAN}--- [{idx}/{len(managers)}] {mgr.name} ({action}) ---{Colors.ENDC}\n")
            sys.stdout.flush()

            supported = MANAGER_SUPPORTED_ACTIONS.get(mgr.name)
            if supported is not None and action not in supported:
                print(f"{Colors.DIM}[SKIPPED] {mgr.name} does not support action '{action}'.{Colors.ENDC}\n")
                sys.stdout.flush()
                results.append((mgr.name, action, 0, 0.0, True))
                continue

            exit_code, elapsed = self.run_submanager(mgr, action)
            results.append((mgr.name, action, exit_code, elapsed, False))
            print()
            sys.stdout.flush()

        total_elapsed = time.perf_counter() - overall_start

        # Consolidated Summary Dashboard
        print(f"{Colors.BOLD}{Colors.HEADER}==============================================================================={Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.HEADER}   AutoInstaller Suite Summary Dashboard: '{action}'{Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.HEADER}==============================================================================={Colors.ENDC}\n")
        print(f"  {'Sub-Manager':<24} {'Action':<12} {'Status':<14} {'Duration':<10}")
        print("  " + "-" * 62)

        all_passed = True
        for name, act, code, elapsed, skipped in results:
            if skipped:
                status_str = f"{Colors.DIM}[SKIPPED]{Colors.ENDC}"
            elif code == 0:
                status_str = f"{Colors.GREEN}[PASS]{Colors.ENDC}"
            else:
                status_str = f"{Colors.RED}[FAIL (exit {code})]{Colors.ENDC}"
                all_passed = False

            duration_str = f"{elapsed:.2f}s" if not skipped else "-"
            print(f"  {name:<24} {act:<12} {status_str:<23} {duration_str:<10}")

        print("  " + "-" * 62)

        if all_passed:
            executed = [r for r in results if not r[4]]
            print(f"\n{Colors.GREEN}{Colors.BOLD}[OK] All {len(executed)} active manager(s) completed successfully in {total_elapsed:.2f}s.{Colors.ENDC}\n")
        else:
            failed_count = sum(1 for _, _, c, _, s in results if c != 0 and not s)
            print(f"\n{Colors.RED}{Colors.BOLD}[FAIL] {failed_count} of {len(results)} manager(s) reported issues in {total_elapsed:.2f}s.{Colors.ENDC}\n")

        return all_passed


def main():
    parser = argparse.ArgumentParser(
        description="AutoInstaller Unified Audit Suite & Tooling Orchestrator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tools/AutoInstaller/manager.py audit
  python tools/AutoInstaller/manager.py sort
  python tools/AutoInstaller/manager.py sync
  python tools/AutoInstaller/manager.py coverage
        """
    )

    parser.add_argument(
        "action",
        nargs="?",
        default="audit",
        choices=["audit", "check", "sort", "sync", "coverage", "stats"],
        help="Action to dispatch to all sub-managers (default: audit)"
    )
    parser.add_argument(
        "--workspace",
        type=Path,
        default=None,
        help="Path to workspace root (defaults to auto-detected root)"
    )

    args = parser.parse_args()
    workspace = find_workspace_root(args.workspace)
    orchestrator = Orchestrator(workspace)

    success = orchestrator.execute_all(args.action)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
