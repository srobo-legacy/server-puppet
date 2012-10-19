class www::ide ( $git_root, $root_dir ) {
  package { ['pylint', 'php-cli', 'java-1.7.0-openjdk', 'ant']:
    ensure => present,
    before => Vcsrepo["${root_dir}"],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "${git_root}/cyanide.git",
    revision => "master",
    force => true,
    owner => 'wwwcontent',
    group => 'apache',
    require => Class['srweb'],
  }
}
