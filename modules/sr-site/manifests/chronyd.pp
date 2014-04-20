
class sr-site::chronyd {

  package { [ "chrony" ]:
    ensure => latest,
  }

  service { "chronyd":
    ensure => running,
    require => Package[ "chrony" ],
    subscribe => [ File[ "chrony.conf" ],
                   File[ "chrony.keys" ] ],
  }

  file { "chrony.conf":
    path => "/etc/chrony.conf",
    owner => root,
    group => root,
    mode => "0644",
    content => template("sr-site/chrony.conf"),
    require => [ Package[ "chrony" ],
                 File[ "chrony.keys" ] ],
  }

  file { "chrony.keys":
    path => "/etc/chrony.keys",
    owner => root,
    group => chrony,
    mode => "0640",
    content => template("sr-site/chrony.keys"),
    require => Package[ "chrony" ],
  }

}
