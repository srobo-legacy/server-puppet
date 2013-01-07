
class icinga {


# install generic nagios checks
  package { 'nagios-plugins-all':
    ensure => installed,
  }

  package { 'nagios-plugins-check-updates':
    ensure => installed,
  }

# create a user to do the checking
  user { 'monitoring':
    ensure => present,
    comment => 'Monitoring User',
    shell => '/bin/bash',
    gid => 'users',
  }

  file { '/home/monitoring':
    ensure => directory,
    owner => 'monitoring',
    group => 'users',
    mode => '700',
    require => User['monitoring']
  }

  file { '/home/monitoring/.ssh':
    ensure => directory,
    owner => 'monitoring',
    group => 'users',
    mode => '700',
  }

  file { '/home/monitoring/.ssh/authorized_keys':
    ensure => present,
    owner => 'monitoring',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/login/monitoring_ssh_keys',
    require => File['/home/monitoring/.ssh'],
  }

  file { '/srv/monitoring':
    ensure => directory,
    owner => 'monitoring',
    group => 'users',
    mode => '700',
    require => User['monitoring']
  }

  file { '/srv/monitoring/commands.sh':
    mode => 700,
    owner => 'monitoring',
    group => 'users',
    source => "puppet:///modules/icinga/commands.sh",
  }

  file { '/srv/monitoring/commands':
    ensure => directory,
    recurse => true,
    source => 'puppet:///modules/icinga/commands',
    owner => 'monitoring',
    group => 'users',
    mode => 700,
  }

}

