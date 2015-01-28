# Installs python memcache bindings
class memcached::python {

  package {'python-memcache':
    ensure => installed,
  }
}
