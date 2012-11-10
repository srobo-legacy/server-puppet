class sr-site::backup ( $git_root ) {
  vcsrepo { '/srv/backup':
    ensure => present,
    owner => 'root',
    group => 'root',
    provider => 'git',
    source => "${git_root}/server/backup.git",
    revision => "master", # Deliberately no auto update, the scripts here may
                          # end up be run as root by cron
    force => 'true',
  }

  user { 'backup':
    ensure => present,
    comment => "Backup operations user",
    shell => '/bin/bash',
    gid => 'users',
  }

  file { '/home/backup':
    ensure => present,
    owner => 'backup',
    group => 'users',
    mode => '700',
    require => User['backup'],
  }

  file { '/home/backup/.ssh/authorized_keys':
    ensure => present,
    owner => 'backup',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/backup_ssh_keys',
    require => File['/home/backup'],
  }
}
