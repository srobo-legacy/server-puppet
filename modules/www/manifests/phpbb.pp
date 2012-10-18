class www::phpbb ( $git_root, $root_dir ) {
  $forum_db_name = 'phpbb_sr2013'
  $forum_user = extlookup("phpbb_sql_user")
  $forum_pw = extlookup("phpbb_sql_pw")

  package { ['php-mysql']:
    ensure => present,
    notify => Service['httpd'],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    provider => git,
    source => "${git_root}/sr-phpbb3.git",
    revision => "master",
    force => true,
    require => Package[ "php", 'php-mysql' ],
  }

  mysql::db { "$forum_db_name":
    user => $forum_user,
    password => $forum_pw,
    host => 'localhost',
    grant => ['all'],
  }

  file { "${root_dir}/phpBB/config.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/forum_config.php.erb'),
  }

  file { "${root_dir}/phpBB/files":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
  }

  file { "${root_dir}/phpBB/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
  }

  file { "${root_dir}/phpBB/store":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
  }
}
