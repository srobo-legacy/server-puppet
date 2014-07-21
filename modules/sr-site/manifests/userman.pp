# This adds a checkout of userman.git into the root user's home folder.
# While not entirely needed on the live server, it's very useful,
# especially on development badger instances

class sr-site::userman ( $git_root ) {
  # Checkout of userman's code.
  $root_dir = '/root/userman'
  vcsrepo { $root_dir:
    ensure    => present,
    provider  => git,
    source    => "${git_root}/userman.git",
    revision  => 'origin/master',
    owner     => 'root',
    group     => 'root',
    require   => Package['PyYAML', 'python-ldap'],
  }

  # local configuration is stored in local.ini
  $local_ini = "${root_dir}/sr/local.ini"
  $ldap_manager_pw = extlookup('ldap_manager_pw')
  file { $local_ini:
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('sr-site/userman_srusers.ini.erb'),
    require => Vcsrepo[$root_dir],
  }
}
