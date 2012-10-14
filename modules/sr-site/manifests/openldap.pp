
class sr-site::openldap {
  class { 'ldap':
    server => 'true',
    client => 'true',
    localloginok => 'true',
  }

  ldap::define::domain { 'studentrobotics.org':
    ensure => 'present',
    basedn => 'o=sr',
    rootdn => 'cn=Manager', # basedn is jammed on the front of this.
    rootpw => extlookup("ldap_manager_pw"),
  }

  ldap::client::config { 'studentrobotics.org':
    ensure => 'present',
    servers => ['localhost'],
    ssl => 'false',
    base_dn => 'o=sr',
  }

  Ldapres {
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['ldap'],
  }

  # Ensure that test-date from the openldap module's base ldif is removed.
  ldapres { "ou=people,o=sr":
    ensure => absent,
    objectclass => 'organizationalUnit',
    # I hope what this means is "require uid=test is absent first".
    # Because it's fully the wrong order otherwise.
    require => Ldapres['uid=test,ou=people,o=sr'],
  }

  ldapres { "uid=test,ou=people,o=sr":
    ensure => absent,
    objectclass => 'inetOrgPerson',
  }

  # Organizational unit for storing LDAP groups
  ldapres { "ou=groups,o=sr":
    ensure => present,
    objectclass => 'organizationalUnit',
  }

  # Organizational unit for storing LDAP users
  ldapres { "ou=users,o=sr":
    ensure => present,
    objectclass => 'organizationalUnit',
  }

  # SR anonymous user. This is probably a misnomer: "anon" has always been able
  # to access almost all data, everywhere. It's used by things like nscd and
  # apache to bind to ldap and find out various things such as group membership.
  # Essentially it's a catch-all privileged account, but crucially that can't
  # write to anything.
  ldapres { "uid=anon,ou=users,o=sr":
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    uid => "anon",
    cn => "Anon user",
    sn => "Anon user",
    uidnumber => '2043',
    gidnumber => '1999',
    homedirectory => '/home/anon',
    userpassword => extlookup("ldap_anon_user_ssha_pw"),
  }

  file { '/etc/ldap.secret':
    ensure => present,
    content => extlookup('ldap_manager_pw'),
    owner => "root",
    group => "root",
    mode => "0600",
  }

  file { '/etc/pam_ldap.conf':
    ensure => present,
    content => template('sr-site/pam_ldap.conf.erb'),
    owner => "root",
    group => "root",
    mode => "0600",
    require => File['/etc/ldap.secret'],
  }
}
