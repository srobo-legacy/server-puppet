
class sr_site::fw_pre {

  firewall { '000 accept all icmp':
    proto  => 'icmp',
    action => 'accept',
  }

  firewall { '001 allow loopback':
    iniface => 'lo',
    chain => 'INPUT',
    action => 'accept',
  }

  # Allow all traffic attached to established connections. Important for
  # connections made by the server.
  firewall { '000 INPUT allow related and established':
    state => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
    proto => 'all',
  }

  # We've been regularly spammed by some signage in ECS for a while.
  # They operate from these IPs, and grab our news page 500 times each
  # regularly
  firewall { '000.0 Block ECS signage':
    source => '152.78.71.52',
    action => 'drop',
  }
  firewall { '000.1 Block ECS signage':
    source => '152.78.71.95',
    action => 'drop',
  }
  firewall { '000.2 Block ECS signage':
    source => '152.78.71.97',
    action => 'drop',
  }
  firewall { '000.3 Block ECS signage':
    source => '152.78.71.141',
    action => 'drop',
  }

  # Allow everyone to connect to ssh.
  firewall { '002 ssh':
    proto  => 'tcp',
    dport => 22,
    action => 'accept',
  }

  # Allow everyone to connect to the anonymous git service.
  firewall { '003 git':
    proto => 'tcp',
    dport => 9418,
    action => 'accept',
  }

  # Allow everyone to connect to the HTTP website.
  firewall { '004 http':
    proto => 'tcp',
    dport => 80,
    action => 'accept',
  }

  # Allow everyone to connect to the SSL website
  firewall { '005 https':
    proto => 'tcp',
    dport => 443,
    action => 'accept',
  }

  # Open gerrit's HTTP service to be reverse-proxy'd by apache. It's not
  # acceptable to have passwords flying over non-SSL connections.
  firewall { '006 gerrit-http':
    proto => 'tcp',
    dport => '8081',
    action => 'accept',
    source => '127.0.0.1', # Limit to only apache reverse-proxying.
  }

  # Open gerrit's SSHD service to everyone
  firewall { '007 gerrit-sshd':
    proto => 'tcp',
    dport => '29418',
    action => 'accept',
  }
}
