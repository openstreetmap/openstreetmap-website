# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "sputnik13/trusty64"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.enable :apt
    config.cache.scope = :box
  end

  # port forward for webrick on 3000
  config.vm.network :forwarded_port, :guest => 3000, :host => 3000

  # set up synced folder to source in /srv/openstreetmap-website
  config.vm.synced_folder ".", "/srv/openstreetmap-website",
    :rsync__exclude => ["config/application.yml", "config/database.yml"]

  # provision using a simple shell script
  config.vm.provision :shell, :path => "script/vagrant/setup/provision.sh"
end
