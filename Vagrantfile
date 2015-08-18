Vagrant.configure("2") do |config|

    config.vm.box = "box-cutter/fedora22"

    config.vm.provider "virtualbox" do |v|
        # The box defaults to 512, things are smoother if we have more
        v.memory = 1024
    end

    config.vm.network "private_network", ip: "192.168.42.42"
    config.vm.hostname = "sr-vm.local"

    # Secrets
    config.vm.synced_folder "../dummy-secrets", "/srv/secrets"

    # Hiera data, guest path must match the value in the hiera.yaml
    config.vm.synced_folder "hieradata", "/etc/puppet/hieradata"

    # Bootstrap
    config.vm.provision "shell", inline: "yum install -y puppet git"

    config.vm.provision "puppet" do |puppet|
        puppet.hiera_config_path    = "hiera.yaml"
        puppet.environment_path     = "."
        puppet.manifests_path       = "manifests"
        puppet.manifest_file        = "sr-dev.pp"
        puppet.module_path          = "modules"
    end
end
