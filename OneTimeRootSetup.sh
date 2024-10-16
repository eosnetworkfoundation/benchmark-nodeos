#!/bin/bash

## packages ##
apt-get update >> /dev/null
apt-get install -y git unzip jq curl nginx python3 python3-pip sysstat

## aws cli ##
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp/ >> /dev/null
/tmp/aws/install

## new user ##
USER="enf-replay"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbQbXU9uyqGwpeZxjeGR3Yqw8ku5iBxaKqzZgqHhphS support@eosnetwork.com - ANY"

## does the user already exist ##
if getent passwd "${USER}" > /dev/null 2>&1; then
    echo "yes the user exists"
    exit 0
else
    echo "Creating user ${USER}"
fi

KEY_SIZE=$(echo "${PUBLIC_KEY}" | cut -d' ' -f2 | wc -c)
if [ "$KEY_SIZE" -lt 33 ]; then
    echo "Invalid public key"
    exit 1
fi

## gecos non-interactive ##
adduser "${USER}" --disabled-password --gecos ""
sudo -u "${USER}" -- sh -c "mkdir /home/enf-replay/.ssh && chmod 700 /home/enf-replay/.ssh && touch /home/enf-replay/.ssh/authorized_keys && chmod 600 /home/enf-replay/.ssh/authorized_keys"
echo "$PUBLIC_KEY" | sudo -u "${USER}" tee -a /home/enf-replay/.ssh/authorized_keys

## setup data device ##
echo "setting up ext4 /dev/xvdb volume"
mkdir /data
mkfs.ext4 /dev/nvme1n1
mount -o rw,acl,user_xattr /dev/nvme1n1 /data
chmod 777 /data

## create swap
# 128Gb = 131072Mb = 134217728Kb
SWAPFILE=/data/swapfile
dd if=/dev/zero of="${SWAPFILE}" bs=1024 count=134217728
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"

## install nodeos
curl -L --output /tmp/antelope-spring_1.0.2_amd64.deb https://github.com/AntelopeIO/spring/releases/download/v1.0.2/antelope-spring_1.0.2_amd64.deb
dpkg -i /tmp/antelope-spring_1.0.2_amd64.deb
## install CDT
apt-get install libcurl4-gnutls-dev
curl -L --output /tmp/cdt_4.1.0-1_amd64.deb https://github.com/AntelopeIO/cdt/releases/download/v4.1.0/cdt_4.1.0-1_amd64.deb
dpkg -i /tmp/cdt_4.1.0-1_amd64.deb

# build system contracts
cd /home/${USER} || exit
sudo -u ${USER} git clone --depth 1 --branch v3.6.0 https://github.com/eosnetworkfoundation/eos-system-contracts.git

cd eos-system-contracts || exit
sudo -u ${USER} mkdir build
cd build || exit
apt-get install cmake
sudo -u ${USER} cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF ..
sudo -u ${USER} make -j $(nproc)

# install ABI for trace files
mkdir -p /opt/chainuser/eos-system-contracts/contracts
chmod 777 /opt/chainuser/eos-system-contracts/contracts
for contract in eosio.bios eosio.boot eosio.msig eosio.system eosio.token eosio.wrap
do
  sudo -u ${USER} mkdir /opt/chainuser/eos-system-contracts/contracts/${contract}
  sudo -u ${USER} cp contracts/${contract}/${contract}.abi /opt/chainuser/eos-system-contracts/contracts/${contract}
done
