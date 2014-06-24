# Piwik checkout and database.

class www::piwik ( $git_root, $root_dir ) {
  # Some kind of drawing library piwik can make use of.
  package { ['php-gd']:
    ensure => present,
    notify => Service['httpd'],
  }

  # Checkout of piwik's tree. Don't update automatically, they make schema
  # changes between releases.
  vcsrepo { $root_dir:
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => 'git://github.com/piwik/piwik.git',
    revision => '1.12',
    require => Package['php-gd', 'php-mysql'],
  }

  # Database for storing piwiks end user data.
  $piwik_user = extlookup('piwik_sql_user')
  $piwik_pw = extlookup('piwik_sql_pw')
  $piwik_db_name = 'piwik'
  mysql::db { $piwik_db_name:
    user => $piwik_user,
    password => $piwik_pw,
    host => 'localhost',
    grant => ['all'],
  }

  # Load piwik database from backup, if it isn't already installed.
  exec { 'pop_piwik_db':
    command => "mysql -u ${piwik_user} --password='${piwik_pw}' piwik < /srv/secrets/mysql/piwik.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/piwik_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/piwik_installed',
    require => Mysql::Db['piwik'],
  }

  # Piwik web config file - database connection details, as well as an MD5 of
  # the 'admin' password for logging into the web interface.
  $piwik_admin_user = extlookup('piwik_admin_user')
  $piwik_admin_md5_pw = extlookup('piwik_admin_md5_pw')
  $piwik_admin_email = extlookup('piwik_admin_email')
  file { "${root_dir}/config/config.ini.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/piwik_config.ini.php.erb'),
    before => Mysql::Db['piwik'],
  }

  # Some arbitary dirs that piwik wants to store data in. Excitingly its web
  # interface will probe and tell you that it can't write to them when you
  # update or fiddle with thems
  file { "${root_dir}/tmp":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/templates_c":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/assets":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/tcpdf":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/config":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/sessions":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  file { "${root_dir}/tmp/latest":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }
}
