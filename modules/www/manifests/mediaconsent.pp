class www::mediaconsent( $web_root_dir ) {
  $mcf_root = "${web_root_dir}/mediaconsent"

  # Dependencies are identical to the ticket system, which we should depend on

  # create an LDAP user for getting ticket info
  ldapres { "uid=mediaconsent,ou=users,o=sr":
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => "tickets",
    cn => "Tickets user",
    sn => "Tickets user",
    uidnumber => '3000',
    gidnumber => '1999',
    homedirectory => '/home/tickets',
    userpassword => extlookup("ldap_mediaconsent_user_ssha_pw"),
  }

  file {"${tickets_root}/tickets/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => '/srv/secrets/mcfs/local.ini',
  }

  file {"${tickets_root}/tickets/ticket.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => '/srv/secrets/mcfs/ticket.key',
  }

  file {"${tickets_root}/pdfs":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '770',
  }
}
