
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
}
