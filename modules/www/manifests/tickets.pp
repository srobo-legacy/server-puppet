class www::tickets( $web_root_dir ) {
  $tickets_root = "${web_root_dir}/tickets/tickets"

  # The ticket system requires the python imaging library
  package {'python-imaging':
    ensure => present,
  }

  # Inkscape, for converting SVGs to PDFs
  package {'inkscape':
    ensure => present,
  }

  # create an LDAP user for getting ticket info
  ldapres { "uid=tickets,ou=users,o=sr":
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => "tickets",
    cn => "Tickets user",
    sn => "Tickets user",
    uidnumber => '2413',
    gidnumber => '1999',
    homedirectory => '/home/tickets',
    userpassword => extlookup("ldap_ticket_user_ssha_pw"),
  }

  file {"${tickets_root}/webapi/config.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => '/srv/secrets/tickets/config.ini',
  }

  file {"${tickets_root}/ticket.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => '/srv/secrets/tickets/ticket.key',
  }

  file {"${tickets_root}/webapi/users":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '770',
  }

  file {"${tickets_root}/webapi/users/.htaccess":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    source => "puppet:///modules/www/tickets/user_dir.htaccess",
  }

}
