# Primary configuartion for the "External Authentication" system

class www::external-auth ( $git_root, $web_root_dir, $ext_auth_root_dir ) {

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
    require => Vcsrepo[ "${ext_auth_root_dir}" ],
  }

  # Local configuration for external-auth (namely to use the IDE for authentication)
  file { "${ext_auth_root_dir}/server/etc/config.inc.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => 'puppet:///modules/www/ext_auth.config.inc.php',
    require => Vcsrepo["${ext_auth_root_dir}"],
  }

  # Directory to store server keys
  file { "${ext_auth_root_dir}/keys":
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '644',
    require => Vcsrepo["${ext_auth_root_dir}"],
  }

  # The server's private key
  file { "${ext_auth_root_dir}/keys/server":
    source => '/srv/secrets/external-auth/server',
    owner => 'root',
    group => 'root',
    mode => '644',
    require => File["${ext_auth_root_dir}/keys"],
  }

  # The server's public key
  file { "${ext_auth_root_dir}/keys/server.pub":
    source => '/srv/secrets/external-auth/server.pub',
    owner => 'root',
    group => 'root',
    mode => '644',
    require => File["${ext_auth_root_dir}/keys"],
  }

  # Symlink to make it appear in the right place
  file { "${web_root_dir}/external-auth/":
    ensure => 'link',
    target => "${ext_auth_root_dir}/server/",
  }

}
