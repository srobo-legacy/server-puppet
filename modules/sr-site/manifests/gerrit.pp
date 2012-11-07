class sr-site::gerrit {
  user { 'gerrit':
    ensure => present,
    comment => 'Owner of all gerrit specific files/data',
    shell => '/bin/sh', # Has to log in successfully, as it runs java.
    gid => 'users',
  }

  exec { 'download-gerrit':
    command => 'curl http://gerrit.googlecode.com/files/gerrit-full-2.5.war > /home/gerrit/gerrit-full-2.5.war',
    creates => '/home/gerrit/gerrit-full-2.5.war',
    user => 'gerrit',
    require => User['gerrit'],
  }
}
