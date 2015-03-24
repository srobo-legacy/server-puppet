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
    ensure  => present,
    comment => 'Competition Software Owner',
    shell   => '/sbin/nologin',
    gid     => 'users',
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
      subscribe   => Vcsrepo["${src_dir}/${title}"],
    }
  }

  # Install Pip and Virtualenv.
  package { ['python-pip',
             'python-virtualenv',
             'python-setuptools']:
    ensure => present,
  }

  # Yaml loading acceleration
  package { 'libyaml-devel':
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
  srcomp_repo { 'ranker':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
  }
  srcomp_repo { 'srcomp':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
    require  => Srcomp_repo['ranker'],
  }
  srcomp_repo { 'srcomp-http':
    git_root => $git_root,
    src_dir  => $src_dir,
    venv_dir => $venv_dir,
    require  => Srcomp_repo['srcomp'],
  }
}
