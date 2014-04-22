# Primary file for the www module - all this does is include other puppet files
# to configure portions of the website.

class www( $git_root ) {
  $web_root_dir = '/var/www/html'

  class { 'www::httpd':
    web_root_dir => $web_root_dir,
  }

  # We shouldn't let apache own any web content, lest it be able to edit
  # content rather than just serve it. So, all web content that doesn't have
  # a more appropriate user gets owned by wwwcontent (with group=apache).
  user { 'wwwcontent':
    ensure => present,
    comment => 'Owner of all/most web content',
    shell => '/bin/sh',
    gid => 'apache',
    require => Package['httpd'],
  }

  # Home dir needed so it can run cron jobs.
  file { '/home/wwwcontent':
    ensure  => directory,
    owner   => 'wwwcontent',
    group   => 'users',
    mode    => '0711',
    require => User['wwwcontent'],
  }

  # Primary website served at https://studentrobotics.org. Other applications
  # exist either as subdirectories or aliases.
  class { "www::srweb":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  # Web facing user competition state interface, srobo.org/comp-api
  class { 'www::comp-api':
    git_root => $git_root,
    root_dir => '/srv/srcomp-http',
    require => User['wwwcontent'],
  }

  # Competition state vending for shepherds and arenas
  class { 'www::comp-display':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }
}
