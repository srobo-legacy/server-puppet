$extlookup_datadir = "/srv/secrets"
$extlookup_precedence = [ "common" ]
$devmode = 0

class { "sr-site":
  git_root => "/srv/git",
}
