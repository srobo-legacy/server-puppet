class www::mediaconsent( $web_root_dir ) {
  $mcf_root = "${web_root_dir}/mediaconsent"
  $mcf_ldap_pw = extlookup("ldap_mediaconsent_user_pw")

  # Dependencies are identical to the ticket system, which we should depend on

  # create an LDAP user for getting ticket info
  ldapres { "uid=mediaconsent,ou=users,o=sr":
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => "mediaconsent",
    cn => "Media consent user",
    sn => "Media consent user",
    uidnumber => '3000',
    gidnumber => '1999',
    homedirectory => '/home/mediaconsent',
    userpassword => extlookup("ldap_mediaconsent_user_ssha_pw"),
  }

  file {"${mcf_root}/tickets/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/mcf_local.ini.erb'),
  }

  file {"${mcf_root}/tickets/sr/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/mcf_sr_local.ini.erb'),
  }

  file {"${mcf_root}/tickets/ticket.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => '/srv/secrets/mcfs/ticket.key',
  }

  file {"${mcf_root}/pdfs":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '770',
  }

  file {"${mcf_root}/pdfs/.htaccess":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => "puppet:///modules/www/mcf/user_dir.htaccess",
  }
}
