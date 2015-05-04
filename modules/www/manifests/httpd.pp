# Primary webserver configuration. The server part that is, not what gets served

class www::httpd( $web_root_dir ) {
  # Set some overall configuration for the main apache webserver
  # Change with extreme caution!
  $serve_over_ssl = false
  $service_port_no = 8000

  # Webserver binds to LDAP for certain auth/authz operations; use the
  # anon user + password to do that.
  $anonpw = extlookup('ldap_anon_user_pw')

  # Use apache + mod_ssl to serve, wsgi for python services
  package { [ 'httpd', 'mod_ssl', 'mod_wsgi', 'mod_ldap' ]:
    ensure => latest,
  }

 # Ensure /var/www belongs to wwwcontent, allowing vcsrepos to be cloned
  # into it.
  file { '/var/www':
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0755',
  }

  # Load some configuration for httpd.conf. Sets up the general web server
  # operation, number of processes, etc
  $www_canonical_hostname = hiera('www_canonical_hostname')
  $www_base_hostname = hiera('www_base_hostname')
  file { 'httpd.conf':
    path => '/etc/httpd/conf/httpd.conf',
    owner => root,
    group => root,
    mode => '0600',
    content => template('www/httpd.conf.erb'),
    require => Package[ 'httpd' ],
  }

  # Primary configuration file for the SSL website. Most things go in here.
  file { 'ssl.conf':
    path => '/etc/httpd/conf.d/ssl.conf',
    owner => root,
    group => root,
    mode => '0600',
    content => template('www/ssl.conf.erb'),
    require => Package[ 'mod_ssl' ],
    notify => Service['httpd'],
  }

  # Public certificate for the website, presented to all users. In dev mode,
  # a generic self-signed certificate is used. For production we have one from
  # GoDaddy
  file { 'server.crt':
    path => '/etc/pki/tls/certs/server.crt',
    owner => root,
    group => root,
    mode => '0400',
    source => '/srv/secrets/https/server.crt',
    require => Package[ 'mod_ssl' ],
  }

  # Private key for negotiating SSL connections with clients, corresponding
  # to server.crt's public key. A generic (and published publically) key for
  # dev mode.
  file { 'server.key':
    path => '/etc/pki/tls/private/server.key',
    owner => root,
    group => root,
    mode => '0400',
    source => '/srv/secrets/https/server.key',
    require => Package[ 'mod_ssl' ],
  }

  # On the production machine, we need to present some intermediate certificates
  # to users as there's an intermediate CA between the root cert and our
  # cerfificate. Not necessary on the dummy config.
  if !$devmode {
    file { 'cert_chain':
      path => '/etc/pki/tls/certs/comodo_bundle.crt',
      owner => 'root',
      group => 'root',
      mode => '0400',
      source => '/srv/secrets/https/comodo_bundle.crt',
      require => Package[ 'mod_ssl' ],
    }
  }

  # The webserver process itself; restart on updates to some important files.
  service { 'httpd':
    ensure => running,
    enable => true,
    subscribe => [Package['httpd'],
                  Package['mod_ssl'],
                  File['httpd.conf'],
                  File['ssl.conf'],
                  File['server.key'],
                ],
  }
}
