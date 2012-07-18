
class bee {

  file { "/etc/motd":
    mode => 444,
    owner => root,
    group => root,
    source => "puppet:///modules/bee/motd",
  }

}
