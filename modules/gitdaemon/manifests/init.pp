

class gitdaemon {

  package { 'xinetd':
    ensure => latest,
  }

  service { 'xinetd':
    ensure => running,
    enable => true,
  }

  # Restart xinetd after package updates
  Package['xinetd'] ~> Service['xinetd']

  package { 'git-daemon':
    ensure => latest,
    require => Package['xinetd'],
  }

  # The xinetd git daemon config file
  file { '/etc/xinetd.d/git':
    mode => '0644',
    owner => 'root',
    group => 'root',
    source => 'puppet:///modules/gitdaemon/git.xinetd',

    # Install after git-daemon package
    require => Package['git-daemon'],

    # Restart xinetd when this file changes
    notify => Service['xinetd'],
  }

}
