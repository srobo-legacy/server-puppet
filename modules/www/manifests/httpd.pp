
class www::httpd {

  # trac config is in ssl.conf, so we need that
  require sr-site::trac

  package { [ "httpd", "mod_ssl" ]:
    ensure => latest,
  }

  file { "httpd.conf":
    path => "/etc/httpd/conf/httpd.conf",
    owner => root,
    group => root,
    mode => "0600",
    source => "puppet:///modules/www/httpd.conf",
    require => Package[ "httpd" ],
  }

  file { "ssl.conf":
    path => "/etc/httpd/conf.d/ssl.conf",
    owner => root,
    group => root,
    mode => "0600",
    content => template('www/ssl.conf.erb'),
    require => Package[ "mod_ssl" ],
  }

  file { "server.crt":
    path => "/etc/pki/tls/certs/server.crt",
    owner => root,
    group => root,
    mode => "0400",
    source => "/srv/secrets/https/server.crt",
    require => Package[ "mod_ssl" ],
  }

  file { "server.key":
    path => "/etc/pki/tls/private/server.key",
    owner => root,
    group => root,
    mode => "0400",
    source => "/srv/secrets/https/server.key",
    require => Package[ "mod_ssl" ],
  }

  service { "httpd":
    enable => true,
    ensure => running,
    subscribe => [ Package[ "httpd" ],
                   Package[ "mod_ssl" ],
                   File[ "httpd.conf" ],
                   File[ "ssl.conf" ],
                   File[ "server.key"] ],
  }
}
