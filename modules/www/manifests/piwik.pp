class www::piwik ( $git_root, $root_dir ) {
  package { ['php-gd']:
    ensure => present,
    notify => Service['httpd'],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => 'git://github.com/piwik/piwik.git',
    revision => '1.8.4',
    force => true,
    require => Package['php-gd', 'php-mysql'],
  }

  $piwik_user = extlookup('piwik_sql_user')
  $piwik_pw = extlookup('piwik_sql_pw')
  mysql::db { 'piwik':
    user => $piwik_user,
    password => $piwik_pw,
    host => 'localhost',
    grant => ['all'],
  }

  exec { 'pop_piwik_db':
    command => "mysql -u ${piwik_user} --password='${piwik_pw}' piwik < /srv/secrets/piwik/defaultdata.mysql; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/piwik_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/piwik_installed',
    require => Mysql::Db["piwik"],
  }

  $piwik_admin_user = extlookup('piwik_admin_user')
  $piwik_admin_md5_pw = extlookup('piwik_admin_md5_pw')
  $piwik_admin_email = extlookup('piwik_admin_email')
  file { "${root_dir}/config/config.ini.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/piwik_config.ini.php.erb'),
    before => Mysql::Db['piwik'],
  }

  file { "${root_dir}/tmp":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/templates_c":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/assets":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/tcpdf":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/config":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/sessions":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/latest":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }
}
