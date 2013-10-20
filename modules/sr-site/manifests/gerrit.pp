class sr-site::gerrit {

  # Gerrit runs on java...
  package { ['java-1.7.0-openjdk']:
    ensure => present,
  }

  # A user for the gerrit service to be run as
  user { 'gerrit':
    ensure => present,
    comment => 'Owner of all gerrit specific files/data',
    shell => '/bin/sh', # Has to log in successfully, as it runs java.
    gid => 'users',
  }

  # Gerrit stores a 'site' that it serves in a 'site directory', which we'll
  # be keeping in its home directory. /srv might be more appropriate in the
  # future.
  file { '/home/gerrit':
    ensure => directory,
    owner => "gerrit",
    group => "users",
    require => User['gerrit'],
  }

  # The entirety of gerrit is installed and served out of one 'war' file,
  # containing a mass of java goo, which we download here.
  # FIXME: some additional arrangement is going to have to occur when we want
  # to update gerrit, which given how bad it is will happen fairly frequently.
  # This also needs to consider the fact that updates can bring in schema
  # changes to the db.
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

  # The gerrit 'All-projects' project is intimitely associated with a particular
  # database of data due to group identification being done by some UUIDs.
  # Therefore a specific All-Projects.git has to be associated with the server.
  exec { 'install-gerrit-all-projs':
    command => 'tar -xf /srv/secrets/gerrit/all_projs.tgz -C /home/gerrit/srdata/git; touch /home/gerrit/srdata/git/All-Projects.git/.srinstalled',
    provider => 'shell',
    user => 'gerrit',
    creates => '/home/gerrit/srdata/git/All-Projects.git/.srinstalled',
    notify => Service['gerrit'],
    require => Exec['install-gerrit'],
  }

  # Symlink the All-Projects git repo into the list of served repos. This is
  # also where Gerrit accesses it from.
  # Why it's not installed to /srv/git/All-Projects.git in the first place, is
  # because things were pretty funky when this was originally configured, poorly
  # understood, and I just wanted to ship something that worked.
  file { '/srv/git/All-Projects.git':
    ensure => link,
    target => '/home/gerrit/srdata/git/All-Projects.git',
    notify => Service['gerrit'],
  }

  # Set of email templates Gerrit will use to mail things at people.
  file { '/home/gerrit/srdata/etc/mail':
    ensure => directory,
    recurse => true,
    source => 'puppet:///modules/sr-site/gerritmail',
    owner => 'gerrit',
    group => 'users',
    mode => '444',
    require => Exec['install-gerrit'],
  }

  # Install files for the gerrit _service_. It currently only provides a SYSV
  # init script, which appears to do a non-trivial amount of work and thus
  # can't be easily moved over to systemd.
  exec { 'install-gerrit-service':
    command => 'cp /home/gerrit/srdata/bin/gerrit.sh /etc/init.d/gerrit',
    creates => '/etc/init.d/gerrit',
    require => Exec['install-gerrit'],
  }

  # Start gerrit in runlevel 3.
  file { '/etc/rc3.d/S90gerrit':
    ensure => link,
    target => '/etc/init.d/gerrit',
    owner => root,
    group => root,
  }

  # Kill gerrit below runlevel 3.
  file { '/etc/rc3.d/K90gerrit':
    ensure => link,
    target => '/etc/init.d/gerrit',
    owner => root,
    group => root,
  }

  # Configuration data for the gerrit service (i.e. the SYSV init script),
  # this lets it know what to serve and from where.
  file { '/etc/default/gerritcodereview':
    ensure => present,
    owner => 'root',
    group => 'root',
    source => 'puppet:///modules/sr-site/gerritcodereview',
  }

  $www_canonical_hostname = extlookup('www_canonical_hostname')
  $ldap_manager_pw = extlookup('ldap_manager_pw')
  $gerrit_db_pw = extlookup('gerrit_db_pw')
  $gerrit_email_key = extlookup('gerrit_email_key')
  $gerrit_email_pw = extlookup('gerrit_email_pw')
  $gerrit_email_user = extlookup('gerrit_email_user')
  $gerrit_email_smtp = extlookup('gerrit_email_smtp')

  # Primary gerrit config goo. All the major themes in gerrit are configured
  # in this file.
  file { '/home/gerrit/srdata/etc/gerrit.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '644',
    content => template('sr-site/gerrit.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  # File to store passwords for things configured in gerrit.config. Templates
  # in the passwords loaded earlier in this file.
  file { '/home/gerrit/srdata/etc/secure.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '600',
    content => template('sr-site/secure.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  # A series of host keys - if our server ever dies we'll need to restore these,
  # therefore we have to configure them in the first place too.

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

  # For unknown reasons, a number of warnings and errors get sprayed by Gerrit
  # if the SSHv1 host key is in existance.
  file { '/home/gerrit/srdata/etc/ssh_host_key':
    ensure => absent,
  }

  # A mysql database for gerrit to store user info, group info, reviews and so
  # forth.
  mysql::db { 'reviewdb':
    user => 'gerrit',
    password => "$gerrit_db_pw",
    host => "localhost",
    grant => ["all"],
  }

  # Load the contents of the Gerrit database from backup.
  exec { "pop_gerrit_db":
    command => "mysql -u gerrit --password='${gerrit_db_pw}' reviewdb < /srv/secrets/mysql/gerrit.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/gerrit_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/gerrit_installed',
    require => Mysql::Db["reviewdb"],
    notify => Service['gerrit'],
  }

  # Download and install the java goo to link up gerrit and mysql. I couldn't
  # find an automated way to do this in the gerrit installation process, it'd
  # be cleaner if that were possible.
  exec { 'install-gerrit-mysql-connector':
    command => 'curl http://repo2.maven.org/maven2/mysql/mysql-connector-java/5.1.10/mysql-connector-java-5.1.10.jar > /home/gerrit/srdata/lib/tmpdownload; echo "517e19ba790cceee31148c30a887155e  /home/gerrit/srdata/lib/tmpdownload" | md5sum -c; if test $? = 1; then exit 1; fi; mv /home/gerrit/srdata/lib/tmpdownload /home/gerrit/srdata/lib/mysql-connector-java-5.1.10.jar',
    creates => '/home/gerrit/srdata/lib/mysql-connector-java-5.1.10.jar',
    user => 'gerrit',
    require => Exec['install-gerrit'],
  }

  # Download and install the java goo to allow Gerrit to do crypto stuff, like
  # its SSHD service. Once more, making this use gerrit's own installation
  # process would be a hell of a lot better than this.
  exec { 'install-gerrit-ssh-goo':
    command => 'curl -L http://www.bouncycastle.org/download/bcprov-jdk16-144.jar > /home/gerrit/srdata/lib/tmpbcdownload; echo "76e37f4f7910c5759be87302f7c4d067  /home/gerrit/srdata/lib/tmpbcdownload" | md5sum -c; if test $? = 1; then exit 1; fi; mv /home/gerrit/srdata/lib/tmpbcdownload /home/gerrit/srdata/lib/bcprov-jdk16-144.jar',
    creates => '/home/gerrit/srdata/lib/bcprov-jdk16-144.jar',
    user => 'gerrit',
    require => Exec['install-gerrit'],
  }

  # The gerrit service, depends on many things.
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

    # Command to check the status of the gerrit service; this differs from the
    # SYSV default/convention for some reason.
    status => 'service gerrit check',
  }
}
