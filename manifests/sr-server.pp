$extlookup_datadir = '/srv/secrets'
$extlookup_precedence = [ 'common' ]
$devmode = false

class { 'sr-site':
  git_root => '/srv/git',
}
