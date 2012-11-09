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
}
