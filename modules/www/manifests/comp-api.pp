# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp-api ( $git_root, $root_dir ) {

  # SimpleJSON so we can handle Decimal()s,
  package { ['python-simplejson',
             # PIP so we can get Flask from it.
             'python-pip',
             # We use dateutil for timezone munging
             'python-dateutil' ]:
    ensure => present,
    notify => Service['httpd'],
    before => Vcsrepo[$root_dir],
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
    before => Vcsrepo[$root_dir],
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

  # A WSGI config file for serving inside of apache.
  file { "${root_dir}/comp-api.wsgi":
    ensure  => present,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0644',
    source  => 'puppet:///modules/www/comp-api.wsgi',
    require => Vcsrepo[$root_dir],
  }
}
