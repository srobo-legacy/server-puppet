
class www::httpd {
  $anonpw = extlookup("ldap_anon_user_pw")

  # trac config is in ssl.conf, so we need that
  require sr-site::trac

  package { [ "httpd", "mod_ssl" ]:
    ensure => latest,
  }

  # Ensure /var/www belongs to wwwcontent, allowing vcsrepos to be cloned
  # into it.
  file { '/var/www':
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '755',
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
