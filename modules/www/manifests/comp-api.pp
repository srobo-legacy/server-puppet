# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp-api ( $git_root, $root_dir ) {

  # SimpleJSON so we can handle Decimal()s,
  package { ['python-simplejson',
             # PIP so we can get Flask from it.
             'python-pip',
             # Virtualenv so we can install the srcomp stuff into one.
             'python-virtualenv',
             # We use dateutil for timezone munging
             'python-dateutil' ]:
    ensure => present,
    notify => Service['httpd'],
    before => Exec['srcomp-venv'],
  }

  # Need more recent than version 0.8, which is all that's available in the F17 repos
  # Ensure the Fedora-provided package is removed
  package { 'python-flask':
    ensure => absent,
  }

  # Get it from pip instead
  package { ['Flask']:
    ensure => present,
    provider => pip,
    require => [ Package['python-pip'],
                 Package['python-flask'] ],
    notify => Service['httpd'],
  }

  # Containing folder
  file { $root_dir:
    ensure  => directory,
    force   => true,
    owner   => 'wwwcontent',
    group   => 'apache',
  }

  # Virtual environment
  $venv_dir = "${root_dir}/venv"
  exec { 'srcomp-venv':
    command => "virtualenv --system-site-packages --python=python2.7 '${venv_dir}'",
    cwd     => $root_dir,
    creates => $venv_dir,
    path    => ['/usr/bin'],
    user    => 'wwwcontent',
    group   => 'apache',
    require => [Package['python-virtualenv'],File[$root_dir]],
  }

  srcomp_repo { 'ranker':
    git_root  => $git_root,
    root_dir  => $root_dir,
    venv_dir  => $venv_dir,
  }

  srcomp_repo { 'srcomp':
    git_root  => $git_root,
    root_dir  => $root_dir,
    venv_dir  => $venv_dir,
    require   => Srcomp_repo['ranker'],
  }

  srcomp_repo { 'srcomp-http':
    git_root  => $git_root,
    root_dir  => $root_dir,
    venv_dir  => $venv_dir,
    require   => [Package['Flask'],Srcomp_repo['srcomp']],
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
    revision  => 'origin/sr2015-format',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => File[$root_dir],
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
    require => [File[$root_dir],Srcomp_repo['srcomp-http']],
  }
}
