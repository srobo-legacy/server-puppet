$extlookup_datadir = '/srv/secrets'
$extlookup_precedence = [ 'common' ]
$devmode = false

class { 'sr_site':
  git_root => '/srv/git',
}
