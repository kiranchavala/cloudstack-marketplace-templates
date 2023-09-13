# Cloudstack Market Place Templates

Packer templates for a Cloudstack based cloud.

The following tool will generate Cloudinit based templates for Cloudstack and also specific application templates which can be readily used in Cloudstack.


***Requirements***

To build these templates for Cloudstack make sure you have the following tools installed:

    packer
    ovftool
    qemu/qemu-img


***Steps to install Packer on a Preffered Linux Distribution***

```
https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
```


***Steps to install Ovf tool*** 

```
sudo ./VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --extract ovftool && cd ovftool
sudo mv vmware-ovftool /usr/bin/
sudo chmod +x /usr/bin/vmware-ovftool/ovftool.bin
sudo chmod +x /usr/bin/vmware-ovftool/ovftool
alias ovftool=/usr/bin/vmware-ovftool/ovftool
```

Steps to install qemu/qemu-img tool

```
https://computingforgeeks.com/install-kvm-centos-rhel-ubuntu-debian-sles-arch/

```

Generating a specific Application involves the following steps 

***
1. Generate the Golden base image (Cloud init enabled) for a specific OS 

This will generate templates based on the hypervisor and os 


```
git clone ""

cd cloudstack-marketplace-templates
packer build <guestos.phr.hcl>

Example

packer build ubuntu-22.04.pkr.hcl
```

This will generate, the qcow2, vhd and ova format templates for the respective os 

***

2. Register the Golden base image for a speciic OS and a Hypervisor on Cloudstack 

Images> Template > 

Screenshot

***
3. Register the following user-data to the Gloden base image templates 

#cloud-config
chpasswd:
  list: |
    root:password
  expire: False

***
4. Generate the Application based Golden image for the Specific OS


Currently the applications that have a packer template are 

Docker
wordpress
phpmyadmin


Replace the following variables values in the application HCL files based with your respective cloudstack credentials 

```

variable "cloudstack_api_url" {
    description = "The api url of Cloudstack Account."
    default = "http://10.0.34.193:8080/client/api"

}
variable "cloudstack_api_key" {
    description = "The api key of your Cloudstack Account."
    default = "LIN6rqXuaJwMPfGYFh13qDwYz5VNNz1J2J6qIOWcd3oLQOq0WtD4CwRundBL6rzXToa3lQOC_vKjI3nkHtiD8Q"
}
variable "cloudstack_secret_key" {
    description = "The secret key of your Cloudstack Account."
    default = "R6QPwRUz09TVXBjXNwZk7grTjcPtsFRphH6xhN1oPvnc12YUk296t4KHytg8zRLczDA0X5NsLVi4d8rfMMx3yg"
}
variable "network" {
    description ="Network UUID"
    default="37b699ec-c176-4c81-a2d6-1daf08df30a7"
}
variable "zone" {
    description = "Zone UUID"
    default = "86d9a63a-3d0b-466f-8f32-81cefc39e31d"
}
variable "service_offering" {
    description ="Service Offering UUID"
    default="784c5df8-defa-4eca-8347-9db8ce38ef9a"
}
variable "template_os" {
    description ="The Guest os id  of the template."
    default="849c97eb-34e6-48bd-80ba-68c9a2a84704"
}
variable "source_template"{
    description ="The name or ID of the template used as base template for the instance"
    default="0c08d357-f3c9-4104-a96f-07e65a23c126"
}

```
```
packer build <application.pkr.hcl>

Example

packer build docker-22-04.pkr.hcl

The packer application template will be generated in your Cloudstack Cloud

```
Images> Template > 

***

5. Deploy the application template

Login to the instance and check the application info

```
cat /var/lib/cloudstack/application.info
```


Licensing

The Cloudstack Packer Templates are licensed under the Apache License, Version 2.0. See LICENSE for the full license text.