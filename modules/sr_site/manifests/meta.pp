
class sr_site::meta{

  cron { 'puppet-update':
    command => 'git --git-dir=/etc/puppet/.git/ fetch',
    hour => '4',
    minute => '3',
    user => 'root',
  }

  file { '/root/puppet_apply':
    ensure  => link,
    target  => '/etc/puppet/scripts/apply',
  }
}
