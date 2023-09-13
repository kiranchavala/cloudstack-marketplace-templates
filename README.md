Cloudstack Market Place Templates

Packer templates source for a Cloudstack based cloud.


Requirements

To build these templates for Cloudstack make sure you have the following tools installed:

    packer
    ovftool
    qemu/qemu-img


Steps to install Packer on a Preffered Linux Distribution 

https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli



Steps to install Ovf tool 

sudo ./VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --extract ovftool && cd ovftool
sudo mv vmware-ovftool /usr/bin/
sudo chmod +x /usr/bin/vmware-ovftool/ovftool.bin
sudo chmod +x /usr/bin/vmware-ovftool/ovftool
alias ovftool=/usr/bin/vmware-ovftool/ovftool

Steps to install qemu/qemu-img tool

https://computingforgeeks.com/install-kvm-centos-rhel-ubuntu-debian-sles-arch/


Generating a Specific Application involves the following steps 

1. Generate the Golden base image for a specific OS 

git clone ""

cd 

2. Register the Golden base image for a speciic OS and a Hypervisor on Cloudstack 

#Optional step

3. Register the user-data to the Gloden base image

4. Generate the Application based Golden image for the Specific OS









Licensing
The Cloudstack Packer Templates are licensed under the Apache License, Version 2.0. See LICENSE for the full license text.