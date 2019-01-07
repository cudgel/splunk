# == Class: splunk::config
#
# This class manages system/local config files, certificates (if defined in hiera and
# served via puppet fileserver), and service installation.
#
# === Examples
#
#  class { 'splunk::config': }
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::config
{
  $type              = $splunk::type
  # splunk user home dir from fact
  $splunk_home       = $splunk::splunk_home
  $install_path      = $splunk::install_path
  # where splunk is installed
  $dir               = $splunk::dir
  $local             = $splunk::local
  $splunk_user       = $splunk::splunk_user
  $splunk_group      = $splunk::splunk_group
  $cacert            = $splunk::cacert
  $privkey           = $splunk::privkey
  $servercert        = $splunk::servercert
  $webcert           = $splunk::webcert
  $managesecret      = $splunk::managesecret
  $id                = $splunk::shcluster_id
  $confdeploy        = $splunk::search_deploy
  $repl_port         = $splunk::repl_port
  $repl_count        = $splunk::repl_count
  $shcluster_id      = $splunk::shcluster_id
  $shcluster_mode    = $splunk::shcluster_mode
  $shcluster_label   = $splunk::shcluster_label
  $is_captain        = $splunk::is_captain
  $shcluster_members = $splunk::shcluster_members
  $symmkey           = $splunk::symmkey
  $splunk_acls       = $splunk::acls
  $splunk_inputs     = $splunk::inputs
  $cluster_mode      = $splunk::cluster_mode
  $tcpout            = $splunk::tcpout

  $bashrc = "
SPLUNK_HOME=${dir}
export SPLUNK_HOME
PATH=\$SPLUNK_HOME/bin:\$PATH
export PATH
  "

  $perms = "${splunk_user}:${splunk_group}"

  file { "${splunk_home}/.bashrc.custom":
    owner   => $splunk_user,
    group   => $splunk_group,
    content => $bashrc
  }

  exec { 'test_for_splunk':
    command => "test -d ${dir}/etc",
    path    => "${dir}/bin:/bin:/usr/bin:",
    cwd     => $install_path,
    user    => $splunk_user,
    group   => $splunk_group,
    unless  => "test -d ${dir}/etc"
  }

  file_line { 'splunk-start':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${dir}/bin/splunk\" start --no-prompt --answer-yes\'",
    match   => "^\s\s\"${dir}/bin/splunk\" start",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-stop':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${dir}/bin/splunk\" stop\'",
    match   => "^\s\s\"${dir}/bin/splunk\" stop",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-restart':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${dir}/bin/splunk\" restart\'",
    match   => "^\s\s\"${dir}/bin/splunk\" restart",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-status':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${dir}/bin/splunk\" status\'",
    match   => "^\s\s\"${dir}/bin/splunk\" status",
    require => Exec['test_for_splunk']
  }

  file { "${dir}/etc/splunk-launch.conf":
    content => template("${module_name}/splunk-launch.conf.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    notify  => Service['splunk'],
    require => Exec['test_for_splunk']
  }

  if $cacert != 'cacert.pem' {
    file { "${dir}/etc/auth/${cacert}":
      source  => "puppet:///splunk_files/auth/${cacert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service['splunk'],
      require => Exec['test_for_splunk']
    }
  }

  if $privkey != 'privkey.pem' {
    file { "${dir}/etc/auth/splunkweb/${privkey}":
      source  => "puppet:///splunk_files/auth/splunkweb/${privkey}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service['splunk'],
      require => Exec['test_for_splunk']
    }
  }

  if $servercert != 'server.pem' {
    file { "${dir}/etc/auth/${servercert}":
      source  => "puppet:///splunk_files/auth/${servercert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service['splunk'],
      require => Exec['test_for_splunk']
    }
  }

  if $webcert != 'cert.pem' {
    file { "${dir}/etc/auth/splunkweb/${webcert}":
      source  => "puppet:///splunk_files/auth/splunkweb/${webcert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service['splunk'],
      require => Exec['test_for_splunk']
    }
  }

  if $managesecret == true {
    file { "${dir}/etc/splunk.secret":
      ensure => absent
    }

    file { "${dir}/etc/auth/splunk.secret":
      source  => 'puppet:///splunk_files/splunk.secret',
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service['splunk'],
      require => Exec['test_for_splunk']
    }
  }

  file { "${dir}/etc/apps":
    ensure  => 'directory',
    mode    => '0770',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { $local:
    ensure  => 'directory',
    mode    => '0750',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${local}/inputs.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${local}/inputs.d/000_default":
    content => template("${module_name}/inputs.d/default_inputs.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    require => File["${local}/inputs.d"]
  }

  file { "${local}/inputs.d/000_splunkssl":
    content => template("${module_name}/inputs.d/ssl.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs']
  }

  if $type != 'forwarder' {

    if ($type != 'indexer') and ($type != 'standalone')  and is_hash($tcpout) {
      file { "${local}/outputs.d":
        ensure  => 'directory',
        mode    => '0750',
        owner   => $splunk_user,
        group   => $splunk_group,
        require => Exec['test_for_splunk']
      }

      file { "${local}/outputs.d/000_default":
        content => template("${module_name}/outputs.d/outputs.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${local}/outputs.d"],
        notify  => Exec['update-outputs']
      }
    }

    file { "${local}/server.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $splunk_user,
      group   => $splunk_group,
      require => Exec['test_for_splunk']
    }

    file { "${local}/server.d/000_default":
      ensure => absent
    }

    file { "${local}/server.d/000_header":
      content => '# DO NOT EDIT -- Managed by Puppet',
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/server.d/001_license":
      content => template("${module_name}/server.d/license.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${local}/server.d"]
    }

    if $cluster_mode != 'none' {
      file { "${local}/server.d/997_ixclustering":
      content => template("${module_name}/server.d/ixclustering.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }
    }

    file { "${local}/server.d/998_ssl":
      content => template("${module_name}/server.d/ssl_server.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/server.d/999_default":
      content => template("${module_name}/server.d/default_server.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/web.conf":
      content => template("${module_name}/web.conf.erb"),
      alias   => 'splunk-web',
      owner   => $splunk_user,
      group   => $splunk_user,
      require => Exec['test_for_splunk'],
      notify  => Service['splunk']
    }

    if $type == 'indexer' {

      file { "${local}/inputs.d/999_splunktcp":
        content => template("${module_name}/inputs.d/splunktcp.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${local}/inputs.d"],
        notify  => Exec['update-inputs']
      }

      if $cluster_mode != 'none' {
        file { "${local}/server.d/995_replication":
        content => template("${module_name}/server.d/replication.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${local}/server.d"],
        notify  => Exec['update-server']
      }
      }

    }

    if ($type == 'search') or ($type == 'standalone') {

      if $shcluster_mode == 'peer' {

        unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {

          exec { 'join_cluster':
            command     => "splunk init shcluster-config -auth admin:changme -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} -secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
            environment => "SPLUNK_HOME=${dir}",
            path        => "${dir}/bin:/bin:/usr/bin:",
            cwd         => $dir,
            timeout     => 600,
            user        => $splunk_user,
            group       => $splunk_group,
            onlyif      => 'splunk status',
            require     => Exec['test_for_splunk']
          }

          if $is_captain == true and $shcluster_members != undef {
            $shcluster_members.each |String $member| {
              $servers_list = "${servers_list}.${member}:8089"
            }

            exec { 'bootstrap_cluster':
              command     => "splunk bootstrap shcluster-captain -servers_list \"${servers_list}\" -auth admin:changme",
              environment => "SPLUNK_HOME=${dir}",
              path        => "${dir}/bin:/bin:/usr/bin:",
              cwd         => $dir,
              user        => $splunk_user,
              group       => $splunk_group,
              onlyif      => 'splunk status',
              require     => Exec['test_for_splunk']
            }
          }

        }
      }

      if $::osfamily == 'RedHat' {
        # support PDF Report Server
        package { [
          'xorg-x11-server-Xvfb',
          'liberation-mono-fonts',
          'liberation-sans-fonts',
          'liberation-serif-fonts' ]:
          ensure => installed
        }
      } elsif $::osfamily == 'Debian' {
        package { [
          'xvfb',
          'fonts-liberation' ]:
          ensure => installed
        }
      }

      file { "${local}/default-mode.conf":
        alias   => 'splunk-mode',
        content => template("${module_name}/default-mode.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/alert_actions.conf":
        alias   => 'alert-actions',
        content => template("${module_name}/alert_actions.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/ui-prefs.conf":
        content => template("${module_name}/ui-prefs.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/limits.conf":
        content => template("${module_name}/limits.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      if ($shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/) or ($shcluster_mode == 'deployer') {
        # if clustering has already been set up, manage configs
        file { "${local}/server.d/996_shclustering":
          content => template("${module_name}/server.d/shclustering.erb"),
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${local}/server.d"],
          notify  => Exec['update-server']
        }

        file { "${local}/server.d/995_replication":
          content => template("${module_name}/server.d/replication.erb"),
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${local}/server.d"],
          notify  => Exec['update-server']
        }
      } else {
        # remove any fragments from unconfigured shc member or standalone
        file { "${local}/server.d/996_shclustering":
          ensure => absent,
          notify => Exec['update-server']
        }

        file { "${local}/server.d/995_replication":
          ensure => absent,
          notify => Exec['update-server']
        }
      }
    }
  }

  if is_hash($splunk_inputs) and $splunk_inputs != undef {
    create_resources('splunk::input', $splunk_inputs)
  }
  if is_hash($splunk_acls) and $splunk_acls != undef {
    create_resources('splunk::acl', $splunk_acls)
  }
}
