# == Class: puppet-etherpad_lite::mysql
#
class etherpad_lite::mysql(
  $database_password,
  $mysql_root_password,
  $database_name = 'etherpad-lite',
  $database_user = 'eplite',
) {
  class { '::mysql::server':
    root_password    => $mysql_root_password,
    override_options => {
      'mysqld' => {
        'default-storage-engine' => 'InnoDB',
      }
    }
  }

  include ::mysql::server::account_security

  mysql::db { $database_name:
    user     => $database_user,
    password => $database_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8mb4',
    collate  => 'utf8mb4_unicode_ci',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}
