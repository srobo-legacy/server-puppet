# Root this-is-the-sr-server config file. Fans out to different kinds of service
# we operate.

# git_root: The root URL to access the SR git repositories
class sr-site( $git_root ) {

  # Default PATH
  Exec {
    path => [ "/usr/bin" ],
  }

  # Directory for 'installed flags' for various flavours of data. When some
  # piece of data is loaded from backup/wherever into a database, files here
  # act as a guard against data being reloaded.
  file { '/usr/local/var':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '755',
  }

  file { '/usr/local/var/sr':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '700',
    require => File['/usr/local/var'],
  }

  # Choose speedy yum mirrors
  package { "yum-plugin-fastestmirror":
    ensure => latest,
  }

  # The bee
  include bee

  # Alternative NTP situation that's allegedly easier to use than ntpd
  include sr-site::chronyd

  # Web stuff
  class { "www":
    git_root => $git_root,
  }
}
