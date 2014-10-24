# The IDE. Here be dragons.

class www::ide ( $git_root, $root_dir ) {
  # Numerous packages are required; the IDE is written in php, binds to ldap,
  # runs pylint to syntax check things. In the past it used a java web browser
  # plugin which is why there are java dependancies, but it's not been deployed
  # this year (sr2013). Everyone I spoke to didn't want it to exist any more.
  package { ['pylint', 'php-cli', 'php-ldap',

              #### Packages required for packaging robot.zip:
              # These contain the various *-strip utils required:
              'msp430-binutils', 'binutils-arm-linux-gnu',
              # Contains readelf:
              'binutils',
            ]:

    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo[$root_dir],
  }

  $ide_repos_root = "${root_dir}/repos"

  # Checkout of cyanide, acts as backend and serves the frontend of the IDE.
  vcsrepo { $root_dir:
    ensure => present,
    provider => git,
    source => "${git_root}/cyanide.git",
    revision => 'origin/master',
    user =>'wwwcontent',
    require => Class['srweb'],
  }

  # Secret key for encrypting IDE cookies, protecting against users twiddling
  # with stored data.
  file { "${root_dir}/config/ide-key.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => extlookup('ide_cookie_key'),
    require => Vcsrepo[$root_dir],
  }

  # Site-local configuration is stored in local.ini; assign some variables that
  # will be templated into it.
  $ide_key_file = "${root_dir}/config/ide-key.key"
  $team_status_dir = "${root_dir}/settings/team-status"
  $team_status_imgs_dir = "${root_dir}/uploads/team-status"
  $team_status_imgs_live_dir = "${root_dir}/../images/teams"
  $ide_ldap_pw = extlookup('ide_ldap_user_pw')
  file { "${root_dir}/config/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/ide_config.ini.erb'),
    require => Vcsrepo[$root_dir],
  }

  # IDE ldap user has general read access to ou=groups,o=sr.
  $ide_user = extlookup('ide_ldap_user_uid')
  ldapres { "uid=${ide_user},ou=users,o=sr":
    ensure => present,
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup('ldap_manager_pw'),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['sr-site::openldap'],
    objectclass => ['inetOrgPerson', 'uidObject', 'posixAccount'],
    uid => $ide_user,
    cn => 'IDE account',
    sn => 'IDE account',
    uidnumber => '2323',
    gidnumber => '1999', # srusers
    homedirectory => '/home/ide',
    userpassword => extlookup('ide_ldap_user_ssha_pw'),
  }

  # Zips directory contains generated zips, unsuprisingly. To be writeable
  # by apache. (Was configured 02777 on optimus, so it is here)
  file { "${root_dir}/zips":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Settings dir, contains user config goo, as well as team-status. (Was
  # configured 02777 on optimus, so it is here).
  file { "${root_dir}/settings":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Directory for user repos; self explanatory.
  file { $ide_repos_root:
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Notifications. Never used, to my knowledge.
  file { "${root_dir}/notifications":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Team Status dir. Contains post-reviewed team-status images
  # Warning: This folder is actually outside the IDE tree!
  #          It should already exist -- we're just setting permissions here
  file { $team_status_imgs_live_dir :
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Class['srweb'],
  }

  # Install team status images from backup.
  exec { 'team_status_install':
    user => 'root',
    command => "su -m apache -c 'cp -r /srv/secrets/team_status_images/* ${team_status_imgs_live_dir}'; touch /usr/local/var/sr/team_status_images_installed",
    creates => '/usr/local/var/sr/team_status_images_installed',
    require => File[$team_status_imgs_live_dir],
  }

  # Uploads dir. Contains un-reviewed team-status images
  file { "${root_dir}/uploads":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Web Cache. Used for the combined CSS & JS files.
  file { "${root_dir}/web/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2777',
    require => Vcsrepo[$root_dir],
  }

  # Script for applying the desired configuration to all repos. Not done
  # automatically, only when administratively desired.
  file { "${ide_repos_root}/conf":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0744',
    content => template('www/conf.erb'),
  }

  # All-repo integrity checking script for after crashes.
  file { "${ide_repos_root}/fsck":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0744',
    content => template('www/fsck.erb'),
  }

  # Script for repacking/gcing user repos
  file { "${ide_repos_root}/repack":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0744',
    content => template('www/repack.erb'),
  }

  # Install backed up IDE copy unless data is already installed. This is based
  # on the assumption that all IDE data is in {config/settings/notifications}.
  exec { 'ide_copy':
    command =>
         "cp -r /srv/secrets/ide/notifications/* ${root_dir}/notifications;\
          if test $? != 0; then exit 1; fi;\
          cp -r /srv/secrets/ide/repos/* ${ide_repos_root};\
          if test $? != 0; then exit 1; fi;\
          cp -r /srv/secrets/ide/settings/* ${root_dir}/settings;\
          if test $? != 0; then exit 1; fi;\
          chown -R apache.apache ${ide_repos_root}/*;\
          chown -R apache.apache ${root_dir}/notifications/*;\
          chown -R apache.apache ${root_dir}/settings/*;\
          touch /usr/local/var/sr/ide_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/ide_installed',
    require => [File["${root_dir}/notifications"],File[ $ide_repos_root ]],
  }

  cron { 'ide-cron':
    command => 'curl --insecure https://localhost/ide/control.php/cron/cron',
    hour => '3',
    minute => '14',
    user => 'root',
    require => Vcsrepo[$root_dir],
  }

  package{'zip':
    ensure => present,
  }

  # Install the wifi keys that get exported in robot.zip into /etc, for reading
  # by the IDE.
  # The creation of the /etc/sr directory could be somewhere better; that can
  # be improved at a later date.
  file { '/etc/sr/':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '755',
  }

  file { '/etc/sr/wifi-keys.yaml':
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '440',
    source => "/srv/secrets/wifi-keys.yaml",
  }
}
