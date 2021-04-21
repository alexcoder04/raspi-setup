
# fish config for my Raspberry pi

set -gx PATH $PATH /home/pi/Programs

if [ $TERM = linux ]
	setfont /usr/share/consolefonts/Lat7-Terminus22x11.psf.gz
	set fish_image "WT Fish ><>° "
	set fish_img_color 005fd7
else
	set fish_image " rocks > "
	set fish_img_color normal
end

function fish_prompt
	set_color green
	printf $USER
	set_color normal
	printf "@"
	set_color yellow
	printf $hostname
	set_color normal
	printf " in "
	set_color 005fd7
	echo (prompt_pwd)
	set_color $fish_img_color
	printf $fish_image
	set_color normal
end

alias :q="exit"
alias gostore="cd /media/pi/whitestore"
alias python="python3"

