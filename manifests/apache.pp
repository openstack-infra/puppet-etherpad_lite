# == Class: etherpad_lite::apache
#
class etherpad_lite::apache (
  $vhost_name = $::fqdn,
  $docroot = '/srv/etherpad-lite',
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = undef,
  $ssl_key_file = undef,
  $ssl_chain_file = undef,
  $ssl_cert_file_contents = undef, # If left undef puppet will not create file.
  $ssl_key_file_contents = undef, # If left undef puppet will not create file.
  $ssl_chain_file_contents = undef, # If left undef puppet will not create file.
) {

  package { 'ssl-cert':
    ensure => present,
  }

  include ::httpd
  httpd::mod { 'rewrite':
    ensure => present,
  }
  httpd::mod { 'proxy':
    ensure => present,
  }
  httpd::mod { 'proxy_http':
    ensure => present,
  }
  ::httpd::vhost { $vhost_name:
    port       => 443,
    vhost_name => $vhost_name,
    docroot    => $docroot,
    priority   => '50',
    template   => 'etherpad_lite/etherpadlite.vhost.erb',
    ssl        => true,
    require    => [
      Httpd::Mod['rewrite'],
      Httpd::Mod['proxy'],
      Httpd::Mod['proxy_http'],
    ]
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
    file { '/etc/apache2/conf-available/connection-tuning.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/etherpad_lite/apache-connection-tuning',
      notify  => Service['httpd'],
      require => Httpd::Vhost[$vhost_name],
    }

    file { '/etc/apache2/conf-enabled/connection-tuning.conf':
      ensure  => link,
      target  => '/etc/apache2/conf-available/connection-tuning.conf',
      notify  => Service['httpd'],
      require => File['/etc/apache2/conf-available/connection-tuning.conf'],
    }

    httpd::mod { 'proxy_wstunnel':
      ensure => present,
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

  if $ssl_cert_file_contents != undef {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != undef {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != undef {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }
}
