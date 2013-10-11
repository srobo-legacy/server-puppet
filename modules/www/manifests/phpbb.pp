# phpBB, the popular and featureful forum software.

class www::phpbb ( $git_root, $root_dir ) {
  # MySQL database configuration
  $forum_db_name = 'phpbb_sr2014'
  $forum_user = extlookup("phpbb_sql_user")
  $forum_pw = extlookup("phpbb_sql_pw")

  # We require the bindings between php and mysql to work
  package { ['php-mysql']:
    ensure => present,
    notify => Service['httpd'],
  }

  # Checkout of the phpbb installation, with SRs patches against phpbb. One
  # of these is to delete the installation directory, which is mandatory before
  # the forum will start serving.
  vcsrepo { "${root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/sr-phpbb3.git",
    revision => "origin/master",
    force => true,
    require => Package[ "php", 'php-mysql' ],
  }

  # Create the MySQL db for the forum
  mysql::db { "$forum_db_name":
    user => $forum_user,
    password => $forum_pw,
    host => 'localhost',
    grant => ['all'],
  }

  # Load the database data from backup, if it hasn't already.
  exec { 'pop_forum_db':
    command => "mysql -u ${forum_user} --password='${forum_pw}' ${forum_db_name} < /srv/secrets/mysql/phpbb.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/forum_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/forum_installed',
    require => Mysql::Db["${forum_db_name}"],
  }

  # Maintain permissions on the config file, and template it. Contains SQL
  # connection gunge.
  file { "${root_dir}/phpBB/config.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/forum_config.php.erb'),
    require => Vcsrepo["${root_dir}"],
  }

  # Directory for storing forum attachments. Not currently backed up, see #1467
  file { "${root_dir}/phpBB/files":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  # Some form of forum page cache
  file { "${root_dir}/phpBB/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  # Not the foggiest, but this is how it was on optimus, so this is configured
  # thus here too.
  file { "${root_dir}/phpBB/store":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }
}
