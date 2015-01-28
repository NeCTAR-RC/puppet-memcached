# Installs python memcache bindings
class memcached::python {

  package {'python-memcached':
    ensure => installed,
  }
}
