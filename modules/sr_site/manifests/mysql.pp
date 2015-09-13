# Various things need mysql: PHPBB forums, Piwik, Gerrit, etc.

class sr_site::mysql {
  $root_password = hiera('mysql_rootpw')

  # Install the mysql server
  class { 'mysql::server':
    root_password => $root_password,
  }

}
