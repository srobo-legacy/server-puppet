class www::nemesis ( $git_root, $root_dir ) {
  package { ['python-sqlite3dbm']:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo["${root_dir}"],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "https://github.com/samphippen/nemesis.git",
    revision => "master",
    force => true,
    owner => 'wwwcontent'
  }

  exec { "${root_dir}/nemesis/make_db.sh":
    cwd => "${root_dir}/nemesis",
    creates => "${root_dir}/nemesis/db/nemesis.sqlite",
    path => ["/usr/bin"],
    user => "wwwcontent"
  }

  file { "${root_dir}/nemesis/nemesis.wsgi":
    source => "puppet:///modules/www/nemesis.wsgi"
  }
}
