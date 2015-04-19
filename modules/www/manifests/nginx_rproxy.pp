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

  # Configure service. Keep initially stopped until deployment situation
  # confirmed
  service { 'nginx':
    ensure => running,
    enable => true,
    subscribe => [Package['nginx'], File['/etc/nginx/nginx.conf']],
    require => [Service['httpd'], Service['httpd-ide']],
  }
}
