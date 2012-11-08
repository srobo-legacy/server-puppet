class www::ide ( $git_root, $root_dir ) {
  package { ['pylint', 'php-cli', 'java-1.7.0-openjdk', 'ant', 'php-ldap']:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo["${root_dir}"],
  }

  # NB: the applet is deliberately unconfigured because everyone I speak to
  # doesn't want it to exist any more.
  vcsrepo { "${root_dir}":
    ensure => present,
    provider => git,
    source => "${git_root}/cyanide.git",
    revision => "origin/master",
    force => true,
    user =>'wwwcontent',
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

  $ide_key_file = "${root_dir}/config/ide-key.key"
  $team_status_dir = "${root_dir}/settings/team-status"
  $team_status_imgs_dir = "${root_dir}/uploads/team-status"
  $ide_ldap_pw = extlookup('ide_ldap_user_pw')
  file { "${root_dir}/config/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/ide_config.ini.erb'),
    require => Vcsrepo["${root_dir}"],
  }

  $ide_user = extlookup('ide_ldap_user_uid')
  ldapres { "uid=${ide_user},ou=users,o=sr":
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['sr-site::openldap'],
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    uid => $ide_user,
    cn => "IDE account",
    sn => "IDE account",
    uidnumber => 2321,
    gidnumber => 1999, # srusers
    homedirectory => '/home/ide',
    userpassword => extlookup('ide_ldap_user_ssha_pw'),
  }

  file { "${root_dir}/zips":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/settings":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/repos":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/notifications":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/repos/conf":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '744',
    source => 'puppet:///modules/www/conf',
  }

  file { "${root_dir}/repos/fsck":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '744',
    source => 'puppet:///modules/www/fsck',
  }

  file { "${root_dir}/repos/repack":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '744',
    source => 'puppet:///modules/www/repack',
  }
}
