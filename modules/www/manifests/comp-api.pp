# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp-api ( $git_root, $root_dir ) {

  # SimpleJSON so we can handle Decimal()s,
  package { ['python-simplejson',
             # PIP so we can remove Flask from it
             'python-pip',
             # Flask runs our python WSGI things
             'python-flask',
             # We use dateutil for timezone munging
             'python-dateutil' ]:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo[$root_dir],
  }

  # Remove Flask from pip
  package { ['Flask']:
    ensure    => absent,
    provider  => pip,
    require   => [Package['python-pip']],
    notify    => Service['httpd'],
    before    => Package['python-flask'],
  }

  # Main checkout of the codebase
  vcsrepo { $root_dir:
    ensure    => present,
    provider  => git,
    source    => "${git_root}/comp/srcomp-http.git",
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Package['Flask', 'python-simplejson'],
    notify    => Service['httpd'],
  }

  # Syslog configuration, using local1
  file { '/etc/rsyslog.d/comp-api.conf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    source => 'puppet:///modules/www/comp-api-syslog.conf',
    notify => Service['rsyslog'],
  }

  # Checkout of the competition state
  $compstate_dir = "${root_dir}/compstate"
  vcsrepo { $compstate_dir:
    ensure    => present,
    provider  => git,
    source    => "${git_root}/comp/sr2014-comp.git",
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$root_dir],
  }

  # Update trigger and lock files
  file { "${compstate_dir}/.update-pls":
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0644',
    require => Vcsrepo[$compstate_dir],
  }
  # The lock file is writable by apache so it can get a lock on it
  file { "${compstate_dir}/.update-lock":
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0664',
    require => Vcsrepo[$compstate_dir],
  }

  # A WSGI config file for serving inside of apache.
  file { "${root_dir}/comp-api.wsgi":
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0644',
    content => template('www/comp-api.wsgi.erb'),
    require => Vcsrepo[$root_dir],
  }
}
