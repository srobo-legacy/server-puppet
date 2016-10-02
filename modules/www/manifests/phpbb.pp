# phpBB, the popular and featureful forum software.

class www::phpbb ( $git_root, $root_dir ) {
  # MySQL database configuration
  $forum_db_name = 'phpbb_sr2016'
  $forum_user = hiera('phpbb_sql_user')
  $forum_pw = hiera('phpbb_sql_pw')

  # We require the bindings between php and mysql to work
  package { 'php-mysqlnd':
    ensure => present,
    notify => Service['httpd'],
    alias  => 'php-mysql',
  }

  # Checkout of the phpbb sources
  vcsrepo { $root_dir:
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => 'https://github.com/phpbb/phpbb.git',
    revision => 'release-3.1.6',
    require => Package[ 'php', 'php-mysql' ],
  }

  # Create the MySQL db for the forum
  mysql::db { $forum_db_name:
    user => $forum_user,
    password => $forum_pw,
    host => 'localhost',
    grant => ['all'],
  }

  # Load the database data from backup, if it hasn't already.
  exec { 'pop_forum_db':
    command => "mysql -u ${forum_user} --password='${forum_pw}' ${forum_db_name} < /srv/secrets/mysql/${forum_db_name}.db && touch /usr/local/var/sr/forum_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/forum_installed',
    require => Mysql::Db[$forum_db_name],
  }

  # Maintain permissions on the config file, and template it. Contains SQL
  # connection gunge.
  file { "${root_dir}/phpBB/config.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '0640',
    content => template('www/forum_config.php.erb'),
    require => Vcsrepo[$root_dir],
  }

  exec { 'phpbb-composer-install':
    command     => '/usr/bin/php ../composer.phar install',
    provider    => 'shell',
    cwd         => "${root_dir}/phpBB",
    user        => 'wwwcontent',
    group       => 'apache',
    environment => [ 'HOME=/home/wwwcontent', ],
    refreshonly => true,
    subscribe   => Vcsrepo[$root_dir],
    require     => File['/home/wwwcontent'],
  }

  # Remove the install directory since we're restoring from a database
  # dump instead. Needed before the forums will serve the actual forums.
  file { "${root_dir}/phpBB/install":
    ensure  => absent,
    force   => true,
    require => Vcsrepo[$root_dir],
  }

  # The style we want
  archive { 'phpbb-prosilver_se-style':
    ensure        => present,
    url           => 'https://www.phpbb.com/customise/db/download/119406',
    extension     => 'zip',
    digest_string => 'c2743e19b5e98261a301e107fecedd8c',
    digest_type   => 'md5',
    user          => 'wwwcontent',
    target        => "${root_dir}/phpBB/styles",
    # where it downloads the file to, also where it puts the .md5 file
    src_target    => $root_dir,
    require       => Vcsrepo[$root_dir],
  }

  # Our custom extensions
  $extensions_dir = "${root_dir}/phpBB/ext/sr"
  file { $extensions_dir:
    ensure  => directory,
    owner   => 'wwwcontent',
    group   => 'apache',
    mode    => '0755',
    require => Vcsrepo[$root_dir],
  }

  vcsrepo { "${extensions_dir}/pipebot":
    ensure    => present,
    user      => 'wwwcontent',
    provider  => git,
    source    => "${git_root}/phpbb-ext-sr-pipebot.git",
    revision  => 'origin/master',
    require   => File[$extensions_dir],
  }

  vcsrepo { "${extensions_dir}/etc":
    ensure    => present,
    user      => 'wwwcontent',
    provider  => git,
    source    => "${git_root}/phpbb-ext-sr-etc.git",
    revision  => 'origin/master',
    require   => File[$extensions_dir],
  }

  # Directory for storing forum attachments.
  $attachments_dir = "${root_dir}/phpBB/files"
  file { $attachments_dir:
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  # Some form of forum page cache
  file { "${root_dir}/phpBB/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }

  # Not the foggiest, but this is how it was on optimus, so this is configured
  # thus here too.
  file { "${root_dir}/phpBB/store":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo[$root_dir],
  }
}
