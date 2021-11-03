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

PACKAGES_TO_REMOVE="geany thonny lxtask"
PACKAGES_REQUIRED="git"
PACKAGES_TO_INSTALL="
i3 i3blocks rofi feh
lxappearance arc-theme papirus-icon-theme fonts-font-awesome
w3m
cmatrix"
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

# ------------------

install_config(){
	[ -e "$1" ] || return
	if [ -e "$2" ]; then
		dialog \
			--backtitle "File or folder exists" \
			--title "$2 already exists" \
			--yesno "Replace it?" 10 60
		[ "$?" = "0" ] && rm -rfv "$2" || return
		clear
	fi
	cp -rv "$1" "$2"
}
# ----------------

echo "0. Introduction"
echo "Welcome to the Raspberry Pi setup script!"
echo "What you need? An internet connection and some time :)"

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
fi

echo "1.2. Updating package database"
sudo apt update || subscript_failed "apt update"

echo "1.3. Installing setup dependencies"
sudo apt install $PACKAGES_REQUIRED || subscript_failed "install required packages"

echo "1.4. Installing software"
for p in $PACKAGES_TO_INSTALL; do
  sudo apt install "$p"
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

echo "2.3. Configuring themes: running lxappearance..."
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
fi








dialog \
	--backtitle "Config files" \
	--title "3.1. Downloading config files" \
	--yesno "Use local config files?" 10 40
if [ "$?" = "0" ]; then
	dialog \
		--backtitle "Mount additional drives" \
		--title "3.1.1. Mounting additional drives" \
		--yesno "Do you want to mount additional drives?" 10 50
	[ "$?" = "0" ] && clear && fish
	dialog \
		--backtitle "Config folder" \
		--title "3.1.2. Selecting config folder" \
		--inputbox "Enter the folder with your config files:" 10 50 "/mnt/config" \
		2>"$dialog_input_file"
	config_files_dir="$(cat $dialog_input_file)"
else
	dialog \
		--backtitle "Custom repository" \
		--title "3.1.1. Select repository" \
		--yesno "Use custom repository?" 10 40
	if [ "$?" = "0" ]; then
		dialog \
			--backtitle "Repository link" \
			--title "3.1.2. Selecting repository" \
			--inputbox "Enter repository link:" 10 60 \
			2>"$dialog_input_file"
		repo_link="$(cat $dialog_input_file)"
	else
		repo_link="https://github.com/alexcoder04/raspi-config"
	fi
	clear
	config_files_dir="$HOME/raspi-setup"
	git clone "$repo_link" "$config_files_dir"
fi

echo "3.2. Copying config files..."
echo "Copying i3 config..."
install_config "$config_files_dir/i3wm" "$HOME/.config/i3"
echo "Copying fish config..."
install_config "$config_files_dir/fish" "$HOME/.config/fish"
echo "Copying rofi config..."
install_config "$config_files_dir/rofi" "$HOME/.config/rofi"
echo "Copying vim config..."
install_config "$config_files_dir/.vimrc" "$HOME/.vimrc"
echo "Installing local scripts..."
install_config "$config_files_dir/Programs" "$HOME/Programs"


echo "6. Completion."
echo "Reboot the Raspberry Pi to complete the setup!"

