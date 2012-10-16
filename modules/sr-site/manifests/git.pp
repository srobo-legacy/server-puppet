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

  user { 'git':
    ensure => present,
    comment => 'Owner of git maintenence scripts and cron jobs',
    shell => '/sbin/nologin',
    gid => 'users', # Dummy group, I've no idea what it should be in.
  }

  file { '/srv/git':
    ensure => directory,
    owner => 'root',
    group => 'git-admin',
    mode => '02775',
    require => Ldapres["cn=git-admin,${openldap::groupdn}"],
  }

  # Maintain a clone of the git admin scripts.
  vcsrepo { '/srv/git/scripts':
    ensure => present,
    provider => git,
    source => "${::git_root}/scripts",
    revision => "master",
    force => true,
    owner => 'root',
    group => 'git-admin',
    require => File['/srv/git'],
  }

  package { 'GitPython':
    ensure => present,
  }

  cron { 'commitrss':
    command => '/srv/git/scripts/rss',
    minute => '*/15',
    user => 'git',
    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython']],
  }

  cron { 'pushrss':
    command => '/srv/git/scripts/pushlog-rss',
    minute => '10',
    user => 'git',
    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython']],
  }
}
