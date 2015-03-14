# Pipebot emits things from a fifo into the #srobo IRC channel

class sr_site::pipebot ( $git_root ) {
  # For lack of a more appropriate user,
  user { 'pipebot':
    ensure => present,
    comment => 'Pipe attendant',
    shell => '/sbin/nologin',
    gid => 'users',
    managehome => true,
  }

  # Checkout of pipebot's code.
  $root_dir = '/home/pipebot/pipebot'
  vcsrepo { $root_dir:
    ensure => present,
    provider => git,
    source => "${git_root}/pipebot",
    revision => 'origin/master',
    owner => 'pipebot',
    group => 'users',
    require => File['/home/pipebot'],
  }

  # Site-local configuration is stored in local.ini; assign some variables that
  # will be templated into it.
  $pipe_dir = "/var/run/irc"
  $pipe_path = "/tmp/hash-srobo" # "$pipe_dir/hash-srobo"
  $pipebot_nick = extlookup('pipebot_nick')
  $pipebot_ident = extlookup('pipebot_ident')
  file { "${root_dir}/localconfig.py":
    ensure => present,
    owner => 'pipebot',
    group => 'users',
    content => template('sr_site/pipebot_localconfig.py.erb'),
    require => Vcsrepo[$root_dir],
  }

  file { $pipe_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'users',
    mode    => '0664',
  }

  if !$devmode {
    # Also, some systemd goo to install the service.
    file { '/etc/systemd/system/pipebot.service':
      ensure => present,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => 'puppet:///modules/sr_site/pipebot.service',
    }

    # Link in the systemd service to run in multi user mode.
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

    # And finally maintain pipebot being running.
    service { 'pipebot':
      ensure => running,
      require => Exec['pipebot-systemd-load'],
    }
  }
}
