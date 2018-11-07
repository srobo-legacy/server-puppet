$devmode = hiera('devmode')

class { 'sr_site':
  git_root => hiera('git_root'),
}
