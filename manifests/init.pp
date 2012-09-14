class memcached {

  package {'memcached':
    ensure => installed,
  }

  file {'/etc/memcached.conf':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/memcached/memcached.conf',
    notify => Service['memcached'],
  }

  service { 'memcached':
    ensure  => running,
    require => Package['memcached'],
  }

  if !defined(Package['python-memcache']) {
    package {'python-memcache':
      ensure => installed,
    }
  }

  nagios::nrpe::service {
    'memcached':
      check_command => "/usr/local/lib/nagios/plugins/check_memcached -H ${::fqdn}";
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
