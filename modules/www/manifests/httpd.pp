# Primary webserver configuration. The server part that is, not what gets served

class www::httpd( $web_root_dir ) {
  # Set some overall configuration for the main apache webserver
  # Change with extreme caution!
  $serve_over_ssl = false
  $service_port_no = 8000

  # Webserver binds to LDAP for certain auth/authz operations; use the
  # anon user + password to do that.
  $anonpw = hiera('ldap_anon_user_pw')

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
  $competition_services = hiera('competition_services')
  $competitor_services = hiera('competitor_services')
  $volunteer_services = hiera('volunteer_services')
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

  if !hiera('static_tls_certificate') {
    file { "${web_root_dir}/.well-known":
      ensure  => directory,
      owner   => 'wwwcontent',
      group   => 'apache',
      mode    => '0755',
      require => File[$web_root_dir],
    } ->
    file { "${web_root_dir}/.well-known/acme-challenge":
      ensure  => directory,
      owner   => 'wwwcontent',
      group   => 'apache',
      mode    => '0755',
    }

    class { letsencrypt:
      # Note: if setting up a server for testing, you may want to un-comment
      # these lines to avoid polling the live letsencrypt API too much and
      # getting rate limited.
      # config => {
      #     server  => 'https://acme-staging.api.letsencrypt.org/directory',
      # },
      # TODO: make this safe
      unsafe_registration => true,
    }

    letsencrypt::certonly { $::fqdn:
      plugin        => webroot,
      webroot_paths => [$web_root_dir],
      require       => [
        Service['httpd'],
        File['ssl.conf', "${web_root_dir}/.well-known/acme-challenge"],
      ],
      notify        => Service['nginx'],
    } -> File['server.crt', 'server.key']

    file { 'server.crt':
      path    => '/etc/pki/tls/certs/server.crt',
      ensure  => link,
      target  => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
    }
    file { 'server.key':
      path    => '/etc/pki/tls/private/server.key',
      ensure  => link,
      target  => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
    }
  } else {
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
}

  # The webserver process itself; restart on updates to some important files.
  service { 'httpd':
    ensure => running,
    enable => true,
    subscribe => [Package['httpd'],
                  Package['mod_ssl'],
                  File['httpd.conf'],
                  File['ssl.conf'],
                ],
    require => File[$web_root_dir],
  }

  if $serve_over_ssl {
    File['server.key'] ~> Service['httpd']
  }
}
