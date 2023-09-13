packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}



variable "iso_checksum" {
  type    = string
  default = "sha256:b79079ad71cc3c5ceb3561fff348a1b67ee37f71f4cddfec09480d4589c191d6"
}

variable "name" {
  type    = string
  default = "centos-7"
}

variable "url" {
  type    = string
  default = "http://compute.o.auroraobjects.eu/iso/CentOS-7-x86_64-NetInstall-2009.iso"
}

locals{
  arg1="${path.cwd}/build_${var.name}/${var.name}"
  arg2="${path.cwd}/build_${var.name}/${var.name}.vmdk"
}

source "qemu" "centos-qemu" {
  accelerator      = "kvm"
  boot_command     = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart/centos-7.ks<enter><wait>"]
  communicator     = "ssh"
  cpus             = 2
  disk_compression = true
  disk_discard     = "unmap"
  disk_interface   = "virtio-scsi"
  disk_size        = "8G"
  format           = "qcow2"
  headless         = true
  http_directory   = "${path.root}/files"
  http_port_max    = 8100
  http_port_min    = 8000
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.url}"
  memory           = 2048
  output_directory = "build_${var.name}"
  ssh_password     = "UnZkE8EcCpPzYbvN"
  ssh_username     = "root"
  ssh_wait_timeout = "30m"
  vm_name          = "${var.name}"
  vnc_bind_address = "[::]"
}

build {
  sources = ["source.qemu.centos-qemu"]

  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "${path.root}/files/generic/cloud-init.cfg"
  }

  provisioner "file" {
    destination = "/etc/watchdog.conf"
    source      = "${path.root}/files/generic/watchdog.conf"
  }

  provisioner "file" {
    destination = "/etc/sysctl.d/99-disable-ipv6-tempaddr.conf"
    source      = "${path.root}/files/generic/99-disable-ipv6-tempaddr.conf"
  }

  provisioner "file" {
    destination = "/etc/NetworkManager/conf.d/90-dns-none.conf"
    source      = "${path.root}/files/centos/90-dns-none.conf"
  }

  provisioner "shell" {
    execute_command = "sh '{{ .Path }}'"
    scripts         = ["${path.root}/scripts/centos-7/post.sh"]
  }

  provisioner "shell" {
    inline = ["fstrim -v /"]
  }

post-processors {

    post-processor "shell-local" {
      #rename the build to qcow2 format
      command = "mv build_${var.name}/${var.name} build_${var.name}/${var.name}.qcow2"
    }
    
     post-processor "shell-local" {
      #generate the vmdk file
      command = "qemu-img convert -f qcow2 -O vmdk -o subformat=streamOptimized build_${var.name}/${var.name}.qcow2 build_${var.name}/${var.name}.vmdk"
      
    }
    
     post-processor "shell-local" {
      #generate the vhd file
      command = "qemu-img convert -f qcow2 -O vpc -o subformat=dynamic build_${var.name}/${var.name}.qcow2 build_${var.name}/${var.name}.vhd"
      
    }
      post-processor "shell-local" {
       #genrate the ova file  
      script           = "${path.root}/scripts/centos-7/vmdk-ova.sh"

      execute_command  = [
      "/bin/sh",
      "-c",
      " {{.Script}} ${local.arg1} ${local.arg2}"
      ]   
    }

     post-processor "artifice" {
      files = ["build_${var.name}/${var.name}.qcow2"]
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "build_${var.name}/${var.name}.checksum"
    }
    post-processor "manifest" {
      custom_data = {
        oscategory    = "${var.name}"
        osversion     = "${var.name}"
        template_slug = "${var.name}"
      }
      output     = "build_${var.name}/${var.name}.json"
      strip_path = true
    }
}
  
}
