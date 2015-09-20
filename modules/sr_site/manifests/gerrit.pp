# Gerrit provides review of our commits as well as easy push access

class sr_site::gerrit {

  # Gerrit runs on java...
  package { ['java-1.8.0-openjdk',
             'mysql-connector-java']:
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
    owner => 'gerrit',
    group => 'users',
    require => User['gerrit'],
  }

  # The entirety of gerrit is installed and served out of one 'war' file,
  # containing a mass of java goo, which we download here.
  # FIXME: some additional arrangement is going to have to occur when we want
  # to update gerrit, which given how bad it is will happen fairly frequently.
  # This also needs to consider the fact that updates can bring in schema
  # changes to the db.
  $gerrit_war = '/home/gerrit/gerrit-2.8.war'
  exec { 'download-gerrit':
    command => "curl http://gerrit-releases.storage.googleapis.com/gerrit-2.8.war  > '${gerrit_war}'",
    creates => $gerrit_war,
    user => 'gerrit',
    require => File['/home/gerrit'],
  }

  # In a coup for usability, gerrit will perform a default install if it's
  # not attached to an interactive terminal when run. We can then configure
  # config files by other means!
  exec { 'install-gerrit':
    require => [Exec['download-gerrit'], Package['java-1.8.0-openjdk']],
    user => 'gerrit',
    command => "java -jar '${gerrit_war}' init --no-auto-start -d /home/gerrit/srdata",
    creates => '/home/gerrit/srdata',
  }

  file { 'mysql-connector',
    path    => '/home/gerrit/srdata/libs/mysql-connector-java.jar',
    ensure  => 'link',
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [Exec['install-gerrit'], Package['mysql-connector-java']],
  }

  # The gerrit 'All-projects' project is intimitely associated with a particular
  # database of data due to group identification being done by some UUIDs.
  # Therefore a specific All-Projects.git has to be associated with the server.
  exec { 'install-gerrit-all-projs':
    command => 'tar -xf /srv/secrets/gerrit/all_projs.tgz -C /home/gerrit/srdata/git && touch /home/gerrit/srdata/git/All-Projects.git/.srinstalled',
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
    source => 'puppet:///modules/sr_site/gerritmail',
    owner => 'gerrit',
    group => 'users',
    mode => '0444',
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
    owner => 'root',
    group => 'root',
  }

  # Kill gerrit below runlevel 3.
  file { '/etc/rc3.d/K90gerrit':
    ensure => link,
    target => '/etc/init.d/gerrit',
    owner => 'root',
    group => 'root',
  }

  # Configuration data for the gerrit service (i.e. the SYSV init script),
  # this lets it know what to serve and from where.
  file { '/etc/default/gerritcodereview':
    ensure => present,
    owner => 'root',
    group => 'root',
    source => 'puppet:///modules/sr_site/gerritcodereview',
  }

  $www_canonical_hostname = hiera('www_canonical_hostname')
  $ldap_manager_pw = hiera('ldap_manager_pw')
  $gerrit_db_name = 'reviewdb'
  $gerrit_db_pw = hiera('gerrit_db_pw')
  $gerrit_email_key = hiera('gerrit_email_key')
  $gerrit_email_pw = hiera('gerrit_email_pw')
  $gerrit_email_user = hiera('gerrit_email_user')
  $gerrit_email_smtp = hiera('gerrit_email_smtp')

  # Primary gerrit config goo. All the major themes in gerrit are configured
  # in this file.
  file { '/home/gerrit/srdata/etc/gerrit.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0644',
    content => template('sr_site/gerrit.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  # File to store passwords for things configured in gerrit.config. Templates
  # in the passwords loaded earlier in this file.
  file { '/home/gerrit/srdata/etc/secure.config':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0600',
    content => template('sr_site/secure.config.erb'),
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  # A series of host keys - if our server ever dies we'll need to restore these,
  # therefore we have to configure them in the first place too.

  file { '/home/gerrit/srdata/etc/ssh_host_dsa_key':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0600',
    source => '/srv/secrets/gerrit/ssh_host_dsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_dsa_key.pub':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0600',
    source => '/srv/secrets/gerrit/ssh_host_dsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_rsa_key':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0600',
    source => '/srv/secrets/gerrit/ssh_host_rsa_key',
    require => Exec['install-gerrit'],
    notify => Service['gerrit'],
  }

  file { '/home/gerrit/srdata/etc/ssh_host_rsa_key.pub':
    ensure => present,
    owner => 'gerrit',
    group => 'users',
    mode => '0600',
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
  mysql::db { $gerrit_db_name:
    user => 'gerrit',
    password => $gerrit_db_pw,
    host => 'localhost',
    grant => ['all'],
  }

  # Load the contents of the Gerrit database from backup.
  exec { 'pop_gerrit_db':
    command => "mysql -u gerrit --password='${gerrit_db_pw}' reviewdb < /srv/secrets/mysql/${gerrit_db_name}.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/gerrit_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/gerrit_installed',
    require => Mysql::Db['reviewdb'],
    notify => Service['gerrit'],
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
    enable => true,
    require => [
      Exec['install-gerrit-ssh-goo'],
      Exec['install-gerrit'],
      Exec['install-gerrit-service'],
      File['mysql-connector'],
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
