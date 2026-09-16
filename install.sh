#!/usr/bin/env bash

# Setup colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hyprland & Quickshell Dotfiles Installer ===${NC}"

# 1. OS Detection
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}[Warning] This configuration is designed and tested on Arch Linux.${NC}"
    read -p "Do you want to proceed anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 1
    fi
fi

# 2. Dependency Audit
echo -e "\n${BLUE}[*] Auditing system dependencies...${NC}"
MISSING_OFFICIAL=()
MISSING_AUR=()

# Official commands/packages to check
declare -A OFFICIAL_DEPS=(
    ["hyprland"]="hyprland"
    ["hyprlock"]="hyprlock"
    ["hypridle"]="hypridle"
    ["kitty"]="kitty"
    ["rofi"]="rofi"
    ["cliphist"]="cliphist"
    ["wlogout"]="wlogout"
    ["cava"]="cava"
    ["starship"]="starship"
    ["matugen"]="matugen"
    ["awww-daemon"]="awww"
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["swappy"]="swappy"
    ["wl-copy"]="wl-clipboard"
    ["nm-applet"]="network-manager-applet"
    ["blueman-applet"]="blueman"
    ["mpris-proxy"]="bluez-utils"
    ["socat"]="socat"
    ["pw-play"]="pipewire-utils"
    ["wpctl"]="wireplumber"
    ["brightnessctl"]="brightnessctl"
    ["jq"]="jq"
    ["curl"]="curl"
    ["kdeconnect-cli"]="kdeconnect"
    ["zenity"]="zenity"
)

for cmd in "${!OFFICIAL_DEPS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_OFFICIAL+=("${OFFICIAL_DEPS[$cmd]}")
    fi
done

# AUR tools to check
declare -A AUR_DEPS=(
    ["quickshell"]="quickshell-git"
    ["swayosd-client"]="swayosd-git"
    ["omniglyph"]="omniglyph"
)

for cmd in "${!AUR_DEPS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_AUR+=("${AUR_DEPS[$cmd]}")
    fi
done

# 3. Handle Missing Dependencies
if [ ${#MISSING_OFFICIAL[@]} -ne 0 ] || [ ${#MISSING_AUR[@]} -ne 0 ]; then
    echo -e "${YELLOW}[!] Some dependencies are missing from your system:${NC}"
    if [ ${#MISSING_OFFICIAL[@]} -ne 0 ]; then
        echo -e "  Missing Official packages: ${MISSING_OFFICIAL[*]}"
    fi
    if [ ${#MISSING_AUR[@]} -ne 0 ]; then
        echo -e "  Missing AUR packages: ${MISSING_AUR[*]}"
    fi

    # Check if pacman is available
    if command -v pacman &>/dev/null; then
        read -p "Would you like to install the missing official packages now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed "${MISSING_OFFICIAL[@]}"
        fi

        if [ ${#MISSING_AUR[@]} -ne 0 ]; then
            if command -v yay &>/dev/null; then
                read -p "Would you like to install the missing AUR packages using yay? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    yay -S "${MISSING_AUR[@]}"
                fi
            elif command -v paru &>/dev/null; then
                read -p "Would you like to install the missing AUR packages using paru? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    paru -S "${MISSING_AUR[@]}"
                fi
            else
                echo -e "${YELLOW}[!] No AUR helper (yay/paru) detected. Please install AUR packages manually: ${MISSING_AUR[*]}${NC}"
            fi
        fi
    fi
else
    echo -e "${GREEN}[✓] All core dependencies are met!${NC}"
fi

# 4. Create backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config/dotfiles_backup_$TIMESTAMP"
echo -e "\n${BLUE}[*] Creating backup directory for existing configurations at: ${BACKUP_DIR}${NC}"
mkdir -p "$BACKUP_DIR"

# Config folders to symlink
CONFIG_FOLDERS=(
    "hypr"
    "quickshell"
    "kitty"
    "rofi"
    "wlogout"
    "cava"
    "matugen"
    "swayosd"
    "swappy"
    "fastfetch"
)

# Repo Root path
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 5. Backup & Symlink Configurations
mkdir -p "$HOME/.config"

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$HOME/.config/$folder"
    SOURCE="$REPO_DIR/.config/$folder"

    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        echo -e "  Backing up existing ~/.config/$folder -> $BACKUP_DIR/"
        mv "$TARGET" "$BACKUP_DIR/"
    fi

    echo -e "  Linking $folder -> ~/.config/$folder"
    ln -sf "$SOURCE" "$TARGET"
done

# Link starship.toml
STARSHIP_TARGET="$HOME/.config/starship.toml"
STARSHIP_SOURCE="$REPO_DIR/.config/starship.toml"
if [ -e "$STARSHIP_TARGET" ] || [ -L "$STARSHIP_TARGET" ]; then
    echo -e "  Backing up existing ~/.config/starship.toml -> $BACKUP_DIR/"
    mv "$STARSHIP_TARGET" "$BACKUP_DIR/"
fi
echo -e "  Linking starship.toml -> ~/.config/starship.toml"
ln -sf "$STARSHIP_SOURCE" "$STARSHIP_TARGET"

# Link .zshrc
ZSH_TARGET="$HOME/.zshrc"
ZSH_SOURCE="$REPO_DIR/.zshrc"
if [ -e "$ZSH_TARGET" ] || [ -L "$ZSH_TARGET" ]; then
    echo -e "  Backing up existing ~/.zshrc -> $BACKUP_DIR/"
    mv "$ZSH_TARGET" "$BACKUP_DIR/"
fi
echo -e "  Linking .zshrc -> ~/.zshrc"
ln -sf "$ZSH_SOURCE" "$ZSH_TARGET"

# Link Wallpaper
echo -e "\n${BLUE}[*] Copying wallpaper to ~/Pictures/wallpapers/...${NC}"
mkdir -p "$HOME/Pictures/wallpapers"
cp "$REPO_DIR/Pictures/wallpapers/fixed.jpg" "$HOME/Pictures/wallpapers/fixed.jpg"

# 6. Complete and summary
echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "Your previous configurations have been backed up in: ${YELLOW}${BACKUP_DIR}${NC}"
echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "  1. Reload your shell to apply Zsh configurations: ${YELLOW}source ~/.zshrc${NC}"
echo -e "  2. Restart Hyprland or reload configs: ${YELLOW}hyprctl reload${NC}"
echo -e "  3. Launch or reload Quickshell: ${YELLOW}quickshell --path ~/.config/quickshell/shell.qml${NC}"
echo -e "  4. Make sure to authenticate gh if you want to use the github dashboard: ${YELLOW}gh auth login${NC}"
