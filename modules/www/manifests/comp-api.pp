# 'comp-api' is the web API to the SRComp library which contains information
# about the state of the competition

class www::comp-api ( $git_root, $root_dir ) {

  # Main checkout of the codebase
  vcsrepo { $root_dir:
    ensure    => present,
    provider  => git,
# Doesn't yet exist
#    source    => "${git_root}/comp/sr-comp-http.git",
    source    => 'git://github.com/PeterJCLaw/sr-comp-http.git',
    revision  => 'origin/master',
    force     => true,
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Package['python-flask'],
    notify    => Service['httpd'],
  }

  # Checkout of the competition state
  $compstate_dir = "${root_dir}/compstate"
  vcsrepo { $compstate_dir:
    ensure    => present,
    provider  => git,
# Doesn't work
#    source    => "${git_root}/comp/comp/sr2014-comp.git",
    source    => 'git://github.com/PeterJCLaw/sr-dummy-comp.git',
    revision  => 'origin/master',
    force     => true,
    owner     => 'wwwcontent',
    group     => 'apache',
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

  # TODO: review this mechanism
  #  -- should we instead put a post-recieve-pack hook into the repo?
  cron { 'comp-api-updates':
    command => "cd ${compstate_dir} && git pull origin master",
    minute  => '*/5',
    user    => 'wwwcontent',
    require => Vcsrepo[$compstate_dir],
  }
}
