class { '::etherpad_lite':
  nodejs_version => 'system',
}

class { '::etherpad_lite::apache':
  ssl_cert_file  => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_key_file   => '/etc/ssl/private/ssl-cert-snakeoil.key',
}

class { '::etherpad_lite::site':
  etherpad_title    => 'OpenStack Etherpad',
  database_host     => 'localhost',
  database_user     => 'eplite',
  database_name     => 'etherpad-lite',
  database_password => '',
}

etherpad_lite::plugin { 'ep_headings':
  require => Class['etherpad_lite'],
}
