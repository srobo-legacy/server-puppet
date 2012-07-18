
class www( $git_root ) {

  include www::httpd

  class { "www::srweb":
    git_root => $git_root,
  }

}
