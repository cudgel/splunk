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
  $type              = $::splunk::type
  # splunk user home dir from fact
  $splunk_home       = $::splunk::splunk_home
  $install_path      = $::splunk::install_path
  # where splunk is installed
  $splunkdir         = $::splunk::splunkdir
  $splunk_local      = "${splunkdir}/etc/system/local"
  # splunk or splunkforwarder
  $sourcepart        = $::splunk::sourcepart
  # currently installed version from fact
  $current_version   = $::splunk::current_version
  # new verion from hiera
  $new_version       = $::splunk::new_version
  $splunkos          = $::splunk::splunkos
  $splunkarch        = $::splunk::splunkarch
  $splunkext         = $::splunk::splunkext
  $tarcmd            = $::splunk::params::tarcmd
  $manifest          = $::splunk::manifest
  # splunk (web) or fileserver or a custom url
  $source            = $::splunk::params::source
  $splunk_user       = $::splunk::splunk_user
  $splunk_group      = $::splunk::splunk_group
  $my_perms          = "${::splunk_user}:${::splunk_group}"
  $adminpass         = $::splunk::params::adminpass


  if $current_version != undef {
    $oldsource = "${sourcepart}-${current_version}-${splunkos}-${splunkarch}.${splunkext}"

    file { "${install_path}/${oldsource}":
      ensure => absent
    }
  } else {
    $new_install = true
  }

  $newsource   = "${sourcepart}-${new_version}-${splunkos}-${splunkarch}.${splunkext}"

  splunk::fetch{ 'sourcefile':
    splunk_bundle => $newsource,
    type          => $type,
    source        => $source
  }

  $stopcmd  = 'splunk stop'
  $startcmd = 'splunk start --accept-license --answer-yes --no-prompt'

  exec { 'unpackSplunk':

    command   => "${tarcmd} ${newsource}",
    path      => "${splunkdir}/bin:/bin:/usr/bin:",
    cwd       => $install_path,
    timeout   => 600,
    user      => $splunk_user,
    group     => $splunk_group,
    subscribe => File["${install_path}/${newsource}"],
    before    => Exec['test_for_splunk'],
    unless    => "test -e ${splunkdir}/${manifest}",
    onlyif    => "test -s ${newsource} \
    && test -d ${splunkdir}",
    creates   => "${splunkdir}/${manifest}"
  }

  exec { 'serviceStart':
    command     => "${stopcmd}; ${startcmd}",
    path        => "${splunkdir}/bin:/bin:/usr/bin:",
    user        => $splunk_user,
    group       => $splunk_group,
    subscribe   => Exec['unpackSplunk'],
    refreshonly => true
  }

  exec { 'installSplunkService':
    command   => 'splunk enable boot-start',
    path      => "${splunkdir}/bin:/bin:/usr/bin:",
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk'
  }

}
