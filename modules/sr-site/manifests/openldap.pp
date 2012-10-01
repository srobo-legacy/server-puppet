
class sr-site::openldap {
  class { 'ldap':
    server => 'true'
  }
}
