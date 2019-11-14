# Installs python memcache bindings
class memcached::python {
  include ::oslo::params
  
  ensure_resources('package', { 'python-memcache' => {
    name   => $::oslo::params::python_memcache_package_name,
    tag    => ['openstack'],
    }})

}
