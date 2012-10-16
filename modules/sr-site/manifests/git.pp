class sr-site::git {
  # Git package is installed in the kickstart file,

  # Ldapres defaults,
  Ldapres {
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['ldap'],
  }

  ldapres {"cn=git-admin,${openldap::groupdn}":
    ensure => present,
    cn => 'git-admin',
    objectclass => 'posixGroup',
    gidnumber => '3076',
    # Don't configure memberuid
    require => Class['sr-site::openldap'],
  }

  ldapres {"cn=git-commit,${openldap::groupdn}":
    ensure => present,
    cn => 'git-commit',
    objectclass => 'posixGroup',
    gidnumber => '3075',
    # Don't configure memberuid
    require => Class['sr-site::openldap'],
  }

  file { '/srv/git':
    ensure => directory,
    owner => 'root',
    group => 'git-admin',
    mode => '02775',
    require => Ldapres["cn=git-admin,${openldap::groupdn}"],
  }
}
