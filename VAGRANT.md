# Installing Vagrant

On Ubuntu, it should be as simple as:

```
sudo apt-get install vagrant
```

Other Linux distributions should have similar installation instructions using `yum` or similar.

Installers are available for Mac OS X and Windows, please see the [Vagrant project download page](http://www.vagrantup.com/downloads) for more information.

# Setting up openstreetmap-website

Once Vagrant has been installed, you can start an environment by changing to the directory which contains the Vagrantfile and typing:

```
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

You should run the tests before submitting any patch or Pull Request back to the original repository. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.
