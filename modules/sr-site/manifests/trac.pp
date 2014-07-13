# Trac configuration; currently mostly incomplete and distributed primarily as
# a directory of goo. Can be developed to correctness in the future.

class sr-site::trac ( $git_root ) {

  # Trac needs mysql
  require sr-site::mysql

  $mysql_trac_pw = extlookup('mysql_trac_pw')
  $trac_env_root = '/srv/trac'

  package { ['trac', 'MySQL-python', 'python-pygments', 'trac-xmlrpc-plugin']:
    ensure => latest,
  }

  File {
    ensure  => 'present',
    group   => 'root',
    owner   => 'apache',
    mode    => '0664',
  }

  # A hacky way of initialising the trac database's character set
  file { '/tmp/trac.init':
    ensure => present,
    content => 'ALTER DATABASE trac DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;',
    owner => 'root',
    group => 'root',
    mode => '0600',
  }

  # All trac data lives inside an SQL db
  $trac_db_user = 'trac'
  $trac_db_name = 'trac'
  $trac_db_host = 'localhost'
  mysql::db { $trac_db_name:
    user => $trac_db_user,
    password => $mysql_trac_pw,
    host => $trac_db_host,
    grant => ['all'],
    sql => '/tmp/trac.init',
    require => File['/tmp/trac.init'],
  }

  # Populate the database, but only run if a given table doesn't exist
  exec { 'pop_db':
    command => "mysql -u trac --password='${mysql_trac_pw}' trac < /srv/secrets/mysql/trac.db; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/trac_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/trac_installed',
    require => Mysql::Db['trac'],
  }

  # Copy the trac attachments from backup, but only if it doesn't
  # already exist
  file { "${trac_env_root}/attachments":
    ensure  => 'directory',
    source  => '/srv/secrets/trac/attachments',
    recurse => true,
    require => File[$trac_env_root],
  }

  # Install the trac config file
  $www_canonical_hostname = extlookup('www_canonical_hostname')
  # Yes, it really does re-use the gerrit email credential
  $trac_email_pw = extlookup('gerrit_email_pw')
  $trac_email_user = extlookup('gerrit_email_user')
  $trac_email_smtp = extlookup('gerrit_email_smtp')
  $trac_db_string = "mysql://${trac_db_user}:${mysql_trac_pw}@${trac_db_host}/${trac_db_name}"
  $trac_env_conf = "${trac_env_root}/conf"
  file { $trac_env_conf:
    ensure  => 'directory',
    require => File[$trac_env_root],
  }
  $trac_env_ini = "${trac_env_conf}/trac.ini"
  file { $trac_env_ini:
    ensure  => 'file',
    mode    => '0660',
    content => template('sr-site/trac.ini.erb'),
    require => File[$trac_env_conf],
  }

  # Install the logo
  $trac_env_htdocs = "${trac_env_root}/htdocs"
  file { $trac_env_htdocs:
    ensure  => 'directory',
    require => File[$trac_env_root],
  }
  file { "${trac_env_htdocs}/sr-trac.png":
    ensure => 'file',
    source => 'puppet:///modules/sr-site/sr-trac.png',
    require => File[$trac_env_htdocs],
  }

  # Folder for the logs
  file { "${trac_env_root}/log":
    ensure  => 'directory',
    require => File[$trac_env_root],
  }

  # Install the trac plugins
  vcsrepo { "${trac_env_root}/plugins":
    ensure => 'present',
    provider => 'git',
    source => "${git_root}/trac-plugins.git",
    revision => 'origin/master',
    group => 'root',
    owner => 'apache',
    require => File[$trac_env_root],
  }

  # Install the site template
  $trac_env_templates = "${trac_env_root}/templates"
  file { $trac_env_templates:
    ensure  => 'directory',
    require => File[$trac_env_root],
  }
  file { "${trac_env_templates}/site.html":
    ensure => 'file',
    content => template('sr-site/trac-site.html.erb'),
    require => File[$trac_env_templates],
  }

  # Install the README and VERSION files.
  # Not really sure if these are needed, but they're not hard to create
  file { "${trac_env_root}/README":
    ensure => 'file',
    content => 'This directory contains a Trac environment created by a puppet run.
Visit http://trac.edgewall.org/ for more information.
',
    require => File[$trac_env_root],
  }
  file { "${trac_env_root}/VERSION":
    ensure => 'file',
    content => 'Trac Environment Version 1
',
    require => File[$trac_env_root],
  }

  file { $trac_env_root:
    ensure  => 'directory',
  }

  # Install WSGI service file
  file { '/var/www/trac':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  file { '/var/www/trac/trac.wsgi':
    ensure => present,
    owner => root,
    group => root,
    mode => '0644',
    source => 'puppet:///modules/sr-site/trac.wsgi',
  }

  if $devmode {

    # When in devmode, make all authenticated users TRAC_ADMINs
    # and give everyone access to XML_RPC
    exec { 'dev_perms':
      command => 'trac-admin /srv/trac permission add authenticated TRAC_ADMIN; \
      trac-admin /srv/trac permission add anonymous XML_RPC; \
      touch /usr/local/var/sr/trac_perms_configured',
      provider => 'shell',
      creates => '/usr/local/var/sr/trac_perms_configured',
      require => [ Exec['pop_db'], File[$trac_env_ini] ],
    }

  }

}
