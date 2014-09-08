# A wall of fire!

class sr-site::firewall {

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
