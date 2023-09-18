#!/bin/sh

if [ "$(id -u)" = 0 ]; then
    echo "######################################################################"
    echo "This script should NOT be run as root user as it may create unexpected"
    echo " problems and you may have to reinstall Arch. So run this script as a"
    echo "  normal user. You will be asked for a sudo password when necessary"
    echo "######################################################################"
    exit 1
fi

read -p "Enter your Full Name: " fn
if [ -n "$fn" ]; then
    un=$(whoami)
    sudo chfn -f "$fn" "$un"
else
    echo ""
fi
sudo cp pacman.conf /etc/
sudo pacman -Syu --needed --noconfirm pacman-contrib
echo ""
read -r -p "Do you want to install Reflector? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm reflector
    echo -e "--save /etc/pacman.d/mirrorlist\n-p https\n-c 'Netherlands,United States'\n-l 10\n--sort rate" | sudo tee /etc/xdg/reflector/reflector.conf > /dev/null
    #Change location as per your need
    echo ""
    echo "It will take time to fetch the server/mirrors so please wait"
    echo ""
    if [ "$(pactree -r reflector)" ]; then
        sudo systemctl restart reflector
    else
        sudo systemctl enable --now reflector 
        sudo systemctl enable reflector.timer
    fi
fi

echo ""
if [ "$(pactree -r yay)" ]; then
    echo "Yay is already installed"
else
    git clone https://aur.archlinux.org/yay.git
    cd yay
    yes | makepkg -si
    cd ..
    rm -rf yay
fi

echo ""
sudo pacman -Syu --needed --noconfirm - < tpkg
sudo systemctl enable --now ufw
sudo ufw enable
sudo systemctl enable --now cups
sudo cp cups /etc/ufw/applications.d/
sudo cupsctl --share-printers
sudo ufw app update CUPS
sudo ufw allow CUPS
sudo systemctl enable sshd avahi-daemon
sudo cp /usr/share/doc/avahi/ssh.service /etc/avahi/services/
sudo ufw allow SSH
chsh -s /bin/fish
sudo chsh -s /bin/fish
pipx ensurepath

echo ""
read -r -p "Do you want to install Samba? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm samba
    sudo cp smb.conf /etc/samba/
    sudo systemctl enable smb nmb
    echo -e "[Share]\ncomment = Samba Share\npath = /home/"$(whoami)"/Share\nwritable = yes\nbrowsable = yes\nguest ok = no" | sudo tee -a /etc/samba/smb.conf > /dev/null
    mkdir ~/Share
    echo ""
    sudo smbpasswd -a $(whoami)
    sudo cp samba /etc/ufw/applications.d/
    sudo ufw app update SMB
    sudo ufw allow SMB
    sudo ufw allow CIFS
fi

sudo sed -i 's/Logo=1/Logo=0/' /etc/libreoffice/sofficerc

echo -e "VISUAL=nvim\nEDITOR=nvim\nQT_QPA_PLATFORMTHEME=qt6ct" | sudo tee /etc/environment > /dev/null
grep -qF "set number" /etc/xdg/nvim/sysinit.vim || echo "set number" | sudo tee -a /etc/xdg/nvim/sysinit.vim > /dev/null

echo ""
sudo pacman -Syu --needed --noconfirm numlockx lightdm-gtk-greeter
sudo systemctl enable lightdm
sudo cp lightdm-gtk-greeter.conf /etc/lightdm
sudo sed -i 's/^#greeter-setup-script=/greeter-setup-script=\/usr\/bin\/numlockx\ on/' /etc/lightdm/lightdm.conf

echo ""
read -r -p "Do you want to install WhiteSur icon theme? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
    cd WhiteSur-icon-theme
    sudo ./install.sh -a
    cd ..
    rm -rf WhiteSur-icon-theme
fi

echo ""
echo "Installing XFCE..."
echo ""
sudo pacman -Syu --needed --noconfirm - < xf
xfconf-query -c xsettings -p /Net/ThemeName -s "Materia-dark-compact"
xfconf-query -c xfwm4 -p /general/theme -n -t string -s "Materia-dark-compact"
xfconf-query -c xfwm4 -p /general/raise_with_any_button -n -t bool -s "false"
xfconf-query -c xfwm4 -p /general/scroll_workspaces -n -t bool -s "false"
xfconf-query -c xfwm4 -p /general/placement_ratio -n -t int -s "100"
xfconf-query -c xfwm4 -p /general/show_popup_shadow -n -t bool -s "true"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans 10"
xfconf-query -c xfce4-terminal -p /font-name -n -t string -s "Monospace 10"
xfconf-query -c xfce4-terminal -p /misc-default-geometry -n -t string -s "100x25"
xfconf-query -c xfce4-terminal -p /scrolling-unlimited -n -t bool -s "true"
xfconf-query -c xfce4-terminal -p /misc-show-unsafe-paste-dialog -n -t bool -s "false"
xfconf-query -c xfce4-screensaver -p /lock/embedded-keyboard/command -n -t string -s "onboard -e"
xfconf-query -c xfce4-screensaver -p /lock/embedded-keyboard/enabled -n -t bool -s "true"
xfconf-query -c xfce4-notifyd -p /expire-timeout -n -t int -s "3"
xfconf-query -c xfce4-notifyd -p /expire-timeout-allow-override -n -t bool -s "false"
xfconf-query -c xfce4-notifyd -p /initial-opacity -n -t double -s "1"
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -n -t bool -s "false"
xfconf-query -c xfce4-appfinder -p /icon-view -n -t bool -s "true"
xfconf-query -c xfce4-appfinder -p /last/window-height -n -t int -s "400"
xfconf-query -c xfce4-appfinder -p /last/window-width -n -t int -s "506"
xfconf-query -c thunar -p /misc-parallel-copy-mode -n -t string -s "THUNAR_PARALLEL_COPY_MODE_ALWAYS"
xfconf-query -c thunar -p /misc-thumbnail-mode -n -t string -s "THUNAR_THUMBNAIL_MODE_ALWAYS"
xfconf-query -c thunar -p /misc-file-size-binary -n -t bool -s "false"
xfconf-query -c xfce4-desktop -p /desktop-menu/show -n -t bool -s "false"
xfconf-query -c xfce4-desktop -p /desktop-menu/show-delete -n -t bool -s "false"
xfconf-query -c xfce4-desktop -p /windowlist-menu/show -n -t bool -s "false"

echo ""
read -r -p "Do you want to configure git? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo ""
    read -r -p "Do you want generate SSH keys? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo ""
	    ssh-keygen -t ed25519 -C "$git_email"
        echo ""
        echo "Make changes accordingly if SSH key is generated again"
    fi
fi

echo ""
read -r -p "Do you want Bluetooth Service? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm bluez bluez-utils blueman
    sudo systemctl enable bluetooth
fi

echo ""
read -r -p "Do you want to install VS Code(from AUR)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    yay -Syu --needed --noconfirm visual-studio-code-bin
fi

echo ""
read -r -p "Do you want to install HPLIP(Driver for HP printers)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm hplip sane python-pillow rpcbind python-reportlab
    hp-plugin -i
fi

cp -r qt5ct ~/.config
cp -r qt6ct ~/.config
cp -r galculator ~/.config
cp -r Thunar ~/.config
cp -r Kvantum ~/.config
cp QtProject.conf ~/.config
sudo pacman -Syu --needed --noconfirm libinput
sudo cp 40-libinput.conf /usr/share/X11/xorg.conf.d/

echo ""
echo "You can now reboot your system "
