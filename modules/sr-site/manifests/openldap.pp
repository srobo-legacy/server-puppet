
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
    require  => Ldap::Client::Config['studentrobotics.org'],
    source   => "puppet:///modules/sr-site/sr_base.ldif",
  }
}
