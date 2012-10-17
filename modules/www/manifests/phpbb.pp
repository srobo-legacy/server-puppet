class www::phpbb ( $git_root, $root_dir ) {
  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "${git_root}/sr-phpbb3.git",
    revision => "master",
    force => true,
    require => Package[ "php" ],
  }
}
