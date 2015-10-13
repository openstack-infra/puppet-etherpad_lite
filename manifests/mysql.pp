# == Class: puppet-etherpad_lite::mysql
#
class etherpad_lite::mysql(
  $mysql_root_password,
  $database_name = 'etherpad-lite',
  $database_user = 'eplite',
  $database_password,
) {
  class { '::mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
  include ::mysql::server::account_security

  mysql::db { $database_name:
    user     => $database_user,
    password => $database_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}
