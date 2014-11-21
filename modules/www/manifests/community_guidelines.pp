# Community guidelines

class www::community_guidelines( $git_root, $web_root_dir ) {

  # Guidelines page
  vcsrepo { "${web_root_dir}/community-guidelines":
    ensure    => latest,
    provider  => git,
    force     => true,
    source    => "${git_root}/community-guidelines.git",
    # TODO: change to origin/master once a maintainer situation is in place
    revision  => '8d351d565751ca9e36cc701cfece5ec025d335b5',
    owner     => 'wwwcontent',
    group     => 'apache',
    require   => Vcsrepo[$web_root_dir],
  }

}
