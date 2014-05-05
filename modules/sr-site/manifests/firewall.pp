# A wall of fire!

class sr-site::firewall {

  # Always persist firewall rules
  exec { 'persist-firewall':
    command     => '/sbin/iptables-save > /etc/sysconfig/iptables',
    refreshonly => true,
  }

  # These defaults ensure that the persistence command is executed after
  # every change to the firewall, and that pre & post classes are run in the
  # right order to avoid potentially locking you out of your box during the
  # first puppet run.
  Firewall {
    notify  => Exec['persist-firewall'],
  }

  Firewallchain {
    notify  => Exec['persist-firewall'],
  }

  # Purge unmanaged firewall resources
  #
  # This will clear any existing rules, and make sure that only rules
  # defined in puppet exist on the machine
  resources { 'firewall':
    purge => true
  }

  include sr-site::fw_pre
  include sr-site::fw_post

}
