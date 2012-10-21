class www::userman ( $root_dir, $git_root ) {
  package { "mod_wsgi":
    ensure => present,
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => 'git://github.com/samphippen/nemesis.git', # Should be come SR hosted
    force => true,
  }
}
