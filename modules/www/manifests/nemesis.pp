# 'Nemesis' is the web frontend of the user management interface, allowing
# teachers to administrate users at their college, and register the details of
# new ones. SR blueshirt config might end up being operated by this interface
# too in the future.

class www::nemesis ( $git_root, $root_dir ) {
  # Nemesis is a flask application
  # An sqlite DB is used to store data, install the python bindings for it.

  $nemesis_db = "${root_dir}/nemesis/db/nemesis.sqlite"

  package { 'sqlite':
    ensure  => present,
  }

  package { ['python-sqlite3dbm',
             'python-flask']:
    ensure  => present,
    notify  => Service['httpd'],
  }

  # Main checkout of the Nemesis codebase
  vcsrepo { $root_dir:
    ensure => present,
    provider => git,
    source => "${git_root}/nemesis.git",
    revision => 'origin/master',
    owner => 'wwwcontent',
    group => 'apache',
    require => Package['python-flask',
                       'python-ldap',
                       'python-sqlite3dbm',
                       'python-unidecode'],
    notify => Service['httpd'],
  }

  # Generate the SQLite DB for registration storage, unless it already
  # exists.
  exec { "${root_dir}/nemesis/scripts/make_db.sh":
    cwd => "${root_dir}/nemesis",
    creates => $nemesis_db,
    path => ['/usr/bin'],
    user => 'wwwcontent',
    require => [Vcsrepo[$root_dir], Package['sqlite']],
  }

  # Maintain permissions of the sqlite DB. SQLite determines what user to create
  # the journal and locking files as based on who owns the DB. If it's owned
  # by wwwcontent, SQLite attempts to chown files it creates to wwwcontent,
  # and EPERMs
  file { $nemesis_db:
    owner => 'apache',
    group => 'apache',
    mode => '0660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  # Maintain the directory permissions of the sqlite db.
  file { "${root_dir}/nemesis/db":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  # Restore nemesis from backup, if it hasn't been already.
  exec { 'nemesis_install':
    command => "gzip -d < /srv/secrets/nemesis/sqlite3_dump.gz | sqlite3 $nemesis_db && touch /usr/local/var/sr/nemesis_installed",
    creates => '/usr/local/var/sr/nemesis_installed',
    require => File["${root_dir}/nemesis/db"],
  }

  # A WSGI config file for serving nemesis inside of apache.
  file { "${root_dir}/nemesis/nemesis.wsgi":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0644',
    source => 'puppet:///modules/www/nemesis.wsgi',
    require => Vcsrepo[$root_dir],
  }

  # Syslog configuration, using local0
  file { '/etc/rsyslog.d/nemesis.conf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    source => 'puppet:///modules/www/nemesis-syslog.conf',
    notify => Service['rsyslog'],
    require => Package['rsyslog'],
  }

  # Configurate nemesis with the ability to send emails.
  $nemesis_mail_smtp = hiera('nemesis_mail_smtp')
  $nemesis_mail_user = hiera('nemesis_mail_user')
  $nemesis_mail_pw   = hiera('nemesis_mail_pw')
  $nemesis_mail_from = hiera('nemesis_mail_from')
  file { "${root_dir}/nemesis/local.ini":
    ensure => present,
    content => template('www/nemesis_local.ini.erb'),
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0440',
    require => Vcsrepo[$root_dir],
  }

  # Configurate the srusers library so that nemesis can interact with LDAP.
  # Idealy this should not be using the LDAP manager account. An even more idea
  # situation would trac ticket #1053 to be applied. Until then, use the LDAP
  # manager account.
  $ldap_manager_pw = hiera('ldap_manager_pw')
  file { "${root_dir}/nemesis/libnemesis/libnemesis/srusers/local.ini":
    ensure => present,
    content => template('www/nemesis_srusers.ini.erb'),
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0440',
    require => Vcsrepo[$root_dir],
  }

  cron { 'nemesis-cron':
    command => "${root_dir}/nemesis/scripts/cron.py",
    hour => '3',
    minute => '41',
    user => 'wwwcontent',
    require => Vcsrepo[$root_dir],
  }

  # Note: we need to ensure we stay within the limits of our mail transport
  # provider. Since it's not entirely clear what those are (and they apply over
  # large time ranges - some at 10 minute windows, some at 24 hour windows), we
  # need to balance the latency of email sending we're happy with against the
  # overall number of emails we can send.
  cron { 'nemesis-email-cron':
    command => "${root_dir}/nemesis/scripts/send-emails.py --limit 5",
    minute => '*/2',
    user => 'wwwcontent',
    require => Vcsrepo[$root_dir],
  }
}
