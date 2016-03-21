# == Define: buildsource
#
# define to build from source using ./configure && make && make install.
#
define etherpad_lite::buildsource(
  $creates = '/nonexistant/file',
  $dir     = $title,
  $timeout = 300,
  $user    = 'root',
) {

  exec { "./configure in ${dir}":
    command => './configure',
    path    => "/usr/bin:/bin:/usr/local/bin:${dir}",
    user    => $user,
    cwd     => $dir,
    creates => $creates,
    before  => Exec["make in ${dir}"],
  }

  exec { "make in ${dir}":
    command => 'make',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    timeout => $timeout,
    creates => $creates,
    before  => Exec["make install in ${dir}"],
  }

  exec { "make install in ${dir}":
    command => 'make install',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    creates => $creates,
  }
}
