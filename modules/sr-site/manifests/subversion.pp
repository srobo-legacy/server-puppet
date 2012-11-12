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

  exec { 'load-svn':
    command => 'fname=`mktemp /usr/local/var/sr/svn_load_XXXXXX`;\
                gzip -d -c /srv/secrets/svn/db > $fname;\
                svnadmin load /srv/svn/sr < $fname;\
                if test $? != 0; then exit 1; fi;\
                rm $fname;\
                touch /usr/local/var/sr/svn_installed',
    provider => 'shell',
    creates => '/usr/local/var/sr/svn_installed',
    require => [File['/usr/local/var/sr'],Subversion::Svnrepo['sr']],
  }

  file { '/srv/svn/sr/authfile':
    ensure => present,
    source => 'puppet:///modules/sr-site/authfile',
    owner => 'svn',
    group => 'svn',
    mode => '644',
    require => Subversion::Svnrepo['sr'],
  }

  # Require for SVN web access.
  package { 'mod_dav_svn':
    ensure => present,
    notify => Package['httpd'],
  }
}
