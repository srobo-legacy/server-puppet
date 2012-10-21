
class www::srweb ( $git_root, $web_root_dir ) {
  package { [ "php", "php-Smarty", "memcached"]:
    ensure => latest,
    notify => Package[ "httpd" ],
  }

  service { 'memcached':
    enable => 'true',
    ensure => 'running',
    hasrestart => 'true',
    hasstatus => 'true',
  }

  # Maintain a git clone of the website
  vcsrepo { "${web_root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/srweb.git",
    revision => "master",
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

  # Set the rewrite base
  exec { "rewritebase":
    command => "sed -i .htaccess -e 's#/~chris/srweb#/#'",
    onlyif => "grep '~chris' /var/www/html/.htaccess",
    cwd => "${web_root_dir}",
    subscribe => Vcsrepo[ "${web_root_dir}" ],
  }

  # Maintain existance and permissions on the 404log.
  file { "${web_root_dir}/404log":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '664',
  }
}
