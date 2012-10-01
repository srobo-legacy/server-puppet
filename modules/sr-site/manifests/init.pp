
# git_root: The root URL to access the SR git repositories
class sr-site( $git_root ) {

  # Default PATH
  Exec {
    path => [ "/usr/bin" ],
  }
  
  # Anonymous git access
  include gitdaemon

  # The bee
  include bee

  include sr-site::firewall
  include sr-site::mysql
  include sr-site::openldap
  include sr-site::trac

  # Web stuff
  class { "www":
    git_root => $git_root,
  }
}



