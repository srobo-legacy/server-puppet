class sr-site::pipebot ( $git_root ) {
  # For lack of a more appropriate user,
  user { 'pipebot':
    ensure => present,
    comment => 'Pipe attendant',
    shell => '/sbin/nologin',
    gid => 'users',
  }

  file { '/home/pipebot':
    ensure => directory,
    owner => 'pipebot',
    group => 'users',
    mode => '700',
    require => User['pipebot'],
  }

  vcsrepo { '/home/pipebot/pipebot':
    ensure => present,
    provider => git,
    source => "${git_root}/pipebot",
    revision => 'origin/master',
    force => true,
    owner => 'pipebot',
    group => 'users',
    require => File['/home/pipebot'],
  }

  # Also, some systemd goo.
  file { '/etc/systemd/system/pipebot.service':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '644',
    source => 'puppet:///modules/sr-site/pipebot.service',
  }

  file { '/etc/systemd/system/multi-user.target.wants/pipebot.service':
    ensure => link,
    target => '/etc/systemd/system/pipebot.service',
    require => File['/etc/systemd/system/pipebot.service'],
  }

  # systemd has to be reloaded before picking this up,
  exec { 'pipebot-systemd-load':
    provider => 'shell',
    command => 'systemctl daemon-reload',
    onlyif => 'systemctl --all | grep pipebot; if test $? = 0; then exit 1; fi; exit 0',
    require => File['/etc/systemd/system/multi-user.target.wants/pipebot.service'],
  }

  service { 'pipebot':
    ensure => running,
    require => Exec['pipebot-systemd-load'],
  }
}
