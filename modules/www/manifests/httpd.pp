# Primary webserver configuration. The server part that is, not what gets served

class www::httpd( $web_root_dir ) {
  # Webserver binds to LDAP for certain auth/authz operations; use the
  # anon user + password to do that.
  $anonpw = extlookup("ldap_anon_user_pw")

  # Use apache + mod_ssl to serve, wsgi for python services
  package { [ "httpd", "mod_wsgi",]:
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

  # Load some configuration for httpd.conf. Sets up the general web server
  # operation, number of processes, etc
  $www_canonical_hostname = extlookup('www_canonical_hostname')
  $www_base_hostname = extlookup('www_base_hostname')
  file { "httpd.conf":
    path => "/etc/httpd/conf/httpd.conf",
    owner => root,
    group => root,
    mode => "0600",
    content => template('www/httpd.conf.erb'),
    require => Package[ "httpd" ],
  }


  # The webserver process itself; restart on updates to some important files.
  service { "httpd":
    enable => true,
    ensure => running,
    subscribe => [ Package[ "httpd" ],
                   File[ "httpd.conf" ] ],
  }
}
