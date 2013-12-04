
class sr-site::ntpd {

  package { [ "ntp" ]:
    ensure => latest,
  }

  service { "ntpd":
    ensure => running,
    require => Package[ "ntp" ]
  }

}
