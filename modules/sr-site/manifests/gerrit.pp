class sr-site::gerrit {
  user { 'gerrit':
    ensure => present,
    comment => 'Owner of all gerrit specific files/data',
    shell => '/bin/sh', # Has to log in successfully, as it runs java.
    gid => 'users',
  }

  exec { 'download-gerrit':
    command => 'curl http://gerrit.googlecode.com/files/gerrit-full-2.5.war > /home/gerrit/gerrit-full-2.5.war',
    creates => '/home/gerrit/gerrit-full-2.5.war',
    user => 'gerrit',
    require => User['gerrit'],
  }

  # In a coup for usability, gerrit will perform a default install if it's
  # not attached to an interactive terminal when run. We can then configure
  # config files by other means!
  exec { 'install-gerrit':
    require => [Exec['download-gerrit'], Package['java-1.7.0-openjdk']],
    user => 'gerrit',
    command => 'java -jar /home/gerrit/gerrit-full-2.5.war init -d /home/gerrit/srdata',
    creates => '/home/gerrit/srdata',
  }

  $ssl_site_url = extlookup('ssl_site_url')
  $ldap_manager_pw = extlookup('ldap_manager_pw')
  file { '/home/gerrit/srdata/etc/gerrit.config':
    owner => 'gerrit',
    group => 'users',
    mode => '644',
    content => template('sr-site/gerrit.config.erb'),
    require => Exec['install-gerrit'],
  }

  $gerrit_db_pw = extlookup('gerrit_db_pw')
  file { '/home/gerrit/srdata/etc/secure.config':
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    content => template('sr-site/secure.config.erb'),
    require => Exec['install-gerrit'],
  }

  mysql::db { 'reviewdb':
    user => 'gerrit',
    password => "$gerrit_db_pw",
    host => "localhost",
    grant => ["all"],
  }
}
