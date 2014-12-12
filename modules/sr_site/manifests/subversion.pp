# Subversion - which we used quite a large while ago. It's still kept around
# as it contains a) useful historic data and b) possibly data we still use.

class sr_site::subversion {
  # Install subversion package(s), using an imported subversion module
  class {'::subversion': # :: for global namespace
  }

  # Group for owning subversion files. Because puppet is rubbish, the members
  # never get configured.
  group { 'svn':
    ensure => present,
    members => ['svn', 'apache'],
  }

  # User for owning subversion files. Is /actually/ part of the svn group
  # because the primary-unix-group (gid) is ocnfigured.
  user { 'svn':
    ensure => present,
    comment => 'Owner of SR SVN repository',
    shell => '/sbin/nologin',
    gid => 'svn',
  }

  # Define the sr svn repo. Subversion module does all the heavy lifting.
  subversion::svnrepo { 'sr': # /srv/svn is pasted on the front
    owner => 'svn',
    group => 'svn',
    mode => '0644',
    require => User['svn'],
  }

  # If subversion data isn't installed yet, install it.
  exec { 'load-svn':
    command => 'fname=`mktemp /usr/local/var/sr/svn_load_XXXXXX`;\
                gzip -d -c /srv/secrets/svn/db.gz > $fname;\
                if test $? != 0; then rm $fname; exit 1; fi;\
                svnadmin load /srv/svn/sr < $fname;\
                if test $? != 0; then rm $fname; exit 1; fi;\
                rm $fname;\
                touch /usr/local/var/sr/svn_installed',
    provider => 'shell',
    creates => '/usr/local/var/sr/svn_installed',
    require => [File['/usr/local/var/sr'],Subversion::Svnrepo['sr']],
  }

  # Install historical authorization data. Required to restrict information to
  # certain files, that are in SVN but shouldn't be public.
  file { '/srv/svn/sr/authfile':
    ensure => present,
    source => 'puppet:///modules/sr_site/authfile',
    owner => 'svn',
    group => 'svn',
    mode => '0644',
    require => Subversion::Svnrepo['sr'],
  }

  # Require for SVN web access.
  package { 'mod_dav_svn':
    ensure => present,
    notify => Package['httpd'],
  }
}
