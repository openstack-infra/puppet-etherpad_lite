class { '::etherpad_lite':
  ep_ensure      => 'latest',
  eplite_version => 'cc9f88e7ed4858b72feb64c99beb3e13445ab6d9',
  nodejs_version => 'system',
}

class { '::etherpad_lite::apache':
  ssl_cert_file_contents => file('/etc/ssl/certs/ssl-cert-snakeoil.pem'),
  ssl_cert_file          => '/etc/pki/tls/certs/localhost.pem',
  ssl_key_file_contents  => file('/etc/ssl/private/ssl-cert-snakeoil.key'),
  ssl_key_file           => '/etc/pki/tls/private/localhost.key',
}

class { '::etherpad_lite::site':
  database_password => 'fake_password',
  etherpad_title    => 'A fake title',
}
