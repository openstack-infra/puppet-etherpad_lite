# Define to install etherpad lite plugins
#
define etherpad_lite::plugin {
  $plugin_name = $name
  exec { "npm install ${plugin_name}":
    cwd         => $etherpad_lite::modules_dir,
    path        => $etherpad_lite::path,
    user        => $etherpad_lite::ep_user,
    environment => "HOME=/home/${etherpad_lite::ep_user}",
    creates     => "${etherpad_lite::modules_dir}/${plugin_name}",
    require     => [
      Class['etherpad_lite'],
      User[$etherpad_lite::ep_user],
    ],
  }
}
