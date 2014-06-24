# Voting scripts. Installed in a users public_html: this way apache will use
# suexec to run the scripts as the 'voting' user, making sure that recorded
# votes are only accessible by the voting user.

class www::voting ($git_root, $web_root_dir) {
  # The voting scripts use pyyaml,
  package { 'PyYAML':
    ensure => present,
  }

  # Directories and user for 'voting' user; all with only traverse permission
  # for other users.
  file { '/home/voting':
    ensure  => directory,
    owner   => 'voting',
    group   => 'users',
    mode    => '0711',
    require => User['voting'],
  }

  file { '/home/voting/public_html':
    ensure  => directory,
    owner   => 'voting',
    group   => 'users',
    mode    => '0711',
    require => [User['voting'], File['/home/voting']],
  }

  user { 'voting':
    ensure  => present,
    comment => 'Owner of voting record files',
    shell   => '/sbin/nologin',
    gid     => 'users',
    home    => '/home/voting',
  }

  # Checkout of the voting scripts, for people to vote with.
  vcsrepo { '/home/voting/public_html/voting':
    ensure   => present,
    provider => git,
    source   => "${git_root}/voting.git",
    revision => 'origin/master',
    require  => [Package['PyYAML'], User['voting']],
    owner    => 'voting',
    group    => 'users',
  }

  # Directory for storing votes in. Only accessible by the voting user itself.
  file { '/home/voting/public_html/voting/votes':
    ensure  => directory,
    owner   => 'voting',
    group   => 'users',
    mode    => '0700', # Prohibit people from seeing who voted.
    require => Vcsrepo['/home/voting/public_html/voting'],
  }
}
