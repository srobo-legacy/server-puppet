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
}
