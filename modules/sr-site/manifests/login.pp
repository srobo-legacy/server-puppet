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

  file { '/etc/pam.d/sr-auth':
    ensure => present,
    source => 'puppet:///modules/sr-site/sr-auth',
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

  file { '/etc/ssh/sshd_config':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '600',
    content => template('sr-site/sshd_config.erb'),
  }

# Puppet is a gigantic piece of rubbish that can't manager unix groups >:|
#  group { 'facebees':
#    ensure => present,
#    members => 'root',
#    provider => 'groupadd',
#    system => true,
#  }
}
