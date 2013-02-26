# Primary configuartion for the "External Authentication" system

class www::external-auth ( $git_root, $web_root_dir, $ext_auth_root_dir ) {
  # external-auth is served through php and some other goo,
  package { [ "php" ]:
    ensure => latest,
    notify => Service[ "httpd" ],
  }

  # Directory permissions and ownership of the external-auth directory. Seeing how
  # /var/www/html belongs to root by default on fedora.
  file { "${ext_auth_root_dir}":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644',
    before => Vcsrepo[ "${ext_auth_root_dir}" ],
  }

  # Maintain a checkout of the external auth system
  vcsrepo { "${ext_auth_root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/external-auth.git",
    revision => "origin/master",
    force => true,
    require => Package[ "php" ],
  }

  # external auth needs this directory to belong to apache
  file { "${ext_auth_root_dir}/server/sessions":
    ensure => directory,
    owner => "wwwcontent",
    group => "apache",
    mode => "u=rwx,g=rwxs,o=rx",
    recurse => false,
    require => Vcsrepo[ "${web_root_dir}" ],
  }

  # Local configuration for external-auth (namely to use the IDE for authentication)
  # to true.
  file { "${ext_auth_root_dir}/server/etc/config.inc.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => 'puppet:///modules/www/ext_auth.config.inc.php',
    require => Vcsrepo["${web_root_dir}"],
  }

  # Symlink to make it appear in the right place
  file { "${web_root_dir}/external-auth/":
    ensure => 'link',
    target => "${ext_auth_root_dir}/server/",
  }

}
