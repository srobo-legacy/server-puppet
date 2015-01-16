# Willie is our IRC bot
# TODO: Should we be backing up the logs it creates?

class sr_site::willie ($git_root) {
  package { 'willie':
    ensure    => present,
  }

  # Home directory and user created by the package above
  $home_dir  = '/var/lib/willie'
  $user_name = 'willie'

  # Defaults for files
  File {
    owner   => 'willie',
    group   => 'users',
    mode    => '0644',
  }

  # Checkout of the plugins
  $plugins_repo = "${home_dir}/srbot-plugins"
  # only this directory is searched by willie
  $plugins_dir = "${plugins_repo}/plugins"
  vcsrepo { $plugins_repo:
    ensure   => present,
    provider => 'git',
    source   => "${git_root}/srbot-plugins.git",
    revision => 'origin/master',
    owner    => $user_name,
    group    => 'users',
    require  => Package['willie'],
  }

  # Install the service, only if the live instance
  if !$devmode {
    # Configure the willie instance
    $config_path = "${home_dir}/willie.cfg"
    file { $config_path:
      ensure  => present,
      content => template('sr_site/willie.cfg.erb'),
      require => Package['willie'],
      notify  => Service['willie'],
    }

    $service_file = '/etc/systemd/system/willie.service'
    file { $service_file:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('sr_site/willie.service.erb'),
      require => [Vcsrepo[$plugins_repo],File[$config_path]],
      notify  => Service['willie'],
    }

    # Link in the systemd service to run in multi user mode
    $service_link = '/etc/systemd/system/multi-user.target.wants/willie.service'
    file { $service_link:
      ensure  => link,
      target  => $service_file,
      require => File[$service_file],
    }

    # systemd has to be reloaded before picking this up
    exec { 'willie-systemd-load':
      provider  => 'shell',
      command   => 'systemctl daemon-reload',
      onlyif    => 'systemctl --all | grep willie.service; test $? -gt = 0',
      require   => File[$service_link],
    }

    # And finally maintain willie being running, but only on the live server
    service { 'willie':
      ensure  => running,
      require => Exec['willie-systemd-load'],
    }
  }
}
