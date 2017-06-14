# Installs python memcache bindings
class memcached::python {
  
  ensure_resources('package', { 'python-memcache' => {
    name   => 'python-memcache',
    tag    => ['openstack'],
    }})

}
