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

  if defined(Package['nagios-plugins-basic']) {

    file { '/usr/lib/nagios/plugins/check_memcached.py':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/memcached/check_memcached.py',
      require => Package['nagios-plugins-basic'],
    }
  }
}
