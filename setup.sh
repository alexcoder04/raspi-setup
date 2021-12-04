#!/bin/sh
#        _                        _            ___  _  _   
#   __ _| | _____  _____ ___   __| | ___ _ __ / _ \| || |  
#  / _` | |/ _ \ \/ / __/ _ \ / _` |/ _ \ '__| | | | || |_ 
# | (_| | |  __/>  < (_| (_) | (_| |  __/ |  | |_| |__   _|
#  \__,_|_|\___/_/\_\___\___/ \__,_|\___|_|   \___/   |_|  
# 
# Copyright (c) 2021 alexcoder04 <https://github.com/alexcoder04>
# 
# setting up raspberry pi (on RaspberryPi OS)
# requires: git
#                                                          

_VERSION="0.0.2"
PACKAGES_TO_REMOVE="geany thonny lxtask"
PACKAGES_REQUIRED="git"
PACKAGES_TO_INSTALL="
w3m cmatrix"
PACKAGES_GRAPHICAL="
i3 i3blocks rofi feh
lxappearance arc-theme papirus-icon-theme fonts-font-awesome"
DIALOG_INPUT_FILE="/tmp/raspisetup-inputfile"

die(){
    echo "ERROR: $1"; exit 1
}

yesno_continue(){
  printf "${1:-Do you want to continue [y/n]?}"
  read answer
  case "$answer" in
    y|Y|yes|YES|Yes) return 0 ;;
    *) return 1;;
  esac
}

subscript_failed(){
  echo "$1 did not exit with a success return code."
  echo "Something may went wrong"
  yesno_continue \
    && echo "Continuing anyway" \
    || die "component failed to run"
}

wait_to_continue(){
  printf "Press <Enter> to continue..."
  read _
}

setup_dotfiles(){
  printf "Dotfiles folder (default: ~/Dotfiles): "
  read answer
  [ -n "$answer" ] \
    && export DOTFILES_REPO="$answer" \
    || export DOTFILES_REPO="$HOME/Dotfiles"
  answer=
  mkdir -vp "$DOTFILES_REPO"
  printf "Dotfiles repository (default: https://github.com/alexcoder04/linux-dotfiles): "
  read answer
  [ -n "$answer" ] \
    && dotfiles_url="$answer" \
    || dotfiles_url="https://github.com/alexcoder04/linux-dotfiles"
  answer=
  git clone "$dotfiles_url" "$DOTFILES_REPO"
  echo "Dotfiles were cloned to $DOTFILES_REPO"
  echo "Please install them manually"
  wait_to_continue
}

cat <<EOF
0. Introduction"
Welcome to the Raspberry Pi setup script!
What you need? An internet connection and some time :)
---
Info:
date: $(date)
linux version: $(uname -r)
setup script version: $_VERSION
---
Warning: the setup script is a work in progress.
Bugs and missing features are expected.
EOF

wait_to_continue

echo "1. Package operations"
echo "1.1. Removing unnecessary packages"
echo "Following packages will be removed:"
for p in $PACKAGES_TO_REMOVE; do
  echo " - $p"
done

if yesno_continue; then
  sudo apt remove $PACKAGES_TO_REMOVE || subscript_failed "apt remove"
else
  printf "Custom list of packages to remove (leave blank if none): "
  read answer
  [ -n "$answer" ] && sudo apt remove $answer || subscript_failed "apt remove"
  answer=
fi

echo "1.2. Updating package database"
sudo apt update || subscript_failed "apt update"

echo "1.3. Installing setup dependencies"
for p in $PACKAGES_REQUIRED; do
  sudo apt install "$p" || subscript_failed "install $p"
done

echo "1.4. Installing software"
for p in $PACKAGES_TO_INSTALL; do
  sudo apt install "$p" || subscript_failed "install $p"
done

echo "2. System configuration"
echo "2.1. Forcing password confirmation by sudo"
[ -f /etc/sudoers.d/010_pi-nopasswd ] && sudo rm -v /etc/sudoers.d/010_pi-nopasswd

echo "2.2. Configuration with raspi-config"
cat <<EOF
What you can do
 - enable SSH
 - enable picamera
 - change login to CLI interface
EOF

wait_to_continue
sudo raspi-config

if yesno_continue "Configure GUI? "; then
  echo "2.3.1. Installing GUI packages..."
  for p in $PACKAGES_GRAPHICAL; do
    sudo apt install "$p" || subscript_failed "install $p"
  done
  echo "2.3.2. Configuring themes: running lxappearance..."
  echo "lxappearance is a graphical program which will open up now"
  echo "Just close it after you made the configurations and this script will go on"
  wait_to_continue
  lxappearance

  echo "2.4. Configuring i3 as default desktop enviroment..."
  echo "Writing i3 to ~/.xsession..."
  cat >"$HOME/.xsession" <<EOF
  #!/bin/sh
  exec /usr/bin/i3
EOF
else
  echo "skipping 2.3. and 2.4. - GUI"
fi

echo "2.5. Configuring fstab"
if yesno_continue "Do you want to use a ramdisk for /tmp?"; then
  echo "Creating fstab backup"
  sudo cp -v /etc/fstab /etc/fstab.bak
  line="tmpfs      /tmp         tmpfs    defaults,size=25%   0   0"
  echo "Default configuration for the ramdisk:"
  echo "$line"
  if ! yesno_continue; then
    echo "Enter custom ramdisk configuration line:"
    read line
  fi
  cat <<EOF | sudo tee -a /etc/file.conf
# ramdisk configured with raspi-setup
$line
EOF
  line=
fi

echo "2.6. Configuring dotfiles system"
if yesno_continue "Do you want to use alexcoder04's dotfiles system"; then
  setup_dotfiles
else
  echo "Skipping dotfiles setup"
fi

echo "3. Completion."
echo "Please reboot the Raspberry Pi to complete the setup!"

