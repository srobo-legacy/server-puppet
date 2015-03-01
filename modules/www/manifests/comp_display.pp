# Various forms of output of competition related information

class www::comp_display( $git_root, $web_root_dir ) {

  # Arena Screens
  vcsrepo { "${web_root_dir}/screens":
    ensure    => absent,
  }

  # Information for shepherds
  vcsrepo { "${web_root_dir}/shepherding":
    ensure    => present,
    provider  => git,
    source    => "${git_root}/srcomp-shepherding.git",
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

}
