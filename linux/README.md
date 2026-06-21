# Prerequisites (must be true BEFORE running this script)

Provisioning is driven by the unified, cross-platform entry point at the repo
root: **`~/dotfiles/setup.sh`**. It detects the distro and dispatches to
`setup/os/linux.sh` (shared helpers in `setup/lib/common.sh`; package lists in
`setup/packages/*.txt`). The old `~/dotfiles/linux/setup.sh` path still works —
it's a shim that execs the root script.

---

## Arch:

A working install booted, with a non-root user that has sudo privileges

Working internet connection

1.  Switch to the root account (use the root password set in archinstall)

```bash
su -
```

2.  Install the packages needed to run this script

```
pacman -Sy --needed sudo git
```

3.  Add existing user to the wheel group

```bash
 usermod -aG wheel <user>
```

4.  Allow members of the wheel group to use sudo.

```bash
   #    Uncomment the line:  %wheel ALL=(ALL:ALL) ALL
   EDITOR=nano visudo
```

5.  Drop back to user, clone the dotfiles, run the script.

```bash
   exit
   su - <user>             #
   git clone https://github.com/<github-user>/dotfiles.git
   ~/dotfiles/setup.sh
```

## Debian Trixie:

A working install booted, with a non-root user that has sudo privileges

Working internet connection

1.  Switch to the root account

```bash
su -
```

2.  Install the packages needed to run this script

```
apt update -y && apt install -y sudo git
```

3.  Add existing user to the sudo group

```bash
 usermod -aG sudo <user>
```

4.  Drop back to user, clone the dotfiles, run the script.

````bash
   exit
   su - <user>             #
   git clone https://github.com/<github-user>/dotfiles.git
   ~/dotfiles/setup.sh

## Fedora 44:

A working install booted, with a non-root user account; sudo is

Working internet connection

These packages installed via dnf: git

```bash
sudo dnf update -y && sudo dns install git -y
git clone https://github.com/<github-user>/dotfiles
~/dotfiles/setup.sh
````

# - Run as the target user (NOT root); the script will sudo when needed

# macOS: a fresh user account; Xcode CLI tools + Homebrew will be installed.

# ============================================================================
