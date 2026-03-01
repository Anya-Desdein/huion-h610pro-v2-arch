# Maintainer: BABEL (Anya Desdein)
# Contributor: Ported from Debian package v15.0.0.175

# Ensure UTF-8 so bsdtar can handle pathnames with non-ASCII characters (e.g. Chinese in res/DevImg)
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

pkgname=huion-tablet
pkgver=15.0.0.175
pkgrel=1
pkgdesc="Huion Tablet Driver Setting Software (requires X11)"
arch=('x86_64')
url="https://www.huion.com"
license=('WTFPL' 'custom:Huion')
options=('!debug') #comment that if you need debug symbols
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

    install -dm755 "$pkgdir/opt/huiontablet"
    cp -r usr/lib/huiontablet/* "$pkgdir/opt/huiontablet/"

    install -dm755 "$pkgdir/opt/huiontablet/share/icons"
    install -m644 usr/share/icons/huiontablet.png "$pkgdir/opt/huiontablet/share/icons/"

    install -dm755 "$pkgdir/usr/lib/udev/rules.d"
    install -m644 usr/lib/udev/rules.d/20-huion.rules "$pkgdir/usr/lib/udev/rules.d/"

    # PATH: run with 'huiontablet'
    install -dm755 "$pkgdir/usr/bin"
    ln -s /opt/huiontablet/huiontablet.sh "$pkgdir/usr/bin/huiontablet"

    # Fix permissions for executables
    chmod +x "$pkgdir/opt/huiontablet/huiontablet"
    chmod +x "$pkgdir/opt/huiontablet/huionCore"
    chmod +x "$pkgdir/opt/huiontablet/huiontablet.sh"
    chmod +x "$pkgdir/opt/huiontablet/huionCore.sh"

    # Fix permissions for bundled xdotool
    if [ -f "$pkgdir/opt/huiontablet/xdotool/xdotool" ]; then
        chmod +x "$pkgdir/opt/huiontablet/xdotool/xdotool"
    fi

    # Remove temporary files that shouldn't be in the package
    rm -f "$pkgdir/opt/huiontablet/.DriverUI.pid"
    rm -f "$pkgdir/opt/huiontablet/.huion.log"
    rm -f "$pkgdir/opt/huiontablet/.HuionCore.pid"

    # Remove incompatible bundled libraries - use system libraries instead
    echo "Removing incompatible bundled libraries..."
    rm -f "$pkgdir/opt/huiontablet/libs/libdbus-1.so.3"
    rm -f "$pkgdir/opt/huiontablet/libs/libsystemd.so.0"

    # Desktop entries: patch paths for /opt and install
    install -dm755 "$pkgdir/usr/share/applications" "$pkgdir/etc/xdg/autostart"
    sed -e 's|/usr/lib/huiontablet/|/opt/huiontablet/|g' \
        -e 's|/usr/share/icons/huiontablet.png|/opt/huiontablet/share/icons/huiontablet.png|g' \
        usr/share/applications/huiontablet.desktop > "$pkgdir/usr/share/applications/huiontablet.desktop"
    sed -e 's|/usr/lib/huiontablet/|/opt/huiontablet/|g' \
        -e 's|/usr/share/icons/huiontablet.png|/opt/huiontablet/share/icons/huiontablet.png|g' \
        etc/xdg/autostart/huiontablet.desktop > "$pkgdir/etc/xdg/autostart/huiontablet.desktop"
}
