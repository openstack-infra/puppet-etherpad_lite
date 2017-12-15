class { '::etherpad_lite':
  ep_ensure      => 'latest',
  eplite_version => '1.6.2',
  nodejs_version => '6.x',
}

class { '::etherpad_lite::apache':
  ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_key_file  => '/etc/ssl/private/ssl-cert-snakeoil.key',
}

class { '::etherpad_lite::site':
  database_password => 'fake_password',
  etherpad_title    => 'A fake title',
}
