$extlookup_datadir = "/srv/secrets"
$extlookup_precedence = [ "common" ]

class { "sr-site":
  git_root => "git://srobo.org",
}
