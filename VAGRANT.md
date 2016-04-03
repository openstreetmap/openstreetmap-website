# Installing Vagrant

On Ubuntu, it should be as simple as:

```
sudo apt-get install vagrant
```

Other Linux distributions should have similar installation instructions using `yum` or similar.

Installers are available for Mac OS X and Windows, please see the [Vagrant project download page](http://www.vagrantup.com/downloads.html) for more information.

# Setting up openstreetmap-website

Once Vagrant has been installed, you can start an environment by checking out the openstreetmap-website code if you haven't already, then changing to the directory which contains the Vagrantfile by typing:

```
git clone git@github.com:openstreetmap/openstreetmap-website.git
cd openstreetmap-website
vagrant up
```

This will take a few minutes to download required software from the internet and set it up as a running system. Once it is complete, you should be able to log into the running VM by typing:

```
vagrant ssh
```

Within this login shell, you can do development, run the server or the tests. For example, to run the tests:

```
cd /srv/openstreetmap-website/
rake test
```

To access the web pages you run the following commands then access the site in your [local browser](http://localhost:3000):

```
vagrant ssh
cd /srv/openstreetmap-website/
rails server --binding=0.0.0.0
```

You edit the code on your computer using the code editor you are used to using, then through shared folders the code is updated on the VM instantly.

You should run the tests before submitting any patch or Pull Request back to the original repository. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.
