class www::nemesis ( $git_root, $root_dir ) {
  package { ['python-sqlite3dbm']:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo["${root_dir}"],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "${git_root}/nemesis.git",
    revision => "origin/master",
    force => true,
    owner => 'wwwcontent',
    group => 'apache',
    notify => Service['httpd'],
  }

  exec { "${root_dir}/nemesis/scripts/make_db.sh":
    cwd => "${root_dir}/nemesis",
    creates => "${root_dir}/nemesis/db/nemesis.sqlite",
    path => ["/usr/bin"],
    user => "wwwcontent",
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/nemesis/db/nemesis.sqlite":
    owner => 'apache',
    group => 'apache',
    mode => '660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  file { "${root_dir}/nemesis/db":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '660',
    require => Exec["${root_dir}/nemesis/scripts/make_db.sh"],
  }

  file { "${root_dir}/nemesis/nemesis.wsgi":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644',
    source => "puppet:///modules/www/nemesis.wsgi",
    require => Vcsrepo["${root_dir}"],
  }

  $ldap_manager_pw = extlookup('ldap_manager_pw')
  file { "${root_dir}/nemesis/userman/sr/local.ini":
    ensure => present,
    content => template('www/nemesis_conf.ini.erb'),
    owner => 'wwwcontent',
    group => 'apache',
    mode => '440',
    require => Vcsrepo["${root_dir}"],
  }
}
