# Partition clearing information
clearpart --none --initlabel

# Use text based install
text
eula --agreed

# Network
network  --bootproto=dhcp --device=ens4 --ipv6=auto --activate
network  --hostname=cloudlinux8

# Repos
url --url=http://repo.cloudlinux.com/cloudlinux/8/BaseOS/x86_64/os
repo --name="AppStream" --baseurl=http://repo.cloudlinux.com/cloudlinux/8/AppStream/x86_64/os

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Root password
rootpw --plaintext UuCMEMmBXQyyjGYv

# Disable the Setup Agent on first boot
firstboot --disabled

# Do not configure the X Window System
skipx

# System services
services --enabled="chronyd"

# System timezone
timezone Europe/Amsterdam --isUtc

# Disk partitioning information
part / --fstype xfs --fsoptions="rw,noatime" --size=1 --grow

# Enable SELinux
selinux --disabled

# Package installation
%packages
@^minimal-environment
qemu-guest-agent
cloud-init
cloud-utils-growpart
curl
wget
-alsa-*
-ivtv*
-iwl*firmware
%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

# Post scripts
%post
dnf remove -y linux-firmware
dnf update -y
dnf clean all
sed -i '/^disable_root/s/1/0/ ; /^disable_root/s/true/false/ ; /^ssh_pwauth/s/0/1/ ; /^ssh_pwauth/s/false/true/' /etc/cloud/cloud.cfg
%end

reboot
