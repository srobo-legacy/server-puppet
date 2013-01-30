# Primary file for the www module - all this does is include other puppet files
# to configure portions of the website.

class www( $git_root ) {
  $web_root_dir = '/var/www/html'

  include www::httpd

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

  # Primary website served at https://studentrobotics.org. Other applications
  # exist either as subdirectories or aliases.
  class { "www::srweb":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  # Voting scripts, at srobo.org/~voting/voting
  class { "www::voting":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  # phpBB forum, at srobo.org/forum
  class { 'www::phpbb':
    git_root => $git_root,
    root_dir => '/var/www/phpbb',
    require => User['wwwcontent'],
  }

  # The IDE, srobo.org/ide
  class { 'www::ide':
    git_root => $git_root,
    root_dir => '/var/www/html/ide',
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Piwik, for getting information about visitors, srobo.org/piwik
  class { 'www::piwik':
    git_root => $git_root,
    root_dir => '/var/www/html/piwik',
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Redundant dir for installing the user management web interface; now lives
  # in www::nemesis
  class { 'www::userman':
    git_root => $git_root,
    root_dir => '/var/www/html/userman',
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Web facing user managment interface, srobo.org/userman
  class { 'www::nemesis':
    git_root => $git_root,
    root_dir => '/srv/nemesis',
    require => User['wwwcontent'],
  }

  include www::teamgit
}
