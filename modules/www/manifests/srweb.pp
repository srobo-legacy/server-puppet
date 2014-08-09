# Primary config goo for the root website

class www::srweb ( $git_root, $web_root_dir ) {

  # Use Smarty v2, which has different package name and location on F17 vs F20
  $smarty_dir = $::operatingsystemrelease ? {
    20 => '/usr/share/php/Smarty2/',
    17 => '/usr/share/php/Smarty/',
  }
  $smarty_package = $::operatingsystemrelease ? {
    20 => 'php-Smarty2',
    17 => 'php-Smarty',
  }

  package { $smarty_package:
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

  # Install and run memcached for the plus plus speed.
  service { 'memcached':
    ensure => 'running',
    enable => true,
    hasrestart => true,
    hasstatus => true,
  }

  # Ensure that the web root directory is nonexistant before installing srweb
  # there. Vcsrepo will throw it's cookies otherwise. The before flag ensures
  # this doesn't delete the vcsrepo installation itself.
  #
  # Disabled because this triggers puppet (on badger) attempting to index the
  # entire contents of /var/www/html, for some reason. Commenting this block out
  # prevents that from happening, uncommenting resumes indexing. This may break
  # fresh builds.
  #
  #file { $web_root_dir:
  #  ensure => absent,
  #  before => Vcsrepo[$web_root_dir],
  #}

  # Maintain a checkout of the website
  vcsrepo {$web_root_dir:
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/srweb.git",
    revision => 'origin/master',
    require   => [ Package['php'], Package['php-Smarty'], ],
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

  # Set the rewrite base
  exec { 'rewritebase':
    command => 'sed -i .htaccess -e "s#/~chris/srweb#/#"',
    onlyif => "grep '~chris' '${web_root_dir}/.htaccess'",
    cwd => $web_root_dir,
    subscribe => Vcsrepo[$web_root_dir],
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
