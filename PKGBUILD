# Maintainer: BABEL (Anya Desdein)
# Contributor: Ported from Debian package v15.0.0.175

pkgname=huion-tablet
pkgver=15.0.0.175
pkgrel=1
pkgdesc="Huion Tablet Driver Setting Software (requires X11)"
arch=('x86_64')
url="https://www.huion.com"
license=('WTFPL' 'custom:Huion')
provides=('huion')
conflicts=('huiontablet')
depends=('qt5-base' 'qt5-declarative' 'qt5-quickcontrols' 'libx11' 'libxext' 'libxrender' 'libxrandr' 'dbus' 'systemd-libs')
install=huion-tablet.install
source=("https://driverdl.huion.com/driver/Linux/HuionTablet_LinuxDriver_v${pkgver}.x86_64.deb")
sha256sums=('bcf4d9263f2a82e942c79929a89d9841adef527febf91c43027ab3311f2c3ede')  # Replace with: sha256sum HuionTablet_LinuxDriver_v15.0.0.175.x86_64.deb

prepare() {
    cd "$srcdir"
    
    # Extract the .deb file that contains:
    # - debian-binary (version info)
    # - control.tar.xz (metadata and scripts)
    # - data.tar.xz (actual files)
    ar x "HuionTablet_LinuxDriver_v${pkgver}.x86_64.deb"
    
    # Extract data archive
    tar -xf data.tar.*
}

package() {
    cd "$srcdir"
    
    # Copy all files from deb/data to package directory
    # This preserves the directory structure
    cp -r usr "$pkgdir/"
    cp -r etc "$pkgdir/"
    
    # Fix permissions for executables
    chmod +x "$pkgdir/usr/lib/huiontablet/huiontablet"
    chmod +x "$pkgdir/usr/lib/huiontablet/huionCore"
    chmod +x "$pkgdir/usr/lib/huiontablet/huiontablet.sh"
    chmod +x "$pkgdir/usr/lib/huiontablet/huionCore.sh"
    
    # Fix permissions for bundled xdotool
    if [ -f "$pkgdir/usr/lib/huiontablet/xdotool/xdotool" ]; then
        chmod +x "$pkgdir/usr/lib/huiontablet/xdotool/xdotool"
    fi
    
    # Remove temporary files that shouldn't be in the package
    # (These are created at runtime)
    rm -f "$pkgdir/usr/lib/huiontablet/.DriverUI.pid"
    rm -f "$pkgdir/usr/lib/huiontablet/.huion.log"
    rm -f "$pkgdir/usr/lib/huiontablet/.HuionCore.pid"
    
    # Remove incompatible bundled libraries - use system libraries instead
    # These bundled versions are incompatible with Arch's current libraries
    echo "Removing incompatible bundled libraries..."
    rm -f "$pkgdir/usr/lib/huiontablet/libs/libdbus-1.so.3"
    rm -f "$pkgdir/usr/lib/huiontablet/libs/libsystemd.so.0"
}
