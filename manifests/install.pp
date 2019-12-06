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


  if $admin_pass != undef and ($my_cwd == undef or $my_cwd != $dir) {
    $seed = " --seed-passwd ${admin_pass}"
  } else {
    $seed = ''
  }
  $startcmd = "splunk start --accept-license --answer-yes --no-prompt${seed}"
  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) >= 7 {
    $enablecmd = "splunk enable boot-start -systemd-managed 1 -user ${user}"
    $disablecmd = 'splunk disable boot-start -systemd-managed 1'
    if $type == 'forwarder' {
      $stopcmd = 'systemctl stop SplunkForwarder'
    } else {
      $stopcmd = 'systemctl stop Splunkd'
    }
  } else {
    $enablecmd = "splunk enable boot-start -systemd-managed 0 -user ${user}"
    $disablecmd = 'splunk disable boot-start'
    $stopcmd = 'splunk stop'
  }

  # clean up a splunk instance running out of the wrong directory for the type
  if $action == 'change' {

    exec { 'uninstallSplunkService':
      command => $disablecmd,
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      returns => [0, 8]
    }

    exec { 'serviceStop':
      command => $stopcmd,
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      timeout => 600
    }

    if $my_cwd =~ /\/\w+\/.*/ {
      file { $my_cwd:
        ensure  => absent,
        force   => true,
        backup  => false,
        require => Exec['serviceStop']
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

  exec { 'splunkDir':
    command => "mkdir -p ${dir} && chown ${user}:${group} ${dir}",
    path    => "${dir}/bin:/bin:/usr/bin:",
    cwd     => $install_path,
    before  => Exec['unpackSplunk'],
    unless  => "test -d ${dir}"
  }

  exec { 'unpackSplunk':
    command   => "${tarcmd} ${newsource}",
    path      => "${dir}/bin:/bin:/usr/bin:",
    user      => $user,
    group     => $group,
    cwd       => $install_path,
    timeout   => 600,
    subscribe => File["${install_path}/${newsource}"],
    before    => Exec['test_for_splunk'],
    unless    => "test -e ${dir}/${manifest}",
    onlyif    => "test -s ${newsource}",
    creates   => "${dir}/${manifest}"
  }

  file { "${dir}/etc/splunk-launch.conf":
    content   => template("${module_name}/splunk-launch.conf.erb"),
    owner     => $user,
    group     => $group,
    notify    => Service['splunk'],
    subscribe => Exec['unpackSplunk']
  }

  if $my_cwd =~ /\/\w+\/.*/ {
    $servicecmd = "${stopcmd}; ${startcmd}"
  } else {
    $servicecmd = $startcmd
  }

  exec { 'serviceStart':
    command     => $servicecmd,
    environment => 'HISTFILE=/dev/null',
    path        => "${dir}/bin:/bin:/usr/bin:",
    subscribe   => Exec['unpackSplunk'],
    refreshonly => true
  }

  exec { 'installSplunkService':
    command   => $enablecmd,
    path      => "${dir}/bin:/bin:/usr/bin:",
    cwd       => $dir,
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk',
    require   => Exec['unpackSplunk'],
    returns   => [0, 8]
  }
}
