#!/bin/bash

while getopts "d:f:" opt; do
  case $opt in
    d) dir=$OPTARG      ;;
    f) format=$OPTARG   ;;
    *) echo 'error' >&2
       exit 1
  esac
done

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

if [ -z "$1" ] || [ ! -d "/home/$1" ]; then
  # Take action if $DIR exists. #
  echo "Undefined user or folder not exists"
  exit
fi

dir_folder=$(pwd)
# If -d is *required*
#if [ ! -d "$dir" ]; then
#    echo 'Option -d missing or designates non-directory' >&2
#    exit 1
#fi

# If -d is *optional*
#if [ -n "$dir" ] && [ ! -d "$dir" ]; then
#    echo 'Option -d designates non-directory' >&2
#    exit 1
#fi

# 0. ctualizamos SO:

apt-get update && apt-get -y upgrade

# 1. Instalamos los siguientes paquetes:

## bspwm y sxhkd
apt -y install build-essential git vim xcb libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

## polybar
apt -y install cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev libuv1-dev

## rofi firejail feh
apt -y install rofi firejail feh

## slim-lock
apt -y install libpam0g-dev libxrandr-dev libfreetype6-dev libimlib2-dev libxft-dev

## Picom
apt -y install meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev

echo "#################### 2"
# 2. Descarga de repositorios
cd /home/$1/Downloads
git clone https://github.com/baskerville/bspwm.git
git clone https://github.com/baskerville/sxhkd.git
git clone --recursive https://github.com/polybar/polybar
git clone https://github.com/ibhagwan/picom.git
git clone https://github.com/VaughnValle/blue-sky.git
git clone https://github.com/joelburget/slimlock.git

echo "#################### 3"
# 3. Instalamos bspwm y sxhkd
cd /home/$1/Downloads/bspwm
make
make install
apt -y install bspwm

cd /home/$1/Downloads/sxhkd
make
make install

apt -y install bspwm

mkdir /home/$1/.config/bspwm
mkdir /home/$1/.config/sxhkd
cp -r $dir_folder/config/bspwm /home/$1/.config/

chmod +x /home/$1/.config/bspwm/bspwmrc 
cp $dir_folder/config/sxhkdrc /home/$1/.config/sxhkd/

sed -i "s/{USER}/$1/g" /home/$1/.config/bspwm/bspwmrc 
sed -i "s/{USER}/$1/g" /home/$1/.config/sxhkd/sxhkdrc

cp $dir_folder/pictures/fondo.jpg /home/$1/Pictures/

echo "#################### 4"
# 4. Instalamos polybar
cd /home/$1/Downloads/polybar/
mkdir build
cd build/
cmake ..
make -j$(nproc)
make install

echo "#################### 5"
# 5. Instalamos Picom
cd /home/$1/Downloads/picom/
git submodule update --init --recursive
meson --buildtype=release . build
ninja -C build
ninja -C build install

echo "#################### 6"
# 6. Instalamos las fuentes 
cp $dir_folder/font/Hack.zip /usr/local/share/fonts
cd /usr/local/share/fonts
unzip Hack.zip
fc-cache -v
rm /usr/local/share/fonts/Hack.zip

echo "#################### 7"
# 7. Instalamos polybar
mkdir /home/$1/.config/polybar
cp -r /home/$1/Downloads/blue-sky/polybar/*  /home/$1/.config/polybar/
cp /home/$1/Downloads/blue-sky/polybar/fonts/* /usr/share/fonts/truetype/
fc-cache -v

cp -r $dir_folder/config/bin /home/$1/.config/
cp $dir_folder/config/polybar/current.ini /home/$1/.config/polybar/
cp $dir_folder/config/polybar/launch.sh /home/$1/.config/polybar/
cp $dir_folder/config/polybar/workspace.ini /home/$1/.config/polybar/
cp $dir_folder/config/polybar/powermenu_alt /home/$1/.config/polybar/scripts

echo "#################### 8"
# 8. Configuracion de picom
mkdir /home/$1/.config/picom
cp $dir_folder/config/picom/picom.conf /home/$1/.config/picom

echo "#################### 9"
# 9. Configuramos tema de nord
mkdir -p /home/$1/.config/rofi/themes
cp /home/$1/Downloads/blue-sky/nord.rasi /home/$1/.config/rofi/themes

echo "#################### 10"
# 10. Configuramos slimlock
cd /home/$1/Downloads/slimlock
make
make install

cp slimlock.conf /etc

# 11. Instalamos powerlevel10k
## usuario
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$1/powerlevel10k
echo "source /home/${1}/powerlevel10k/powerlevel10k.zsh-theme" >> /home/$1/.zshrc

## root
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc

## configuramos zshrc
#cp $dir_folder/config/zsh/.zshrc /home/$1/

## Creamos enlace simbolico
#ln -s -f /home/$1/.zshrc ~/.zshrc

## Cambiamos shell por defecto
#usermod --shell /usr/bin/zsh $1
#usermod --shell /usr/bin/zsh root

## Configuramos .p10k.zsh
#cp $dir_folder/config/zsh/.p10k.zsh /home/$1/
#ln -s -f /home/$1/.p10k.zsh ~/.p10k.zsh

## Permisos de ejecucion
#chown $1:$1 /root
#chown $1:$1 /root/.cache -R
#chown $1:$1 /root/.local -R

# Instalamos bat lsd fzf ranger
apt -y install bat
apt -y install fzf 
apt -y install ranger

# Instalamos nvim con nord
## USER
mkdir /home/$1/.config/nvim/
wget https://github.com/arcticicestudio/nord-vim/archive/master.zip /home/$1/.config/nvim/
unzip /home/$1/.config/nvim/master.zip 
rm /home/$1/.config/nvim/master.zip 
mv /home/$1/.config/nvim/nord-vim-master/colors /home/$1/.config/nvim/
rm -r /home/$1/.config/nvim/nord-vim-master/

rm /home/$1/.config/nvim/init.vim

wget https://raw.githubusercontent.com/Necros1s/lotus/master/lotus.vim /home/$1/.config/nvim/
wget https://raw.githubusercontent.com/Necros1s/lotus/master/lotusbar.vim /home/$1/.config/nvim/
wget https://raw.githubusercontent.com/Necros1s/lotus/master/init.vim /home/$1/.config/nvim/

#echo 'colorscheme nord' >> /home/$1/.config/nvim/init.vim
echo 'syntax on' >> /home/$1/.config/nvim/init.vim

## ROOT
mkdir ~/.config/nvim/
wget https://github.com/arcticicestudio/nord-vim/archive/master.zip ~/.config/nvim/
unzip ~/.config/nvim/master.zip 
rm ~/.config/nvim/master.zip
mv ~/.config/nvim/nord-vim-master/colors ~/.config/nvim/
rm -r ~/.config/nvim/nord-vim-master/

rm ~/.config/nvim/init.vim

wget https://raw.githubusercontent.com/Necros1s/lotus/master/lotus.vim ~/.config/nvim/
wget https://raw.githubusercontent.com/Necros1s/lotus/master/lotusbar.vim ~/.config/nvim/
wget https://raw.githubusercontent.com/Necros1s/lotus/master/init.vim ~/.config/nvim/

#echo 'colorscheme nord' >> ~/.config/nvim/init.vim
echo 'syntax on' >> ~/.config/nvim/init.vim

# Reiniciamos sesion
kill -9 -1