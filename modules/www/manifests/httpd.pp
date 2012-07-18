
class www::httpd {

  package { [ "httpd" ]:
    ensure => latest,
  }

  service { "httpd":
    enable => true,
    ensure => running,
    subscribe => Package[ "httpd" ],
  }

  

}
