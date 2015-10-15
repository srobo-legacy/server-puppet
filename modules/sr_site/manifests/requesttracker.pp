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

}
