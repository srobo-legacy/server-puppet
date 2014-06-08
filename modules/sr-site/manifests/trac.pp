# Trac configuration; currently mostly incomplete and distributed primarily as
# a directory of goo. Can be developed to correctness in the future.

class sr-site::trac {

  # Trac needs mysql
  require sr-site::mysql

  $mysql_trac_pw = extlookup("mysql_trac_pw")

  package { ["trac", "mod_python", "MySQL-python", "python-pygments", "trac-xmlrpc-plugin"]:
    ensure => latest,
  }

  # A hacky way of initialising the trac database's character set
  file { "/tmp/trac.init":
    ensure => present,
    content => "ALTER DATABASE trac DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;",
    owner => "root",
    group => "root",
    mode => "0600",
  }

  # All trac data lives inside an SQL db
  $trac_db_name = 'trac'
  mysql::db { $trac_db_name:
    user => "trac",
    password => $mysql_trac_pw,
    host => "localhost",
    grant => ["all"],

    sql => "/tmp/trac.init",
    require => File["/tmp/trac.init"],
  }

  # Populate the database, but only run if a given table doesn't exist
  exec { "pop_db":
    command => "mysql -u trac --password='${mysql_trac_pw}' trac < /srv/secrets/mysql/trac.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/trac_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/trac_installed',
    require => Mysql::Db["trac"],
  }

  # Copy the trac installation from backup, but only if it doesn't
  # already exist
  # (TODO: Consider moving our trac installation into git)
  exec { "file_cp":
    command => "cp -r /srv/secrets/trac /srv/trac",
    creates => "/srv/trac",
  }

  file { "/srv/trac":
    require => Exec["file_cp"],
    ensure => directory,
    owner => "apache",
    group => "root",
    recurse => true,
    checksum => none,
    mode => "0664",
  }

  # Install WSGI service file
  file { "/var/www/trac":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "644",
  }

  file { "/var/www/trac/trac.wsgi":
    ensure => present,
    owner => root,
    group => root,
    mode => "644",
    source => 'puppet:///modules/sr-site/trac.wsgi',
  }

  if $devmode {

    # When in devmode, make all authenticated users TRAC_ADMINs
    # and give everyone access to XML_RPC
    exec { "dev_perms":
      command => "trac-admin /srv/trac permission add authenticated TRAC_ADMIN; \
      trac-admin /srv/trac permission add anonymous XML_RPC; \
      touch /usr/local/var/sr/trac_perms_configured",
      provider => "shell",
      creates => "/usr/local/var/sr/trac_perms_configured",
      require => [ Exec["pop_db"], Exec["file_cp"] ],
    }

  }

}
