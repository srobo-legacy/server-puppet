$extlookup_datadir = "/srv/secrets"
$extlookup_precedence = [ "common" ]
$devmode = 1

class { "sr-site":
  git_root => "git://srobo.org",
}
