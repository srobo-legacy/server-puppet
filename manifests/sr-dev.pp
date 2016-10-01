$extlookup_datadir = '/srv/secrets'
$extlookup_precedence = [ 'common' ]
$devmode = true

class { 'sr_site':
  git_root => 'git://git.srobo.org',
}
