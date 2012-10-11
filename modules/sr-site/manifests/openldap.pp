
class sr-site::openldap {
  class { 'ldap':
    server => 'true',
    client => 'true',
  }

  ldap::define::domain { 'studentrobotics.org':
    ensure => 'present',
    basedn => 'o=sr',
    rootdn => 'cn=Manager', # basedn is jammed on the front of this.
    rootpw => '123456',
  }

  ldap::client::config { 'studentrobotics.org':
    ensure => 'present',
    servers => ['localhost'],
    ssl => 'false',
    base_dn => 'o=sr',
  }

  Ldapres {
    binddn => 'cn=Manager,o=sr',
    bindpw => '123456',
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['ldap'],
  }

  ldapres { "bees":
    ensure => present,
    dn => "ou=groups,o=sr",
    objectclass => 'organizationalUnit',
  }

  ldapres { "faces":
    ensure => present,
    dn => "ou=users,o=sr",
    objectclass => 'organizationalUnit',
  }
}
