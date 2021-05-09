#!/bin/sh

packages_to_remove="geany thonny lxtask"
dialog_input_file="/tmp/raspisetup-inputfile"

fatal_error(){
    echo "$1"; exit 1
}

wait_to_continue(){
    read -p "Press <Enter> to continue..."
}

config_ramdisk(){
	sudo cp /etc/fstab /etc/fstab.bak
	line="tmpfs      /tmp         tmpfs    defaults,size=25%   0   0"
	dialog \
		--backtitle "Ramdisk config" \
		--title "Configuring fstab and ramdisk" \
		--inputbox "fstab configuration line for the ramdisk:" 10 80 "$line" \
		2>"$dialog_input_file"
	sudo echo "# ramdisk" >> /etc/fstab
	sudo echo "$(cat $dialog_input_file)" >> /etc/fstab
}

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

dialog \
	--backtitle "Introduction" \
	--title "Welcome to the Raspberry Pi setup script!" \
	--msgbox "What you need? An internet connection and some time :)" 10 60
clear

echo "1. Performing package operations; this may take some time."
echo "1.1. Updating package database..."
sudo apt update || fatal_error "Could not perform apt update!"
echo "1.2. Installing script dependencies..."
sudo apt install vim git dialog
wait_to_continue
dialog \
	--backtitle "Packages config" \
	--title "1.3. Removing unnecessary software" \
	--inputbox "Following packages will be removed:" 10 80 "$packages_to_remove" \
	2>"$dialog_input_file"
clear
sudo apt remove $(cat $dialog_input_file)
echo "1.4. Upgrading packages..."
sudo apt upgrade
echo "1.5. Installing additional software..."
sudo apt install \
		i3 i3blocks rofi feh \
		cmatrix \
		arc-theme papirus-icon-theme fonts-font-awesome \
		ranger w3m \
		fish
wait_to_continue

echo "2. Making system configurations."
echo "2.1. Forcing password confirmation by sudo..."
[ -f /etc/sudoers.d/010_pi-nopasswd ] && sudo rm -v /etc/sudoers.d/010_pi-nopasswd

dialog \
	--backtitle "Login Shell" \
	--title "2.2. Login shell"
	--radiolist "Select your login shell:" 10 50 4\
		1 /bin/bash off \
		2 /usr/bin/fish on \
		3 /bin/sh off \
	2>"$dialog_input_file"
case "$(cat $dialog_input_file)" in
	1)
		chsh -s /bin/bash
		;;
	2)
		chsh -s /usr/bin/fish
		;;
	*)
		chsh -s /bin/sh
		;;
esac

dialog \
	--backtitle "System configuration" \
	--title "2.3. Configuring system with raspi-config" \
	--msgbox "Things you can do:\n - enable SSH\ - enable picamera\ - change login to the command line mode" 10 60
sudo raspi-config

clear
echo "2.4. Configuring themes: running lxappearance..."
wait_to_continue
lxappearance

echo "2.5. Configuring i3 as default desktop enviroment..."
echo "Writing i3 to ~/.xsession..."
echo -e "#!/bin/sh\nexec /usr/bin/i3" > "$HOME/.xsession"

dialog \
	--backtitle "fstab and ramdisk" \
	--title "2.6. Configuring fstab." \
	--yesno "Use a ramdisk?" 10 40
[ "$?" = "0" ] && config_ramdisk

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

echo "4. Setting up systemd daemons"
dialog \
	--backtitle "CPU temperature tracker" \
	--title "4.1. Setting up CPU temperature tracker" \
	--yesno "Setup CPU temperature tracker?" 10 40
[ "$?" = "0" ] \
	&& clear \
	&& sudo cat "$config_files_dir/systemd/cputracker.service" | sed "s/+USER+/$USER/" > "/etc/systemd/system/cputracker.service" \
	&& sudo systemctl enable cputracker.service \
	&& wait_to_continue

echo "5. Cleaning up."
[ -e "$HOME/raspi-setup" ] && rm -rf "$HOME/raspi-setup"
rm $dialog_input_file

echo "6. Completion."
echo "Reboot the Raspberry Pi to complete the setup!"

