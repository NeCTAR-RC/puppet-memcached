class memcached {

  package {"memcached":
    ensure => installed,
  }
  
  file {"/etc/memcached.conf":
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

  package {'python-memcache':
    ensure => installed,
  }

}
