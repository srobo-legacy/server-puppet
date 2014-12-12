
class sr_site::fw_post {

  firewall { '999 drop all':
    action  => 'drop',
  }

}
