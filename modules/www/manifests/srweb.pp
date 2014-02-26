# Primary config goo for the root website

class www::srweb ( $git_root, $web_root_dir ) {
  # srweb is served through php and some other goo,
  package { [ "php", "php-Smarty", "php-xml", "memcached"]:
    ensure => latest,
    notify => Service[ "httpd" ],
  }

  # needed to build the sitemap
  package { [ "linkchecker", "python-BeautifulSoup" ]:
    ensure => latest,
  }

  # Install and run memcached for the plus plus speed.
  service { 'memcached':
    enable => 'true',
    ensure => 'running',
    hasrestart => 'true',
    hasstatus => 'true',
  }

  # Directory permissions and ownership of srwebs directory. Seeing how
  # /var/www/html belongs to root by default on fedora.
  file { "${web_root_dir}":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644',
    before => Vcsrepo[ "${web_root_dir}" ],
  }

  # Maintain a checkout of the website
  vcsrepo { "${web_root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/srweb.git",
    revision => "ad5a74cfb267e204b88b5a782510f54d6ed08b80",
    force => true,
    require => Package[ "php" ],
  }

  # srweb needs this directory to belong to apache
  file { "${web_root_dir}/templates_compiled":
    ensure => directory,
    owner => "wwwcontent",
    group => "apache",
    mode => "u=rwx,g=rwxs,o=rx",
    recurse => false,
    require => Vcsrepo[ "${web_root_dir}" ],
  }

  # srweb needs this directory to be writeable too
  file { "${web_root_dir}/cache":
    ensure => directory,
    owner => "wwwcontent",
    group => "apache",
    mode => "u=rwx,g=rwxs,o=rx",
    recurse => false,
    require => Vcsrepo[ "${web_root_dir}" ],
  }

  # Local configuration for srweb - specifically setting the LIVE_SITE option
  # to true.
  file { "${web_root_dir}/local.config.inc.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/srweb_local.config.inc.php.erb'),
    require => Vcsrepo["${web_root_dir}"],
  }

  # Set the rewrite base
  exec { "rewritebase":
    command => "sed -i .htaccess -e 's#/~chris/srweb#/#'",
    onlyif => "grep '~chris' '${web_root_dir}/.htaccess'",
    cwd => "${web_root_dir}",
    subscribe => Vcsrepo[ "${web_root_dir}" ],
  }
#
#  # Build the sitemap.xml
#  $www_canonical_hostname = extlookup('www_canonical_hostname')
#  exec { "build-sitemap":
#    command => "${web_root_dir}/createsitemap.sh 'https://${www_canonical_hostname}'",
#    cwd => "${web_root_dir}",
#    user => "wwwcontent",
#    subscribe => Vcsrepo[ "${web_root_dir}" ],
#    require => Package["linkchecker"],
#  }
#
  # Maintain existance and permissions on the 404log.
  file { "${web_root_dir}/404log":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '664',
  }

  # Configure php
  file { '/etc/php.ini':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '644',
    source => 'puppet:///modules/www/php.ini',
  }

  # Create subscribed_people. No need for extended acls because we don't need
  # the group to be www-admin any more. People filling out the joining form
  # will have an entry written to this file (and a pipebot notification)
  file { "${web_root_dir}/subscribed_people.csv":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '660',
  }
}
