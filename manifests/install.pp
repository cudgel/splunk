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
  $my_cwd          = $splunk::cwd
  $type            = $splunk::type
  # splunk user home dir from fact
  $splunk_home     = $splunk::splunk_home
  $install_path    = $splunk::install_path
  # where splunk is installed
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
  $perms           = $splunk::perms
  $adminpass       = $splunk::adminpass

  $stopcmd  = 'splunk stop'
  $startcmd = 'splunk start --accept-license --answer-yes --no-prompt'

  # clean up a splunk instance running out of the wrong directory for this role
  if $my_cwd != $dir and $my_cwd != '' {

    exec { 'uninstallSplunkService':
      command => 'splunk disable boot-start',
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      cwd     => $my_cwd,
      returns => [0, 8]
    }

    exec { 'serviceStop':
      command   => $stopcmd,
      path      => "${my_cwd}/bin:/bin:/usr/bin:",
      user      => $splunk_user,
      group     => $splunk_group,
      subscribe => Exec['uninstallSplunkService'],
      before    => File[$my_cwd],
      timeout   => 600
    }

    file { $my_cwd:
      ensure    => absent,
      subscribe => Exec['serviceStop']
    }

  }

  if $current_version != undef and $my_cwd == $dir {
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

  if $splunk_home != $dir {
    file { $dir:
      ensure  => directory,
      owner   => $splunk_user,
      group   => $splunk_group,
      require => User[$splunk_user]
    }
  }


  exec { 'unpackSplunk':
    command   => "${tarcmd} ${newsource}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $install_path,
    timeout   => 600,
    user      => $splunk_user,
    group     => $splunk_group,
    subscribe => File["${install_path}/${newsource}"],
    before    => Exec['test_for_splunk'],
    unless    => "test -e ${dir}/${manifest}",
    onlyif    => "test -s ${newsource} \
    && test -d ${dir}",
    creates   => "${dir}/${manifest}"
  }

  exec { 'serviceStart':
    command     => "${stopcmd}; ${startcmd}",
    path        => "${dir}/bin:/bin:/usr/bin:",
    user        => $splunk_user,
    group       => $splunk_group,
    subscribe   => Exec['unpackSplunk'],
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
