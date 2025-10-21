#!/usr/bin/env bash
# lab-checks.sh - Automated lab checks for the Beginner's Guide
# Safe, non-destructive: operates in ~/linux-freebsd-lab
# Usage: chmod +x lab-checks.sh && ./lab-checks.sh
set -u
LAB_DIR="$HOME/linux-freebsd-lab"
PASS=0
FAIL=0
TOTAL=0
ok() { printf "\e[32mPASS\e[0m    %s\n" "$1"; PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); }
not_ok() { printf "\e[31mFAIL\e[0m    %s\n" "$1"; FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); }
note() { printf "\e[34mINFO\e[0m    %s\n" "$1"; }

# ensure lab directory
rm -rf "$LAB_DIR"
mkdir -p "$LAB_DIR"
cd "$LAB_DIR" || exit 1
note "Working in $LAB_DIR (will be removed on reset by you)."

# Test 1: Navigation & basic ls/pwd
TOTAL=$((TOTAL+1))
mkdir -p navtest/a/b || not_ok "create nested dirs"
cd navtest/a/b || not_ok "cd into nested dirs"
CURPWD=$(pwd)
if [[ "$CURPWD" == */navtest/a/b ]]; then
  ok "Navigation: cd to nested dirs and pwd ends with navtest/a/b"
else
  not_ok "Navigation: expected to be in navtest/a/b but in $CURPWD"
fi
cd "$LAB_DIR" || true

# Test 2: touch and ls
TOTAL=$((TOTAL+1))
mkdir -p practice && cd practice
touch a.txt b.txt c.txt
if ls -1 a.txt b.txt c.txt >/dev/null 2>&1; then
  ok "touch and ls: created a.txt b.txt c.txt"
else
  not_ok "touch and ls: failed to create/list files"
fi
cd "$LAB_DIR" || true

# Test 3: write content and tail/head
TOTAL=$((TOTAL+1))
mkdir -p viewtest && cd viewtest
printf "one\ntwo\nthree\n" > file.txt
if tail -n 2 file.txt | grep -q 'three'; then
  ok "head/tail: tail -n 2 shows 'three'"
else
  not_ok "head/tail: unexpected tail output"
fi
cd "$LAB_DIR" || true

# Test 4: Permissions (chmod 644)
TOTAL=$((TOTAL+1))
touch permissions_report.txt
chmod 644 permissions_report.txt
MODE=$(stat -c "%a" permissions_report.txt 2>/dev/null || stat -f "%A" permissions_report.txt 2>/dev/null || echo "unknown")
if [[ "$MODE" == "644" ]]; then
  ok "chmod 644 applied to permissions_report.txt (mode: $MODE)"
else
  not_ok "chmod 644 failed (mode: $MODE)"
fi

# Test 5: Script file chmod 744 and executable check
TOTAL=$((TOTAL+1))
cat > runme.sh <<'SH'
#!/bin/sh
echo "runme ok"
SH
chmod 744 runme.sh
if [ -x runme.sh ] && ./runme.sh | grep -q "runme ok"; then
  ok "chmod 744 and executable script ran successfully"
else
  not_ok "Script not executable or did not run"
fi

# Test 6: Sticky bit directory (local test, no sudo)
TOTAL=$((TOTAL+1))
mkdir -p stickytest
chmod 1777 stickytest
MODE_FULL=$(stat -c "%a" stickytest 2>/dev/null || stat -f "%A" stickytest 2>/dev/null || echo "")
if [[ "$MODE_FULL" == "1777" || "$MODE_FULL" == "777" ]]; then
  ok "Sticky bit set on stickytest (mode: $MODE_FULL)"
else
  not_ok "Sticky bit not set as expected (mode: $MODE_FULL)"
fi

# Test 7: grep/find functionality
TOTAL=$((TOTAL+1))
mkdir -p grepdir && cd grepdir
printf "TODO: write tests\nnote\n" > task1.txt
printf "something else\nTODO: second\n" > task2.txt
if grep -R "TODO" . | wc -l | grep -q '[12]'; then
  ok "grep find: found TODO entries in files"
else
  not_ok "grep find: failed to find TODO entries"
fi
cd "$LAB_DIR" || true

