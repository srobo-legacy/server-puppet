
class sr-site::trac {

  # Trac needs mysql
  require sr-site::mysql

  $mysql_trac_pw = extlookup("mysql_trac_pw")

  package { ["trac", "mod_python", "MySQL-python"]:
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

  mysql::db { "trac":
    user => "trac",
    password => $mysql_trac_pw,
    host => "localhost",
    grant => ["all"],

    sql => "/tmp/trac.init",
    require => File["/tmp/trac.init"],
  }

  # Populate the database, but only run if a given table doesn't exist
  exec { "pop_db":
    command => "mysql -u trac --password='${mysql_trac_pw}' trac < /srv/secrets/trac.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/trac_installed",
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

}
