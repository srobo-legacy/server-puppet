# SRComp is the suite of software that Student Robotics uses to manage a
# competition. It consists of various Git repositories containing Python
# modules using Setuptools, however they are not uploaded on PyPI. Therefore
# they must be installed using Pip.
#
# The process of installing SRComp involves installing Pip and Virtualenv which
# means that a virtual environment can be created. The virtual environment will
# contain dependencies specific to SRComp, and the SRComp modules themselves
# (ranker, srcomp and srcomp-http). SRComp-HTTP is a Flask (Python) application
# that has a WSGI application which is run in Apache. This is not configured in
# this module, instead it can be found in the Www::Comp-api module.

class sr_site::srcomp($git_root,
                      $src_dir,
                      $venv_dir) {

  # A user to owner all SRComp related stuff.
  user { 'srcomp':
    ensure      => present,
    comment     => 'Competition Software Owner',
    gid         => 'users',
    shell       => '/bin/bash',
  }

  $srcomp_home_dir = '/home/srcomp'
  $ref_compstate = "${srcomp_home_dir}/compstate.git"
  $srcomp_ssh_dir = "${srcomp_home_dir}/.ssh"

  file { $srcomp_home_dir:
    ensure  => directory,
    owner   => 'srcomp',
    group   => 'users',
    mode    => '0700',
    require => User['srcomp'],
  }

  file { $srcomp_ssh_dir:
    ensure  => directory,
    owner   => 'srcomp',
    group   => 'users',
    mode    => '0700',
    require => [User['srcomp'],File[$srcomp_home_dir]],
  }

  file { "${srcomp_ssh_dir}/authorized_keys":
    ensure  => file,
    owner   => 'srcomp',
    group   => 'users',
    mode    => '0600',
    # TODO: this should probably end up in hiera
    source  => 'puppet:///modules/sr_site/srcomp-authorized_keys',
    require => [User['srcomp'],File[$srcomp_ssh_dir]],
  }

  # The location of the srcomp-http checkout. Would ideally have used
  # something like Srcomp_repo['srcomp']::location but that doesn't work
  $http_dir = "${src_dir}/srcomp-http"

  # The location of the live compstate. Would ideally get this from the
  # www::comp-api class, but that gets complicated since the name contains
  # a hyphen, and since it fixes the parse ordering of the classes.
  # TODO: restructure things so this is injected from the top down?
  $compstate_dir = '/srv/comp-api/compstate'

  # Update script, configured for direct use (via the above two variables)
  file { "${srcomp_home_dir}/update":
    ensure  => file,
    owner   => 'srcomp',
    group   => 'users',
    # Only this user can run it
    mode    => '0744',
    # Uses $compstate_dir, $http_dir, $venv_dir
    content => template('sr_site/srcomp-update.erb'),
    require => [Srcomp_repo['srcomp-http'],User['srcomp'],File[$srcomp_home_dir]],
  }

  # All exec's should be run as srcomp
  Exec {
    user => 'srcomp',
    group => 'users',
  }

  # A type that represents a repository containing a Python module that should
  # be installed using Setuptools via Pip.
  define srcomp_repo($git_root, $src_dir, $venv_dir) {
    vcsrepo { "${src_dir}/${title}":
      ensure   => present,
      provider => git,
      source   => "${git_root}/comp/${title}",
      revision => 'origin/master',
      owner    => 'srcomp',
      group    => 'users',
      require  => File[$src_dir],
    }

    exec { "install-srcomp-${title}":
      require     => [Vcsrepo["${src_dir}/${title}"],
                      Exec['install-srcomp-requirements'], User['srcomp']],
      command     => "${venv_dir}/bin/pip install -e ${src_dir}/${title}",
      path        => ['/usr/bin', '/usr/share/bin'],
      notify      => Service['httpd'],
      refreshonly => true,
      subscribe   => [Vcsrepo["${src_dir}/${title}"],
                      Exec['install-srcomp-requirements']],
    }
  }

  vcsrepo { $ref_compstate:
    ensure    => bare,
    provider  => git,
    source    => "${git_root}/comp/sr2015-comp.git",
    user      => 'srcomp',
    require   => [User['srcomp'],File[$srcomp_home_dir]],
  }

  # Install Pip and Virtualenv.
  package { ['python-pip',
             'python-virtualenv',
             'python-setuptools']:
    ensure => present,
  }

  # Yaml loading acceleration
  package { ['libyaml-devel', 'gcc']:
    ensure  => present,
    before  => [Srcomp_repo['srcomp'],Exec['install-srcomp-requirements']],
  }

  # Create a virtual environment to hold the various Python modules.
  file { $venv_dir:
    ensure => directory,
    owner  => 'srcomp',
    group  => 'users',
  }

  exec { 'srcomp-venv':
    command => "virtualenv --python=python2.7 '${venv_dir}'",
    cwd     => '/',
    creates => "${venv_dir}/bin/python",
    path    => ['/usr/bin'],
    require => [File[$venv_dir],
                Package['python-virtualenv'],
                Package['python-pip'],
                User['srcomp']],
  }

  # Ensure the source directory exists.
  file { $src_dir:
    ensure => directory,
    owner => 'srcomp',
    group => 'users',
  }

  # Install base modules.
  $requirements_path = "${src_dir}/requirements.txt"
  file { $requirements_path:
    ensure  => file,
    source  => 'puppet:///modules/sr_site/srcomp_requirements.txt',
    require => File[$src_dir],
  }

  exec { 'install-srcomp-requirements':
    require     => [File[$requirements_path], User['srcomp']],
    command     => "${venv_dir}/bin/pip install -U -r ${requirements_path}",
    path        => ['/usr/bin', '/usr/share/bin'],
    notify      => Service['httpd'],
    refreshonly => true,
    subscribe   => [File[$requirements_path],
                    Exec['srcomp-venv']],
  }

  # Install our custom stuff.
  sr_site::srcomp::srcomp_repo { 'ranker':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
  }
  sr_site::srcomp::srcomp_repo { 'srcomp':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
    require  => Srcomp_repo['ranker'],
  }
  sr_site::srcomp::srcomp_repo { 'srcomp-http':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
    require  => Srcomp_repo['srcomp'],
  }
}
