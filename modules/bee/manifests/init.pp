# A bee to show in the Message of the day

class bee {

  file { '/etc/motd':
    mode => '0444',
    owner => 'root',
    group => 'root',
    source => 'puppet:///modules/bee/motd',
  }

}
