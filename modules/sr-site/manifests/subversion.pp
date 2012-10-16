class sr-site::subversion {
  # Install subversion package(s)
  class {'::subversion': # :: for global namespace
  }

  group { 'svn':
    ensure => present,
    members => ['svn', 'apache'],
  }

  user { 'svn':
    ensure => present,
    comment => 'Owner of SR SVN repository',
    shell => '/sbin/nologin',
    gid => 'svn',
  }

  # Define the sr svn repo
  subversion::svnrepo { 'sr': # /srv/svn is pasted on the front
    owner => 'svn',
    group => 'svn',
    mode => '644',
    require => User['svn'],
  }
}
