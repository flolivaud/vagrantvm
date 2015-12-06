# -*- mode: ruby -*-
# vi: set ft=ruby :
PHP_VERSION = "7" #5.4, 5.5, 5.6 or 7
WWW_DIRECTORY = "D:/www"

VAGRANTFILE_API_VERSION = "2"
SCRIPTS_DIRECTORY = "scripts"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if PHP_VERSION == "5.4"
    config.vm.box = "ubuntu/precise64"
  else
    config.vm.box = "ubuntu/trusty64"
  end

  #config.vm.box = "ubuntu/precise64"
  # config.vm.box_check_update = false
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "forwarded_port", guest: 8025, host: 8025

  # config.vm.network "private_network", ip: "192.168.56.101"
  # config.vm.network "public_network"

  config.vm.synced_folder WWW_DIRECTORY, "/var/www"

  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end

  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision :shell, path: "#{SCRIPTS_DIRECTORY}/provision-once.sh", args: "#{PHP_VERSION}"
  config.vm.provision :shell, path: "#{SCRIPTS_DIRECTORY}/provision-always.sh", args: "#{PHP_VERSION}"
end
