# Volunteer Handbook

class www::volunteer_handbook($git_root, $web_root_dir) {

  vcsrepo { "${web_root_dir}/volunteer-handbook":
    ensure    => latest,
    provider  => git,
    force     => true,
    source    => "${git_root}/volunteer-handbook.git",
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

}
