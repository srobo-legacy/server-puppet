class sr-site::gerrit {
  user { 'gerrit':
    ensure => present,
    comment => 'Owner of all gerrit specific files/data',
    shell => '/bin/sh', # Has to log in successfully, as it runs java.
    gid => 'users',
  }

  file { '/home/gerrit':
    ensure => directory,
    owner => "gerrit",
    group => "users",
    require => User['gerrit'],
  }

  exec { 'download-gerrit':
    command => 'curl http://gerrit.googlecode.com/files/gerrit-full-2.5.war > /home/gerrit/gerrit-full-2.5.war',
    creates => '/home/gerrit/gerrit-full-2.5.war',
    user => 'gerrit',
    require => File['/home/gerrit'],
  }

  # In a coup for usability, gerrit will perform a default install if it's
  # not attached to an interactive terminal when run. We can then configure
  # config files by other means!
  exec { 'install-gerrit':
    require => [Exec['download-gerrit'], Package['java-1.7.0-openjdk']],
    user => 'gerrit',
    command => 'java -jar /home/gerrit/gerrit-full-2.5.war init --no-auto-start -d /home/gerrit/srdata',
    creates => '/home/gerrit/srdata',
  }

  exec { 'install-gerrit-all-projs':
    command => 'tar -xf /srv/secrets/gerrit/all_projs.tgz -C /home/gerrit/srdata/git; touch /home/gerrit/srdata/git/All-Projects.git/.srinstalled',
    provider => 'shell',
    user => 'gerrit',
    creates => '/home/gerrit/srdata/git/All-Projects.git/.srinstalled',
    notify => Service['gerrit'],
    require => Exec['install-gerrit'],
  }

  file { '/srv/git/All-Projects.git':
    ensure => link,
    target => '/home/gerrit/srdata/git/All-Projects.git',
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/mail':
    ensure => directory,
    recurse => true,
    source => 'puppet:///modules/sr-site/gerritmail',
    owner => 'gerrit',
    group => 'users',
    mode => '444',
    require => Exec['install-gerrit'],
  }

  exec { 'install-gerrit-service':
    command => 'cp /home/gerrit/srdata/bin/gerrit.sh /etc/init.d/gerrit',
    creates => '/etc/init.d/gerrit',
    require => Exec['install-gerrit'],
  }

  file { '/etc/rc3.d/S90gerrit':
    ensure => link,
    target => '/etc/init.d/gerrit',
    owner => root,
    group => root,
  }

  file { '/etc/rc3.d/K90gerrit':
    ensure => link,
    target => '/etc/init.d/gerrit',
    owner => root,
    group => root,
  }

  file { '/etc/default/gerritcodereview':
    ensure => present,
    owner => 'root',
    group => 'root',
    source => 'puppet:///modules/sr-site/gerritcodereview',
  }

  $www_canonical_hostname = extlookup('www_canonical_hostname')
  $ldap_manager_pw = extlookup('ldap_manager_pw')
  file { '/home/gerrit/srdata/etc/gerrit.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '644',
    content => template('sr-site/gerrit.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  $gerrit_db_pw = extlookup('gerrit_db_pw')
  file { '/home/gerrit/srdata/etc/secure.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    content => template('sr-site/secure.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_dsa_key':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/gerrit/ssh_host_dsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_dsa_key.pub':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/gerrit/ssh_host_dsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_rsa_key':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/gerrit/ssh_host_rsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_rsa_key.pub':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    source => '/srv/secrets/gerrit/ssh_host_rsa_key.pub',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_key':
    ensure => absent,
  }

  mysql::db { 'reviewdb':
    user => 'gerrit',
    password => "$gerrit_db_pw",
    host => "localhost",
    grant => ["all"],
  }

  exec { "pop_gerrit_db":
    command => "mysql -u gerrit --password='${gerrit_db_pw}' reviewdb < /srv/secrets/mysql/gerrit.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/gerrit_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/gerrit_installed',
    require => Mysql::Db["reviewdb"],
    notify => Service['gerrit'],
  }

  exec { 'install-gerrit-mysql-connector':
    command => 'curl http://repo2.maven.org/maven2/mysql/mysql-connector-java/5.1.10/mysql-connector-java-5.1.10.jar > /home/gerrit/srdata/lib/tmpdownload; echo "517e19ba790cceee31148c30a887155e  /home/gerrit/srdata/lib/tmpdownload" | md5sum -c; if test $? = 1; then exit 1; fi; mv /home/gerrit/srdata/lib/tmpdownload /home/gerrit/srdata/lib/mysql-connector-java-5.1.10.jar',
    creates => '/home/gerrit/srdata/lib/mysql-connector-java-5.1.10.jar',
    user => 'gerrit',
    require => Exec['install-gerrit'],
  }

  exec { 'install-gerrit-ssh-goo':
    command => 'curl -L http://www.bouncycastle.org/download/bcprov-jdk16-144.jar > /home/gerrit/srdata/lib/tmpbcdownload; echo "76e37f4f7910c5759be87302f7c4d067  /home/gerrit/srdata/lib/tmpbcdownload" | md5sum -c; if test $? = 1; then exit 1; fi; mv /home/gerrit/srdata/lib/tmpbcdownload /home/gerrit/srdata/lib/bcprov-jdk16-144.jar',
    creates => '/home/gerrit/srdata/lib/bcprov-jdk16-144.jar',
    user => 'gerrit',
    require => Exec['install-gerrit'],
  }


  service { 'gerrit':
    ensure => running,
    require => [
      Exec['install-gerrit-mysql-connector'],
      Exec['install-gerrit-ssh-goo'],
      Exec['install-gerrit'],
      Exec['install-gerrit-service'],
      Mysql::Db['reviewdb'],
      File['/etc/default/gerritcodereview'],
      File['/home/gerrit/srdata/etc/gerrit.config'],
      File['/home/gerrit/srdata/etc/secure.config'],
      File['/home/gerrit/srdata/etc/ssh_host_dsa_key'],
      File['/home/gerrit/srdata/etc/ssh_host_dsa_key.pub'],
      File['/home/gerrit/srdata/etc/ssh_host_rsa_key'],
      File['/home/gerrit/srdata/etc/ssh_host_rsa_key.pub'],
      File['/home/gerrit/srdata/etc/ssh_host_key'],
    ],

    status => 'service gerrit check',
  }
}
