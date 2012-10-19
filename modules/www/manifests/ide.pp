class www::ide ( $git_root, $root_dir ) {
  package { ['pylint', 'php-cli', 'java-1.7.0-openjdk', 'ant']:
    ensure => present,
    before => Vcsrepo["${root_dir}"],
  }

  # NB: the applet is deliberately unconfigured because everyone I speak to
  # doesn't want it to exist any more.
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

  file { "${root_dir}/config/ide-key.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => extlookup('ide_cookie_key'),
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/config/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/ide_config.ini.erb'),
    require => Vcsrepo["${root_dir}"],
  }
}
