class www::userman ( $root_dir, $git_root ) {
  package { ['mod_wsgi', 'python-flask', 'python-ldap']:
    ensure => present,
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/userman.git",
    force => true,
  }
}
