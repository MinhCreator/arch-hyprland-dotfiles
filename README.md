**Hyprland + Quickshell Dotfiles**  
A highly customized, modern Wayland desktop environment rice utilizing **Hyprland** (tiling window manager) and  **Quickshell** (QML-based widget/status shell).  
This setup features Material-inspired translucent control widgets, instant dynamic theme synchronization using Matugen, interactive system trays, and an optimized, zero-lag media controller notification.  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OQQmAABRAsSdYxZ4/mJjEsxE8W8GbCFuCLTOzVXsAAPzFuVZ3dXw9AQDgtesBxPEF3bv7x0IAAAAASUVORK5CYII=)  
**📷 Screenshots**  
*Place your captured screenshots in the * *screenshots/* * folder to display them here!*  
| | |  
|-|-|  
|    |    |   
| **Main Desktop** | **Control Dashboard** |   
|    |    |   
| **Media Player** | **Application Search (Rofi)** |   
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OQQmAABRAsSdYxKY/jMFMIZ7ECt5E2BJsmZmt2gMA4C+Otbqr8+sJAACvXQ85QgYXd/O+eQAAAABJRU5ErkJggg==)  
**🌟 Features**  
- **Quickshell Status Bar & Widgets**: Lightweight, hardware-accelerated bar panel with active network/wifi lists, bluetooth trays, and KDE Connect integration.  
- **Unified Media Controller Widget**: Features real-time track progress, album art loading, source selection scrolling, and drag-and-seek functionality with zero skipping delay.  
- **On-the-fly Color Theme Generation**: Matugen parses your current wallpaper and updates colors dynamically across Hyprland, Kitty, Rofi, Cava, and Quickshell.  
- **Integrated Screenshotting & Clipboard**: Capture areas directly to Swappy for editing or manage clipboard history using Rofi applets.  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OQQmAUBBAwSfIb+HdmNvAkgaxgjcRZhLMNjNHdQUAwF/ce7Wq8+sJAACvrQctewNKtdojwQAAAABJRU5ErkJggg==)  
**📂 Repository Structure**  
dotfiles/  
 ├── .config/  
 │   ├── hypr/           # Hyprland configs (lockscreen, idle daemon, workspaces)  
 │   ├── quickshell/     # QML Shell configs (panels, trays, calendar scripts)  
 │   ├── kitty/          # Kitty terminal configs & colors  
 │   ├── rofi/           # Application launcher & clipboard themes  
 │   ├── wlogout/        # Power/logout menu templates  
 │   ├── cava/           # Cava audio visualizer configs & shaders  
 │   └── matugen/        # Dynamic material design generation rules  
 │  
 ├── Pictures/  
 │   └── wallpapers/     # Default wallpapers  
 │  
 ├── screenshots/  
 │   └── README.md       # Showcase screenshot guidelines  
 │  
 ├── .gitignore          # Repository git exclusions  
 ├── .zshrc              # Shell environment profile  
 ├── LICENSE             # MIT License  
 ├── install.sh          # Safe, non-destructive installer script  
 └── packages.txt        # Full system dependencies package list  
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANklEQVR4nO3OMQ2AABAAsSNBCkLfFDZwwIgHRiywEZJWQZeZ2ao9AAD+4lyruzq+ngAA8Nr1AOH0BedHjjlfAAAAAElFTkSuQmCC)  
**🛠️ System Requirements & Dependencies**  
This configuration is tested and optimized on **Arch Linux**.  
**1. Core Requirements (Required)**  
These packages are necessary for the desktop to load and function:  
***Official Repositories***  
- hyprland — Window manager  
- hyprlock — Lockscreen manager  
- hypridle — Idle manager  
- kitty — GPU-accelerated terminal  
- rofi — Launcher  
- matugen — Theme color generator  
- awww — Wallpaper daemon  
- pipewire-utils / wireplumber — Sound / Volume engine (pw-play/wpctl)  
- brightnessctl — Laptop screen brightness controls  
- jq — JSON query tool (for dashboard & shell scripts)  
- curl — Internet data download (for weather & github stats)  
- python — Execution environment (for calendar events)  
***AUR Packages***  
- quickshell-git — Widget layout framework  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OQQ2AQBAAsSHhiQI0IWp9ngBsYIEfIWkVdJuZs5oAAPiLe6+O6vp6AgDAa+sBhYwEOqBD7p8AAAAASUVORK5CYII=)  
**2. Desktop Add-ons & Utilities (Optional)**  
Features can be enabled/disabled by installing the following packages:  
***Official Repositories***  
- cliphist / wl-clipboard — Clipboard management history (Alt+V)  
- wlogout — Logout power menu (Super+Escape)  
- cava — Audio visualizer  
- grim / slurp / swappy — Screen capture and annotation  
- network-manager-applet — Network manager status icon tray (nm-applet)  
- blueman / bluez-utils — Bluetooth panel and proxy management (blueman-applet)  
- kdeconnect / zenity — Mobile device file-sharing and dashboard notifications  
- socat — Sound bell utilities  
- starship — Zsh prompt theme  
***AUR Packages***  
- swayosd-git — Volume/brightness status popups (HUD)  
- omniglyph — Emoji & symbol picker picker (Super+.)  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OQQmAABRAsSfYxKK/kJXEkyE8WcGbCFuCLTOzVXsAAPzFsVZ3dX4cAQDgvesB/vEF9H9odtUAAAAASUVORK5CYII=)  
**🚀 Installation Guide**  
**1. Clone the Repository**  
Clone the dotfiles into your home folder:  
git clone https://github.com/yourusername/dotfiles.git ~/Documents/dotfiles  
 cd ~/Documents/dotfiles  
   
**2. Run the Installer**  
Make the installer executable and run it:  
chmod +x install.sh  
 ./install.sh  
   
What the install.sh script does:  
1. Audits your system and checks for missing packages.  
2. Offers to automatically install missing packages using pacman and yay/paru.  
3. Creates a unique backup folder ~/.config/dotfiles_backup_YYYYMMDD_HHMMSS and moves any existing configs there.  
4. Safely symlinks configurations from ~/Documents/dotfiles to ~/.config/ and ~/.zshrc.  
5. Preloads the default wallpaper into ~/Pictures/wallpapers/fixed.jpg.  
**3. Restart and Log In**  
1. Restart your display manager or log in to a new session.  
2. Launch Hyprland.  
3. Reload Zsh in your terminal: source ~/.zshrc  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANklEQVR4nO3OQQmAABRAsSfYxZo/kC1sYQLPJrCCNxG2BFtmZquOAAD4i3Ot7mr/egIAwGvXA4qzBdC53Vr8AAAAAElFTkSuQmCC)  
**⌨️ Keybindings**  
- Super + Q — Open Kitty Terminal  
- Super + E — Open File Manager (Thunar)  
- Super + B — Open Zen Browser  
- Super + Z — Open Zed Editor  
- Super + R — Open Rofi Application Launcher  
- Alt + V — Open Clipboard History (Rofi)  
- Super + Escape — Open Power Menu (wlogout)  
- Super + A — Toggle Desktop Wallpaper Panel  
- Super + N — Toggle Control Dashboard  
- Super + X — Toggle Music Media Player  
- Super + D — Toggle PDF Tools Widget  
- Super + G — Toggle GitHub Monitor Drawer  
- Alt + W — Toggle Wifi Panel Drawer  
- Alt + B — Toggle Bluetooth Panel Drawer  
- Alt + K — Toggle KDEConnect Drawer  
- PrintScreen — Capture drag area to Swappy  
- Shift + PrintScreen — Take fullscreen screenshot  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAM0lEQVR4nO3OMQ0AIAwAwZKQ6kBqjSAOJywYYCIkd9OP36pqRMQMAAB+sfqJfLoBAMCN3NYoAzBA+QG0AAAAAElFTkSuQmCC)  
**⚙️ Customization**  
**Wallpaper & Colors**  
The wallpaper manager automatically hooks into Matugen. To change the wallpaper:  
1. Select a new wallpaper via the wallpaper widget (Super+A).  
2. Matugen will automatically re-parse the image, generating updated colors in ~/.config/hypr/colors.conf, ~/.config/kitty/color.conf, ~/.config/rofi/colors.rasi, and ~/.config/cava/config, then reloads active apps instantly.  
**Monitor Layouts**  
Edit [monitors.conf to change resolutions or refresh rates to match your monitor hardware:](file:///.config/hypr/monitors.conf "file:///.config/hypr/monitors.conf")  
monitor = eDP-1, 1920x1080@144, 0x0, 1  
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANklEQVR4nO3OMQ2AABAAsSNBACPq8MH2NpGACyywEZJWQZeZ2aszAAD+4l6rrTq+ngAA8Nr1AL/KBEe6dElaAAAAAElFTkSuQmCC)  
**🔍 Troubleshooting**  
**Quickshell fails to launch or displays blank components**  
Check the logs using standard journal command:  
journalctl --user -u quickshell  
   
Ensure QML_XHR_ALLOW_FILE_READ=1 is set in the launch command (already configured in hyprland.conf), which is required by QML for local weather/GitHub API caches.  
**Media controls or album art do not update**  
Make sure playerctld or mpris-proxy is running:  
systemctl --user enable --now playerctld  
   
**Bluetooth or Wi-Fi drawers do not populate**  
Ensure the underlying system daemons are enabled:  
sudo systemctl enable --now NetworkManager  
 sudo systemctl enable --now bluetooth  
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OYQ1AABSAwY9JoICqL4Z8Ikiggn9mu0twy8wc1RkAAH9xbdVa7V9PAAB47X4A9CgEJQFjJ/EAAAAASUVORK5CYII=)  
**🧹 Uninstallation & Restoring Backups**  
To restore your previous configurations:  
1. Delete the created symlinks:  
2. rm -rf ~/.config/{hypr,quickshell,kitty,rofi,wlogout,cava,matugen,starship.toml} ~/.zshrc  
   
3. Move your backed-up files from ~/.config/dotfiles_backup_<timestamp>/ back into ~/.config/ and ~/.  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OQQmAABRAsSd4NIGhrOTvaQBrWMGbCFuCLTOzV2cAAPzFvVZbdXw9AQDgtesBhYQEO+64Y8AAAAAASUVORK5CYII=)  
**📝 License**  
This project is licensed under the MIT License - see the [LICENSE file for details.](LICENSE "LICENSE")  
