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
  default = "sha256:84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
}

variable "name" {
  type    = string
  default = "ubuntu-22.04"
}

variable "url" {
  type    = string
  default = "http://compute.o.auroraobjects.eu/iso/ubuntu-22.04-live-server-amd64.iso"
}

locals{
  arg1="${path.cwd}/build_${var.name}/${var.name}"
  arg2="${path.cwd}/build_${var.name}/${var.name}.vmdk"
}


source "qemu" "ubuntu-qemu" {
  accelerator            = "kvm"
  boot_command           = ["<esc><esc><esc><esc>e<wait>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del>", "<del><del><del><del><del><del><del><del><del>", "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<enter><wait>", "initrd /casper/initrd<enter><wait>", "boot<enter>", "<enter><f10><wait>"]
  boot_wait              = "2s"
  communicator           = "ssh"
  cpus                   = 2
  disk_compression       = true
  disk_discard           = "unmap"
  disk_interface         = "virtio-scsi"
  disk_size              = "8G"
  format                 = "qcow2"
  headless               = true
  http_directory         = "${path.root}/files/ubuntu-22.04"
  http_port_max          = 8100
  http_port_min          = 8000
  iso_checksum           = "${var.iso_checksum}"
  iso_url                = "${var.url}"
  memory                 = 2048
  output_directory       = "build_${var.name}"
  #qemu_binary            = "qemu-system-x86_64"
  ssh_handshake_attempts = "200"
  ssh_password           = "58p5wMfpyTQhqa4Q"
  ssh_username           = "root"
  ssh_wait_timeout       = "30m"
  vm_name                = "${var.name}"
  vnc_bind_address       = "[::]"
}



build {
  sources = ["source.qemu.ubuntu-qemu"]

  provisioner "file" {
    destination = "/etc/apt/sources.list"
    source      = "${path.root}/files/apt/ubuntu-22.04.sources"
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
    destination = "/etc/netplan/01-netcfg.yaml"
    source      = "${path.root}/files/ubuntu-22.04/01-netcfg.yaml"
  }

  provisioner "file" {
    destination = "/etc/sysctl.d/99-disable-ipv6-tempaddr.conf"
    source      = "${path.root}/files/generic/99-disable-ipv6-tempaddr.conf"
  }

  provisioner "shell" {
    execute_command = "sh '{{ .Path }}'"
    scripts         = ["${path.root}/scripts/ubuntu-22.04/remove-swap.sh"]
  }

  provisioner "shell" {
    execute_command = "sudo sh '{{ .Path }}'"
    scripts         = ["${path.root}/scripts/ubuntu-22.04/post.sh"]
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
      script           = "${path.root}/scripts/ubuntu-22.04/vmdk-ova.sh"

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
