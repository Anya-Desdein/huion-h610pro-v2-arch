# Porting Guide: Debian Package to Arch Linux PKGBUILD

## Overview

This guide explains how the Huion Tablet driver was ported from a Debian `.deb` package to an Arch Linux `PKGBUILD` package, specifically optimized for i3 window manager.

## File Structure

### Created Files

1. **`PKGBUILD`** - The main package build script
2. **`huion-tablet.install`** - Installation hooks (replaces Debian's preinst/postinst/prerm/postrm)

## Detailed Explanation

### 1. PKGBUILD File

#### Package Metadata
```bash
pkgname=huion-tablet          # Package name (lowercase, hyphenated)
pkgver=15.0.0.175             # Version from Debian control file
pkgrel=1                      # Package release (increment for rebuilds)
pkgdesc="..."                 # Description
arch=('x86_64')               # Architecture (was 'amd64' in Debian)
```

**Key Differences:**
- Debian uses `Package:` → Arch uses `pkgname=`
- Debian uses `Version:` → Arch uses `pkgver=` + `pkgrel=`
- Debian uses `Architecture: amd64` → Arch uses `arch=('x86_64')`

#### Dependencies
```bash
depends=('qt5-base' 'qt5-declarative' ...)
```

**Why these dependencies?**
- The driver is a Qt5 application (QML-based)
- Requires X11 libraries (libx11, libxext, etc.)
- These are runtime dependencies needed for the driver to work

#### Source Extraction
```bash
prepare() {
    ar x "HuionTablet_LinuxDriver_v${pkgver}.x86_64.deb"
    tar -xf data.tar.*
}
```

**What happens here:**
1. `.deb` files are **ar archives** (like tar, but older format)
2. They contain:
   - `debian-binary` - version info
   - `control.tar.xz` - metadata and scripts (we don't need this)
   - `data.tar.xz` - actual files to install (this is what we extract)
3. We extract `data.tar.*` which contains the `usr/` and `etc/` directories

#### Package Installation
```bash
package() {
    cp -r usr "$pkgdir/"
    cp -r etc "$pkgdir/"
    chmod +x ...  # Fix executable permissions
}
```

**What gets installed:**
- `/usr/lib/huiontablet/` - Main application directory
- `/usr/share/applications/huiontablet.desktop` - Desktop entry
- `/usr/share/icons/huiontablet.png` - Application icon
- `/etc/xdg/autostart/huiontablet.desktop` - Autostart entry
- `/usr/lib/udev/rules.d/20-huion.rules` - Udev rules for hardware detection

### 2. huion-tablet.install File

This file replaces all four Debian maintenance scripts:
- `preinst` → `pre_install()` (not used, but available)
- `postinst` → `post_install()`
- `prerm` → `pre_remove()`
- `postrm` → `post_remove()`

Plus Arch-specific hooks:
- `pre_upgrade()` - Runs before upgrade
- `post_upgrade()` - Runs after upgrade

#### post_install() - What It Does

**1. Install xdotool (if needed)**
```bash
if ! command -v xdotool >/dev/null 2>&1; then
    cp -f /usr/lib/huiontablet/xdotool/xdotool /bin/xdotool
fi
```

**Why:** The driver bundles its own `xdotool` binary and library. If the system doesn't have `xdotool` installed, we copy the bundled version to a system location.

**2. Configure Bluetooth**
```bash
sed -i 's/#UserspaceHID=true/UserspaceHID=true/' /etc/bluetooth/input.conf
```

**Why:** Enables UserspaceHID mode for better tablet support over Bluetooth. This is the same as the Debian script does.

**3. Install udev rules**
```bash
udevadm control --reload-rules
udevadm trigger
```

**Why:** The udev rules allow the system to detect the tablet hardware and set proper permissions. After installing, we reload udev so the rules take effect.

**4. Skip GDM Configuration**
```bash
# NOTE: We DON'T configure GDM for i3 users!
```

**Why:** The Debian script configures GDM to disable Wayland and force X11. Since i3 is X11-only, this is unnecessary. We skip it entirely.

#### pre_remove() - What It Does

**Stops running processes:**
```bash
killall huionCore
killall huiontablet
```

**Why:** Before removing the package, we need to stop any running driver processes. This prevents:
- File locking issues
- Processes continuing to run after files are deleted
- User confusion

#### post_remove() - What It Does

**1. Clean up application directory**
```bash
rm -rf /usr/lib/huiontablet/
```

**Why:** Pacman usually handles this, but we ensure it's gone.

**2. Clean up user files**
```bash
for home_dir in /home/*; do
    rm -f "$home_dir/.HuionCore.pid"
    rm -f "$home_dir/.DriverUI.pid"
    rm -f "$home_dir/.huion.log"
done
```

**Why:** The driver creates PID files and logs in user home directories. We clean these up properly (unlike the Debian script which had broken glob patterns).

**3. Remove udev rules**
```bash
rm -f /usr/lib/udev/rules.d/20-huion.rules
udevadm control --reload-rules
```

**Why:** Remove hardware detection rules and reload udev.

## Key Differences from Debian Package

### 1. No GDM Configuration
- **Debian:** Configures `/etc/gdm/custom.conf` to disable Wayland
- **Arch/i3:** Skipped entirely (i3 is X11-only)

### 2. Better User File Cleanup
- **Debian:** Uses broken glob pattern `/home/*/.file` that doesn't work
- **Arch:** Proper loop through `/home/*` directories

### 3. Modern Script Syntax
- **Debian:** Uses backticks `` `command` ``
- **Arch:** Uses `$(command)` (though we use `command -v` which is POSIX)

### 4. Error Handling
- **Debian:** Basic error checking
- **Arch:** Uses `|| true` to prevent script failures on non-critical operations

### 5. Process Management
- **Debian:** Uses `sudo killall` (assumes sudo)
- **Arch:** Direct `killall` (install scripts run as root)

## Building and Installing

### Build the Package
```bash
makepkg -s
```

This will:
1. Extract the `.deb` file
2. Copy files to package directory
3. Create a `.pkg.tar.zst` file

### Install the Package
```bash
sudo pacman -U huion-tablet-15.0.0.175-1-x86_64.pkg.tar.zst
```

Or build and install in one step:
```bash
makepkg -si
```

### Verify Installation
```bash
# Check if files are installed
ls -la /usr/lib/huiontablet/
ls -la /usr/lib/udev/rules.d/20-huion.rules

# Check if udev rules are loaded
udevadm test /sys/class/input/event0 2>&1 | grep -i huion

# Run the driver
/usr/lib/huiontablet/huiontablet.sh
```

## Troubleshooting

### Driver doesn't detect tablet
1. Check udev rules: `ls -la /usr/lib/udev/rules.d/20-huion.rules`
2. Reload udev: `sudo udevadm control --reload-rules && sudo udevadm trigger`
3. Check device: `lsusb | grep -i huion`
4. Check permissions: `ls -la /dev/input/event*`

### xdotool not found
- The bundled xdotool should be installed automatically
- Check: `which xdotool` or `ls -la /bin/xdotool`
- If missing, manually copy: `sudo cp /usr/lib/huiontablet/xdotool/xdotool /bin/xdotool`

### Processes won't stop
- Force kill: `killall -9 huionCore huiontablet`
- Check for stale PID files: `rm -f ~/.HuionCore.pid ~/.DriverUI.pid`

## i3-Specific Notes

1. **No display manager configuration needed** - i3 is X11-only
2. **Autostart works** - The `/etc/xdg/autostart/` entry will work with i3 if you have a DE/WM that supports it
3. **Manual start** - You can add to your i3 config:
   ```
   exec --no-startup-id /usr/lib/huiontablet/huiontablet.sh
   ```
4. **X11 session** - Verify with: `echo $XDG_SESSION_TYPE` (should show `x11`)

## Summary

The porting process involved:
1. ✅ Converting Debian metadata to PKGBUILD format
2. ✅ Extracting files from `.deb` archive
3. ✅ Replacing maintenance scripts with `.install` file
4. ✅ Removing GDM-specific configuration (not needed for i3)
5. ✅ Fixing broken glob patterns in cleanup scripts
6. ✅ Adding proper udev rule reloading
7. ✅ Improving error handling

The resulting package is cleaner, more maintainable, and optimized for Arch Linux with i3.
