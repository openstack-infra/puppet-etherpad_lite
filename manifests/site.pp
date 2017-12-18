# == Class: etherpad_lite::site
#
class etherpad_lite::site (
  $database_password,
  $etherpad_title,
  $database_host = 'localhost',
  $database_name = 'etherpad-lite',
  $database_user = 'eplite',
  $db_type       = 'mysql',
  $session_key   = '',
) {

  include ::etherpad_lite

  $base = $etherpad_lite::base_install_dir

  file { "${base}/etherpad-lite/settings.json":
    ensure  => present,
    content => template('etherpad_lite/etherpad-lite_settings.json.erb'),
    replace => true,
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0600',
    require => Class['etherpad_lite'],
    before  => Service['etherpad-lite'],
  }

  file { "${base}/etherpad-lite/src/static/custom/pad.js":
    ensure  => present,
    source  => 'puppet:///modules/etherpad_lite/pad.js',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0644',
    require => Class['etherpad_lite'],
    before  => Service['etherpad-lite'],
  }

}
