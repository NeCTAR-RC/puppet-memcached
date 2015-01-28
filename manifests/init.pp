# This module installs and manages memcached and python-memcache,
# defines an nrpe nagios check, and sets firewall rules.
#
# Parameters:
#    slab_size
#      The maximum item size in bytes that memcached will accept.
#    max_mem
#      The maximum amount of memory in MB to use for storing objects.
#    file_handles
#      The maximum number of file handles memcached may use.
#
# Requires: stdlib

class memcached($slab_size='1048576',
                $max_mem='1024',
                $file_handles='4096'
) {

  package {'memcached':
    ensure => installed,
  }

  file {'/etc/memcached.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('memcached/memcached.conf.erb'),
    notify  => Service['memcached'],
  }

  file {'/etc/default/memcached':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('memcached/default.memcached.erb'),
    notify  => Service['memcached'],
  }

  service { 'memcached':
    ensure  => running,
    require => Package['memcached'],
  }

  include memcached::python

  nagios::nrpe::service {
    'memcached':
      check_command =>
        "/usr/local/lib/nagios/plugins/check_memcached -H ${::fqdn}";
  }

  $infra_hosts = hiera('firewall::infra_hosts', [])
  firewall::multisource {[ prefix($infra_hosts, '100 memcache,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => 11211,
  }

  file {'/usr/local/lib/nagios/plugins/check_memcached':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/memcached/check_memcached.py',
    require =>
      [ File['/usr/local/lib/nagios/plugins'],
        Package['python-memcache'] ];
  }
}
