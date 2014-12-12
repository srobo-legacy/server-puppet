
class sr_site::meta{

  cron { 'puppet-update':
    command => 'git --git-dir=/etc/puppet/.git/ fetch',
    hour => '4',
    minute => '3',
    user => 'root',
  }

}
