# Configuration for anything to do with ssh and other authentication goo
# involving shell access.

class sr_site::login {

  # Group that the private key files in /etc/ssh are in
  group { 'ssh_keys':
    ensure => present,
  }

  # Configurate who can run what using sudo.
  file { '/etc/sudoers':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0440',
    source => 'puppet:///modules/sr_site/sudoers',
  }

  if !$devmode {
    augeas { 'sshd_config':
        context => '/files/etc/ssh/sshd_config',
        changes => [
            # deny root logins
            'set PermitRootLogin no',
            # deny logins using passwords
            'set PasswordAuthentication no',
        ],
        notify  => Service['sshd'],
    }
  }

  file { '/etc/ssh/ssh_host_dsa_key':
    ensure  => 'file',
    owner   => 'root',
    group   => 'ssh_keys',
    mode    => '0640',
    source  => '/srv/secrets/login/ssh_host_dsa_key',
    notify  => Service['sshd'],
  }

  file { '/etc/ssh/ssh_host_dsa_key.pub':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => '/srv/secrets/login/ssh_host_dsa_key.pub',
    notify  => Service['sshd'],
  }

  file { '/etc/ssh/ssh_host_key':
    ensure  => 'file',
    owner   => 'root',
    group   => 'ssh_keys',
    mode    => '0640',
    source  => '/srv/secrets/login/ssh_host_key',
    notify  => Service['sshd'],
  }

  file { '/etc/ssh/ssh_host_key.pub':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => '/srv/secrets/login/ssh_host_key.pub',
    notify  => Service['sshd'],
  }

  file { '/etc/ssh/ssh_host_rsa_key':
    ensure  => 'file',
    owner   => 'root',
    group   => 'ssh_keys',
    mode    => '0640',
    source  => '/srv/secrets/login/ssh_host_rsa_key',
    notify  => Service['sshd'],
  }

  file { '/etc/ssh/ssh_host_rsa_key.pub':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => '/srv/secrets/login/ssh_host_rsa_key.pub',
    notify  => Service['sshd'],
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
