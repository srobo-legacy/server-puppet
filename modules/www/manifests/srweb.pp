
class www::srweb ( $git_root ) {
  $root = "/var/www/html"

  package { [ "php", "php-Smarty" ]:
    ensure => latest,
    notify => Package[ "httpd" ],
  }

  # Maintain a git clone of the website
  vcsrepo { "${root}":
    ensure => present,
    provider => git,
    source => "${git_root}/srweb.git",
    revision => "master",
    force => true,
    require => Package[ "php" ],
  }

  # srweb needs this directory to belong to apache
  file { "${root}/templates_compiled":
    ensure => directory,
    owner => "apache",
    group => "apache",
    mode => "u=rwx,g=rwxs,o=rx",
    recurse => false,
    require => Vcsrepo[ "${root}" ],
  }

  # Set the rewrite base
  exec { "rewritebase":
    command => "sed -i .htaccess -e 's#/~chris/srweb#/#'",
    onlyif => "grep '~chris' /var/www/html/.htaccess",
    cwd => "${root}",
    subscribe => Vcsrepo[ "${root}" ],
  }

}
