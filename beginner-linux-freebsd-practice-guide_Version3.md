# Beginner's Hands-On Guide: Linux Navigation, Permissions, vim, Essential Commands, and FreeBSD Package Installation

Welcome! This guide is designed for absolute beginners who want hands‑on practice on the command line. It explains concepts, shows practical commands, and includes short exercises with automated checks you can run locally (see the lab script `lab-checks.sh`).

Contents
- Quick setup & safety notes
- Navigate the Linux file system
- Master user permissions
- Conquer vi / vim editor
- Essential commands (touch, ls, and more!)
- Package installation in FreeBSD (and fun packages)
- Practice plan & mini-project
- Printable 1‑page cheat sheet (ready to print)
- Step‑by‑step lab with automated checks (lab-checks.sh)
- Quick cheat sheet & further resources

---

1) Quick setup & safety notes
- Use your provided lab environment or you can use your own VM
- Work as a normal user; use sudo only when required.
- Read commands before Enter. Avoid destructive samples.
- If on macOS, many commands are similar but package management differs.

---

2) Navigate the Linux File System
Goal: find where you are, list files, move around, and understand common directories.

Key concepts
- Root: `/`
- Common dirs: `/home`, `/etc`, `/var`, `/usr`, `/bin`, `/sbin`, `/dev`, `/proc`
- Absolute vs relative paths: `/home/alice` vs `../otherdir`

Essential commands
- pwd
- ls, ls -l, ls -la, ls -lh, ls -lt
- cd, cd -, cd ~
- tree (installable)
- find . -name 'pattern'
- locate (fast database-based search)

Examples
```sh
pwd
ls -la ~
cd /var/log && ls -lt | head
find /etc -name '*.conf' -type f | head
```

Practice
- Show current dir and list hidden files: `pwd && ls -la ~`
- Find `.conf` under `/etc` and view first 10 lines: `find /etc -name '*.conf' -type f | head -n1 | xargs -r head -n 10`
- Get to `/var/log` using `cd` and list newest files: `cd /var/log && ls -lt | head`

Tips: Use tab completion, `pushd`/`popd`, `cd -`.

---

3) Master User Permissions
Goal: read and set file permissions safely.

Basics
- `ls -l` shows mode: e.g. `-rw-r--r--`
- r=4, w=2, x=1. Numeric mode: 644, 755, etc.

Commands
- chmod 644 file.txt
- chmod 755 script.sh
- chmod 1777 /tmp/myshare (sticky bit)
- chown user:group file
- umask (default permission mask)

Examples
```sh
touch report.txt && chmod 644 report.txt
touch runme.sh && chmod 744 runme.sh
mkdir -p ~/mytmp && chmod 1777 ~/mytmp
```

Practice
- Create `report.txt` and set permissions to 644.
- Create `runme.sh`, make executable for owner only plus readable by others (744).
- Create a shared dir with sticky bit (1777) — try in a test directory if you can't modify `/tmp`.

Safety: avoid `chmod 777` except for controlled experiments.

---

4) Conquer vi / vim Editor
Goal: edit, save, navigate files in vim.

Modes
- Normal (commands), Insert (type), Visual (select), Command-line (colon commands).

Essential keys
- Start: `vim file`
- Insert: `i` / `a` / `o` → Esc to return
- Save/quit: `:w`, `:q`, `:wq`, `:q!`
- Navigation: `h j k l`, `w`, `b`, `gg`, `G`, `0`, `$`
- Edit: `x`, `dd`, `yy`, `p`, `u`, `Ctrl+r`
- Search/replace: `/pattern`, `:%s/old/new/g`

Practice
- `vim notes.txt`, press `i`, add 3 lines, Esc, `:wq`.
- Replace `foo` with `bar`: `:%s/foo/bar/g`
- Yank lines 5–7 and put after line 10: `:5,7y` then `:10put`

Tip: run `vimtutor`.

---

5) Essential Commands (compact toolbox)
- touch, mkdir -p, cp, mv, rm (-i), ln -s
- cat, less, head, tail -f
- stat, file
- grep, find, locate, sort, uniq, wc, cut
- history, alias, man

Examples
```sh
mkdir -p practice && cd practice
touch a.txt b.txt c.txt
printf "line1\nline2\nline3\n" > file.txt
tail -n 2 file.txt
grep -R "TODO" .
```

Practice tasks in guide above.

---

6) Package Installation in FreeBSD (and fun packages)
Goal: use pkg and Ports; discover small "fun" packages you can install for practice and to make the shell more entertaining.

pkg (binary packages)
```sh
sudo pkg update
sudo pkg install vim
pkg search nginx
pkg info -x vim
sudo pkg upgrade
```
Ports (build from source)
```sh
sudo portsnap fetch extract    # first time
cd /usr/ports/sysutils/htop && sudo make install clean
```
Services: `sudo service nginx start` and enable with `nginx_enable="YES"` in `/etc/rc.conf`.

Fun packages to try
- sl — Steam locomotive animation when you type `sl` (common joke for typing `ls`)
- cowsay — ASCII talking cow that prints messages
- fortune or fortune-mod — prints random quotes/jokes; often used with cowsay
- figlet — big ASCII art text
- toilet — colorful ASCII text output with filters
- cmatrix — Matrix-style terminal rain animation
- lolcat — colorize text output (often a Ruby gem or package)

