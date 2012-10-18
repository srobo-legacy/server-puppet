class www::phpbb ( $git_root, $root_dir ) {
  $mysql_db_name = 'phpbb_sr2013'

  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "${git_root}/sr-phpbb3.git",
    revision => "master",
    force => true,
    require => Package[ "php" ],
  }

  mysql::db { "$mysql_db_name":
    user => extlookup("phpbb_sql_user"),
    password => extlookup("phpbb_sql_pw"),
    host => 'localhost',
    grant => ['all'],
  }
}
