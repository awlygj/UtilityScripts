#安装编译需要的依赖开发库和软件包
su - root
cd ~

apt-get update
apt-get install build-essential \
	        linux-headers-amd64 \
		curl \
		tree \
		locales-all \
		sudo \
		vim \
		git \
		libbison-dev \
		llvm-dev \
		clang \
		pkg-config \
		liblz4-dev \
		libzstd-dev \
		libbison-dev \
		flex \
		python3-dev \
		libreadline-dev \
		libkrb5-dev \
		libssl-dev \
		libpam0g-dev \
		libxslt1-dev \
		libldap-dev \
		uuid-dev \
		libselinux1-dev \
		libsystemd-dev \
		gettext \
		tcl-dev \
		libperl-dev \
		libxml2-utils \
		docbook-website \
		xsltproc \
		pspg
apt-get clean
apt-get autoremove

#dpkg -l | grep locales 
#apt-cache search locales
#apt-cache show locales

#安装vbox扩展
mount -t auto /dev/cdrom
ls /media/cdrom
cp /media/cdrom/VBoxLinuxAdditions.run .
./VBoxLinuxAdditions.run
rm VBoxLinuxAdditions.run
umount -t auto /dev/cdrom
eject

#配置vim
vim /usr/share/vim/vim90/defaults.vim
set mouse=

#配置网络ip
vim /etc/network/interfaces
# The primary network interface
auto enp0s17
allow-hotplug enp0s17

#iface enp0s17 inet dhcp
iface enp0s17 inet static
        address 192.168.8.11/24
        gateway 192.168.8.1
	#dns-nameservers 192.168.8.1

#iface enp0s17 inet6 dhcp	
iface enp0s17 inet6 static
        address fe80::11/64
        gateway fe80::9294:97ff:fe45:de52

#vim /etc/dhcp/dhclient.conf
#prepend domain-name-servers 192.168.8.1;

vim /etc/resolv.conf
nameserver 192.168.8.1
nameserver fe80::9294:97ff:fe45:de52%enp0s17
	
systemctl restart networking.service
cat /etc/network/interfaces
cat /etc/resolv.conf
ip address
ip route
ip -6 route

#配置系统操作用户的sudo权限
groups my-user-name #看看有没有sudo组，有则去掉
sudoedit /etc/sudoers
my-user-name    ALL=(ALL)  NOPASSWD:ALL

logout

#配置系统操作用户的环境变量
cd ~

vim .bashrc
alias la='ls -lhaF'
alias ll='ls -lhF'

. .bashrc

#配置系统操作用户的ssh public key登入
sudo vim /etc/ssh/sshd_config
PermitRootLogin no #prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
AllowTcpForwarding yes
X11Forwarding yes

mkdir .ssh

vim .ssh/authorized_keys
ssh-ed25519 ******************************************************************** eddsa-key-yyyymmdd

chmod -R go-xr .ssh
la .ssh
sudo systemctl restart sshd.service
sudo systemctl status sshd.service

#删除root和my-user-name的密码
sudo passwd -d root
sudo passwd -l root
sudo passwd -d my-user-name
sudo passwd -l my-user-name

#下载pg的git仓库
mkdir git-repository
cd git-repository
git clone git://git.postgresql.org/git/postgresql.git
cd postgresql
git tag
git checkout tags/REL_17_4
git describe --tags
git status

#编译和安装PG
mkdir build_dir
cd build_dir
../configure --enable-nls \
             --with-perl \
             --with-python \
             --with-tcl \
             --with-icu \
             --with-llvm \
             --with-lz4  \
             --with-zstd \
             --with-openssl \
             --with-gssapi \
             --with-ldap  \
             --with-pam \
             --with-systemd \
             --with-uuid=e2fs \
             --with-libxml \
             --with-libxslt \
             --with-selinux
make world
make check
sudo make install-world
make distclean

rm -rf build_dir/
la /usr/local/pgsql/
tree /usr/local/pgsql/

#设置systemd unit
sudo vim /etc/systemd/system/postgresql.service
[Unit]
Description=PostgreSQL database server
Documentation=man:postgres(1)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=postgres
ExecStart=/usr/local/pgsql/bin/postgres -D /var/lib/pgsql/data
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutSec=infinity

[Install]
WantedBy=multi-user.target

#创建postgres用户和组
sudo useradd -d /home/postgres -m -r -s /bin/bash -U postgres
#sudo passwd postgres

#设置postgres环境变量
sudo vim /home/postgres/.bashrc
alias la='ls -lhaF'
alias ll='ls -lhF'

LD_LIBRARY_PATH=/usr/local/pgsql/lib
export LD_LIBRARY_PATH

PATH=/usr/local/pgsql/bin:$PATH
export PATH

MANPATH=/usr/local/pgsql/share/man:$MANPATH
export MANPATH

PGDATA=/var/lib/pgsql/data/
export PGDATA

#PGHOST=localhost
#export PGHOST

PGPORT=5432
export PGPORT

PGDATABASE=postgres
export PGDATABASE

PGUSER=postgres
export PGUSER

PG_COLOR=auto
export PG_COLOR

PSQL_PAGER=pspg
export PSQL_PAGER

TZ=Asia/Shanghai
export TZ

#系统基础信息
df -h
hostnamectl
timedatectl
locale -a

sudo sysctl -a | grep sem
sudo sysctl -a | grep shm
sudo sysctl fs.file-max
sudo sysctl net.core.somaxconn
sudo sysctl vm.overcommit_ratio

sudo su - postgres
ulimit -a

env | grep PATH
env | grep TZ
env | grep ^PG

logout

#设置系统资源限制
sudo vim /etc/security/limits.conf
postgres soft nofile unlimited
postgres soft nproc  unlimited
postgres soft memlock unlimited
postgres hard nofile unlimited
postgres hard nproc  unlimited
postgres hard memlock unlimited

cat /etc/security/limits.conf

sudo vim /etc/sysctl.conf
vm.overcommit_memory=2
net.core.somaxconn=65535

sudo sysctl -p
sudo sysctl -a | grep -E '(vm\.overcommit_memory|net\.core\.somaxconn)'

sudo reboot

#创建集簇
sudo mkdir -p /var/lib/pgsql/data
sudo chown -R postgres:postgres /var/lib/pgsql
la /var/lib/pgsql/

sudo su - postgres
initdb --auth-host=scram-sha-256 \
       -D /var/lib/pgsql/data/ \
       -E UTF8 \
       --icu-locale=zh_Hans_CN \
       --locale=zh_CN.utf8 \
       --locale-provider=icu
la /var/lib/pgsql/data/
tree /var/lib/pgsql/data/

vim /var/lib/pgsql/data/postgresql.conf
max_connections = 1024
shared_buffers = 768MB
unix_socket_group = 'postgres'
unix_socket_permissions = 0770

cat /var/lib/pgsql/data/pg_hba.conf

logout

sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service
sudo systemctl status postgresql.service

#设置内存大页
sudo systemctl stop postgresql.service

sudo su - postgres
postgres -D $PGDATA -C shared_memory_size_in_huge_pages
logout

grep ^Hugepagesize /proc/meminfo
ls /sys/kernel/mm/hugepages

id postgres
sudo sysctl vm.hugetlb_shm_group

sudo vim /etc/sysctl.conf
vm.nr_hugepages=100
vm.hugetlb_shm_group=994

sudo sysctl -p
sudo sysctl -a | grep -E '(vm\.nr_hugepages|vm\.hugetlb_shm_group)'
cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

sudo reboot

