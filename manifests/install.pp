# == Class: splunk::install
#
# This class maintains the installation of Splunk, installing a new Splunk
# instance or upgrading an existing one. Currently it tries to fetch the
# specified version of either splunk or splunkforwarder (depending on the
# type of install) from splunk.com or a hiera-defined server.
# Manages system/local config files, certificates (if defined in hiera and
# served via puppet fileserver), and service installation.
#
# === Examples
#
#  class { splunk::install }
#
# === Authors
#
# Christopher Caldwell <author@domain.com>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::install
{
  $action          = $splunk::action
  $my_cwd          = $splunk::cwd
  $type            = $splunk::type
  # splunk user home
  $home            = $splunk::home
  $install_path    = $splunk::install_path
  # splunk install directory
  $dir             = $splunk::dir
  $local           = $splunk::local
  # splunk or splunkforwarder
  $sourcepart      = $splunk::sourcepart
  # currently installed version from fact
  $current_version = $splunk::current_version
  # new verion from hiera
  $new_version     = $splunk::new_version
  $os              = $splunk::os
  $arch            = $splunk::arch
  $ext             = $splunk::ext
  $tarcmd          = $splunk::tarcmd
  $manifest        = $splunk::manifest
  # splunk (web) or fileserver or a custom url
  $source          = $splunk::source
  $splunk_user     = $splunk::splunk_user
  $splunk_group    = $splunk::splunk_group
  $admin_pass      = $splunk::admin_pass

  $perms = "${splunk_user}:${splunk_group}"

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
      user    => $splunk_user,
      group   => $splunk_group,
      timeout => 600
    }

    file { $my_cwd:
      ensure => absent,
      force  => true,
      backup => false
    }

    $wsourcepart = basename($my_cwd)
    if $current_version != undef {
      $wrongsource = "${wsourcepart}-${current_version}-${os}-${arch}.${ext}"

      file { "${install_path}/${wrongsource}":
        ensure => absent,
        backup => false
      }
    }

  }

  if $action == 'upgrade' {
    $oldsource = "${sourcepart}-${current_version}-${os}-${arch}.${ext}"

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
    command   => "chown -R ${splunk_user}:${splunk_group} ${dir}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $install_path,
    subscribe => Exec['unpackSplunk'],
    onlyif    => "test -d ${dir}"
  }

  exec { 'serviceStart':
    command     => "${stopcmd}; ${startcmd}",
    path        => "${dir}/bin:/bin:/usr/bin:",
    user        => $splunk_user,
    group       => $splunk_group,
    subscribe   => Exec['splunkDir'],
    refreshonly => true
  }

  exec { 'installSplunkService':
    command   => "splunk enable boot-start -user ${splunk_user}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $dir,
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk',
    require   => Exec['unpackSplunk'],
    returns   => [0, 8]
  }

}
