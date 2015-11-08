#SRobo Server puppet

This is the puppet config for our server.

High level documentation and how to get started with this all lies at:

https://www.studentrobotics.org/trac/wiki/ServerConfig

##Linting

`puppet-lint` can be used to lint the puppet. To use it do these things:

0. Have ruby
1. `bundle install`
2. `bundle exec rake lint`

##Vagrant Setup

1. Initialise the submodules (`git submodule update --init --recursive`)
2. Clone the dummy-secrets alongside this repo (`git clone git://srobo.org/server/dummy-secrets.git ../dummy-secrets`)
3. Install VirtualBox, usually in your distro's repos, or https://www.virtualbox.org/wiki/Downloads
4. Install Vagrant, usually in your distro's repos, or http://www.vagrantup.com/downloads.html
5. Run `vagrant up --provision`
6. Wait a while, depending on your internet connection
7. Run `vagrant ssh` to log into the box. You have passwordless sudo from the
   vagrant user to root. In case you need to know the password it's 'vagrant'.
8. Configure a hosts entry (add the following line to `/etc/hosts` on the
   *host* machine): `192.168.42.42 sr-vm sr-vm.local`
9. Point your browser at <https://sr-vm> to see the website the VM is hosting.
