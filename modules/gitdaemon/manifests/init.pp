

class gitdaemon {

  package { "xinetd":
    ensure => latest,
  }

  service { "xinetd":
    enable => true,
    ensure => running,
  }

  package { "git-daemon":
      ensure => latest,
  }

  Package["xinetd"] ~> Service["xinetd"]


}
