class { '::etherpad_lite':
  ep_ensure      => 'latest',
  eplite_version => 'cc9f88e7ed4858b72feb64c99beb3e13445ab6d9',
  nodejs_version => 'system',
}

class { '::etherpad_lite::apache': }

class { '::etherpad_lite::site':
  database_password => 'fake_password',
  etherpad_title    => 'A fake title',
}
