
# git_root: The root URL to access the SR git repositories
class sr-site( $git_root ) {
  
  # Anonymous git access
  include gitdaemon

  # The bee
  include bee

  include sr-site::firewall
}



