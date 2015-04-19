# Configuration to install an IDE specific httpd service that does nothing
# other than run the IDE. The idea being that it can then have it's own
# dedicated apache worker processes, and thus requests for the IDE do not need
# to compete with the rest of the website.

class www::ide_httpd ($git_root, $root_dir) {
  # No additional packages are required

  # Pull in relevant variables
  $www_canonical_hostname = extlookup('www_canonical_hostname')
  $www_base_hostname = extlookup('www_base_hostname')

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

  # File to enable php in the ide specific httpd
  file { "/lib/systemd/system/httpd-ide.service":
    ensure => present,
    source => 'puppet:///modules/www/httpd-ide.service',
    mode => '644',
    require => [File["/etc/httpd/conf.ide.d/php.conf"],
                File["/etc/httpd/conf.ide.d/ssl.conf"],
                File["/etc/httpd/conf.ide.d"]],
    notify => Exec['httpd-ide-systemd-load'],
  }

  # Lifted from fritter,
  # systemd has to be reloaded before picking this up,
  exec { 'httpd-ide-systemd-load':
    provider  => 'shell',
    command   => 'systemctl daemon-reload',
    onlyif    => 'systemctl --all | grep httpd-ide.service; if test $? = 0; then exit 1; fi; exit 0',
    require   => File['/lib/systemd/system/httpd-ide.service'],
  }

  # In this initial configuration, ensure it is stopped. One can then start it
  # at will and exercise it a bit.
  service { 'httpd-ide':
    ensure  => stopped,
    enable => false,
    require => Exec['httpd-ide-systemd-load'],
    subscribe => [Package['httpd'],
                  File['/etc/httpd/conf/ide.conf'],
                  File['/etc/httpd/conf.ide.d/ssl.conf']],
  }
}
