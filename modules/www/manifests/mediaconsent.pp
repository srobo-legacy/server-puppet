# The system which provides competitors with personalised media consent forms

class www::mediaconsent( $git_root, $web_root_dir ) {
  $mcf_root = "${web_root_dir}/mediaconsent"
  $mcf_ldap_pw = extlookup('ldap_mediaconsent_user_pw')

  vcsrepo { $mcf_root:
    ensure    => latest,
    provider  => git,
    force     => true,
    source    => "${git_root}/media-consent-access.git",
    # TODO: change to origin/master once a maintainer situation is in place
    revision  => '459cd626b83e96f471755ad6867602770d38eb9c',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

  # Dependencies are identical to the ticket system, which we should depend on

  # create an LDAP user for getting ticket info
  ldapres { 'uid=mediaconsent,ou=users,o=sr':
    ensure => present,
    objectclass => ['inetOrgPerson', 'uidObject', 'posixAccount'],
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup('ldap_manager_pw'),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    uid => 'mediaconsent',
    cn => 'Media consent user',
    sn => 'Media consent user',
    uidnumber => '3000',
    gidnumber => '1999',
    homedirectory => '/home/mediaconsent',
    userpassword => extlookup('ldap_mediaconsent_user_ssha_pw'),
  }

  file {"${mcf_root}/tickets/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/mcf_local.ini.erb'),
    require => VCSRepo[$mcf_root],
  }

  file {"${mcf_root}/tickets/sr/local.ini":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/mcf_sr_local.ini.erb'),
    require => VCSRepo[$mcf_root],
  }

  file {"${mcf_root}/tickets/ticket.key":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    source => '/srv/secrets/mcfs/ticket.key',
    require => VCSRepo[$mcf_root],
  }

  file {"${mcf_root}/pdfs":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0770',
    require => VCSRepo[$mcf_root],
  }

  file {"${mcf_root}/pdfs/.htaccess":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    source => 'puppet:///modules/www/mcf/user_dir.htaccess',
    require => VCSRepo[$mcf_root],
  }
}
