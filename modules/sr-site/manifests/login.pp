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
}
