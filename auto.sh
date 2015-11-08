#!/bin/bash

# Ubuntu dev auto deploying script

# DEFAULT VALUES
XDG_USER_DIRS=(
  DESKTOP
  DOWNLOAD
  TEMPLATES
  PUBLICSHARE
  DOCUMENTS
  MUSIC
  PICTURES
  VIDEOS
)
USER_DIRS=(
  personal
  github
  programs
  src
  test
  deb_pkg
  uconfig
  utils
  blog
  issues
)

DEFAULT_MEDIA_MOUNT_POINT="media"
SSH_KEY='ssh/id_rsa'
DNS_SERVER_ADDR='8.8.8.8'
PRIVILEGE_NEED=(lib bin include)
CPA_NEED=(/usr/local/bin/node /usr/local/bin/ruby)

GIT_CONFIG=(
  'alias.ac "!git add -A && git commit"'
  "alias.co checkout"
  "alias.st 'status -sb'"
  "alias.lg 'log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --'"
  "alias.branches 'branch -a'"
  "alias.remotes 'remote -v'"
  "color.ui 1"
)

GEM=(bundler pry sinatra redis-objects)
NPM=(n node-gyp coffee-script js2coffee cson strongloop mocha)

# start
echo "current user is $USER"
echo "HOME dir is $HOME"
echo "current workdir is $PWD"
echo "disk quota:"
df -Tlh

sudo update
sudo core
sudo dependency
sudo rc-local
sudo config-dns
sudo config-proxy
sudo utility

config-github-account
setup-xdg-userdir
setup-user-dirs

# fish shell

cp -R ./fish/ ~/.config/fish/
chsh -s /usr/local/bin/fish

# Ruby

gem install ${GEM[*]}

# Node, Coffee

npm install ${NPM[*]}

# Lua

# CLisp

# MongoDB

cp ./mongodb.conf ~/uconfig
sudo ln -s ~/uconfig/mongodb.conf /etc/mongodb.conf

# Redis

cp ./redis.conf ~/uconfig
sudo ln -s ~/uconfig/redis.conf /etc/redis.conf

# LevelDB

# RethinkDB

cp ./rethinkdb.conf ~/uconfig
sudo ln -s ~/uconfig/rethinkdb.conf /etc/rethinkdb/default.conf.sample

sudo setcap ${CAP_NEED[*]}
sudo mod-owner ${PRIVILEGE_NEED[*]}

read -p '设置需要挂载的设备:(若多个设备以空格分割, 留空则跳过设置)' device
[[ -z $device ]] || ntfs-auto-mount $device

# sudo needed
update() {
  apt-get update
  apt-get upgrade
}

# 获取绝对路径
get-exact-path() {
  (cd `dirname $0`; pwd)
}

# 安装必需的开发工具/组件
# sudo needed
core() {
  apt-get install git git-core gcc g++ make gyp automake bison openssl autoconf
}

# 安装依赖库
# sudo needed
dependency() {
  apt-get install libssl-dev libtool build-essential libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev  libc6-dev ncurses-dev libcurl4-openssl-dev libopenssl-ruby apache2-prefork-dev libapr1-dev libaprutil1-dev libx11-dev libffi-dev tcl-dev tk-dev libcap2-bin libcairo2-dev libjpeg8-dev libpango1.0-dev libgif-dev build-essential libpixman-1-dev
}

# 重设rc.local引用的shell为bash
# sudo needed
rc-local() {
  rm /bin/sh
  ln -s /bin/bash /bin/sh
  cat <<<'#!/bin/sh' > /etc/rc.local
}

# 修改xdg用户目录的映射关系
setup-xdg-userdir() {
  for dir in ${XDG_USER_DIRS[@]}
  do
    read -p "custom name dir $dir (default to '$dir'):" name
    xdg-user-dirs-update --set $dir "${name:=$dir}"
  done
  echo "${USER}'s directory setup finished, see $XDG_USER_DIRS"
}

# 创建用户自定义目录
setup-user-dirs() {
  for dir in ${USER_DIRS[@]}
  do
    mkdir $dir
  done
  echo "${USER}'s extend directory setup finished, see $USER_DIRS"
}

# 配置DNS
config-dns() {
  cat <<<'nameserver $DNS_SERVER_ADDR' | tee -a >> /etc/network/interfaces | cat >> /etc/resolvconf/resolv.conf.d/base
}

# 安装辅助工具
# sudo needed
utility() {
  apt-get install dump curl traceroute sshd sshfs cifs-utils hostapd
}


# 赋予可执行文件特权
# sudo needed
setcap() {
  for entry in $@
  do
    setcap cap_net_bind_service=+ep $entry
  done
}

# 修改目录所有者
# sudo needed
mod-owner() {
  chown -R $USER /usr/local/{bin, lib, include}
}


# 配置git与github账户
config-github-account() {
  read -p 'github用户名:' name
  read -p 'github邮箱:' email

  # git
  git config --global user.name $name
  git config --global user.email $email
  for (( i = 0; i < ${#GIT_CONFIG[*]}; i++ )); do
    eval "git config --global ${GIT_CONFIG[$i]}"
  done

  # 生成SSH秘钥对
  ssh-keygen -t rsa -C $email
  ssh-add $SSH_KEY

  while true
  do
    echo "公钥路径: ${SSH_KEY}.pub"
    echo "复制公钥内容, 在github新建SSH-Key并粘贴. 完成这一步后输入y"
    read ok
    if [[ $ok == "y" ]]; then
      break
    fi
  done

  echo "系统中已添加的密钥:"
  ssh-add -l

  # 测试连接
  ssh -T git@github.com
}

# 挂载项设置
ntfs-auto-mount() {
  local mount-point
  for entry in $@
  do
    echo "选择$entry的挂载点:(默认$DEFAULT_MEDIA_MOUNT_POINT)"
    read mount-point
    [[ -d ${mount-point:=$DEFAULT_MEDIA_MOUNT_POINT} ]] && mkdir $mount-point
    echo "$entry $(get-exact-path) ntfs-3g auto,rw,uid=1000,gid=1000,umask=022,fmask=133,dmask=002 0 0" | sudo tee >> /etc/fstab
  done
}

# 代理设置
# sudo needed
config-proxy() {
  # 取消更改代理的身份验证机制
  cp ./proxy-settings.xml /usr/share/polkit-1/actions/com.ubuntu.systemservice.policy
}

# 恢复14.04之后的平滑字体
sudo apt-get remove fonts-arphic-ukai
sudo apt-get remove fonts-arphic-uming
