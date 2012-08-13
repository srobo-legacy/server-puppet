
class www::httpd {

  package { [ "httpd" ]:
    ensure => latest,
  }

  file { "httpd.conf":
    path => "/etc/httpd/conf/httpd.conf",
    owner => root,
    group => root,
    mode => "0600",
    source => "puppet:///modules/www/httpd.conf",
  }

  service { "httpd":
    enable => true,
    ensure => running,
    subscribe => [ Package[ "httpd" ],
                   File[ "httpd.conf" ] ],
  }


}
