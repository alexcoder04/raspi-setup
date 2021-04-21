#!/bin/bash

echo "Welcome to this Raspi-installer!!!"

echo "1. Performing package operations; this may take some time."
echo "Updating package database..."
sudo apt update
echo "Removing unnecessary software..."
sudo apt remove geany thonny lxtask
echo "Upgrading packages..."
sudo apt upgrade
echo "Installing addtional software..."
sudo apt install i3 i3blocks rofi feh cmatrix arc-theme papirus-icon-theme fonts-font-awesome fish vim git

echo "2. Making system configurations."

echo "2.1. Changing default login shell to fish..."
chsh -s /usr/bin/fish

echo "2.2. Forcing password confirmation by sudo..."
[ -f /etc/sudoers.d/010_pi-nopasswd ] && sudo rm /etc/sudoers.d/010_pi-nopasswd

echo "2.3. Configuring system with raspi-config."
echo "Things you can do:"
echo " - enable SSH"
echo " - enable picamera"
echo " - change login to the command line mode"
echo "press <Enter> to continue..." && read
echo "Running raspi-config..."
sudo raspi-config

echo "2.4. Configuring themes."
echo "Running lxappearance..."
lxappearance

echo "2.5. Configuring default desktop enviroment."
echo "Writing i3 to ~/.xsession..."
echo "exec /usr/bin/i3" > $HOME/.xsession

echo "3. Downloading config files."
echo "Do you want to use local config files or pull those from an online repo?"
chosen="" && read -p "[ local / online ] ? " chosen
if [ "$chosen" = "local" ]; then
    echo "Running subshell to mount drives..."
    echo "Make sure the config files are in /mnt/config and exit the subshell then!"
    fish
    config_files_dir="/mnt/config"
else
    repo_link="https://github.com/alexcoder04/raspi-config"
    echo "Which repo do you want to use?"
    echo "Enter the link or use the default ($repo_link)"
    chosen="" && read -p "[ <link> / <empty to use default> ] ? " chosen
    [ -z "$chosen" ] || repo_link="$chosen"
    config_files_dir="$HOME/raspi-setup"
    git clone "$repo_link" "$config_files_dir"
fi
echo "Copying config files..."
echo "Copying i3 config..."
[ -e "$HOME/.config/i3" ] && rm -rf "$HOME/.config/i3"
cp -i -r "$config_files_dir/i3wm" "$HOME/.config/"
echo "Copying fish config..."
[ -e "$HOME/.config/fish" ] && rm -rf "$HOME/.config/fish"
cp -i -r "$config_files_folder/fish" "$HOME/.config/"
echo "Copying rofi config..."
[ -e "$HOME/.config/rofi" ] && rm -rf "$HOME/.config/rofi"
cp -i -r "$config_files_dir/rofi" "$HOME/.config/"
echo "Installing local scripts..."
[ -e "$HOME/Programs" ] && rm -rf "$HOME/Programs"
cp -i -r "$config_files_dir/Programs" "$HOME"

echo "4. Cleaning up."
[ -e "$HOME/raspi-setup" ] && rm -rf "$HOME/raspi-setup"

