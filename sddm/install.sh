#!/usr/bin/env bash

# Install sddm-astronaut-theme to the system SDDM themes directory.
# SDDM themes live in /usr/share/sddm/themes/ (a system path), so this
# can't be managed via GNU Stow.  Run this script instead.
#
# Usage:
#   cd ~/dotfiles
#   ./sddm/install.sh            # install / update
#   ./sddm/install.sh uninstall  # remove

set -euo pipefail

THEME_NAME="sddm-astronaut-theme"
SUB_THEME="japanese_aesthetic"
THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_SRC="$SCRIPT_DIR/$THEME_NAME"

info()  { echo -e "\e[32m✅ $*\e[0m"; }
warn()  { echo -e "\e[33m⚠  $*\e[0m"; }
error() { echo -e "\e[31m❌ $*\e[0m" >&2; }

install_deps() {
    info "Installing dependencies…"
    sudo pacman --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
}

install_theme() {
    if [[ ! -d "$THEME_SRC" ]]; then
        error "Theme source not found at $THEME_SRC"
        echo "  Run:  git submodule update --init --recursive"
        exit 1
    fi

    install_deps

    info "Copying theme to $THEMES_DIR/$THEME_NAME…"
    sudo rm -rf "$THEMES_DIR/$THEME_NAME"
    sudo cp -r "$THEME_SRC" "$THEMES_DIR/$THEME_NAME"
    sudo rm -rf "$THEMES_DIR/$THEME_NAME/.git"

    info "Setting sub-theme to $SUB_THEME…"
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${SUB_THEME}.conf|" \
        "$THEMES_DIR/$THEME_NAME/metadata.desktop"

    info "Setting SDDM theme…"
    sudo mkdir -p "$SDDM_CONF_DIR"
    sudo cp "$SCRIPT_DIR/theme.conf" "$SDDM_CONF_DIR/theme.conf"

    info "Enabling sddm.service…"
    sudo systemctl enable sddm.service 2>/dev/null || true

    info "Done! Using sub-theme: $SUB_THEME"
    echo "  Reboot or run 'sudo systemctl start sddm' to see your new login screen."
    echo "  To switch sub-themes, change SUB_THEME in this script and re-run."
    echo "  Available themes:"
    ls "$THEMES_DIR/$THEME_NAME/Themes/" | sed 's/\.conf$//; s/^/    /'
}

uninstall_theme() {
    warn "Removing $THEME_NAME…"
    sudo rm -rf "$THEMES_DIR/$THEME_NAME"
    sudo rm -f  "$SDDM_CONF_DIR/theme.conf"
    info "Theme removed."
}

case "${1:-install}" in
    install)   install_theme   ;;
    uninstall) uninstall_theme ;;
    *)         echo "Usage: $0 [install|uninstall]"; exit 1 ;;
esac
