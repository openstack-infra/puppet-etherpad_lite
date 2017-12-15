class { '::etherpad_lite':
  ep_ensure      => 'latest',
  eplite_version => '1.6.2',
  nodejs_version => '6.x',
}

class { '::etherpad_lite::apache': }

class { '::etherpad_lite::site':
  database_password => 'fake_password',
  etherpad_title    => 'A fake title',
}
