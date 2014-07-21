# Backups make sure that we have all the datas, even if we don't have the server

class sr-site::backup ( $git_root ) {

  # A checkout of the server backup git repo. The backup script has to exist at
  # a known location on the server so that we can configure sudo, so that the
  # 'backup' user can run backups as root.
  vcsrepo { '/srv/backup':
    ensure => present,
    owner => 'root',
    group => 'root',
    provider => 'git',
    source => "${git_root}/server/backup.git",
    revision => 'master', # Deliberately no auto update, the scripts here will
                          # end up be run as root
  }

  # FIXME: find a way of extracting all mysql dbs from puppet?
  $all_dbs = [
    $www::phpbb::forum_db_name,
    $www::piwik::piwik_db_name,
    # Constants because hyphens in the names cause issues
    'trac', # sr-site::trac::trac_db_name
    'reviewdb', # sr-site::gerrit::gerrit_db_name
  ]
  $list_of_dbs = join($all_dbs, ',')
  $ide_loc = $www::ide::root_dir
  $team_status_images_loc = $www::ide::team_status_imgs_live_dir
  $forum_attachments_loc = $www::phpbb::attachments_dir

  # A list of users permitted to use backups. This list doesn't actually allow
  # them to do anything, instead it's used as the list of email IDs that GPG
  # should encrypt backups for. In common.csv, this should be a single entry
  # enclosed in quotes, with commas seperating email IDs within, for example:
  #
  # backup_keys,"bees@example.com,marvin@example.com"
  #
  # Note that all backup keys must also be (locally) signed by the root user.
  # Failure to do this will make backup fail.
  $backup_crypt_keys = extlookup('backup_keys')

  # Config file for mapping puppet configuration goo into the backup script.
  # Quite a lot of improvement could go on here.
  file { '/srv/backup/backup.ini':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0400',
    content => template('sr-site/backup.ini.erb')
  }

  # A user for running backups - anyone permitted to run backups gets an SSH
  # key (see below) enabled to log in as this user. The single additional
  # thing the user is permitted to do is run (encrypted) backups as root.
  # This could be locked down further, not urgent at all.
  user { 'backup':
    ensure => present,
    comment => 'Backup operations user',
    shell => '/bin/bash',
    gid => 'users',
  }

  # Backup's home dir.
  file { '/home/backup':
    ensure => directory,
    owner => 'backup',
    group => 'users',
    mode => '0700',
    require => User['backup'],
  }

  # Backup's ssh key dir.
  file { '/home/backup/.ssh':
    ensure => directory,
    owner => 'backup',
    group => 'users',
    mode => '0700',
  }

  # Backup's ssh keys - this is simply a authorized_keys file that's kept in
  # /srv/secrets, and gets installed into the backup account.
  file { '/home/backup/.ssh/authorized_keys':
    ensure => present,
    owner => 'backup',
    group => 'users',
    mode => '0600',
    source => '/srv/secrets/login/backups_ssh_keys',
    require => File['/home/backup/.ssh'],
  }

  # The backup scripts run GPG to encrypt backups; ensure it's installed.
  package { 'gnupg':
    ensure => present,
  }
}
