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

  # FIXME: find a way of extracting all mysql dbs from puppet?
  $list_of_dbs = 'phpbb_sr2013,piwik,trac,reviewdb'
  $ide_loc = $www::ide::root_dir

  # Danger Will Robinson: All backup keys must also be (locally) signed by the
  # root user. Failure to do this will make backup fail.
  $backup_crypt_keys = extlookup('backup_keys')

  file { '/srv/backup/backup.ini':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '400',
    content => template('sr-site/backup.ini.erb')
  }

  user { 'backup':
    ensure => present,
    comment => "Backup operations user",
    shell => '/bin/bash',
    gid => 'users',
  }

  file { '/home/backup':
    ensure => directory,
    owner => 'backup',
    group => 'users',
    mode => '700',
    require => User['backup'],
  }

  file { '/home/backup/.ssh':
    ensure => directory,
    owner => 'backup',
    group => 'users',
    mode => '700',
  }

  file { '/home/backup/.ssh/authorized_keys':
    ensure => present,
    owner => 'backup',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/login/backups_ssh_keys',
    require => File['/home/backup/.ssh'],
  }

  package { 'gnupg':
    ensure => present,
  }
}
