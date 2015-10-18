# Request tracking system: fetches mail to various mail address
# and provides multiple-access sytem for replying to them.

class sr_site::requesttracker ( ) {
  require sr_site::mysql

  # Load some web related variables
  $www_base_hostname = hiera('www_base_hostname')
  $www_canonical_hostname = hiera('www_canonical_hostname')

  # Install relevant packages
  package {['rt', 'rt-mailgate']:
    ensure => present,
  }

  # RT stores it's data inside a database
  $rt_db_user = 'rt'
  $rt_db_name = 'requesttracker'
  $rt_db_host = 'localhost'
  $mysql_db_pw = hiera('mysql_rt_pw')
  mysql::db { $rt_db_name:
    user => $rt_db_user,
    password => $mysql_db_pw,
    host => $rt_db_host,
    grant => ['all'],
  }

  $rt_admin_address = hiera('rt_admin_address')
  $default_rt_address = hiera('default_rt_address')

  # Specify general config: connection params etc
  file { '/etc/rt/RT_SiteConfig.pm':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '664',
    content => template('sr_site/RT_SiteConfig.pm.erb'),
  }

  # Populate the database. On a development machine, what you want is to have
  # a freshly initialized DB that can be customised as required -- while on
  # the deployment machine, we only ever want the deployment database.
  if $devmode {
    # Insert all relevant data into the database, without creating it.
    # Not passing the pw on the command line is a problem for another time.
    exec { 'initialize-rt':
      command => "/usr/sbin/rt-setup-database --action init --skip-create && touch /usr/local/var/sr/rt_installed",
      provider => 'shell',
      creates => '/usr/local/var/sr/rt_installed',
      require => [Mysql::Db[$rt_db_name], File['/etc/rt/RT_SiteConfig.pm']],
    }
  } else {
    # XXX unimplemented, restore from backup.
  }

###############################################################################

  # Mail gateway specific configuration
  package { ['fetchmail', 'procmail']:
    ensure => present,
  }

  # We require an RT user to perform these actions.
  user { 'rt':
    ensure => present,
    comment => 'Request tracker user',
    shell => '/bin/sh',
    gid => 'users',
  }

  file { '/home/rt':
    ensure => directory,
    owner => 'rt',
    group => 'users',
    require => User['rt'],
  }

  # Dir to filter mail in
  file { '/home/rt/Mail':
    ensure => directory,
    owner => 'rt',
    group => 'users',
    require => File['/home/rt'],
  }

  # Load credentials and address for the RT mailbox. Right now it's fritter.
  $rt_mail_addr = hiera('fritter_mail_user')
  $rt_mail_pw = hiera('fritter_mail_pw')
  $rt_mail_imap = hiera('fritter_mail_imap')

  # Install a fetchmail configuration for getting RT mail
  file { '/home/rt/.fetchmailrc':
    ensure => present,
    owner => 'rt',
    group => 'users',
    mode => '600',
    content => template('sr_site/rt_fetchmail.erb'),
  }

  #############################################################################

  # Outbound mail configuration. The summary for this is: "Sendmail. Not even
  # once".

  package { ['postfix', 'postfix-perl-scripts', 'cyrus-sasl-plain']:
    ensure => present,
  }

  $rt_mail_smtp = hiera('fritter_mail_smtp')

  # Install postfix main config file.
  file { '/etc/postfix/main.cf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '644',
    content => template('sr_site/postfix_main.cf.erb'),
  }

  # Additionally, install some policy / credential tables. First, the policy
  # file that says to always connect to gmail with TLS, and to verify that
  # the given certificate is verified.
  file { '/etc/postfix/tls_policy':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '644',
    content => template('sr_site/postfix_tls_policy.erb'),
  }

  # Credentials for logging into gmail
  file { '/etc/postfix/sasl_passwd':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '400',
    content => template('sr_site/postfix_sasl_passwd.erb'),
  }

  # Rebuild mail maps for each of these
  exec { 'tls-postmap-rebuild':
    command => 'postmap /etc/postfix/tls_policy',
    user => root,
    group => root,
    subscribe => File['/etc/postfix/tls_policy'],
    path => '/usr/bin:/usr/sbin',
  }

  exec { 'passwd-postmap-rebuild':
    command => 'postmap /etc/postfix/sasl_passwd',
    user => root,
    group => root,
    subscribe => File['/etc/postfix/sasl_passwd'],
    path => '/usr/bin:/usr/sbin',
  }

  # Register existance of postfix service
  service { 'postfix':
    ensure => running,
    subscribe => [Exec['tls-postmap-rebuild'], Exec['passwd-postmap-rebuild']],
  }

}
