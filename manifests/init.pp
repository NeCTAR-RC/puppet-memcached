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
  Integer $max_mem               = 1024,
  Integer $max_connections       = 1024,
  Stdlib::IP::Address $listen    = '0.0.0.0',
  Stdlib::Port $port             = 11211,
  String $user                   = 'nobody',
  Integer $slab_size             = 1048576,
  Boolean $include_extra         = true,
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

  if $include_extra {

    notify {'memcached::direct::deprecated':
      message => 'Including the memcache class directly is deprecated. Please include nectar::profile:memcached',
    }

    # Generate 80%/90% values for nagios current connections check
    $curr_connections_warning = inline_template('<%= (@max_connections.to_i * 0.8).floor -%>')
    $curr_connections_error = inline_template('<%= (@max_connections.to_i * 0.9).floor -%>')

    nagios::nrpe::service {
      'memcached':
        check_command =>
        "/usr/local/lib/nagios/plugins/check_memcached -H ${facts['networking']['fqdn']}";
      'memcached-curr_connections':
        check_command =>
        "/usr/local/lib/nagios/plugins/check_memcached_metric -H ${facts['networking']['fqdn']} -M curr_connections -W ${curr_connections_warning} -C ${curr_connections_error}";
    }

    $infra_hosts = hiera('firewall::infra_hosts', [])
    nectar::firewall::multisource {[ prefix($infra_hosts, '100 memcache,') ]:
      jump  => 'ACCEPT',
      proto => 'tcp',
      dport => 11211,
    }

    ensure_packages('python-memcache', {
      name => 'python3-memcache',
      tag  => ['openstack'],
    })

    file {'/usr/local/lib/nagios/plugins/check_memcached':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/memcached/check_memcached.py',
      require => [File['/usr/local/lib/nagios/plugins'],
                  Package['python-memcache']],
    }

    file {'/usr/local/lib/nagios/plugins/check_memcached_metric':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/memcached/check_memcached_metric.py',
      require => [File['/usr/local/lib/nagios/plugins'],
                  Package['python-memcache']],
    }
  }
}
