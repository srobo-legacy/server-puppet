# Configuration to install nginx and get it to reverse-proxy to the local
# apache instance(s). Distributes traffic to the main website, and to the IDE,
# to different apache servers. The reasonf or this is load balancing; see the
# email 'Server Performance' 18/04/15 on srobo-devel

class www::nginx_rproxy ()
{
  $www_canonical_hostname = extlookup('www_canonical_hostname')

  # Install nginx
  package { 'nginx':
    ensure => latest,
  }

  # Install our nginx config file
  file { '/etc/nginx/nginx.conf':
    owner => root,
    group => root,
    mode => '0644',
    content => template('www/nginx.conf.erb'),
    require => Package[ 'nginx' ],
  }

  # Remash server certificate file into a format that nginx likes
  # In devmode, just don't cat in the bundle file
  if !$devmode {
    exec { 'nginx-mangle-cert':
      command => 'cat server.crt comodo_bundle.crt > server-nginx.crt',
      provider => 'shell',
      creates => '/etc/pki/tls/certs/server-nginx.crt',
      cwd => '/etc/pki/tls/certs',
      subscribe => [File['server.crt'], File['cert_chain']],
    }
  } else {
    exec { 'nginx-mangle-cert':
      command => 'cat server.crt > server-nginx.crt',
      provider => 'shell',
      creates => '/etc/pki/tls/certs/server-nginx.crt',
      cwd => '/etc/pki/tls/certs',
      subscribe => File['server.crt'],
    }
  }

  # Configure service. Keep initially stopped until deployment situation
  # confirmed
  service { 'nginx':
    ensure => running,
    enable => true,
    subscribe => [Package['nginx'], File['/etc/nginx/nginx.conf'],
                  Service['httpd'], Service['httpd-ide'],
                  Exec['nginx-mangle-cert']],
  }
}
