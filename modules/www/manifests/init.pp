
class www( $git_root ) {
  $web_root_dir = '/var/www/html'

  include www::httpd

  # We shouldn't let apache own any web content, lest it be able to edit
  # content rather than just serve it.
  user { 'wwwcontent':
    ensure => present,
    comment => 'Owner of all/most web content',
    shell => '/bin/sh',
    gid => 'apache',
    require => Class['www::httpd'],
  }

  class { "www::srweb":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  class { "www::voting":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  class { 'www::phpbb':
    git_root => $git_root,
    root_dir => '/var/www/vhosts/phpbb',
    require => User['wwwcontent'],
  }

  class { 'www::ide':
    git_root => $git_root,
    root_dir => '/var/www/html/ide',
    require => [User['wwwcontent'], Class['srweb']],
  }

  class { 'www::piwik':
    git_root => $git_root,
    root_dir => '/var/www/html/piwik',
    require => [User['wwwcontent'], Class['srweb']],
  }

  class { 'www::userman':
    git_root => $git_root,
    root_dir => '/var/www/html/userman',
    require => [User['wwwcontent'], Class['srweb']],
  }
}
