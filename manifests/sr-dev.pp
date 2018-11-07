$devmode = true

class { 'sr_site':
  git_root => 'git://git.srobo.org',
}
