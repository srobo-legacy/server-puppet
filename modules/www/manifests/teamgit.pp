class www::teamgit {

  file { '/usr/local/bin/team_repos_conf_builder.py':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '600',
    content => template('www/team_repos_conf_builder.py.erb'),
  }

  file { '/usr/local/bin/team_repos_conf_template.conf':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '600',
    source => 'puppet:///modules/www/team_repos_conf_template.conf',
  }

  exec { 'create_team_git':
    command => '/usr/local/bin/team_repos_conf_builder.py /etc/httpd/conf.d/teamgit.conf',
    user => 'root',
  }

  file { '/etc/httpd/conf.d/teamgit.conf':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '600',
    require => Exec['create_team_git'],
    notify => Service['httpd'],
  }
}
