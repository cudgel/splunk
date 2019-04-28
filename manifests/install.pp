# == Class: splunk::install
#
# This class maintains the installation of Splunk, installing a new Splunk
# instance or upgrading an existing one. Currently it tries to fetch the
# specified version of either splunk or splunkforwarder (depending on the
# type of install) from splunk.com or a hiera-defined server.
# Manages system/local config files, certificates (if defined in hiera and
# served via puppet module), and service installation.
#
# === Examples
#
#  This class is not called directly
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::install
{
  $action       = $splunk::action
  $my_cwd       = $splunk::cwd
  $type         = $splunk::type
  # splunk user home
  $home         = $splunk::home
  $install_path = $splunk::install_path
  # splunk install directory
  $dir          = $splunk::dir
  $local        = $splunk::local
  # splunk or splunkforwarder
  $sourcepart   = $splunk::sourcepart
  # currently installed version from fact
  $cur_version  = $splunk::cur_version
  # new verion from hiera
  $new_version  = $splunk::new_version
  $os           = $splunk::os
  $arch         = $splunk::arch
  $ext          = $splunk::ext
  $tarcmd       = $splunk::tarcmd
  $manifest     = $splunk::manifest
  # splunk (web) or module or a custom url
  $source       = $splunk::source
  $user         = $splunk::user
  $group        = $splunk::group
  $admin_pass   = $splunk::admin_pass

  $perms = "${user}:${group}"

  $stopcmd  = 'splunk stop'

  if $admin_pass != undef and ($my_cwd == undef or $my_cwd != $dir) {
    $seed = " --seed-passwd ${admin_pass}"
  } else {
    $seed = ''
  }
  $startcmd = "splunk start --accept-license --answer-yes --no-prompt${seed}"


  # clean up a splunk instance running out of the wrong directory for the type
  if $action == 'change' {

    exec { 'uninstallSplunkService':
      command => 'splunk disable boot-start',
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      returns => [0, 8]
    }

    exec { 'serviceStop':
      command => $stopcmd,
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      user    => $user,
      group   => $group,
      timeout => 600
    }

    if $my_cwd =~ /\/\w+\/.*/ {
      file { $my_cwd:
        ensure => absent,
        force  => true,
        backup => false
      }
    }

    $wsourcepart = basename($my_cwd)
    if $cur_version != undef {
      $wrongsource = "${wsourcepart}-${cur_version}-${os}-${arch}.${ext}"

      file { "${install_path}/${wrongsource}":
        ensure => absent,
        backup => false
      }
    }

  }

  if $action == 'upgrade' {
    $oldsource = "${sourcepart}-${cur_version}-${os}-${arch}.${ext}"

    file { "${install_path}/${oldsource}":
      ensure => absent
    }
  }

  $newsource   = "${sourcepart}-${new_version}-${os}-${arch}.${ext}"

  splunk::fetch{ 'sourcefile':
    splunk_bundle => $newsource,
    type          => $type,
    source        => $source
  }

  exec { 'unpackSplunk':
    command   => "${tarcmd} ${newsource}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $install_path,
    timeout   => 600,
    subscribe => File["${install_path}/${newsource}"],
    before    => Exec['test_for_splunk'],
    unless    => "test -e ${dir}/${manifest}",
    onlyif    => "test -s ${newsource}",
    creates   => "${dir}/${manifest}"
  }

  exec { 'splunkDir':
    command   => "chown -R ${user}:${group} ${dir}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $install_path,
    subscribe => Exec['unpackSplunk'],
    onlyif    => "test -d ${dir}",
    timeout   => 600,
    returns   => [0, 1]
  }

  exec { 'serviceStart':
    command     => "${stopcmd}; ${startcmd}",
    environment => 'HISTFILE=/dev/null',
    path        => "${dir}/bin:/bin:/usr/bin:",
    user        => $user,
    group       => $group,
    subscribe   => Exec['splunkDir'],
    refreshonly => true
  }

  exec { 'installSplunkService':
    command   => "splunk enable boot-start -user ${user}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $dir,
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk',
    require   => Exec['unpackSplunk'],
    returns   => [0, 8]
  }
}
