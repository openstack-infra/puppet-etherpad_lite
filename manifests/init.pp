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
  $base_install_dir = '/opt/etherpad-lite',
  $base_log_dir     = '/var/log',
  $ep_ensure        = 'present',
  $ep_user          = 'eplite',
  $eplite_version   = 'develop',
  # If set to system will install system package.
  $nodejs_version   = 'node_0.10',
) {

  # where the modules are, needed to easily install modules later
  $modules_dir = "${base_install_dir}/etherpad-lite/node_modules"
  $path = "/usr/local/bin:/usr/bin:/bin:${base_install_dir}/etherpad-lite"

  user { $ep_user:
    shell   => '/usr/sbin/nologin',
    home    => "${base_install_dir}/${ep_user}",
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

  package { 'abiword':
    ensure => present,
  }

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present,
    }
  }

  anchor { 'nodejs-package-install': }

  if ($nodejs_version != 'system') {
    class { '::nodejs':
      repo_url_suffix => $nodejs_version,
      before          => Anchor['nodejs-package-install'],
    }
  } else {
    package { ['nodejs', 'npm']:
      ensure => present,
      before => Anchor['nodejs-package-install'],
    }
  }

  file { '/usr/local/bin/node':
    ensure  => link,
    target  => '/usr/bin/nodejs',
    require => Anchor['nodejs-package-install'],
    before  => Anchor['nodejs-anchor'],
  }

  anchor { 'nodejs-anchor': }

  if !defined(Package['git']) {
    package { 'git':
      ensure => present
    }
  }

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
    environment => "HOME=${base_install_dir}/${ep_user}",
    require     => [
      Package['curl'],
      Vcsrepo["${base_install_dir}/etherpad-lite"],
      Anchor['nodejs-anchor'],
    ],
    before      => File["${base_install_dir}/etherpad-lite/settings.json"],
    creates     => "${base_install_dir}/etherpad-lite/node_modules",
  }

  case $::operatingsystem {
    'Ubuntu': {
      if $::operatingsystemrelease <= '14.04' {

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

        include ::logrotate
        logrotate::file { 'epliteerror':
          log     => "${base_log_dir}/${ep_user}/error.log",
          options => [
                      'compress',
                      'copytruncate',
                      'missingok',
                      'rotate 7',
                      'daily',
                      'notifempty',
                      ],
        }

        logrotate::file { 'epliteaccess':
          log     => "${base_log_dir}/${ep_user}/access.log",
          options => [
                      'compress',
                      'copytruncate',
                      'missingok',
                      'rotate 7',
                      'daily',
                      'notifempty',
                      ],
        }

        service { 'etherpad-lite':
          ensure => running,
          enable => true,
        }

      } else {

        # Note logs go to syslog, can maybe change when
        # https://github.com/systemd/systemd/pull/7198 is available
        file { '/etc/systemd/system/etherpad-lite.service':
          ensure  => present,
          content => template('etherpad_lite/etherpad-lite.service.erb'),
          replace => true,
          owner   => 'root',
          require => Exec['install_etherpad_dependencies'],
        }

        # This is a hack to make sure that systemd is aware of the new service
        # before we attempt to start it.
        exec { 'etherpad-lite-systemd-daemon-reload':
          command     => '/bin/systemctl daemon-reload',
          before      => Service['etherpad-lite'],
          subscribe   => File['/etc/systemd/system/etherpad-lite.service'],
          refreshonly => true,
        }

        service { 'etherpad-lite':
          ensure  => running,
          enable  => true,
          require => File['/etc/systemd/system/etherpad-lite.service'],
        }
      }
    }
    default: {
      fail('This operating system not supported')
    }
  }

  # end package management ugliness
}
