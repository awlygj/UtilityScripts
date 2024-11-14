#install package
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install build-essential

sudo mount /dev/cdrom /cdrom
cp /cdrom/VBoxLinuxAdditions.run .
sudo ./VBoxLinuxAdditions.run
rm VBoxLinuxAdditions.run
sudo eject

sudo apt-get clean

#diable ipv6
sudo vim /etc/default/grub
#find GRUB_CMDLINE_LINUX_DEFAULT and add ipv6.disable=1
GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1"

sudo update-grub
sudo reboot
ip a

#set timezone
sudo timedatectl set-timezone "Asia/Shanghai"
sudo timedatectl

#intall mssql
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list

sudo apt-get update
sudo apt-get install -y mssql-server

sudo MSSQL_LCID=2052 \
MSSQL_ENABLE_HADR=1 \
MSSQL_AGENT_ENABLED=true \
ACCEPT_EULA=yes \
MSSQL_SA_PASSWORD="rootme@123" \
MSSQL_PID=Developer \
MSSQL_MEMORY_LIMIT_MB=6600 \
/opt/mssql/bin/mssql-conf setup

systemctl status mssql-server --no-pager

#verify time zone
sqlcmd -C -Usa -Q "select CURRENT_TIMEZONE();"

#install cli tools
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

sudo apt-get update
sudo apt-get install mssql-tools18 unixodbc-dev

echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc

#config msdtc
sudo /opt/mssql/bin/mssql-conf set network.rpcport 13500
sudo /opt/mssql/bin/mssql-conf set distributedtransaction.servertcpport 51000
sudo systemctl restart mssql-server

sudo ufw enable
sudo ufw allow from any to any port 1433 proto tcp
sudo ufw allow from any to any port 51000 proto tcp
sudo ufw allow from any to any port 135 proto tcp
sudo ufw allow from any to any port 13500 proto tcp
sudo ufw allow from any to any app OpenSSH
sudo ufw status verbose

sudo iptables -t nat -A PREROUTING -d 192.168.1.101 -p tcp --dport 135 -m addrtype --dst-type LOCAL  \
   -j DNAT --to-destination 192.168.1.101:13500 -m comment --comment RpcEndPointMapper
sudo iptables -t nat -A OUTPUT -d 192.168.1.101 -p tcp --dport 135 -m addrtype --dst-type LOCAL \
   -j DNAT --to-destination 192.168.1.101:13500 -m comment --comment RpcEndPointMapper

sudo iptables -S -t nat | grep "RpcEndPointMapper"

#persistent iptables rule when reboot
sudo apt-get install iptables-persistent
#sudo netfilter-persistent save
#sudo netfilter-persistent reload

#delete iptables rule
#sudo iptables -S -t nat | grep "RpcEndPointMapper" | sed 's/^-A //' | while read rule; do sudo iptables -t nat -D $rule; done

