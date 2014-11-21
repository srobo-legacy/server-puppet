# Community guidelines

class www::community-guidelines( $git_root, $web_root_dir ) {

  # Guidelines page
  vcsrepo { "${web_root_dir}/community-guidelines":
    ensure    => latest,
    provider  => git,
    source    => "${git_root}/community-guidelines.git",
    revision  => 'origin/master',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

}
