class www::voting ($git_root, $web_root_dir) {
  package { 'PyYAML':
    ensure => present,
  }

  file { '/home/voting':
    ensure => directory,
    owner => 'voting',
    group => 'users',
    mode => '711',
    require => User['voting'],
  }

  user { 'voting':
    ensure => present,
    comment => 'Owner of voting record files',
    shell => '/sbin/nologin',
    gid => 'users',
    home => '/home/voting',
  }

  vcsrepo { "/home/voting/public_html/voting":
    ensure => present,
    provider => git,
    source => "${git_root}/voting.git",
    revision => "master",
    force => true,
    require => [Package['PyYAML'], User['voting']],
    owner => 'voting',
    group => 'users',
  }
}
