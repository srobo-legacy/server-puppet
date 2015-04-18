# Configuration to install an IDE specific httpd service that does nothing
# other than run the IDE. The idea being that it can then have it's own
# dedicated apache worker processes, and thus requests for the IDE do not need
# to compete with the rest of the website.

class www::ide_httpd ($git_root, $root_dir) {
  # No additional packages are required

  File {
    owner => 'root',
    group => 'root',
    mode => '0600',
  }

  # Install httpd configuration files. First, server-wide engine config file
  file { "/etc/httpd/conf/ide.conf":
    ensure => present,
    content => template('www/ide-httpd.conf.erb'),
  }

  # Directory for storing ide config files
  file { "/etc/httpd/conf.ide.d":
    ensure => directory,
    mode => '0755',
  }

  # IDE service configuration file: listens on port 8443, using SSL, serves
  # srcomp and the underlying IDE situation.
  file { "/etc/httpd/conf.ide.d/ssl.conf":
    ensure => present,
    content => template('www/ide-ssl.conf.erb'),
  }

  # File to enable php in the ide specific httpd
  file { "/etc/httpd/conf.ide.d/php.conf":
    ensure => present,
    content => template('www/php.conf.erb'),
  }
}
