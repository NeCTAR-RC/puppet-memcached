class memcached($slab_size='1048576', $max_mem='1024') {

  package {'memcached':
    ensure => installed,
  }

  file {'/etc/memcached.conf':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    content => template("memcached/memcached.conf.erb"),
    notify => Service['memcached'],
  }

  service { 'memcached':
    ensure  => running,
    require => Package['memcached'],
  }

  realize Package['python-memcache']

  nagios::nrpe::service {
    'memcached':
      check_command => "/usr/local/lib/nagios/plugins/check_memcached -H ${::fqdn}";
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
    require => [ File['/usr/local/lib/nagios/plugins'],
                 Package['python-memcache'] ];
  }
}
