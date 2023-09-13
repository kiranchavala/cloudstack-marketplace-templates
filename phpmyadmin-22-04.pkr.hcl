packer {
  required_plugins {
    cloudstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/cloudstack"
    }
  }
}
variable "application_name" {
  type    = string
  default = "phpMyAdmin"
}

variable "application_version" {
  type    = string
  default = "5.2.1"
}

variable "apt_packages" {
  type    = string
  default = "apache2 apache2-utils mysql-server php php-gd php-mysql phpmyadmin python3-certbot-apache libapache2-mod-php lamp-server^"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

locals {
  image_name = "phpmyadmin-22-04-snapshot-${local.timestamp}"
}

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
    description ="The Guest os of the template."
    default="849c97eb-34e6-48bd-80ba-68c9a2a84704"
}
variable "source_template"{
    description ="The name or ID of the template used as base template for the instance"
    default="0c08d357-f3c9-4104-a96f-07e65a23c126"
}


source "cloudstack" "phpmyadmin-template" {
    api_key = var.cloudstack_api_key
    api_url = var.cloudstack_api_url
    network = var.network
    secret_key = var.cloudstack_secret_key
    service_offering = var.service_offering
    source_template = var.source_template
    ssh_username = "root"
    ssh_password = "password"
    template_os = var.template_os
    zone = var.zone
    expunge = true
    #user_data="I2Nsb3VkLWNvbmZpZwpjaHBhc3N3ZDoKICBsaXN0OiB8CiAgICByb290OnBhc3N3b3JkCiAgZXhwaXJlOiBGYWxzZQ=="
    communicator = "ssh"
    ssh_timeout = "20m"
    template_name = "${local.image_name}"
    template_public = "true"
    template_display_text = "${local.image_name}"
    template_featured = "true"
    template_password_enabled = "true"

}

build {
  sources = ["source.cloudstack.phpmyadmin-template"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "file" {
    destination = "/var/"
    source      = "${path.root}/common/files/var/"
  }

  provisioner "file" {
    destination = "/etc/"
    source      = "${path.root}/mysql-20-04/files/etc/"
  }

  provisioner "file" {
    destination = "/var/"
    source      = "${path.root}/mysql-20-04/files/var/"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    inline           = ["apt -qqy update", "apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade", "apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ${var.apt_packages}", "apt-get -qqy clean"]
  }

  provisioner "shell" {
    environment_vars = ["application_name=${var.application_name}", "application_version=${var.application_version}", "phpmyadmin_version=${var.application_version}", "DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    scripts          = ["${path.root}/phpmyadmin-22-04/scripts/010-php-my-admin.sh", "${path.root}/common/scripts/014-ufw-apache.sh", "${path.root}/common/scripts/014-ufw-mysql.sh",  "${path.root}/common/scripts/020-application-tag.sh", "${path.root}/common/scripts/900-cleanup.sh"]
  }

}