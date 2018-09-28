# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # use official ubuntu image for virtualbox
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.box = "ubuntu/bionic64"
    override.vm.synced_folder ".", "/srv/openstreetmap-website"
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
  end

  # use third party image and NFS sharing for lxc
  config.vm.provider "lxc" do |_, override|
    override.vm.box = "generic/ubuntu1804"
    override.vm.synced_folder ".", "/srv/openstreetmap-website", :type => "nfs"
  end

  # use third party image and NFS sharing for libvirt
  config.vm.provider "libvirt" do |_, override|
    override.vm.box = "generic/ubuntu1804"
    override.vm.synced_folder ".", "/srv/openstreetmap-website", :type => "nfs"
  end

  # configure shared package cache if possible
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.enable :apt
    config.cache.scope = :box
  end

  # port forward for webrick on 3000
  config.vm.network :forwarded_port, :guest => 3000, :host => 3000

  # provision using a simple shell script
  config.vm.provision :shell, :path => "script/vagrant/setup/provision.sh"
end
