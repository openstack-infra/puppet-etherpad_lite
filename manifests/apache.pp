# == Class: etherpad_lite::apache
#
# For websockets, set $etherpad_lite::apache::wstunnel to true.
#
#
class etherpad_lite::apache (
  $vhost_name = $::fqdn,
  $docroot = '/srv/etherpad-lite',
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $wstunnel = false
) {

  package { 'ssl-cert':
    ensure => present,
  }

  include ::httpd
  ::httpd::vhost { $vhost_name:
    port     => 443,
    docroot  => $docroot,
    priority => '50',
    template => 'etherpad_lite/etherpadlite.vhost.erb',
    ssl      => true,
  }
  httpd_mod { 'rewrite':
    ensure => present,
  }
  httpd_mod { 'proxy':
    ensure => present,
  }
  httpd_mod { 'proxy_http':
    ensure => present,
  }

  if ($::lsbdistcodename == 'precise') {
    file { '/etc/apache2/conf.d/connection-tuning':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/etherpad_lite/apache-connection-tuning',
      notify => Service['httpd'],
    }
  } else {
    file { '/etc/apache2/conf-available/connection-tuning':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/etherpad_lite/apache-connection-tuning',
    }

    file { '/etc/apache2/conf-enabled/connection-tuning':
      ensure  => link,
      target  => '/etc/apache2/conf-available/connection-tuning',
      notify  => Service['httpd'],
      require => File['/etc/apache2/conf-available/connection-tuning'],
    }

    if ($wstunnel == true) {
      httpd_mod { 'proxy_wstunnel':
        ensure => present,
      }
    } else {
      httpd_mod { 'proxy_wstunnel':
        ensure => absent,
      }
    }
  }

  file { $docroot:
    ensure => directory,
  }

  file { "${docroot}/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/etherpad_lite/robots.txt',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => File[$docroot],
  }

  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    mode   => '0700',
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }
}
