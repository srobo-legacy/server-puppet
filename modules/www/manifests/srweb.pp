# Primary config goo for the root website

class www::srweb ( $git_root, $web_root_dir ) {

  # Use Smarty v2
  $smarty_dir = '/usr/share/php/Smarty/'

  package { 'php-Smarty':
    ensure => latest,
    alias  => 'php-Smarty'
  }

  # srweb is served through php and some other goo,
  package { [ 'php', 'php-xml', 'memcached']:
    ensure => latest,
    notify => Service[ 'httpd' ],
  }

  # needed to build the sitemap
  package { [ 'linkchecker', 'python-BeautifulSoup' ]:
    ensure => latest,
  }

  # needed to build the dependencies
  package { 'npm':
    ensure => latest
  } ->
  package { 'bower':
    provider => 'npm',
    ensure => 'latest'
  }

  # Install and run memcached for the plus plus speed.
  service { 'memcached':
    ensure => 'running',
    enable => true,
    hasrestart => true,
    hasstatus => true,
  }

  # Ensure that the web root directory is correctly owned before installing
  # srwebthere. Vcsrepo will throw it's cookies otherwise.
  #
  file { $web_root_dir:
    ensure => directory,
    before => Vcsrepo[$web_root_dir],
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644'
  }

  # Maintain a checkout of the website
  vcsrepo {$web_root_dir:
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/srweb.git",
    revision => 'origin/master',
    require   => [ Package['php'], Package['php-Smarty'], ],
  }

  # build the bower dependencies
  exec { 'install srweb dependencies':
    command => 'bower install',
    path => ['/usr/bin', '/usr/local/bin'],
    refreshonly => true,
    subscribe => [VCSRepo[$web_root_dir], Package['bower']]
  }

  # srweb needs this directory to belong to apache
  file { "${web_root_dir}/templates_compiled":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => 'u=rwx,g=rwxs,o=rx',
    recurse => false,
    require => Vcsrepo[$web_root_dir],
  }

  # srweb needs this directory to be writeable too
  file { "${web_root_dir}/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => 'u=rwx,g=rwxs,o=rx',
    recurse => false,
    require => Vcsrepo[$web_root_dir],
  }

  # Local configuration for srweb - specifically setting the LIVE_SITE option
  # to true.
  file { "${web_root_dir}/local.config.inc.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/srweb_local.config.inc.php.erb'),
    require => Vcsrepo[$web_root_dir],
  }

#
#  # Build the sitemap.xml
#  $www_canonical_hostname = extlookup('www_canonical_hostname')
#  exec { 'build-sitemap':
#    command => "${web_root_dir}/createsitemap.sh 'https://${www_canonical_hostname}'",
#    cwd => $web_root_dir,
#    user => 'wwwcontent',
#    subscribe => Vcsrepo[$web_root_dir],
#    require => Package['linkchecker'],
#  }
#
  # Maintain existance and permissions on the 404log.
  file { "${web_root_dir}/404log":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0664',
    require => Vcsrepo[$web_root_dir],
  }

  # Configure php
  file { '/etc/php.ini':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    source => 'puppet:///modules/www/php.ini',
  }

  # Create subscribed_people. No need for extended acls because we don't need
  # the group to be www-admin any more. People filling out the joining form
  # will have an entry written to this file (and a pipebot notification)
  file { "${web_root_dir}/subscribed_people.csv":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0660',
    require => Vcsrepo[$web_root_dir],
  }
}
