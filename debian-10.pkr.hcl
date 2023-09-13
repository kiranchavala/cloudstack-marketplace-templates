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
  default = "sha256:b317d87b0a3d5b568f48a92dcabfc4bc51fe58d9f67ca13b013f1b8329d1306d"
}

variable "name" {
  type    = string
  default = "debian-10"
}

variable "url" {
  type    = string
  default = "http://compute.o.auroraobjects.eu/iso/debian-10.7.0-amd64-netinst.iso"
}

locals{
  arg1="${path.cwd}/build_${var.name}/${var.name}"
  arg2="${path.cwd}/build_${var.name}/${var.name}.vmdk"
}



source "qemu" "debian-qemu" {
  accelerator      = "kvm"
  boot_command     = ["<esc><wait5>install <wait> preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed/debian-10.preseed debian-installer=en_US auto locale=en_US kbd-chooser/method=us keyboard-configuration/xkb-keymap=us netcfg/get_hostname=debian10 netcfg/get_domain=auroracompute.com fb=false debconf/frontend=noninteractive console-setup/ask_detect=false <wait> console-keymaps-at/keymap=us <wait><enter>"]
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
  ssh_password     = "PVT6HXW4t7PDy7Pb"
  ssh_username     = "root"
  ssh_wait_timeout = "30m"
  vm_name          = "${var.name}"
  vnc_bind_address = "[::]"
}

build {
  sources = ["source.qemu.debian-qemu"]

  provisioner "file" {
    destination = "/etc/apt/sources.list"
    source      = "${path.root}/files/apt/debian-10.sources"
  }

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

 
  provisioner "shell" {
    execute_command = "sudo sh '{{ .Path }}'"
    scripts         = ["${path.root}/scripts/debian-10/post.sh"]
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
      script           = "${path.root}/scripts/debian-10/vmdk-ova.sh"

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

