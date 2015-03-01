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
  class { 'www::srweb':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => [User['wwwcontent'], File['/var/www']],
  }

  # Python 2.7.5 docs -- version match the python on the BBs
  class { 'www::python-docs':
    web_root_dir => $web_root_dir,
    version => '2.7.5',
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Voting scripts, at srobo.org/~voting/voting
  class { 'www::voting':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  # Community guidelines
  class { 'www::community_guidelines':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => [User['wwwcontent'], Class['www::srweb']],
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
    root_dir => "${web_root_dir}/ide",
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Piwik, for getting information about visitors, srobo.org/piwik
  class { 'www::piwik':
    git_root => $git_root,
    root_dir => "${web_root_dir}/piwik",
    require => [User['wwwcontent'], Class['srweb']],
  }

  # Web facing user managment interface, srobo.org/userman
  class { 'www::nemesis':
    git_root => $git_root,
    root_dir => '/srv/nemesis',
    require => User['wwwcontent'],
  }

  # Web facing user competition state interface, srobo.org/comp-api
  class { 'www::comp-api':
    root_dir => '/srv/comp-api',
    require => User['wwwcontent'],
  }

  # Competition state vending for shepherds
  class { 'www::comp-display':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => User['wwwcontent'],
  }

  class { 'www::teamgit':
    ide_root_dir => "${web_root_dir}/ide",
    require => Class['ide'],
  }

  # Ticket System
  class { 'www::tickets':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => [Class['srweb'], Class['sr_site::Openldap']],
  }

  # Media Consent System
  class { 'www::mediaconsent':
    git_root => $git_root,
    web_root_dir => $web_root_dir,
    require => [Class['srweb'], Class['sr_site::Openldap'], Class['tickets']],
  }



}
