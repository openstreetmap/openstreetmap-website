# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # use official debian image
  config.vm.box = "debian/bookworm64"

  # configure virtualbox provider
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.synced_folder ".", "/srv/openstreetmap-website"
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
  end

  # Use sshfs sharing if available, otherwise NFS sharing
  sharing_type = Vagrant.has_plugin?("vagrant-sshfs") ? "sshfs" : "nfs"

  # configure lxc provider
  config.vm.provider "lxc" do |_, override|
    override.vm.synced_folder ".", "/srv/openstreetmap-website", :type => sharing_type
  end

  # configure libvirt provider
  config.vm.provider "libvirt" do |libvirt, override|
    override.vm.synced_folder ".", "/srv/openstreetmap-website", :type => sharing_type
    libvirt.memory = 4096
    libvirt.cpus = 2
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