Install fun packages on FreeBSD (example)
```sh
sudo pkg update
sudo pkg install sl cowsay fortune-mod figlet toilet cmatrix
# Note: package names can vary; use pkg search to find exact names
pkg search cowsay
pkg search fortune
```

Install fun packages on Debian/Ubuntu:
```sh
sudo apt update
sudo apt install sl cowsay fortune figlet toilet cmatrix lolcat
```

On Fedora:
```sh
sudo dnf install sl cowsay fortune-mod figlet toilet cmatrix
```

On Arch:
```sh
sudo pacman -S sl cowsay fortune-mod figlet toilet cmatrix lolcat
```

Example usage
```sh
fortune | cowsay
figlet Hello | lolcat
sl
cmatrix
```

Notes
- Package names can vary across OSes; use your package manager's search command (pkg search, apt search, dnf search, pacman -Ss).
- These are safe, user-space programs for fun and testing your package manager skills.
- If you are on a system without sudo or network access, you can still practice by searching package metadata (pkg search) or reading man pages of available packages.

---

7) Practice plan & mini-project
Progressive checklist (no time estimates)
- Filesystem navigation + essential commands (practice tasks)
- Permissions deep dive + exercises
- vim basics + vimtutor + exercises
- FreeBSD pkg basics on a FreeBSD VM
- Mini-project: notes manager (create notes, search, script)

Mini-project: notes manager
- Create `~/notes-manager`
- Create daily notes `YYYY-MM-DD.txt` with `vim`
- Create `notes.sh` to search notes for a keyword (script provided below)
- Make `notes.sh` executable and test

Starter script (notes.sh)
```sh
#!/bin/sh
NOTES_DIR="$HOME/notes-manager"
KEY="$1"
if [ -z "$KEY" ]; then
  echo "Usage: $0 keyword"
  exit 1
fi
grep -RIn -- "$KEY" "$NOTES_DIR"
```

---

8) Printable 1‑Page Cheat Sheet (ready to print)
This is designed to fit on one page. Print from this section.

Title: Command Line One‑Page Cheat Sheet

Navigation
- pwd — show current dir
- cd /path, cd .., cd -, cd ~
- ls -la, ls -lh, ls -lt

Files & dirs
- touch file.txt
- mkdir -p a/b/c
- cp src dest | cp -r dir1 dir2
- mv old new
- rm file | rm -r dir
- ln -s target linkname

View & inspect
- cat file
- less file (q to quit)
- head -n 10 file
- tail -n 20 file | tail -f file
- stat file
- file filename

Search & text
- grep -R "pattern" .
- find . -name '*.conf'
- locate name (run updatedb first)
- sort filename | uniq -c | sort -nr
- wc -l file

Permissions & ownership
- ls -l
- chmod 755 script.sh  (rwxr-xr-x)
- chmod 644 file.txt   (rw-r--r--)
- chown user:group file
- umask 022

vim basics
- vim file
- i (insert), Esc, :w, :q, :wq, :q!
- dd (delete line), yy (yank), p (paste)
- /pattern (search), :%s/old/new/g (replace)

FreeBSD pkg basics & fun packages
- sudo pkg update
- sudo pkg install <pkg>     # e.g., vim, cowsay, sl, fortune-mod
- pkg search <name>
- pkg info <pkg>

Helpful commands
- man <cmd>
- command --help
- alias ll='ls -la'

Quick chmod numeric map
- 7 = rwx, 6 = rw-, 5 = r-x, 4 = r--  (e.g., 755, 644)

---

9) Step‑by‑step lab with automated checks
I prepared a safe, self-contained bash script you can run to verify tasks from this guide. It:
- creates a lab folder under your home (~/linux-freebsd-lab) and runs tests there
- checks navigation, essential commands, permissions, simple vim usage (non-interactive checks), grep/find, and FreeBSD pkg presence (if on FreeBSD)
- checks for "fun" packages (cowsay, fortune, sl, figlet, cmatrix) and runs harmless checks if they exist (it does not install anything)
- does not install or remove system packages or require sudo (all operations are in the lab folder). If you want the FreeBSD pkg test to attempt a package install, you must run the script with sudo and accept network installs (the script does not do that by default).

Usage
1. Save the script `lab-checks.sh` (provided in this package).
   you can downlod the script using the following link 
  curl -L -o lab-checks_Version2.sh "https://raw.githubusercontent.com/manhal-mhd/netops1/5b825545250c7415ef174cb272289a150f4494d2/lab-checks_Version2.sh" 
  if you dont have curl , download it *_-
2. Make it executable:
   chmod +x lab-checks.sh
3. Run it:
   ./lab-checks.sh
4. The script prints PASS/FAIL for each test and a final summary. It returns exit status 0 if all checks pass, >0 otherwise.

---

10) Quick reference & further resources
- man pages: man ls, man chmod, man vim, man pkg
- vimtutor: run `vimtutor`
- FreeBSD Handbook: https://www.freebsd.org/doc/handbook/
- The Linux Documentation Project and many distro wikis

---

Files included with this guide
- lab-checks.sh — automated checks (save and run)
- notes.sh — sample notes manager script (shown earlier)

Have fun practicing — repeat short exercises regularly to build muscle memory.
