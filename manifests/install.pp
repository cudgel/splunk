# == Class: splunk::install
#
# This class maintains the installation of Splunk, installing a new Splunk
# instance or upgrading an existing one.
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
  $action            = $splunk::action
  $my_cwd            = $splunk::cwd
  $type              = $splunk::type
  # splunk user home
  $home              = $splunk::home
  $install_path      = $splunk::install_path
  $use_systemd       = $splunk::use_systemd
  # splunk install directory
  $dir               = $splunk::dir
  $local             = $splunk::local
  # splunk or splunkforwarder
  $sourcepart        = $splunk::sourcepart
  # currently installed version from fact
  $cur_version       = $splunk::cur_version
  # new verion from hiera
  $newsource         = $splunk::newsource
  $os                = $splunk::os
  $arch              = $splunk::arch
  $ext               = $splunk::ext
  $tarcmd            = $splunk::tarcmd
  $manifest          = $splunk::manifest
  # splunk (web) or module or a custom url
  $confdeploy        = $splunk::search_deploy
  $repl_port         = $splunk::repl_port
  $repl_count        = $splunk::repl_count
  $source            = $splunk::source
  $user              = $splunk::user
  $group             = $splunk::group
  $admin_pass        = $splunk::admin_pass
  $shcluster_id      = $splunk::shcluster_id
  $shcluster_mode    = $splunk::shcluster_mode
  $shcluster_label   = $splunk::shcluster_label
  $is_captain        = $splunk::is_captain
  $shcluster_members = $splunk::shcluster_members
  $symmkey           = $splunk::symmkey
  $perms = "${user}:${group}"

  if $admin_pass != undef and ($my_cwd == undef or $my_cwd != $dir) {
    $seed = " --seed-passwd ${admin_pass}"
  } else {
    $seed = ''
  }

  $stopcmd = 'splunk stop'
  $args = "--accept-license --answer-yes --no-prompt${seed}"
  if $use_systemd == true {
    $startcmd = 'splunk start'
    $enablecmd = "splunk enable boot-start -systemd-managed 1 -user ${user}"
    $disablecmd = 'splunk disable boot-start -systemd-managed 1'
    $changecmd = "${stopcmd} && ${disablecmd}"
    $upgradecmd = "${stopcmd} && ${startcmd} ${args}"
    $installcmd = "${startcmd} ${args}" && ${stopcmd} && ${enablecmd} && ${startcmd}"
    $installfile = '/etc/systemd/system/splunk.service'
  } else {
    $startcmd = "splunk start ${args}"
    $enablecmd = "splunk enable boot-start -systemd-managed 0 -user ${user}"
    $disablecmd = 'splunk disable boot-start'
    $changecmd = "${disablecmd} && ${stopcmd}"
    $upgradecmd = "${stopcmd} && ${startcmd}"
    $installcmd = "${startcmd} && ${enablecmd}"
    $installfile = '/etc/init.d/splunk'
  }

  # clean up a splunk instance running out of the wrong directory for the type
  if $action == 'change' {

    exec { 'serviceChange':
      command => $changecmd,
      path    => "${my_cwd}/bin:/bin:/usr/bin:",
      timeout => 600
    }

    if $my_cwd =~ /\/\w+\/.*/ {
      file { $my_cwd:
        ensure  => absent,
        force   => true,
        backup  => false,
        require => Exec['serviceChange']
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

  exec { 'splunkDir':
    command => "mkdir -p ${dir} && chown ${user}:${group} ${dir}",
    path    => '/bin:/usr/bin',
    cwd     => $install_path,
    before  => Exec['unpackSplunk'],
    unless  => "test -d ${dir}"
  }

  exec { 'unpackSplunk':
    command   => "${tarcmd} ${newsource}",
    path      => '/bin:/usr/bin',
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
    subscribe => Exec['unpackSplunk'],
    require   => Exec['unpackSplunk']
  }

  if $action == 'upgrade' {
    exec { 'serviceStart':
      command     => $upgradecmd,
      environment => 'HISTFILE=/dev/null',
      path        => "${dir}/bin:/bin:/usr/bin:",
      subscribe   => Exec['unpackSplunk'],
      timeout     => 600,
      refreshonly => true
    }
  } else {
    exec { 'serviceInstall':
      command     => $installcmd,
      environment => 'HISTFILE=/dev/null',
      path        => "${dir}/bin:/bin:/usr/bin:",
      cwd         => $dir,
      timeout     => 600,
      unless      => "test -e ${installfile}",
      creates     => $installfile,
      require     => Exec['unpackSplunk'],
      returns     => [0, 8]
    }
  }

  if ($type == 'search') and $shcluster_mode == 'peer' {

    unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {

      $joincmd = "sleep 30 && splunk init shcluster-config -auth admin:${admin_pass} -mgmt_uri https://${::fqdn}:8089 \
-replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} \
-secret ${symmkey} -shcluster_label ${shcluster_label}"

      exec { 'join_cluster':
        command     => $joincmd,
        timeout     => 600,
        environment => "SPLUNK_HOME=${dir}",
        path        => "${dir}/bin:/bin:/usr/bin:",
        user        => $user,
        group       => $group,
        require     => Exec['serviceInstall']
      }

      if $is_captain == true and $shcluster_members != undef {

        $servers_list = join($shcluster_members, ',')

        $bootstrap_cmd = "splunk restart && sleep 30 && sudo -u splunk ${dir}/bin/splunk bootstrap shcluster-captain \
-servers_list \"${servers_list}\" -auth admin:${admin_pass}"

        exec { 'bootstrap_cluster':
          command     => $bootstrap_cmd,
          timeout     => 600,
          environment => "SPLUNK_HOME=${dir}",
          path        => "${dir}/bin:/bin:/usr/bin:",
          require     => Exec['serviceInstall']
        }
      }
    }
  }

}
