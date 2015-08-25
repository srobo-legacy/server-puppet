# Fritter sends emails to LDAP groups after review via Gerrit
###
# Nota Bene: this manifest is unable to actually install the public key
# into Gerrit, so that needs to be done manually. The service expects
# to be able to ssh in to Gerrit using its LDAP username and the ssh
# key pair from its home directory. It also needs to be granted the
# following capabilities within Gerrit:
# * 'streamEvents' (global)
# * 'label-Verified' (at least within the repo it targets)

class sr_site::fritter ( $git_root ) {
  # Create a home folder.
  # Note that because there is an LDAP user, we don't need a system user
  $fritter_user = 'fritter'
  $home_dir = "/home/${fritter_user}"
  $root_dir = "${home_dir}/fritter"

  package { ['python-paramiko']:
    ensure => present,
    before => Vcsrepo[$root_dir],
  }

  # LDAP user
  $fritter_ldap_user  = $fritter_user
  $fritter_ldap_pw    = hiera('fritter_ldap_user_pw')
  $fritter_ldap_group = "ou=users,o=sr"
  $fritter_ldap_dn    = "uid=${fritter_ldap_user},${fritter_ldap_group}"
  ldapres { $fritter_ldap_dn:
    ensure          => present,
    objectclass     => ['inetOrgPerson', 'uidObject', 'posixAccount'],
    binddn          => 'cn=Manager,o=sr',
    bindpw          => hiera('ldap_manager_pw'),
    ldapserverhost  => 'localhost',
    ldapserverport  => '389',
    uid             => $fritter_ldap_user,
    cn              => 'Reviewed email',
    sn              => 'sending user',
    uidnumber       => '3001',
    gidnumber       => '1999',
    homedirectory   => $home_dir,
    userpassword    => hiera('fritter_ldap_user_ssha_pw'),
    require         => Ldapres[$fritter_ldap_group],
    # Signal to that we need to refresh LDAP/user caches
    notify          => Exec['ldap-groups-flushed'],
  }

  # Defaults for files
  File {
    owner   => $fritter_user,
    group   => 'users',
    mode    => '0600',
    require => Ldapres[$fritter_ldap_dn],
  }

  file { $home_dir:
    ensure  => directory,
    mode    => '0700',
  }

  # Checkout of fritter's code.
  vcsrepo { $root_dir:
    ensure    => present,
    provider  => git,
    source    => "${git_root}/fritter.git",
    revision  => 'origin/master',
    owner     => $fritter_user,
    group     => 'users',
    require   => [File[$home_dir],Ldapres[$fritter_ldap_dn]],
    notify    => Service['fritter'],
  }

  # Local database for caching the emails until they're sent
  $fritter_sqlite_db = "${home_dir}/fritter.sqlite"
  ## NB: sqlite DB is backed up via hard-coded path
  exec { 'create-fritter-sqlite-db':
    command => "${root_dir}/fritter/libfritter/scripts/make_db.sh '${fritter_sqlite_db}'",
    creates => $fritter_sqlite_db,
    user    => $fritter_user,
    group   => 'users',
    umask   => '0077', # ensure no read/write access by group/others
    require => [Vcsrepo[$root_dir],File[$home_dir],Ldapres[$fritter_ldap_dn]],
  }

  file { $fritter_sqlite_db:
    # Just the defaults, though mostly mode = 0600
    # This is here mostly to ensure any existing instances get the right
    # permissions -- new ones should be covered by the umask in the creation
    # above.
    require => Exec['create-fritter-sqlite-db'],
  }

  $fritter_privkey_name = 'fritter_rsa'
  $fritter_privkey = "${home_dir}/${fritter_privkey_name}"
  file { $fritter_privkey:
    ensure  => present,
    source  => "/srv/secrets/fritter/${fritter_privkey_name}",
    require => [File[$home_dir],Ldapres[$fritter_ldap_dn]],
    notify    => Service['fritter'],
  }

  $fritter_pubkey_name = "${fritter_privkey_name}.pub"
  $fritter_pubkey = "${home_dir}/${fritter_pubkey_name}"
  file { $fritter_pubkey:
    ensure  => present,
    source  => "/srv/secrets/fritter/${fritter_pubkey_name}",
    require => [File[$home_dir],Ldapres[$fritter_ldap_dn]],
    notify    => Service['fritter'],
  }

  # Fritter configuration is stored in local.ini; assign some variables
  # that will be templated into it.
  $fritter_mail_smtp = hiera('fritter_mail_smtp')
  $fritter_mail_user = hiera('fritter_mail_user')
  $fritter_mail_pw   = hiera('fritter_mail_pw')
  $fritter_mail_from = hiera('fritter_mail_from')
  $fritter_ini = "${root_dir}/local.ini"
  file { $fritter_ini:
    ensure  => present,
    content => template('sr_site/fritter_local.ini.erb'),
    require => [Vcsrepo[$root_dir],File[$home_dir],Ldapres[$fritter_ldap_dn]],
    notify  => Service['fritter'],
  }

  # Configuration for LDAP connection
  $fritter_srusers_ini = "${root_dir}/fritter/srusers/local.ini"
  file { $fritter_srusers_ini:
    content => template('sr_site/fritter_srusers_local.ini.erb'),
    require => Vcsrepo[$root_dir],
    notify  => Service['fritter'],
  }

  # Install the service
  file { '/etc/systemd/system/fritter.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/sr_site/fritter.service',
    require => [Vcsrepo[$root_dir],
                File[$fritter_privkey],
                File[$fritter_pubkey],
                File[$fritter_ini],
                File[$fritter_srusers_ini],
                Exec['create-fritter-sqlite-db'],
                Ldapres[$fritter_ldap_dn],
               ],
    notify  => Service['fritter'],
  }

  # Link in the systemd service to run in multi user mode.
  file { '/etc/systemd/system/multi-user.target.wants/fritter.service':
    ensure  => link,
    target  => '/etc/systemd/system/fritter.service',
    require => File['/etc/systemd/system/fritter.service'],
  }

  # systemd has to be reloaded before picking this up,
  exec { 'fritter-systemd-load':
    provider  => 'shell',
    command   => 'systemctl daemon-reload',
    onlyif    => 'systemctl --all | grep fritter.service; if test $? = 0; then exit 1; fi; exit 0',
    require   => File['/etc/systemd/system/multi-user.target.wants/fritter.service'],
  }

  # And finally maintain fritter being running.
  service { 'fritter':
    ensure  => running,
    require => Exec['fritter-systemd-load'],
  }

  cron { 'fritter-cron':
    command => "${root_dir}/fritter-cron",
    minute => '*/5',
    user => $fritter_user,
    require => [Vcsrepo[$root_dir],
                File[$fritter_ini],
                File[$fritter_srusers_ini],
                Exec['create-fritter-sqlite-db'],
                Ldapres[$fritter_ldap_dn],
               ],
  }
}
