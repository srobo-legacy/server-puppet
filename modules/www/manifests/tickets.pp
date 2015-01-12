# The system which provides competitors access to their competition tickets

class www::tickets( $git_root, $web_root_dir ) {
  vcsrepo { "${web_root_dir}/tickets":
    ensure    => latest,
    provider  => git,
    force     => true,
    source    => "${git_root}/ticket-access.git",
    # TODO: change to origin/master once a maintainer situation is in place
    revision  => 'cafc4ae99707644a9f3fe26138e86c7048ced702',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

  $tickets_root = "${web_root_dir}/tickets/tickets"

  # The ticket system requires the python imaging library
  package { 'python-pillow':
    ensure  => present,
    alias   => 'python-imaging',
  }

  # Inkscape, for converting SVGs to PDFs
  package {'inkscape':
    ensure => present,
  }

  # create an LDAP user for getting ticket info
  ldapres { 'uid=tickets,ou=users,o=sr':
    ensure => present,
    objectclass => ['inetOrgPerson', 'uidObject', 'posixAccount'],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup('ldap_manager_pw'),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => 'tickets',
    cn => 'Tickets user',
    sn => 'Tickets user',
    uidnumber => '2413',
    gidnumber => '1999',
    homedirectory => '/home/tickets',
    userpassword => extlookup('ldap_ticket_user_ssha_pw'),
  }

  file {"${web_root_dir}/ticket-api":
    ensure  => link,
    owner   => 'wwwcontent',
    group   => 'apache',
    target  => "${tickets_root}/webapi",
    require => VCSRepo[$web_root_dir],
  }

  $tickets_keyfile = "${tickets_root}/ticket.key"
  $ldap_ticket_user_pw = extlookup('ldap_ticket_user_pw')
  file {"${tickets_root}/webapi/config.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/tickets_config.ini.erb'),
    require => VCSRepo["${web_root_dir}/tickets"],
  }

  file { $tickets_keyfile:
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    source => '/srv/secrets/tickets/ticket.key',
    require => VCSRepo["${web_root_dir}/tickets"],
  }

  file {"${tickets_root}/webapi/users":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0770',
    require => VCSRepo["${web_root_dir}/tickets"],
  }

  file {"${tickets_root}/webapi/users/.htaccess":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    source => 'puppet:///modules/www/tickets/user_dir.htaccess',
    require => VCSRepo["${web_root_dir}/tickets"],
  }

}
