
class sr-site::mysql {

  # Install the mysql server
  class { "mysql::server":
    root_password => extlookup('mysql_rootpw'),
  }

}
