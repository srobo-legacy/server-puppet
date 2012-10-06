
class sr-site::openldap {
  class { 'ldap':
    server => 'true',
    client => 'true',
  }
}
