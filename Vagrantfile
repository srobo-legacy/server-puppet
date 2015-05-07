Vagrant.configure("2") do |config|

    config.vm.box = "chef/fedora-20"
    config.vm.box_url = "https://vagrantcloud.com/chef/boxes/fedora-20/versions/1.0.0/providers/virtualbox.box"

    config.vm.provider "virtualbox" do |v|
        # The box defaults to 512, things are smoother if we have more
        v.memory = 1024
    end

    # Bridged mode -- allows you to just use the machine like it was
    # another machine on the same network. Note that this also means
    # it's directly connected to your network and may present security
    # concerns if you don't trust that network.
    config.vm.network "public_network"
    config.vm.hostname = "sr-vm.local"

    # Secrets
    config.vm.synced_folder "../dummy-secrets", "/srv/secrets"

    # Hiera data, guest path must match the value in the hiera.yaml
    config.vm.synced_folder "hieradata", "/etc/puppet/hieradata"

    # Bootstrap
    config.vm.provision "shell", inline: "yum install -y puppet git"

    config.vm.provision "puppet" do |puppet|
        puppet.hiera_config_path    = "hiera.yaml"
        puppet.manifests_path       = "manifests"
        puppet.manifest_file        = "sr-dev.pp"
        puppet.module_path          = "modules"
    end
end
