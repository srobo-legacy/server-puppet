# A wall of fire!

class sr_site::firewall {

  # Install standard firewall arrangement, iptables, and disable firewalld
  # as it isn't useful for us here.
  service { 'firewalld':
    ensure => stopped,
    enable => false,
  }

  package { 'iptables-services':
    ensure => latest,
  }

  service { 'iptables':
    ensure => running,
    enable => true,
    require => [Service['firewalld'], Package['iptables-services']],
  }

  # Purge unmanaged firewall resources
  #
  # This will clear any existing rules, and make sure that only rules
  # defined in puppet exist on the machine
  resources { 'firewall':
    purge => true,
  }

  class { 'sr_site::fw_pre':
    require => Service['iptables'],
  }

  class { 'sr_site::fw_post':
    require => Service['iptables'],
  }
}
