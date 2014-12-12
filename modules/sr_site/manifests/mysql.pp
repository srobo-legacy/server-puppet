# Various things need mysql: PHPBB forums, Piwik, Gerrit, etc.

class sr_site::mysql {

  # Install the mysql server
  class { 'mysql::server':
    root_password => extlookup('mysql_rootpw'),
  }

}
