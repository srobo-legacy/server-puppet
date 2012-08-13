
class www::httpd {

  package { [ "httpd", "mod_ssl" ]:
    ensure => latest,
  }

  file { "httpd.conf":
    path => "/etc/httpd/conf/httpd.conf",
    owner => root,
    group => root,
    mode => "0600",
    source => "puppet:///modules/www/httpd.conf",
  }

  file { "ssl.conf":
    path => "/etc/httpd/conf.d/ssl.conf",
    owner => root,
    group => root,
    mode => "0600",
    source => "puppet:///modules/www/ssl.conf",
  }

  file { "server.crt":
    path => "/etc/pki/tls/certs/server.crt",
    owner => root,
    group => root,
    mode => "0400",
    source => "puppet:///modules/www/server.crt",
    require => Package[ "mod_ssl" ],
  }

  file { "server.key":
    path => "/etc/pki/tls/private/server.key",
    owner => root,
    group => root,
    mode => "0400",
    source => "puppet:///modules/www/server.key",
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
