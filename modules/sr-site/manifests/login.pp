class sr-site::login {

  file { '/etc/pam.d/sshd':
    ensure => present,
    source => 'puppet:///modules/sr-site/sshd',
    owner => "root",
    group => "root",
    mode => "0600",
    notify => Service["nscd"],
    require => File['/etc/pam_ldap.conf'],
  }

  file { '/etc/sudoers':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '440',
    source => 'puppet:///modules/sr-site/sudoers',
  }

# Puppet is a gigantic piece of rubbish that can't manager unix groups >:|
#  group { 'facebees':
#    ensure => present,
#    members => 'root',
#    provider => 'groupadd',
#    system => true,
#  }
}