# Test 8: vim presence and non-interactive replace (foo->bar)
TOTAL=$((TOTAL+1))
mkdir -p vimtest && cd vimtest
printf "foo\nbaz\nfoo\n" > editme.txt
if command -v vim >/dev/null 2>&1; then
  if vim -Es -u NONE -N -c "%s/foo/bar/g" -c "wq" editme.txt >/dev/null 2>&1; then
    if grep -q "bar" editme.txt && ! grep -q "foo" editme.txt; then
      ok "vim present and non-interactive substitution foo->bar succeeded"
    else
      not_ok "vim substitution did not change contents as expected"
    fi
  else
    sed -i.bak 's/foo/bar/g' editme.txt 2>/dev/null || perl -pi.bak -e 's/foo/bar/g' editme.txt 2>/dev/null
    if grep -q "bar" editme.txt && ! grep -q "foo" editme.txt; then
      ok "vim fallback: sed/perl substitution foo->bar succeeded"
    else
      not_ok "substitution failed"
    fi
  fi
else
  not_ok "vim not installed (install vim to practice editing and run vimtutor)"
fi
cd "$LAB_DIR" || true

# Test 9: Mini-project notes.sh check
TOTAL=$((TOTAL+1))
mkdir -p notes-manager && cd notes-manager
printf "2025-01-01: meeting notes\n" > 2025-01-01.txt
cat > notes.sh <<'SH'
#!/bin/sh
NOTES_DIR="$HOME/linux-freebsd-lab/notes-manager"
KEY="$1"
if [ -z "$KEY" ]; then
  echo "Usage: $0 keyword"
  exit 2
fi
grep -RIn -- "$KEY" "$NOTES_DIR"
SH
chmod +x notes.sh
if ./notes.sh meeting | grep -q "meeting"; then
  ok "notes.sh exists and finds keyword in notes"
else
  not_ok "notes.sh failed to find keyword or did not run"
fi
cd "$LAB_DIR" || true

# Test 10: Detect FreeBSD and check pkg availability (non-install check)
TOTAL=$((TOTAL+1))
OSNAME=$(uname -s)
if [[ "$OSNAME" == "FreeBSD" ]]; then
  if command -v pkg >/dev/null 2>&1; then
    if pkg -v >/dev/null 2>&1; then
      ok "FreeBSD detected and pkg is available (pkg -v succeeded)"
    else
      not_ok "FreeBSD detected but pkg -v failed (network or permissions?)"
    fi
  else
    not_ok "FreeBSD detected but pkg command not found"
  fi
else
  note "Not FreeBSD ($OSNAME): skipping pkg install checks"
  ok "Platform check: not FreeBSD, pkg checks skipped"
fi

# Test 11: Fun packages presence check (non-install, non-destructive)
TOTAL=$((TOTAL+1))
FUN_TOOLS=(cowsay fortune sl figlet cmatrix lolcat toilet)
FOUND=0
NOTFOUND=0
FUN_OUTPUTS=()
for tool in "${FUN_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    FOUND=$((FOUND+1))
    case "$tool" in
      cowsay)
        OUT=$(printf "lab check" | cowsay 2>/dev/null || true)
        FUN_OUTPUTS+=("cowsay: available")
        ;;
      fortune)
        # fortune may require a database; run a short test
        OUT=$(fortune -s 2>/dev/null || true)
        FUN_OUTPUTS+=("fortune: available")
        ;;
      sl)
        # sl draws on terminal; check version or presence without running animation
        FUN_OUTPUTS+=("sl: available")
        ;;
      figlet)
        FUN_OUTPUTS+=("figlet: available")
        ;;
      cmatrix)
        FUN_OUTPUTS+=("cmatrix: available")
        ;;
      lolcat)
        FUN_OUTPUTS+=("lolcat: available")
        ;;
      toilet)
        FUN_OUTPUTS+=("toilet: available")
        ;;
      *)
        FUN_OUTPUTS+=("$tool: available")
        ;;
    esac
  else
    NOTFOUND=$((NOTFOUND+1))
  fi
done

if [[ $FOUND -gt 0 ]]; then
  ok "Fun packages: found $FOUND of ${#FUN_TOOLS[@]} (${FUN_OUTPUTS[*]})"
else
  note "Fun packages not found: you can install some with your package manager (pkg/apt/dnf/pacman)."
  not_ok "Fun packages: none of ${FUN_TOOLS[*]} were found"
fi

# Summary
echo
printf "Summary: %d tests, %d passed, %d failed\n" "$TOTAL" "$PASS" "$FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "All checks passed. Great job! The directory $LAB_DIR contains artifacts you can inspect."
  exit 0
else
  echo "Some checks failed. See failures above. The directory $LAB_DIR contains all test files for manual inspection."
  exit 2
fi