# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp-api ( $git_root, $root_dir ) {

  # SimpleJSON so we can handle Decimal()s,
  package { ['python-simplejson',
             # PIP so we can remove Flask from it
             'python-pip',
             # Flask runs our python WSGI things
             'python-flask',
             # Virtualenv so we can install the srcomp stuff into one.
             'python-virtualenv',
             # We use dateutil for timezone munging
             'python-dateutil' ]:
    ensure => present,
    notify => Service['httpd'],
    before => Exec['srcomp-venv'],
  }

  # Remove Flask from pip
  package { ['Flask']:
    ensure    => absent,
    provider  => pip,
    require   => Package['python-pip'],
    notify    => Service['httpd'],
    before    => Package['python-flask'],
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

  # requirements.txt for the whole application
  $requirements_txt = "${root_dir}/requirements.txt"
  # git_root ends up in the requirements file, so we need to ensure
  # that it has a protocol attached
  if $git_root =~ /^git:/ {
    $git_root_url = $git_root
  }
  else {
    $git_root_url = "file://${git_root}"
  }
  file { $requirements_txt:
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    content => template('www/comp-api-requirements.txt.erb'),
    require => File[$root_dir],
  }

  # Install the application into the virtual env we created above
  exec { 'srcomp-install':
    command => "'${venv_dir}/bin/pip' install -U -r '${requirements_txt}'",
    # The requirements.txt includes a bunch of git clones and it turns out
    # that git tries to 'cd' back to its original location when done.
    # Thus things fail if we leave the cwd as /root (the default).
    cwd     => $root_dir,
    user    => 'wwwcontent',
    group   => 'apache',
    require => [Exec['srcomp-venv'],File[$requirements_txt]],
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
    require => [File[$root_dir],Exec['srcomp-install']],
  }
}
