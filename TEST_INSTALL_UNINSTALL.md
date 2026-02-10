# Testing Install and Uninstall

## Prerequisites

- In the repo directory with `PKGBUILD`, `huion-tablet.install`, and the `.deb` file
- Run build/install/uninstall commands as needed (use `sudo` for `pacman -U` and `pacman -R`)

---

## 1. Check that **install** works

### Step 1: Build the package

```bash
cd /home/bobo/git_remote/huion-h610pro-v2-arch
makepkg -s
```

- Should finish without errors and create something like `huion-tablet-15.0.0.175-1-x86_64.pkg.tar.zst`.

### Step 2: Install it

```bash
sudo pacman -U huion-tablet-15.0.0.175-1-x86_64.pkg.tar.zst
```

- You should see the messages from `post_install()` (e.g. “Huion Tablet Driver installed successfully”, udev, xdotool, etc.).

### Step 3: Verify installed files

Run these and confirm paths exist and look right:

```bash
# Main app
ls -la /usr/lib/huiontablet/
ls -la /usr/lib/huiontablet/huiontablet
ls -la /usr/lib/huiontablet/huionCore
ls -la /usr/lib/huiontablet/huiontablet.sh

# Desktop / autostart
ls -la /usr/share/applications/huiontablet.desktop
ls -la /etc/xdg/autostart/huiontablet.desktop
ls -la /usr/share/icons/huiontablet.png

# Udev rules
ls -la /usr/lib/udev/rules.d/20-huion.rules

# Pacman knows about the package
pacman -Q huion-tablet
pacman -Ql huion-tablet
```

### Step 4: Verify install script actions

- **Udev:** rules should be present and udev reloaded (no error when you ran install).
- **xdotool:** if you didn’t have `xdotool` before, one of these should exist and be executable:
  - `which xdotool` → e.g. `/usr/local/bin/xdotool` or `/bin/xdotool`
  - or `ls -la /usr/local/bin/xdotool` / `ls -la /bin/xdotool`
- **Bluetooth (optional):** if you have `/etc/bluetooth/input.conf`, check:
  - `grep -i UserspaceHID /etc/bluetooth/input.conf` (script may have set `UserspaceHID=true`).

### Step 5: Run the driver (functional test)

```bash
/usr/lib/huiontablet/huiontablet.sh
```

- A Huion settings window should appear (with or without the tablet plugged in).
- Close it when done.

If all of the above pass, **install** is working.

---

## 2. Check that **uninstall** works

### Step 1: (Optional) Simulate runtime files

So that uninstall has something to clean up:

```bash
# Create fake PID/log files as if the driver had been run
touch ~/.HuionCore.pid ~/.DriverUI.pid ~/.huion.log
ls -la ~/.HuionCore.pid ~/.DriverUI.pid ~/.huion.log
```

### Step 2: Uninstall the package

```bash
sudo pacman -R huion-tablet
```

- You should see messages from `pre_remove()` and `post_remove()` (e.g. “Stopping Huion driver…”, “Cleaning up…”, “Uninstall cleanup completed.”).

### Step 3: Verify package and files are gone

```bash
# Package not installed
pacman -Q huion-tablet
# Should output: "package 'huion-tablet' was not found"

# Main app dir removed
ls /usr/lib/huiontablet/
# Should output: "No such file or directory"

# Udev rule removed
ls /usr/lib/udev/rules.d/20-huion.rules
# Should output: "No such file or directory"

# Desktop entries gone
ls /usr/share/applications/huiontablet.desktop
ls /etc/xdg/autostart/huiontablet.desktop
# Should output: "No such file or directory"
```

### Step 4: Verify user cleanup (post_remove)

If you created the fake files in Step 1:

```bash
ls -la ~/.HuionCore.pid ~/.DriverUI.pid ~/.huion.log
# All three should be gone (No such file or directory)
```

### Step 5: Verify udev state

```bash
# Rules reloaded (no huion rule left)
ls /usr/lib/udev/rules.d/ | grep -i huion
# Should print nothing
```

If all of the above pass, **uninstall** is working.

---

## Quick one-liner checks

**After install:**

```bash
pacman -Q huion-tablet && ls /usr/lib/huiontablet/huiontablet.sh /usr/lib/udev/rules.d/20-huion.rules
```

**After uninstall:**

```bash
! pacman -Q huion-tablet 2>/dev/null && ! ls /usr/lib/huiontablet/ 2>/dev/null && echo "Uninstall OK"
```

---

## If something fails

- **Install:** Check `makepkg` output and `sudo pacman -U ...` output for errors; ensure the `.deb` and `PKGBUILD`/install file are in the same directory.
- **Uninstall:** If files remain, run the cleanup parts of `post_remove()` manually (remove `/usr/lib/huiontablet/`, udev rule, and `~/.HuionCore.pid`, `~/.DriverUI.pid`, `~/.huion.log`), then `sudo udevadm control --reload-rules`.

Using this flow you can confirm both “does install work?” and “does uninstall work?”.
