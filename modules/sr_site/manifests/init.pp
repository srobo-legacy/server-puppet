# Root this-is-the-sr-server config file. Fans out to different kinds of service
# we operate.

# git_root: The root URL to access the SR git repositories
class sr_site( $git_root ) {

  # Default PATH
  Exec {
    path => [ '/usr/bin' ],
  }

  # Directory for 'installed flags' for various flavours of data. When some
  # piece of data is loaded from backup/wherever into a database, files here
  # act as a guard against data being reloaded.
  file { '/usr/local/var':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }

  file { '/usr/local/var/sr':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0700',
    require => File['/usr/local/var'],
  }

  # Choose speedy yum mirrors
  package { 'yum-plugin-fastestmirror':
    ensure => latest,
  }

  # Anonymous git access
  include gitdaemon

  # The bee
  include bee

  # Monitoring
  class { 'monitoring':
    git_root => $git_root,
  }

  class { 'sr_site::firewall':
    require => File['/usr/local/var/sr'],
  }

  class { 'sr_site::mysql':
    require => File['/usr/local/var/sr'],
  }

  class { 'sr_site::openldap':
    require => File['/usr/local/var/sr'],
  }

  class { 'sr_site::trac':
    git_root => $git_root,
    require => [File['/usr/local/var/sr'],
		Class['www']],
  }

  class { 'sr_site::gerrit':
    require => File['/usr/local/var/sr'],
  }

  include sr_site::subversion
  include sr_site::login
  include sr_site::meta

  class { 'sr_site::git':
    git_root => $git_root,
  }

  # Sends emails to LDAP groups
  class { 'sr_site::fritter':
    git_root => $git_root,
  }

  class { 'sr_site::srcomp':
    git_root => $git_root,
    src_dir  => '/usr/local/src/srcomp',
    venv_dir => '/var/lib/srcomp-venv'
  }

  # Web stuff
  class { 'www':
    git_root => $git_root,
    require => File['/usr/local/var/sr'],
  }

  class { 'sr_site::backup':
    git_root => $git_root,
  }

  class { 'sr_site::pipebot':
    git_root => $git_root,
  }

  class { 'sr_site::userman':
    git_root => $git_root,
  }

  class { 'sr_site::willie':
    git_root => $git_root,
  }

  # Sanity stuff
  package { "rsyslog":
    ensure => latest,
  }

  file {'/etc/systemd/journald.conf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0755',
    source => 'puppet:///modules/sr_site/journald.conf'
  }
}
