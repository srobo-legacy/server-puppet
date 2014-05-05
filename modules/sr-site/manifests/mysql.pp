# Various things need mysql: PHPBB forums, Piwik, Gerrit, etc.

class sr-site::mysql {

  # Install the mysql server
  class { 'mysql::server':
    config_hash => { 'root_password' => extlookup( 'mysql_rootpw' ) }
  }

}
