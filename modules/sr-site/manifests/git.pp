class sr-site::git($git_root) {
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
    notify => Exec['ldap-groups-flushed'],
  }

  ldapres {"cn=git-commit,${openldap::groupdn}":
    ensure => present,
    cn => 'git-commit',
    objectclass => 'posixGroup',
    gidnumber => '3075',
    # Don't configure memberuid
    notify => Exec['ldap-groups-flushed'],
  }

  user { 'git':
    ensure => present,
    comment => 'Owner of git maintenence scripts and cron jobs',
    shell => '/sbin/nologin',
    gid => 'users', # Dummy group, I've no idea what it should be in.
    home => '/'
  }

  file { '/srv/git':
    ensure => directory,
    owner => 'root',
    group => 'git-admin',
    mode => '02775',
    require => Exec['ldap-groups-flushed'],
  }

  # Maintain a clone of the git admin scripts.
  vcsrepo { '/srv/git/scripts':
    ensure => present,
    provider => git,
    source => "${git_root}/scripts",
    revision => "origin/master",
    force => true,
    owner => 'root',
    group => 'git-admin',
    require => [File['/srv/git'], Exec['ldap-groups-flushed']],
  }

  package { 'GitPython':
    ensure => present,
  }

  package { 'python-pyrss2gen.noarch':
    ensure => present,
    provider => rpm,
    source => '/root/python-pyrss2gen.noarch.rpm',
   }

  file { '/root/python-pyrss2gen.noarch.rpm':
    ensure => present,
    owner => root,
    mode => 400,
    source => 'puppet:///modules/sr-site/python-pyrss2gen-1.0.0-2.2.noarch.rpm',
    before => Package['python-pyrss2gen.noarch'],
  }

  cron { 'commitrss':
    command => '/srv/git/scripts/rss',
    minute => '*/15',
    user => 'git',
    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython','python-pyrss2gen.noarch']],
  }

  cron { 'pushrss':
    command => '/srv/git/scripts/pushlog-rss',
    minute => '10',
    user => 'git',
    require => [Vcsrepo['/srv/git/scripts'], Package['GitPython','python-pyrss2gen.noarch']],
  }

  file { '/srv/git/commits.rss':
    ensure => present,
    owner => 'git',
    group => 'srusers',
    mode => '644',
    before => Vcsrepo['/srv/git/scripts'],
  }

  file { '/srv/git/pushes.rss':
    ensure => present,
    owner => 'git',
    group => 'srusers',
    mode => '644',
    before => Vcsrepo['/srv/git/scripts'],
  }

  file { '/srv/git/push-log':
    ensure => present,
    owner => 'root',
    group => 'git-commit',
    mode => '664',
    before => Vcsrepo['/srv/git/scripts'],
  }

  file { '/srv/git/update-log':
    ensure => present,
    owner => 'root',
    group => 'git-commit',
    mode => '664',
    before => Vcsrepo['/srv/git/scripts'],
  }

  file { '/srv/git/repolist':
    ensure => present,
    owner => 'root',
    group => 'git-admin',
    mode => '664',
    before => Vcsrepo['/srv/git/scripts'],
    require => Exec['ldap-groups-flushed'],
  }

  package { 'cgit':
    ensure => present,
  }

  file { '/etc/cgitrc':
    ensure => present,
    group => 'git-admin',
    mode => '664',
    require => [Package['cgit'], Exec['ldap-groups-flushed']],
  }

  package { ['perl', 'perl-RPC-XML']:
    ensure => present,
  }
}
