
class sr-site::chronyd {

  package { [ "chrony" ]:
    ensure => latest,
  }

  service { "chronyd":
    ensure => running,
    require => Package[ "chrony" ]
  }

}
