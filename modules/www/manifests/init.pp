
class www( $git_root ) {
  $web_root_dir = '/var/www/html'

  include www::httpd

  class { "www::srweb":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
  }

  class { "www::voting":
    git_root => $git_root,
    web_root_dir => $web_root_dir,
  }

  class { 'www::phpbb':
    git_root => $git_root,
    root_dir => '/var/www/vhosts/phpbb',
  }
}
