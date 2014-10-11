# Fritter sends emails to LDAP groups after review via Gerrit
###
# Nota Bene: this manifest is unable to actually install the public key
# into Gerrit, so that needs to be done manually. The service expects
# to be able to ssh in to Gerrit using its LDAP username and the ssh
# key pair from its home directory. It also needs to be granted the
# following capabilities within Gerrit:
# * 'streamEvents' (global)
# * 'label-Verified' (at least within the repo it targets)

class sr-site::fritter ( $git_root ) {
  # System user
  user { 'fritter':
    ensure      => present,
    comment     => 'Email sender',
    shell       => '/sbin/nologin',
    gid         => 'users',
    managehome  => true,
  }

  $home_dir = '/home/fritter'

  # LDAP user
  $fritter_ldap_user  = 'fritter'
  $fritter_ldap_pw    = extlookup('fritter_ldap_user_pw')
  $fritter_ldap_dn    = "uid=${fritter_ldap_user},ou=users,o=sr"
  ldapres { $fritter_ldap_dn:
    ensure => present,
    objectclass => ['inetOrgPerson', 'uidObject', 'posixAccount'],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup('ldap_manager_pw'),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => $fritter_ldap_user,
    cn => 'Reviewed email sending user',
    sn => 'Reviewed email sending user',
    uidnumber => '3001',
    gidnumber => '1999',
    homedirectory => $home_dir,
    userpassword => extlookup('fritter_ldap_user_ssha_pw'),
  }

  # Checkout of fritter's code.
  $root_dir = "${home_dir}/fritter"
  vcsrepo { $root_dir:
    ensure    => present,
    provider  => git,
  # source    => "${git_root}/fritter.git",
  # Override for now since there isn't a canonical repo yet
    source    => 'git://github.com/PeterJCLaw/fritter.git',
    revision  => 'origin/master',
    owner     => 'fritter',
    group     => 'users',
    require   => User['fritter'],
  }

  # Local database for caching the emails until they're sent
  $fritter_sqlite_db = "${home_dir}/fritter.sqlite"
  exec { 'create-fritter-sqlite-db':
    command => "${root_dir}/fritter/libfritter/scripts/make_db.sh '${fritter_sqlite_db}'",
    creates => $fritter_sqlite_db,
    user    => 'fritter',
    group   => 'users',
    require => [Vcsrepo[$root_dir],User['fritter']],
  }

  $fritter_privkey_name = 'fritter_rsa'
  $fritter_privkey = "${home_dir}/${fritter_privkey_name}"
  file { $fritter_privkey:
    ensure  => present,
    owner   => 'fritter',
    group   => 'users',
    mode    => '0600',
    source  => "/srv/secrets/fritter/${fritter_privkey_name}",
    require => User['fritter'],
  }

  $fritter_pubkey_name = "${fritter_privkey_name}.pub"
  $fritter_pubkey = "${home_dir}/${fritter_pubkey_name}"
  file { $fritter_pubkey:
    ensure  => present,
    owner   => 'fritter',
    group   => 'users',
    mode    => '0600',
    source  => "/srv/secrets/fritter/${fritter_pubkey_name}",
    require => User['fritter'],
  }

  # Fritter configuration is stored in local.ini; assign some variables
  # that will be templated into it.
  $fritter_mail_smtp = extlookup('fritter_mail_smtp')
  $fritter_mail_user = extlookup('fritter_mail_user')
  $fritter_mail_pw   = extlookup('fritter_mail_pw')
  $fritter_mail_from = extlookup('fritter_mail_from')
  $fritter_ini = "${root_dir}/local.ini"
  file { $fritter_ini:
    ensure  => present,
    owner   => 'fritter',
    group   => 'users',
    content => template('sr-site/fritter_local.ini.erb'),
    require => [Vcsrepo[$root_dir],User['fritter']],
  }

  # Configuration for LDAP connection
  $fritter_srusers_ini = "${root_dir}/fritter/srusers/local.ini"
  file { $fritter_srusers_ini:
    owner   => 'fritter',
    group   => 'users',
    mode    => '0600',
    content => template('sr-site/fritter_srusers_local.ini.erb'),
    require => Vcsrepo[$root_dir],
  }

  # Install the service
  file { '/etc/systemd/system/fritter.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/sr-site/fritter.service',
    require => [Vcsrepo[$root_dir],
                File[$fritter_privkey],
                File[$fritter_pubkey],
                File[$fritter_ini],
                File[$fritter_srusers_ini],
                Exec['create-fritter-sqlite-db'],
                Ldapres[$fritter_ldap_dn],
               ],
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
    onlyif    => 'systemctl --all | grep fritter-service; if test $? = 0; then exit 1; fi; exit 0',
    require   => File['/etc/systemd/system/multi-user.target.wants/fritter.service'],
  }

  # And finally maintain fritter being running.
  service { 'fritter':
    ensure  => running,
    require => Exec['fritter-systemd-load'],
  }
}
