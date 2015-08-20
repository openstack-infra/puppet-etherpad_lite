# == Class: etherpad_lite
#
# Class to install etherpad lite. Puppet acts a lot like a package manager
# through this class.
#
# To use etherpad lite you will want the following includes:
# include etherpad_lite
# include etherpad_lite::mysql # necessary to use mysql as the backend
# include etherpad_lite::site # configures etherpad lite instance
# include etherpad_lite::apache # will add reverse proxy on localhost
# The defaults for all the classes should just work (tm)
#
#
class etherpad_lite (
  $ep_user          = 'eplite',
  $base_log_dir     = '/var/log',
  $base_install_dir = '/opt/etherpad-lite',
  # If set to system will install system package.
  $nodejs_version   = 'v0.10.21',
  $eplite_version   = 'develop',
  $ep_ensure        = 'present',
) {

  # where the modules are, needed to easily install modules later
  $modules_dir = "${base_install_dir}/etherpad-lite/node_modules"
  $path = "/usr/bin:/bin:/usr/local/bin:${base_install_dir}/etherpad-lite"

  user { $ep_user:
    shell   => '/usr/sbin/nologin',
    home    => "${base_log_dir}/${ep_user}",
    system  => true,
    gid     => $ep_user,
    require => Group[$ep_user],
  }

  group { $ep_user:
    ensure => present,
  }

  # Below is what happens when you treat puppet as a package manager.
  # This is probably bad, but it works and you don't need to roll .debs.
  file { $base_install_dir:
    ensure => directory,
    group  => $ep_user,
    mode   => '0664',
  }

  if ($nodejs_version != 'system') {
    vcsrepo { "${base_install_dir}/nodejs":
      ensure   => present,
      provider => git,
      source   => 'https://github.com/joyent/node.git',
      revision => $nodejs_version,
      require  => [
          Package['git'],
          File[$base_install_dir],
      ],
    }

    package { [
        'gzip',
        'curl',
        'python',
        'libssl-dev',
        'pkg-config',
        'abiword',
        'build-essential',
      ]:
      ensure => present,
    }

    package { ['nodejs', 'npm']:
      ensure => purged,
    }

    file { '/usr/local/bin/node':
      ensure => absent,
    }

    buildsource { "${base_install_dir}/nodejs":
      timeout => 900, # 15 minutes
      creates => '/usr/local/bin/node',
      require => [
        Package['gzip'],
        Package['curl'],
        Package['python'],
        Package['libssl-dev'],
        Package['pkg-config'],
        Package['build-essential'],
        Vcsrepo["${base_install_dir}/nodejs"],
      ],
      before  => Anchor['nodejs-anchor'],
    }
  } else {
    package { ['nodejs', 'npm']:
      ensure => present,
      before => Anchor['nodejs-anchor'],
    }

    file { '/usr/local/bin/node':
      ensure => link,
      target => '/usr/bin/nodejs',
      before => Anchor['nodejs-anchor'],
    }
  }

  anchor { 'nodejs-anchor': }

  vcsrepo { "${base_install_dir}/etherpad-lite":
    ensure   => $ep_ensure,
    provider => git,
    source   => 'https://github.com/ether/etherpad-lite.git',
    owner    => $ep_user,
    revision => $eplite_version,
    require  => [
        Package['git'],
        User[$ep_user],
    ],
  }

  exec { 'install_etherpad_dependencies':
    command     => './bin/installDeps.sh',
    path        => $path,
    user        => $ep_user,
    cwd         => "${base_install_dir}/etherpad-lite",
    environment => "HOME=${base_log_dir}/${ep_user}",
    require     => [
      Vcsrepo["${base_install_dir}/etherpad-lite"],
      Anchor['nodejs-anchor'],
    ],
    before      => File["${base_install_dir}/etherpad-lite/settings.json"],
    creates     => "${base_install_dir}/etherpad-lite/node_modules",
  }

  file { '/etc/init/etherpad-lite.conf':
    ensure  => present,
    content => template('etherpad_lite/upstart.erb'),
    replace => true,
    owner   => 'root',
  }

  file { '/etc/init.d/etherpad-lite':
    ensure => link,
    target => '/lib/init/upstart-job',
  }

  file { "${base_log_dir}/${ep_user}":
    ensure => directory,
    owner  => $ep_user,
  }
  # end package management ugliness
}
