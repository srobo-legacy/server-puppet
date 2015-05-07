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

0. Clone the dummy-secrets alongside this repo (`git clone git://srobo.org/server/dummy-secrets.git ../dummy-secrets`)
1. Install VirtualBox, usually in your distro's repos, or https://www.virtualbox.org/wiki/Downloads
2. Install Vagrant, usually in your distro's repos, or http://www.vagrantup.com/downloads.html
3. Run `vagrant up --provision`
4. Wait a while, depending on your internet connection
5. Run `vagrant ssh` to log into the box. You have passwordless sudo from the
   vagrant user to root. In case you need to know the password it's 'vagrant'.
6. Configure a hosts entry (add the following line to `/etc/hosts` on the
   *host* machine): `192.168.42.42 sr-vm sr-vm.local`
7. Point your browser at <https://sr-vm> to see the website the VM is hosting.
