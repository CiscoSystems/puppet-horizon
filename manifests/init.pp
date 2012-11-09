#
# installs a horizon server
#
#
# - Parameters
# $cache_server_ip      memcached ip address (or VIP)
# $cache_server_port    memcached port
# $swift                (bool) is swift installed
# $quantum              (bool) is quantum installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
#
class horizon(
  $cache_server_ip   = '127.0.0.1',
  $cache_server_port = '11211',
  $swift = false,
  $quantum = false,
  $horizon_app_links = false,
  $horizon_top_links = false,
  $www_hostname = 'www.example.com'
) {

  include horizon::params

  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }

  include apache

  package { "$::horizon::params::package_name":
    ensure => present,
    tag => "openstack"
  }

  file { '/etc/openstack-dashboard/local_settings.py':
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
    notify  => Service[httpd]
  }

  file { "/etc/apache2/conf.d/openstack-dashboard.conf":
        source  => 'puppet:///modules/horizon/openstack-dashboard.def',
        owner   => 'root',
        group   => 'root',
        mode    => '755',
        notify  => Service['httpd'],
  }

  apache::vhost::proxy { $www_hostname:
    port            => '80',
    dest            => 'http://localhost/openstack-dashboard',
    no_proxy_uris   => ['/openstack-dashboard']
  }

  
}
