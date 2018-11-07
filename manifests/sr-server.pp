$devmode = false

class { 'sr_site':
  git_root => '/srv/git',
}
