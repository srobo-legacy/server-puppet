
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

  # Base SR LDAP data
  file {"${ldap::params::lp_openldap_var_dir}/studentrobotics.org/sr_base.ldif":
    ensure   => file,
    owner    => $ldap::params::lp_daemon_user,
    source   => "puppet:///modules/sr-site/sr_base.ldif",
    notify   => Exec['import-base-sr-data'],
  }

  # Password file for running ldapadd
  file {"${ldap::params::lp_openldap_conf_dir}/domains/studentrobotics.org.passwd":
    ensure   => file,
    owner    => 'root',
    group    => 'root',
    mode     => '400',
    content  => '123456',
  }

  # Increadibly hacky import of SR structural data. Ideally we'd have some kind
  # of puppet facility for managing resources that lie in ldap, but a google
  # survey failed to turn up any modules that do this, and the built-in
  # user/group ldap provider makes it's own uid/gid decisions, and dictates the
  # schema. So, jam an ldif in now, and prettify its management later.
  #
  # The shell script goo in here returns zero if either ldapadd succeeds or
  # returns 68 ("Already exists") to get around this exec being run twice. Ugh.
  exec { 'import-base-sr-data':
    command => "sh -c \"ldapadd -c -D cn=Manager,o=sr -y ${ldap::params::lp_openldap_conf_dir}/domains/studentrobotics.org.passwd -f ${ldap::params::lp_openldap_var_dir}/studentrobotics.org/sr_base.ldif\"; case $? in 0) exit 0;; 68) exit 0;; *) exit 1;; esac",
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    user      =>  'root',
    group     =>  'root',
    logoutput => 'true',
    require   =>  [File["${ldap::params::lp_openldap_conf_dir}/domains/studentrobotics.org.passwd"], Ldap::Define::Domain['studentrobotics.org']]
  }
}
