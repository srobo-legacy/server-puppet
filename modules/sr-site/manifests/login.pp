# Configuration for anything to do with ssh and other authentication goo
# involving shell access.

class sr-site::login {

  # PAM configuration for SSHD, just passes control to the sr-auth stack.
  file { '/etc/pam.d/sshd':
    ensure => present,
    source => 'puppet:///modules/sr-site/sshd',
    owner => 'root',
    group => 'root',
    mode => '0600',
    notify => Service['nscd'],
    require => File['/etc/pam_ldap.conf'],
  }

  # sr-auth PAM stack; our primary PAM config goo. Allows authentication and
  # account-info from LDAP, subject to the pam_ldap configuration. Also the same
  # operations for local users.
  file { '/etc/pam.d/sr-auth':
    ensure => present,
    source => 'puppet:///modules/sr-site/sr-auth',
    owner => 'root',
    group => 'root',
    mode => '0600',
    notify => Service['nscd'],
    require => File['/etc/pam_ldap.conf'],
  }

  # Configurate who can run what using sudo.
  file { '/etc/sudoers':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0440',
    source => 'puppet:///modules/sr-site/sudoers',
  }

  # Our SSH configuration; mostly the default, with the difference that root
  # logins are disabled on the production machine.
  file { '/etc/ssh/sshd_config':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0600',
    content => template('sr-site/sshd_config.erb'),
    notify => Service['sshd'],
  }

  service { 'sshd':
    ensure => running,
  }

# Puppet is a gigantic piece of rubbish that can't manager unix groups >:|
#  group { 'facebees':
#    ensure => present,
#    members => 'root',
#    provider => 'groupadd',
#    system => true,
#  }
}
