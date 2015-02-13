# A type which wraps checking out an SRComp repo for installation into
# the comp-api virtualenv.

define www::srcomp_repo ( $git_root, $root_dir, $venv_dir ) {

  $url = "${git_root}/comp/${title}.git"
  $location = "${root_dir}/${title}"
  $exec_name = "install-${title}"

  # Checkout of the repo
  vcsrepo { $location:
    ensure    => present,
    provider  => git,
    source    => $url,
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => File[$root_dir],
    notify    => Exec[$exec_name],
  }

  exec { $exec_name:
    command     => "'${venv_dir}/bin/python' setup.py install",
    cwd         => $location,
    user        => 'wwwcontent',
    group       => 'apache',
    refreshonly => true,
    require     => [Exec['srcomp-venv'],Vcsrepo[$location]],
    notify      => Service['httpd'],
  }
}
