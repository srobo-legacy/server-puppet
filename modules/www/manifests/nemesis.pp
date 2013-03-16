# 'Nemesis' is the web frontend of the user management interface, allowing
# teachers to administrate users at their college, and register the details of
# new ones. SR blueshirt config might end up being operated by this interface
# too in the future.

class www::nemesis ( $git_root, $root_dir ) {
  # An sqlite DB is used to store data, install the python bindings for it.
  package { ['python-sqlite3dbm']:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo["${root_dir}"],
  }

  # Main checkout of the Nemesis codebase
  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "https://github.com/samphippen/nemesis.git",
    revision => "origin/master",
    force => true,
    owner => 'wwwcontent',
    group => 'apache',
    notify => Service['httpd'],
  }

  # Generate the SQLite DB for registration storage, unless it already
  # exists.
  exec { "${root_dir}/nemesis/scripts/make_db.sh":
    cwd => "${root_dir}/nemesis",
    creates => "${root_dir}/nemesis/db/nemesis.sqlite",
    path => ["/usr/bin"],
    user => "wwwcontent",
    require => Vcsrepo["${root_dir}"],
  }

  # Maintain permissions of the sqlite DB. SQLite determines what user to create
  # the journal and locking files as based on who owns the DB. If it's owned
  # by wwwcontent, SQLite attempts to chown files it creates to wwwcontent,
  # and EPERMs
  file { "${root_dir}/nemesis/db/nemesis.sqlite":
    owner => 'apache',
    group => 'apache',
    mode => '660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  # Maintain the directory permissions of the sqlite db.
  file { "${root_dir}/nemesis/db":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  # A WSGI config file for serving nemesis inside of apache.
  file { "${root_dir}/nemesis/nemesis.wsgi":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644',
    source => "puppet:///modules/www/nemesis.wsgi",
    require => Vcsrepo["${root_dir}"],
  }

  # Configurate the srusers library so that nemesis can interact with LDAP.
  # Idealy this should not be using the LDAP manager account. An even more idea
  # situation would trac ticket #1053 to be applied. Until then, use the LDAP
  # manager account.
  $ldap_manager_pw = extlookup('ldap_manager_pw')
  file { "${root_dir}/nemesis/libnemesis/libnemesis/srusers/local.ini":
    ensure => present,
    content => template('www/nemesis_conf.ini.erb'),
    owner => 'wwwcontent',
    group => 'apache',
    mode => '440',
    require => Vcsrepo["${root_dir}"],
  }
}
