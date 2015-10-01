# This module installs and manages memcached and python-memcache,
# defines an nrpe nagios check, and sets firewall rules.
#
# Parameters:
#    slab_size
#      The maximum item size in bytes that memcached will accept.
#    max_mem
#      The maximum amount of memory in MB to use for storing objects.
#    max_connections
#      The maximum number of simultaneous incoming connections.
#    listen
#      The which IP address to listen on.
#    port
#      The port to listen on.
#    user
#      User account to run process as.
#
# Requires: stdlib

class memcached (
  $max_mem='1024',
  $max_connections='1024',
  $listen='0.0.0.0',
  $port='11211',
  $user='nobody',
  $slab_size='1048576'
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

    'memcached-curr_connections':
      check_command =>
        "/usr/local/lib/nagios/plugins/check_memcached_metric -H ${::fqdn} -M curr_connections -V ${max_connections}";
  }


  $infra_hosts = hiera('firewall::infra_hosts', [])
  nectar::firewall::multisource {[ prefix($infra_hosts, '100 memcache,') ]:
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

  file {'/usr/local/lib/nagios/plugins/check_memcached_metric':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/memcached/check_memcached_metric.py',
    require => File['/usr/local/lib/nagios/plugins'],
  }

}
