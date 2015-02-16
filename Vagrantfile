# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # port forward for webrick on 3000
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  # set up synced folder to source in /srv/openstreetmap-website
  config.vm.synced_folder ".", "/srv/openstreetmap-website"

  # provision using a simple shell script
  config.vm.provision :shell, :path => "script/vagrant/setup/provision.sh"
end
