#! /bin/bash

set -e

# runs on first login to set up and save firewall rules

SSH_PORT=REPLACE_ME

read -p "$(echo -e "\e[32mWelcome! The last thing we need to do is set up and save firewall rules. Do you want to do this now (y/n)?\e[0m ")" yn

if [[ ! $yn =~ ^[Yy]$ ]]
then
  echo "Goodbye. This script will run again next time you log in."
  exit
fi

# allow return traffic for outgoing connections initiated by the server itself
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# allow loopback traffic from localhost
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
# allow http, https, ssh
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443,$SSH_PORT -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# set input policy to drop everything else
sudo iptables --policy INPUT DROP

sudo apt install iptables-persistent -y

# don't need to run this as it runs automatically on install
# sudo netfilter-persistent save

echo -e "\n\e[32mFirewall configured 👍. If you didn't save rules, please run sudo netfilter-persistent save :)\e[0m\n"

rm ~/firewall.sh